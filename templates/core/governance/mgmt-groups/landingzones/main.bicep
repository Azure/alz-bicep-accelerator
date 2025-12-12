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

@description('Optional. Policy assignment parameter overrides. Specify only the policy parameter values you want to change (logAnalytics, backup exclusions, etc.). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

var builtInRoleDefinitionIds = {
  contributor: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  owner: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  reader: '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  vmContributor: '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  networkContributor: '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
  managedIdentityOperator: '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
  managedIdentityContributor: '/providers/Microsoft.Authorization/roleDefinitions/e40ec5ca-96e0-45a2-b4ff-59039f2c2b59'
  logAnalyticsContributor: '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  sqlSecurityManager: '/providers/Microsoft.Authorization/roleDefinitions/056cd41c-7e88-42e1-933e-88ba6a50c9c3'
  sqlDbContributor: '/providers/Microsoft.Authorization/roleDefinitions/9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
  monitoringContributor: '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  connectedMachineResourceAdministrator: '/providers/Microsoft.Authorization/roleDefinitions/cd570a14-e51a-42ad-bac8-bafd67325302'
}

var alzRbacRoleDefsJson = []

var alzPolicyDefsJson = []

var alzPolicySetDefsJson = []

var alzPolicyAssignmentsJson = [
  loadJsonContent('../../lib/alz/landingzones/Audit-AppGW-WAF.alz_policy_assignment.json')
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

var alzPolicyAssignmentRoleDefinitions = {
  'Deploy-GuestAttest': [
    builtInRoleDefinitionIds.reader
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.managedIdentityContributor
  ]
  'Deploy-VM-Backup': [builtInRoleDefinitionIds.owner]
  'Enable-DDoS-VNET': [builtInRoleDefinitionIds.networkContributor]
  'Enforce-TLS-SSL-Q225': [builtInRoleDefinitionIds.owner]
  'Deploy-AzSqlDb-Auditing': [
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.sqlSecurityManager
  ]
  'Deploy-SQL-Threat': [builtInRoleDefinitionIds.owner]
  'Deploy-SQL-TDE': [builtInRoleDefinitionIds.sqlDbContributor]
  'Deploy-vmArc-ChangeTrack': [
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-VM-ChangeTrack': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-VMSS-ChangeTrack': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-vmHybr-Monitoring': [
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.reader
    builtInRoleDefinitionIds.connectedMachineResourceAdministrator
  ]
  'Deploy-VM-Monitoring': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-VMSS-Monitoring': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-MDFC-DefSQL-AMA': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Enforce-ASR': [builtInRoleDefinitionIds.contributor]
  'Enable-AUM-CheckUpdates': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.connectedMachineResourceAdministrator
    builtInRoleDefinitionIds.managedIdentityOperator
  ]
  'Enforce-Encrypt-CMK0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-APIM0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-AppServices0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-Automation0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-BotService0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-CogServ0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-Compute0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-ContApps0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-ContInst0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-ContReg0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-CosmosDb0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-DataExpl0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-DataFactory0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-EventGrid0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-EventHub0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-KeyVault': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-KeyVaultSup0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-Kubernetes0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-MachLearn0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-MySQL0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-Network0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-OpenAI0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-PostgreSQL0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-ServiceBus0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-SQL0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-Storage0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-Synapse0': [builtInRoleDefinitionIds.contributor]
  'Enforce-GR-VirtualDesk0': [builtInRoleDefinitionIds.contributor]
  'Enforce-Subnet-Private': [builtInRoleDefinitionIds.contributor]
}

var managementGroupFinalName = landingZonesConfig.?managementGroupName ?? 'landingzones'
var intRootManagementGroupFinalName = landingZonesConfig.?managementGroupIntermediateRootName ?? 'alz'

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

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, landingZonesConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, landingZonesConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, landingZonesConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(
  alzPolicyAssignmentsWithOverrides,
  landingZonesConfig.?customerPolicyAssignments ?? []
)

var unionedPolicyAssignmentNames = [for policyAssignment in unionedPolicyAssignments: policyAssignment.name]

var deduplicatedPolicyAssignments = filter(
  unionedPolicyAssignments,
  (policyAssignment, index) => index == indexOf(unionedPolicyAssignmentNames, policyAssignment.name)
)

var allRbacRoleDefs = [
  for roleDef in unionedRbacRoleDefs: {
    name: roleDef.name
    roleName: replace(roleDef.properties.roleName, '(alz)', '(${managementGroupFinalName})')
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

module landingZones 'br/public:avm/ptn/alz/empty:0.3.5' = {
  params: {
    createOrUpdateManagementGroup: landingZonesConfig.?createOrUpdateManagementGroup
    managementGroupName: managementGroupFinalName
    managementGroupDisplayName: landingZonesConfig.?managementGroupDisplayName ?? 'Landing zones'
    managementGroupDoNotEnforcePolicyAssignments: landingZonesConfig.?managementGroupDoNotEnforcePolicyAssignments ?? []
    managementGroupExcludedPolicyAssignments: landingZonesConfig.?managementGroupExcludedPolicyAssignments ?? []
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
    waitForConsistencyCounterBeforeRoleAssignments: landingZonesConfig.?waitForConsistencyCounterBeforeRoleAssignments
    waitForConsistencyCounterBeforeSubPlacement: landingZonesConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../alzCoreType.bicep'
