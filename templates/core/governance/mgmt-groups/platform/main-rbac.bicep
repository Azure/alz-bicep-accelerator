metadata name = 'ALZ Bicep - Platform Cross-MG RBAC Module'
metadata description = 'ALZ Bicep Module used to assign RBAC roles to policy-assigned managed identities from Corp and Connectivity management groups to Platform management group. This is required because deployment stacks do not support cross-management group role assignments.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The name of the Platform management group where role assignments will be created.')
param parPlatformManagementGroupName string

@description('Required. The name of the Connectivity management group where Enable-DDoS-VNET policy is assigned.')
param parConnectivityManagementGroupName string

@description('Optional. Array of policy assignment names excluded from deployment across all management groups.')
param parManagementGroupExcludedPolicyAssignments array = []

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

//================================
// Variables
//================================

var builtInRoleDefinitionIds = {
  networkContributor: '/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7'
}

// Policy assignments that need cross-MG RBAC to Platform
var policyAssignmentsRequiringCrossMgRbac = {
  'Enable-DDoS-VNET': [
    builtInRoleDefinitionIds.networkContributor
  ]
}

//================================
// Resources
//================================

// Get reference to Enable-DDoS-VNET policy assignment in Connectivity MG
resource policyAssignmentEnableDdosVnet 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Enable-DDoS-VNET')) {
  name: 'Enable-DDoS-VNET'
  scope: managementGroup(parConnectivityManagementGroupName)
}

//================================
// Modules
//================================

// Enable-DDoS-VNET role assignments to Platform MG
module rbacEnableDdosVnet 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Enable-DDoS-VNET') ? policyAssignmentsRequiringCrossMgRbac['Enable-DDoS-VNET'] : []): {
    name: 'rbac-ddosvnet-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentEnableDdosVnet.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parPlatformManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]
