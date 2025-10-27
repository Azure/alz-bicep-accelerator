metadata name = 'ALZ Bicep - Landing Zones-Corp Module'
metadata description = 'ALZ Bicep Module used to deploy the Landing Zones-Corp Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Landing Zones-Corp.')
param landingZonesCorpConfig alzCoreType

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var alzRbacRoleDefsJson = [
]

var alzPolicyDefsJson = [
]

var alzPolicySetDefsJson = [
]

var alzPolicyAssignmentsDefs = [
  loadJsonContent('../../../lib/alz/landingzones/corp/Audit-PeDnsZones.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/corp/Deny-HybridNetworking.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/corp/Deny-Public-Endpoints.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/corp/Deny-Public-IP-On-NIC.alz_policy_assignment.json')
  loadJsonContent('../../../lib/alz/landingzones/corp/Deploy-Private-DNS-Zones.alz_policy_assignment.json')
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, landingZonesCorpConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, landingZonesCorpConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, landingZonesCorpConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsDefs, landingZonesCorpConfig.?customerPolicyAssignments ?? [])

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

module landingZonesCorp 'br/public:avm/ptn/alz/empty:0.3.1' = {
  params: {
    createOrUpdateManagementGroup: landingZonesCorpConfig.?createOrUpdateManagementGroup
    managementGroupName: landingZonesCorpConfig.?managementGroupName ?? 'alz-landingzones-corp'
    managementGroupDisplayName: landingZonesCorpConfig.?managementGroupDisplayName ?? 'Corp'
    managementGroupDoNotEnforcePolicyAssignments: []
    managementGroupExcludedPolicyAssignments: []
    managementGroupParentId: landingZonesCorpConfig.?managementGroupParentId ?? 'alz-landingzones'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: landingZonesCorpConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: landingZonesCorpConfig.?location
    subscriptionsToPlaceInManagementGroup: landingZonesCorpConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: landingZonesCorpConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: landingZonesCorpConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: landingZonesCorpConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: landingZonesCorpConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: landingZonesCorpConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: landingZonesCorpConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parTelemetryOptOut ? false : true
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../int-root/main.bicep'


