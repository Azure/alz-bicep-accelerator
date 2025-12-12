metadata name = 'ALZ Bicep - Landing Zones Cross-MG RBAC Module'
metadata description = 'ALZ Bicep Module used to assign RBAC roles to policy-assigned managed identities from Platform management group to Landing Zones management group. This is required because deployment stacks do not support cross-management group role assignments.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The name of the Landing Zones management group where role assignments will be created.')
param parLandingZonesManagementGroupName string

@description('Required. The name of the Platform management group where policy assignments are deployed.')
param parPlatformManagementGroupName string

@description('Required. The name of the Connectivity management group where policy assignments are deployed.')
param parConnectivityManagementGroupName string

@description('Optional. Array of policy assignment names excluded from deployment across all management groups.')
param parManagementGroupExcludedPolicyAssignments array = []

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

//================================
// Variables
//================================

var builtInRoleDefinitionIds = {
  vmContributor: '/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
  logAnalyticsContributor: '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  monitoringContributor: '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  managedIdentityOperator: '/providers/Microsoft.Authorization/roleDefinitions/f1a07417-d97a-45cb-824c-7a7467783830'
  reader: '/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
  connectedMachineResourceAdministrator: '/providers/Microsoft.Authorization/roleDefinitions/cd570a14-e51a-42ad-bac8-bafd67325302'
  networkContributor: '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
}

// Policy assignments that need cross-MG RBAC to Landing Zones
var policyAssignmentsRequiringCrossMgRbac = {
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
  'Deploy-MDFC-DefSQL-AMA': [
    builtInRoleDefinitionIds.vmContributor
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
    builtInRoleDefinitionIds.managedIdentityOperator
    builtInRoleDefinitionIds.reader
  ]
  'Enable-DDoS-VNET': [
    builtInRoleDefinitionIds.networkContributor
  ]
}

//================================
// Resources
//================================

// Get reference to each policy assignment in Platform MG to extract managed identity principal IDs
resource policyAssignmentVmChangeTrack 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VM-ChangeTrack')) {
  name: 'Deploy-VM-ChangeTrack'
  scope: managementGroup(parPlatformManagementGroupName)
}

resource policyAssignmentVmMonitoring 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VM-Monitoring')) {
  name: 'Deploy-VM-Monitoring'
  scope: managementGroup(parPlatformManagementGroupName)
}

resource policyAssignmentVmArcChangeTrack 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-vmArc-ChangeTrack')) {
  name: 'Deploy-vmArc-ChangeTrack'
  scope: managementGroup(parPlatformManagementGroupName)
}

resource policyAssignmentVmssChangeTrack 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VMSS-ChangeTrack')) {
  name: 'Deploy-VMSS-ChangeTrack'
  scope: managementGroup(parPlatformManagementGroupName)
}

resource policyAssignmentVmHybrMonitoring 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-vmHybr-Monitoring')) {
  name: 'Deploy-vmHybr-Monitoring'
  scope: managementGroup(parPlatformManagementGroupName)
}

resource policyAssignmentVmssMonitoring 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VMSS-Monitoring')) {
  name: 'Deploy-VMSS-Monitoring'
  scope: managementGroup(parPlatformManagementGroupName)
}

resource policyAssignmentMdfcDefSqlAma 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-MDFC-DefSQL-AMA')) {
  name: 'Deploy-MDFC-DefSQL-AMA'
  scope: managementGroup(parPlatformManagementGroupName)
}

// Get reference to Enable-DDoS-VNET policy assignment in Connectivity MG
resource policyAssignmentEnableDdosVnet 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Enable-DDoS-VNET')) {
  name: 'Enable-DDoS-VNET'
  scope: managementGroup(parConnectivityManagementGroupName)
}

// Deploy-VM-ChangeTrack role assignments
module rbacVmChangeTrack 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VM-ChangeTrack') ? policyAssignmentsRequiringCrossMgRbac['Deploy-VM-ChangeTrack'] : []): {
    name: 'rbac-vmchgtrk-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentVmChangeTrack.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Deploy-VM-Monitoring role assignments
module rbacVmMonitoring 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VM-Monitoring') ? policyAssignmentsRequiringCrossMgRbac['Deploy-VM-Monitoring'] : []): {
    name: 'rbac-vmmon-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentVmMonitoring.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Deploy-vmArc-ChangeTrack role assignments
module rbacVmArcChangeTrack 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-vmArc-ChangeTrack') ? policyAssignmentsRequiringCrossMgRbac['Deploy-vmArc-ChangeTrack'] : []): {
    name: 'rbac-vmarcchgtrk-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentVmArcChangeTrack.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Deploy-VMSS-ChangeTrack role assignments
module rbacVmssChangeTrack 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VMSS-ChangeTrack') ? policyAssignmentsRequiringCrossMgRbac['Deploy-VMSS-ChangeTrack'] : []): {
    name: 'rbac-vmsschgtrk-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentVmssChangeTrack.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Deploy-vmHybr-Monitoring role assignments
module rbacVmHybrMonitoring 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-vmHybr-Monitoring') ? policyAssignmentsRequiringCrossMgRbac['Deploy-vmHybr-Monitoring'] : []): {
    name: 'rbac-vmhybrmon-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentVmHybrMonitoring.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Deploy-VMSS-Monitoring role assignments
module rbacVmssMonitoring 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-VMSS-Monitoring') ? policyAssignmentsRequiringCrossMgRbac['Deploy-VMSS-Monitoring'] : []): {
    name: 'rbac-vmssmon-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentVmssMonitoring.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Deploy-MDFC-DefSQL-AMA role assignments
module rbacMdfcDefSqlAma 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-MDFC-DefSQL-AMA') ? policyAssignmentsRequiringCrossMgRbac['Deploy-MDFC-DefSQL-AMA'] : []): {
    name: 'rbac-mdfcdefsqlama-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentMdfcDefSqlAma.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]

// Enable-DDoS-VNET role assignments to Landing Zones MG
module rbacEnableDdosVnet 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Enable-DDoS-VNET') ? policyAssignmentsRequiringCrossMgRbac['Enable-DDoS-VNET'] : []): {
    name: 'rbac-ddosvnet-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentEnableDdosVnet.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parLandingZonesManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]
