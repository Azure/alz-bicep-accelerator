metadata name = 'ALZ Bicep - Decommissioned Module'
metadata description = 'ALZ Bicep Module used to deploy the Decommissioned Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Decommissioned.')
param decommmissionedConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

var alzRbacRoleDefsJson = [
]

var alzPolicyDefsJson = [
]

var alzPolicySetDefsJson = [
]

var alzPolicyAssignmentsJson = [
  loadJsonContent('../../lib/alz/decommissioned/Enforce-ALZ-Decomm.alz_policy_assignment.json')
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, decommmissionedConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, decommmissionedConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, decommmissionedConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsJson, decommmissionedConfig.?customerPolicyAssignments ?? [])

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

module intRoot 'br/public:avm/ptn/alz/empty:0.3.1' = {
  params: {
    createOrUpdateManagementGroup: decommmissionedConfig.?createOrUpdateManagementGroup
    managementGroupName: decommmissionedConfig.?managementGroupName ?? 'alz-decommmissioned'
    managementGroupDisplayName: decommmissionedConfig.?managementGroupDisplayName ?? 'Decommmissioned'
    managementGroupDoNotEnforcePolicyAssignments: decommmissionedConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: decommmissionedConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: decommmissionedConfig.?managementGroupParentId ?? 'alz'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: decommmissionedConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: decommmissionedConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: decommmissionedConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: decommmissionedConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: decommmissionedConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: decommmissionedConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: decommmissionedConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: decommmissionedConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../int-root/main.bicep'




