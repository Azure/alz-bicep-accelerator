metadata name = 'ALZ Bicep Accelerator - Health Model Discovery Reader (Management Group)'
metadata description = 'Grants the health model discovery identity the Reader role on a management group queried by its discovery rules.'

targetScope = 'managementGroup'

//========================================
// Parameters
//========================================

@description('Required. The principal ID of the health model discovery identity.')
param parPrincipalId string

@description('Required. The ID of the built-in role for the discovery identity.')
param parRoleDefinitionId string

//========================================
// Resources
//========================================

resource resDiscoveryReaderMg 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managementGroup().id, parRoleDefinitionId, parPrincipalId)
  properties: {
    roleDefinitionId: tenantResourceId('Microsoft.Authorization/roleDefinitions', parRoleDefinitionId)
    principalId: parPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Lets ALZ platform health model discovery rules read resources in this management group.'
  }
}

//========================================
// Outputs
//========================================

@description('The resource ID of the role assignment granted to the discovery identity.')
output outRoleAssignmentResourceId string = resDiscoveryReaderMg.id
