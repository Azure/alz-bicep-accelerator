metadata name = 'ALZ Bicep - Landing Zones-Online Module'
metadata description = 'ALZ Bicep Module used to deploy the Landing Zones-Online Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Landing Zones-Online.')
param landingZonesOnlineConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

@description('Optional. Policy assignment parameter overrides. Specify only the policy parameter values you want to override (currently no policies assigned to this management group). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

// Built-in Azure RBAC role definition IDs (ready for future use)
// var builtInRoleDefinitionIds = {
//   contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
//   reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
// }

// var builtInRoleDefinitionIds = {
//   contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
// }
var alzRbacRoleDefsJson = []

var alzPolicyDefsJson = []

var alzPolicySetDefsJson = []

var alzPolicyAssignmentsJson = []

var managementGroupFinalName = landingZonesOnlineConfig.?managementGroupName ?? 'online'
var intRootManagementGroupFinalName = landingZonesOnlineConfig.?managementGroupIntermediateRootName ?? 'alz'

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

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, landingZonesOnlineConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, landingZonesOnlineConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, landingZonesOnlineConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(
  alzPolicyAssignmentsWithOverrides,
  landingZonesOnlineConfig.?customerPolicyAssignments ?? []
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
      description: policy.properties.description
      displayName: policy.properties.displayName
      metadata: policy.properties.metadata
      parameters: policy.properties.parameters
      policyType: policy.properties.policyType
    }
  }
]

var allPolicySetDefinitions = [
  for policySet in unionedPolicySetDefs: {
    name: policySet.name
    properties: {
      description: policySet.properties.description
      displayName: policySet.properties.displayName
      metadata: policySet.properties.metadata
      parameters: policySet.properties.parameters
      policyType: policySet.properties.policyType
      version: policySet.properties.version
      policyDefinitions: policySet.properties.policyDefinitions
    }
  }
]

var allPolicyAssignments = [
  for policyAssignment in deduplicatedPolicyAssignments: {
    name: policyAssignment.name
    description: policyAssignment.properties.description
    displayName: policyAssignment.properties.displayName
    policyDefinitionId: policyAssignment.properties.policyDefinitionId
    enforcementMode: policyAssignment.properties.enforcementMode
    identity: policyAssignment.properties.identity
    userAssignedIdentityId: policyAssignment.properties.userAssignedIdentity
    roleDefinitionIds: policyAssignment.properties.roleDefinitionIds
    parameters: policyAssignment.properties.parameters
    nonComplianceMessages: policyAssignment.properties.nonComplianceMessages
    metadata: policyAssignment.properties.metadata
    overrides: policyAssignment.properties.overrides
    resourceSelectors: policyAssignment.properties.resourceSelectors
    definitionVersion: policyAssignment.properties.?definitionVersion
    notScopes: policyAssignment.properties.notScopes
    additionalManagementGroupsIDsToAssignRbacTo: policyAssignment.properties.additionalManagementGroupsIDsToAssignRbacTo
    additionalSubscriptionIDsToAssignRbacTo: policyAssignment.properties.additionalSubscriptionIDsToAssignRbacTo
    additionalResourceGroupResourceIDsToAssignRbacTo: policyAssignment.properties.additionalResourceGroupResourceIDsToAssignRbacTo
  }
]

// ============ //
//   Resources  //
// ============ //

module landingZonesOnline 'br/public:avm/ptn/alz/empty:0.3.5' = {
  params: {
    createOrUpdateManagementGroup: landingZonesOnlineConfig.?createOrUpdateManagementGroup
    managementGroupName: managementGroupFinalName
    managementGroupDisplayName: landingZonesOnlineConfig.?managementGroupDisplayName ?? 'Online'
    managementGroupDoNotEnforcePolicyAssignments: landingZonesOnlineConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: landingZonesOnlineConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: landingZonesOnlineConfig.?managementGroupParentId ?? 'landingzones'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: landingZonesOnlineConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: landingZonesOnlineConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: landingZonesOnlineConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: landingZonesOnlineConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: landingZonesOnlineConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: landingZonesOnlineConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: landingZonesOnlineConfig.?waitForConsistencyCounterBeforeRoleAssignments
    waitForConsistencyCounterBeforeSubPlacement: landingZonesOnlineConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../../alzCoreType.bicep'
