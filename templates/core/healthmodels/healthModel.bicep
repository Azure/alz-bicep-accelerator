metadata name = 'ALZ Bicep Accelerator - Platform Health Model Resources'
metadata description = 'Used to deploy a Microsoft.CloudHealth health model, top-level entities, and Resource Graph discovery rules.'

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

@description('Required. The top-level entities under the model root.')
param parEntities entityType[]

@description('Required. Discovery rules that target discovered resources.')
param parDiscoveryRules discoveryRuleType[]

@description('Required. Entity-to-discovery relationships. One discovery rule can be linked from many entities.')
param parEntityDiscoveryLinks entityDiscoveryLinkType[]

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
var varEntityNames = [for entity in parEntities: entity.name]
var varDiscoveryRuleNames = [for discoveryRule in parDiscoveryRules: discoveryRule.name]

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
  for discoveryRule in parDiscoveryRules: {
    parent: resHealthModel
    name: discoveryRule.name
    properties: {
      displayName: discoveryRule.displayName
      authenticationSetting: resAuthenticationSetting.name
      addRecommendedSignals: discoveryRule.?addRecommendedSignals ?? 'Disabled'
      addResourceHealthSignal: discoveryRule.?addResourceHealthSignal ?? 'Disabled'
      discoverRelationships: discoveryRule.?discoverRelationships ?? 'Disabled'
      specification: {
        kind: 'ResourceGraphQuery'
        resourceGraphQuery: discoveryRule.resourceGraphQuery
      }
    }
  }
]

resource resEntities 'Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview' = [
  for entity in parEntities: {
    parent: resHealthModel
    name: entity.name
    properties: {
      displayName: entity.displayName
      impact: 'Standard'
      canvasPosition: entity.?canvasPosition
      signalGroups: {
        dependencies: {
          aggregationType: 'WorstOf'
          ignoreUnknown: true
        }
      }
    }
  }
]

// The resource provider creates the model root entity named after the model itself.
resource resRootToEntityRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for (entity, index) in parEntities: {
    parent: resHealthModel
    name: 'root-to-${entity.name}'
    properties: {
      displayName: 'Root to ${entity.displayName}'
      parentEntityName: parHealthModelName
      childEntityName: resEntities[index].name
    }
  }
]

resource resEntityToDiscoveryRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for entityDiscoveryLink in parEntityDiscoveryLinks: {
    parent: resHealthModel
    name: '${entityDiscoveryLink.entityName}-to-${entityDiscoveryLink.discoveryRuleName}'
    properties: {
      displayName: '${entityDiscoveryLink.entityName} to ${entityDiscoveryLink.discoveryRuleName}'
      parentEntityName: resEntities[indexOf(varEntityNames, entityDiscoveryLink.entityName)].name
      childEntityName: resDiscoveryRules[indexOf(varDiscoveryRuleNames, entityDiscoveryLink.discoveryRuleName)].name
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
@description('The shape of a top-level entity under the model root.')
type entityType = {
  @description('Required. The entity name.')
  name: string

  @description('Required. The display name shown for the entity.')
  displayName: string

  @description('Optional. Canvas position of the entity in the model topology view.')
  canvasPosition: { x: int, y: int }?
}

@export()
@description('The shape of a discovery rule.')
type discoveryRuleType = {
  @description('Required. The name of the discovery rule and the discovered entity root.')
  name: string

  @description('Required. The display name shown for the discovery rule.')
  displayName: string

  @description('Required. Resource Graph query for this discovery rule.')
  resourceGraphQuery: string

  @description('Optional. Whether to add recommended signals to discovered entities.')
  addRecommendedSignals: ('Enabled' | 'Disabled')?

  @description('Optional. Whether to add Azure Resource Health to discovered entities.')
  addResourceHealthSignal: ('Enabled' | 'Disabled')?

  @description('Optional. Whether discovery creates built-in relationships between discovered entities.')
  discoverRelationships: ('Enabled' | 'Disabled')?
}

@export()
@description('Relationship shape that links a top-level entity to a discovery rule.')
type entityDiscoveryLinkType = {
  @description('Required. The parent entity name.')
  entityName: string

  @description('Required. The child discovery rule name.')
  discoveryRuleName: string
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
