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

@description('Optional. Policy assignment parameter overrides. Specify only the policy parameter values you want to change (logAnalytics, etc.). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

var builtInRoleDefinitionIds = {
  contributor: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  aksContributor: '/providers/Microsoft.Authorization/roleDefinitions/ed7f3fbd-7b88-4dd4-9017-9adb7ce333f8'
  aksPolicyAddon: '/providers/Microsoft.Authorization/roleDefinitions/18ed5180-3e48-46fd-8541-4ea054d57064'
  logAnalyticsContributor: '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  sqlSecurityManager: '/providers/Microsoft.Authorization/roleDefinitions/056cd41c-7e88-42e1-933e-88ba6a50c9c3'
  sqlDbContributor: '/providers/Microsoft.Authorization/roleDefinitions/9b7fa17d-e63e-47b0-bb0a-15c516ac86ec'
  backupContributor: '/providers/Microsoft.Authorization/roleDefinitions/5e467623-bb1f-42f4-a55d-6e525e11384b'
  vmContributor: '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  connectedMachineResourceAdministrator: '/providers/Microsoft.Authorization/roleDefinitions/cd570a14-e51a-42ad-bac8-bafd67325302'
  monitoringContributor: '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  managedIdentityOperator: '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
  managedIdentityContributor: '/providers/Microsoft.Authorization/roleDefinitions/e40ec5ca-96e0-45a2-b4ff-59039f2c2b59'
  reader: '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

var alzRbacRoleDefsJson = []

var alzPolicyDefsJson = []

var alzPolicySetDefsJson = []

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

var alzPolicyAssignmentRoleDefinitions = {
  'Deploy-AKS-Policy': [builtInRoleDefinitionIds.aksContributor, builtInRoleDefinitionIds.aksPolicyAddon]
  'Deploy-AzActivity-Log': [builtInRoleDefinitionIds.logAnalyticsContributor]
  'Deploy-Diag-LogsCat': [builtInRoleDefinitionIds.logAnalyticsContributor]
  'Deploy-Log-Analytics': [builtInRoleDefinitionIds.logAnalyticsContributor]
  'Deploy-LogicApp-TLS': [builtInRoleDefinitionIds.contributor]
  'Deploy-MDFC-Config': [builtInRoleDefinitionIds.contributor]
  'Deploy-MDFC-Config-H224': [builtInRoleDefinitionIds.contributor]
  'Deploy-MDFC-DefSQL-AMA': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-MySQL-sslEnforcement': [builtInRoleDefinitionIds.contributor]
  'Deploy-PostgreSQL-sslEnforcement': [builtInRoleDefinitionIds.contributor]
  'Deploy-Sql-AuditingSettings': [
    builtInRoleDefinitionIds.sqlSecurityManager
    builtInRoleDefinitionIds.logAnalyticsContributor
  ]
  'Deploy-Sql-SecurityAlertPolicies': [builtInRoleDefinitionIds.sqlSecurityManager]
  'Deploy-Sql-Tde': [builtInRoleDefinitionIds.sqlDbContributor]
  'Deploy-SqlMi-minTLS': [builtInRoleDefinitionIds.sqlSecurityManager]
  'Deploy-Storage-sslEnforcement': [builtInRoleDefinitionIds.contributor]
  'Deploy-VM-Backup': [builtInRoleDefinitionIds.backupContributor, builtInRoleDefinitionIds.vmContributor]
  'Deploy-GuestAttest': [
    builtInRoleDefinitionIds.reader
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.managedIdentityContributor
  ]
  'Deploy-VM-ChangeTrack': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-VM-Monitoring': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Deploy-vmArc-ChangeTrack': [
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
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
  'Deploy-VMSS-Monitoring': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Enable-ArcAutoProvisioning': [builtInRoleDefinitionIds.connectedMachineResourceAdministrator]
  'Enable-AUM-CheckUpdates': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.connectedMachineResourceAdministrator
    builtInRoleDefinitionIds.managedIdentityOperator
  ]
  'Enforce-ASR': [builtInRoleDefinitionIds.contributor]
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

var managementGroupFinalName = platformConfig.?managementGroupName ?? 'platform'
var intRootManagementGroupFinalName = platformConfig.?managementGroupIntermediateRootName ?? 'alz'

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

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, platformConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, platformConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, platformConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsWithOverrides, platformConfig.?customerPolicyAssignments ?? [])

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

module platform 'br/public:avm/ptn/alz/empty:0.3.5' = {
  params: {
    createOrUpdateManagementGroup: platformConfig.?createOrUpdateManagementGroup
    managementGroupName: managementGroupFinalName
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
    waitForConsistencyCounterBeforeRoleAssignments: platformConfig.?waitForConsistencyCounterBeforeRoleAssignments
    waitForConsistencyCounterBeforeSubPlacement: platformConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../alzCoreType.bicep'
