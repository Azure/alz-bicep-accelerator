metadata name = 'ALZ Bicep - Platform-Identity Module'
metadata description = 'ALZ Bicep Module used to deploy the Platform-Identity Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Platform-Identity.')
param platformIdentityConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

@description('Optional. Policy assignment parameter overrides. Specify only the policy parameter values you want to change (logAnalytics, etc.). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

var builtInRoleDefinitionIds = {
  contributor: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  vmContributor: '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  backupContributor: '/providers/Microsoft.Authorization/roleDefinitions/5e467623-bb1f-42f4-a55d-6e525e11384b'
  reader: '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var alzRbacRoleDefsJson = []

var alzPolicyDefsJson = []

var alzPolicySetDefsJson = []

var alzPolicyAssignmentsJson = [
  loadJsonContent('../../../lib/alz/platform/identity/Deny-MgmtPorts-Internet.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/platform/identity/Deny-Public-IP.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/platform/identity/Deny-Subnet-Without-Nsg.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/platform/identity/Deploy-VM-Backup.alz_policy_assignment.json')
]

var alzPolicyAssignmentRoleDefinitions = {
  'Deploy-VM-Backup': [builtInRoleDefinitionIds.backupContributor, builtInRoleDefinitionIds.vmContributor]
}

var managementGroupFinalName = platformIdentityConfig.?managementGroupName ?? 'identity'
var intRootManagementGroupFinalName = platformIdentityConfig.?managementGroupIntermediateRootName ?? 'alz'

var alzPolicyAssignmentsWithOverrides = [
  for policyAssignment in alzPolicyAssignmentsJson: union(
    policyAssignment,
    contains(parPolicyAssignmentParameterOverrides, policyAssignment.name)
      ? {
          location: parPolicyAssignmentParameterOverrides[policyAssignment.name].?location ?? parLocations[0]
          identity: policyAssignment.?identity
          properties: union(
            policyAssignment.properties,
            parPolicyAssignmentParameterOverrides[policyAssignment.name].?scope != null
              ? {
                  scope: parPolicyAssignmentParameterOverrides[policyAssignment.name].scope
                }
              : {
                  scope: '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}'
                },
            contains(parPolicyAssignmentParameterOverrides[policyAssignment.name], 'parameters')
              ? {
                  parameters: union(
                    policyAssignment.properties.?parameters ?? {},
                    parPolicyAssignmentParameterOverrides[policyAssignment.name].parameters
                  )
                }
              : {},
            contains(alzPolicyAssignmentRoleDefinitions, policyAssignment.name)
              ? {
                  roleDefinitionIds: alzPolicyAssignmentRoleDefinitions[policyAssignment.name]
                }
              : {},
            {
              policyDefinitionId: replace(
                replace(
                  policyAssignment.properties.policyDefinitionId,
                  '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}/',
                  '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
                ),
                '/providers/Microsoft.Management/managementGroups/alz/',
                '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
              )
            }
          )
        }
      : {
          location: parLocations[0]
          identity: policyAssignment.?identity
          properties: union(
            policyAssignment.properties,
            {
              scope: '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}'
            },
            contains(alzPolicyAssignmentRoleDefinitions, policyAssignment.name)
              ? {
                  roleDefinitionIds: alzPolicyAssignmentRoleDefinitions[policyAssignment.name]
                }
              : {},
            {
              policyDefinitionId: replace(
                replace(
                  policyAssignment.properties.policyDefinitionId,
                  '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}/',
                  '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
                ),
                '/providers/Microsoft.Management/managementGroups/alz/',
                '/providers/Microsoft.Management/managementGroups/${intRootManagementGroupFinalName}/'
              )
            }
          )
        }
  )
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, platformIdentityConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, platformIdentityConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, platformIdentityConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(
  alzPolicyAssignmentsWithOverrides,
  platformIdentityConfig.?customerPolicyAssignments ?? []
)

var unionedPolicyAssignmentNames = [for policyAssignment in unionedPolicyAssignments: policyAssignment.name]

var deduplicatedPolicyAssignments = filter(
  unionedPolicyAssignments,
  (policyAssignment, index) => index == indexOf(unionedPolicyAssignmentNames, policyAssignment.name)
)

var allRbacRoleDefs = [
  for roleDef in unionedRbacRoleDefs: {
    name: roleDef.name
    roleName: replace(roleDef.properties.roleName, '(alz)', '(${managementGroup().name})')
    description: roleDef.properties.description
    actions: roleDef.properties.permissions[0].actions
    notActions: roleDef.properties.permissions[0].notActions
    dataActions: roleDef.properties.permissions[0].dataActions
    notDataActions: roleDef.properties.permissions[0].notDataActions
  }
]

var allPolicyDefs = [
  for policy in unionedPolicyDefs: {
    name: policy.name
    properties: {
      description: policy.properties.?description
      displayName: policy.properties.?displayName
      metadata: policy.properties.?metadata
      mode: policy.properties.?mode
      parameters: policy.properties.?parameters
      policyType: policy.properties.?policyType
      policyRule: policy.properties.policyRule
      version: policy.properties.?version
    }
  }
]

var allPolicySetDefinitions = [
  for policySet in unionedPolicySetDefs: {
    name: policySet.name
    properties: {
      description: policySet.properties.?description
      displayName: policySet.properties.?displayName
      metadata: policySet.properties.?metadata
      parameters: policySet.properties.?parameters
      policyType: policySet.properties.?policyType
      version: policySet.properties.?version
      policyDefinitions: policySet.properties.policyDefinitions
      policyDefinitionGroups: policySet.properties.?policyDefinitionGroups
    }
  }
]

var allPolicyAssignments = [
  for policyAssignment in deduplicatedPolicyAssignments: {
    name: policyAssignment.name
    displayName: policyAssignment.properties.?displayName
    description: policyAssignment.properties.?description
    policyDefinitionId: policyAssignment.properties.policyDefinitionId
    parameters: policyAssignment.properties.?parameters
    parameterOverrides: policyAssignment.properties.?parameterOverrides
    identity: policyAssignment.identity.?type ?? 'None'
    userAssignedIdentityId: policyAssignment.properties.?userAssignedIdentityId
    roleDefinitionIds: policyAssignment.properties.?roleDefinitionIds
    nonComplianceMessages: policyAssignment.properties.?nonComplianceMessages
    metadata: policyAssignment.properties.?metadata
    enforcementMode: policyAssignment.properties.?enforcementMode ?? 'Default'
    notScopes: policyAssignment.properties.?notScopes
    location: policyAssignment.?location
    overrides: policyAssignment.properties.?overrides
    resourceSelectors: policyAssignment.properties.?resourceSelectors
    definitionVersion: policyAssignment.properties.?definitionVersion
    additionalManagementGroupsIDsToAssignRbacTo: policyAssignment.properties.?additionalManagementGroupsIDsToAssignRbacTo
    additionalSubscriptionIDsToAssignRbacTo: policyAssignment.properties.?additionalSubscriptionIDsToAssignRbacTo
    additionalResourceGroupResourceIDsToAssignRbacTo: policyAssignment.properties.?additionalResourceGroupResourceIDsToAssignRbacTo
  }
]

// ============ //
//   Resources  //
// ============ //

module platformIdentity 'br/public:avm/ptn/alz/empty:0.3.5' = {
  params: {
    createOrUpdateManagementGroup: platformIdentityConfig.?createOrUpdateManagementGroup
    managementGroupName: managementGroupFinalName
    managementGroupDisplayName: platformIdentityConfig.?managementGroupDisplayName ?? 'identity'
    managementGroupDoNotEnforcePolicyAssignments: platformIdentityConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: platformIdentityConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: platformIdentityConfig.?managementGroupParentId ?? 'platform'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: platformIdentityConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: platformIdentityConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: platformIdentityConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: platformIdentityConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: platformIdentityConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: platformIdentityConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: platformIdentityConfig.?waitForConsistencyCounterBeforeRoleAssignments
    waitForConsistencyCounterBeforeSubPlacement: platformIdentityConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../../alzCoreType.bicep'

