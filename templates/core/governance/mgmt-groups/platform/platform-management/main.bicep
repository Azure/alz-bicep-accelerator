metadata name = 'ALZ Bicep - Platform-Management Module'
metadata description = 'ALZ Bicep Module used to deploy the Platform-Management Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Platform-Management.')
param platformManagementConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

@description('Optional. Policy assignment parameter overrides. Specify only the policy parameter values you want to change (logAnalytics, etc.). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

// Built-in Azure RBAC role definition IDs (ready for future use)
// var builtInRoleDefinitionIds = {
//   contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   networkContributor: '4d97b98b-1d4f-4787-a291-c67834d212e7'
//   reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
// }

var alzRbacRoleDefsJson = [
]

var alzPolicyDefsJson = [
]

var alzPolicySetDefsJson = [
]

var alzPolicyAssignmentsJson = [
]

// Policy assignment to role definition mappings (ready for future use)
// When adding policy assignments, use this pattern:
// var alzPolicyAssignmentRoleDefinitions = {
//   'Deploy-Log-Analytics': [builtInRoleDefinitionIds.contributor]
// }
// var alzPolicyAssignmentRoleDefinitions = {}

var alzPolicyAssignmentsWithOverrides = [
  for policyAssignment in alzPolicyAssignmentsJson: union(
    policyAssignment,
    contains(parPolicyAssignmentParameterOverrides, policyAssignment.name) ? {
      location: parPolicyAssignmentParameterOverrides[policyAssignment.name].?location ?? parLocations[0]
      properties: union(
        policyAssignment.properties,
        parPolicyAssignmentParameterOverrides[policyAssignment.name].?scope != null ? {
          scope: parPolicyAssignmentParameterOverrides[policyAssignment.name].scope
        } : {
          scope: '/providers/Microsoft.Management/managementGroups/${platformManagementConfig.?managementGroupName ?? 'alz-platform-management'}'
        },
        contains(parPolicyAssignmentParameterOverrides[policyAssignment.name], 'parameters') ? {
          parameters: union(policyAssignment.properties.?parameters ?? {}, parPolicyAssignmentParameterOverrides[policyAssignment.name].parameters)
        } : {}
      )
    } : {
      location: parLocations[0]
      properties: union(
        policyAssignment.properties,
        {
          scope: '/providers/Microsoft.Management/managementGroups/${platformManagementConfig.?managementGroupName ?? 'alz-platform-management'}'
        }
      )
    }
  )
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, platformManagementConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, platformManagementConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, platformManagementConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsWithOverrides, platformManagementConfig.?customerPolicyAssignments ?? [])

var unionedPolicyAssignmentNames = [
  for policyAssignment in unionedPolicyAssignments: policyAssignment.name
]

var deduplicatedPolicyAssignments = filter(
  unionedPolicyAssignments,
  (policyAssignment, index) => index == indexOf(unionedPolicyAssignmentNames, policyAssignment.name)
)

var allRbacRoleDefs = [
  for roleDef in unionedRbacRoleDefs: {
    name: roleDef.name
    roleName: roleDef.properties.roleName
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

module platformManagement 'br/public:avm/ptn/alz/empty:0.3.1' = {
  params: {
    createOrUpdateManagementGroup: platformManagementConfig.?createOrUpdateManagementGroup
    managementGroupName: platformManagementConfig.?managementGroupName ?? 'alz-platform-management'
    managementGroupDisplayName: platformManagementConfig.?managementGroupDisplayName ?? 'management'
    managementGroupDoNotEnforcePolicyAssignments: platformManagementConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: platformManagementConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: platformManagementConfig.?managementGroupParentId ?? 'alz-platform'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: platformManagementConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: platformManagementConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: platformManagementConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: platformManagementConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: platformManagementConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: platformManagementConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: platformManagementConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: platformManagementConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../int-root/main.bicep'



