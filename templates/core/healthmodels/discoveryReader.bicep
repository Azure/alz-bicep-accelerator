metadata name = 'ALZ Bicep Accelerator - Health Model Discovery Reader'
metadata description = 'Grants the health model discovery identity the Reader role on a subscription queried by its discovery rules.'

targetScope = 'subscription'

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

resource resDiscoveryReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, parRoleDefinitionId, parPrincipalId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', parRoleDefinitionId)
    principalId: parPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Lets ALZ platform health model discovery rules read resources in this subscription.'
  }
}

//========================================
// Outputs
//========================================

@description('The resource ID of the role assignment granted to the discovery identity.')
output outRoleAssignmentResourceId string = resDiscoveryReader.id
