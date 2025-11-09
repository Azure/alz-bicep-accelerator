metadata name = 'ALZ Bicep - Platform Module'
metadata description = 'ALZ Bicep Module used to deploy the Platform Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Platform.')
param platformConfig alzCoreType

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
  loadJsonContent('../../lib/alz/platform/DenyAction-DeleteUAMIAMA.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-GuestAttest.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-MDFC-DefSQL-AMA.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-VM-ChangeTrack.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-VM-Monitoring.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-vmArc-ChangeTrack.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-vmHybr-Monitoring.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-VMSS-ChangeTrack.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Deploy-VMSS-Monitoring.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enable-AUM-CheckUpdates.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-ASR.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-Encrypt-CMK0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-APIM0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-AppServices0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-Automation0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-BotService0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-CogServ0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-Compute0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-ContApps0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-ContInst0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-ContReg0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-CosmosDb0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-DataExpl0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-DataFactory0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-EventGrid0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-EventHub0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-KeyVault.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-KeyVaultSup0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-Kubernetes0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-MachLearn0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-MySQL0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-Network0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-OpenAI0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-PostgreSQL0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-ServiceBus0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-SQL0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-Storage0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-Synapse0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-GR-VirtualDesk0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/platform/Enforce-Subnet-Private.alz_policy_assignment.json')
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, platformConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, platformConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, platformConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsJson, platformConfig.?customerPolicyAssignments ?? [])

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

module platform 'br/public:avm/ptn/alz/empty:0.3.1' = {
  params: {
    createOrUpdateManagementGroup: platformConfig.?createOrUpdateManagementGroup
    managementGroupName: platformConfig.?managementGroupName ?? 'alz-platform'
    managementGroupDisplayName: platformConfig.?managementGroupDisplayName ?? 'Platform'
    managementGroupDoNotEnforcePolicyAssignments: platformConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: platformConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: platformConfig.?managementGroupParentId ?? 'alz'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: platformConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: platformConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: platformConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: platformConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: platformConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: platformConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: platformConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: platformConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../int-root/main.bicep'

