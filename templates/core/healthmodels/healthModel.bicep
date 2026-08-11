metadata name = 'ALZ Bicep Accelerator - Platform Health Model Resources'
metadata description = 'Used to deploy the Microsoft.CloudHealth health model, its authentication setting, and one Resource Graph discovery rule per platform domain.'

targetScope = 'resourceGroup'

//========================================
// Parameters
//========================================

@description('Required. The name of the platform health model. The root entity of the model carries this same name.')
param parHealthModelName string

@description('Required. The location of the platform health model. Must be a region where the Microsoft.CloudHealth resource provider offers health models.')
param parHealthModelLocation string

@description('Required. The resource ID of the User Assigned Identity that the discovery rules authenticate with.')
param parDiscoveryIdentityResourceId string

@description('Required. The platform domains to discover. Each entry produces one discovery rule and one relationship to the model root.')
param parDomains domainType[]

@description('Optional. Adds the Azure Resource Health signal to every discovered resource.')
param parEnableResourceHealthSignal bool = false

@description('''Resource Lock Configuration for the Health Model.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parHealthModelLock lockType?

@description('Optional. Tags to be applied to resources.')
param parTags object = {}

//========================================
// Variables
//========================================

var varAuthenticationSettingName = 'managed-identity'

//========================================
// Resources
//========================================

resource resHealthModel 'Microsoft.CloudHealth/healthmodels@2026-05-01-preview' = {
  name: parHealthModelName
  location: parHealthModelLocation
  tags: parTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${parDiscoveryIdentityResourceId}': {}
    }
  }
  properties: {}
}

resource resAuthenticationSetting 'Microsoft.CloudHealth/healthmodels/authenticationsettings@2026-05-01-preview' = {
  parent: resHealthModel
  name: varAuthenticationSettingName
  properties: {
    displayName: 'Health model discovery identity'
    authenticationKind: 'ManagedIdentity'
    managedIdentityName: parDiscoveryIdentityResourceId
  }
}

resource resDiscoveryRules 'Microsoft.CloudHealth/healthmodels/discoveryrules@2026-05-01-preview' = [
  for domain in parDomains: {
    parent: resHealthModel
    name: domain.name
    properties: {
      displayName: domain.displayName
      // The discovery rule references the authentication setting by name, not by resource ID.
      authenticationSetting: resAuthenticationSetting.name
      addRecommendedSignals: 'Enabled'
      addResourceHealthSignal: parEnableResourceHealthSignal ? 'Enabled' : 'Disabled'
      discoverRelationships: 'Enabled'
      specification: {
        kind: 'ResourceGraphQuery'
        resourceGraphQuery: 'resources | where subscriptionId =~ \'${domain.subscriptionId}\' | where type in~ (\'${join(domain.resourceTypes, '\',\'')}\') | project id'
      }
    }
  }
]

// The resource provider creates the model root entity named after the model itself.
// Rooting every domain entity there manages that built in root rather than adding a
// second, childless root beside it.
resource resDiscoveryRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for (domain, index) in parDomains: {
    parent: resHealthModel
    name: 'root-to-${domain.name}'
    properties: {
      displayName: 'Root to ${domain.displayName}'
      parentEntityName: parHealthModelName
      // Referencing the rule from the first loop orders the two loops implicitly.
      childEntityName: resDiscoveryRules[index].name
    }
  }
]

resource resHealthModelLock 'Microsoft.Authorization/locks@2020-05-01' = if (parHealthModelLock != null && parHealthModelLock.?kind != 'None') {
  scope: resHealthModel
  name: parHealthModelLock.?name ?? 'lock-${parHealthModelName}'
  properties: {
    level: parHealthModelLock!.kind
    notes: parHealthModelLock.?notes
  }
}

//========================================
// Outputs
//========================================

@description('The resource ID of the platform health model.')
output outHealthModelResourceId string = resHealthModel.id

@description('The name of the platform health model.')
output outHealthModelName string = resHealthModel.name

//========================================
// Definitions
//========================================

@export()
@description('The shape of a platform domain discovered by the health model.')
type domainType = {
  @description('Required. The name of the discovery rule and of the entity it creates.')
  name: string

  @description('Required. The display name shown for the domain in the health model.')
  displayName: string

  @description('Required. The resource types the domain discovery query matches.')
  resourceTypes: array

  @description('Required. The ID of the subscription the domain discovery query is scoped to.')
  subscriptionId: string
}

// Lock Type
type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}?
