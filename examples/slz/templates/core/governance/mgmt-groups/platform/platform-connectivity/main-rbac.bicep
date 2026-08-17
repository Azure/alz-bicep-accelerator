metadata name = 'ALZ Bicep - Platform-Connectivity RBAC Module'
metadata description = 'ALZ Bicep Module used to assign RBAC roles to policy-assigned managed identities from Corp management group to Connectivity management group. This is required for policies like Deploy-Private-DNS-Zones that need permissions in the Connectivity management group.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The name of the Corp management group where Deploy-Private-DNS-Zones policy is assigned.')
param parCorpManagementGroupName string

@description('Required. The name of the Connectivity management group where role assignments will be created.')
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

// Policy assignments that need RBAC to Connectivity management group
var policyAssignmentsRequiringRbac = {
  'Deploy-Private-DNS-Zones': [
    builtInRoleDefinitionIds.networkContributor
  ]
}

//================================
// Resources
//================================

// Get reference to Deploy-Private-DNS-Zones policy assignment in Corp MG
resource policyAssignmentPrivateDnsZones 'Microsoft.Authorization/policyAssignments@2024-04-01' existing = if (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-Private-DNS-Zones')) {
  name: 'Deploy-Private-DNS-Zones'
  scope: managementGroup(parCorpManagementGroupName)
}

// Deploy-Private-DNS-Zones role assignments to Connectivity MG
module rbacPrivateDnsZones 'br/public:avm/ptn/authorization/role-assignment:0.2.4' = [
  for roleDefId in (!contains(parManagementGroupExcludedPolicyAssignments, 'Deploy-Private-DNS-Zones') ? policyAssignmentsRequiringRbac['Deploy-Private-DNS-Zones'] : []): {
    name: 'rbac-privdns-${substring(uniqueString(roleDefId), 0, 8)}'
    params: {
      principalId: policyAssignmentPrivateDnsZones.identity.principalId
      roleDefinitionIdOrName: roleDefId
      principalType: 'ServicePrincipal'
      managementGroupId: parConnectivityManagementGroupName
      enableTelemetry: parEnableTelemetry
    }
  }
]
