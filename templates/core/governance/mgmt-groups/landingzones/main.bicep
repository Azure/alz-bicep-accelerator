metadata name = 'ALZ Bicep - Landing Zones Module'
metadata description = 'ALZ Bicep Module used to deploy the Landing Zones Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Landing Zones.')
param landingZonesConfig alzCoreType

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

var alzPolicyAssignmentsDefs = [
  loadJsonContent('../../lib/alz/landingzones/Audit-AppGW-WAF.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/corp/Audit-PeDnsZones.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/corp/Deny-HybridNetworking.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/corp/Deny-Public-Endpoints.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/corp/Deny-Public-IP-On-NIC.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/corp/Deploy-Private-DNS-Zones.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deny-IP-forwarding.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deny-MgmtPorts-Internet.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deny-Priv-Esc-AKS.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deny-Privileged-AKS.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deny-Storage-http.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deny-Subnet-Without-Nsg.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-AzSqlDb-Auditing.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-GuestAttest.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-MDFC-DefSQL-AMA.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-SQL-TDE.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-SQL-Threat.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-VM-Backup.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-VM-ChangeTrack.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-VM-Monitoring.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-vmArc-ChangeTrack.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-vmHybr-Monitoring.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-VMSS-ChangeTrack.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Deploy-VMSS-Monitoring.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enable-AUM-CheckUpdates.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enable-DDoS-VNET.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-AKS-HTTPS.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-ASR.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-Encrypt-CMK0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-APIM0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-AppServices0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-Automation0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-BotService0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-CogServ0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-Compute0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-ContApps0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-ContInst0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-ContReg0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-CosmosDb0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-DataExpl0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-DataFactory0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-EventGrid0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-EventHub0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-KeyVault.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-KeyVaultSup0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-Kubernetes0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-MachLearn0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-MySQL0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-Network0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-OpenAI0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-PostgreSQL0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-ServiceBus0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-SQL0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-Storage0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-Synapse0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-GR-VirtualDesk0.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-Subnet-Private.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/landingzones/Enforce-TLS-SSL-Q225.alz_policy_assignment.json')
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, landingZonesConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, landingZonesConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, landingZonesConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsDefs, landingZonesConfig.?customerPolicyAssignments ?? [])

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

module landingZones 'br/public:avm/ptn/alz/empty:0.3.1' = {
  params: {
    createOrUpdateManagementGroup: landingZonesConfig.?createOrUpdateManagementGroup
    managementGroupName: landingZonesConfig.?managementGroupName ?? 'alz-landingzones'
    managementGroupDoNotEnforcePolicyAssignments: []
    managementGroupExcludedPolicyAssignments: []
    managementGroupParentId: landingZonesConfig.?managementGroupParentId ?? 'alz'
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: landingZonesConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: landingZonesConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: landingZonesConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: landingZonesConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: landingZonesConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: landingZonesConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: landingZonesConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: landingZonesConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../int-root/main.bicep'




