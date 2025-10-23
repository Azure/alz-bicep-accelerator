metadata name = 'ALZ Bicep - Platform-Management Module'
metadata description = 'ALZ Bicep Module used to deploy the Platform-Management Group and associated resources such as policy/policy set definitions, custom RBAC roles, and policy assignments.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Platform-Management.')
param platformManagementConfig alzCoreType

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var alzRbacRoleDefsJson = []

var alzPolicyDefsJson = []

var alzPolicySetDefsJson = []

var alzPolicyAssignmentsDefs = [
  loadJsonContent('../lib/policy_assignments/Audit-TrustedLaunch.alz_policy_assignment.json')
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, platformManagementConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, platformManagementConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, platformManagementConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsDefs, platformManagementConfig.?customerPolicyAssignments ?? [])

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
  for policyAssignment in unionedPolicyAssignments: {
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

module platformManagement 'br/public:avm/ptn/alz/empty:0.2.0' = {
  params: {
    createOrUpdateManagementGroup: platformManagementConfig.?createOrUpdateManagementGroup
    managementGroupName: platformManagementConfig.?managementGroupName ?? 'alz-platform-management'
    managementGroupDisplayName: platformManagementConfig.?managementGroupDisplayName ?? 'Management'
    managementGroupParentId: platformManagementConfig.?managementGroupParentId ?? 'alz-platform'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: platformManagementConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: platformManagementConfig.?location
    subscriptionsToPlaceInManagementGroup: platformManagementConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: platformManagementConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: platformManagementConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: platformManagementConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: platformManagementConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: platformManagementConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: platformManagementConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parTelemetryOptOut ? false : true
  }
}

// ================ //
// Type Definitions
// ================ //

import {alzCoreType as alzCoreType} from '../int-root/main.bicep'
