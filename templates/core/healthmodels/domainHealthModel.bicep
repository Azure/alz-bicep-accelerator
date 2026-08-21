metadata name = 'ALZ Bicep Accelerator - Domain Health Model'
metadata description = 'Used to deploy a simple ALZ domain Health Model with one dummy health entity.'

targetScope = 'resourceGroup'

import { discoveryRuleType } from './healthModel.bicep'

//========================================
// Parameters
//========================================

@description('Required. The name of the domain health model.')
@minLength(3)
@maxLength(44)
param parHealthModelName string

@description('Required. The name of the parent platform health model that discovers this domain model.')
param parHealthModelParentModelName string

@description('Required. The domain represented by this health model.')
param parDomain string

@description('Optional. The display name shown for the domain.')
param parDomainDisplayName string = parDomain

@description('Required. The location of the health model. Must be a region where Microsoft.CloudHealth offers health models.')
@allowed([
  'australiaeast'
  'canadacentral'
  'centralus'
  'eastasia'
  'germanywestcentral'
  'italynorth'
  'japanwest'
  'northeurope'
  'southeastasia'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
])
param parHealthModelLocation string = 'swedencentral'

@sys.description('''Global Resource Lock Configuration used for resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}

@description('Optional. Tags to be applied to the domain health model.')
param parTags object = {}

@description('Optional. Resource ID of the shared discovery User Assigned Identity. Required when parDiscoveryRules is non-empty.')
param parDiscoveryIdentityResourceId string = ''

@description('Optional. Resource Graph discovery rules to attach to this domain model root.')
param parDiscoveryRules discoveryRuleType[] = []

//========================================
// Variables
//========================================

var varDummyEntityName = 'entity-${parDomain}-dummy-green'
var varDummyEntityCanvasPosition = { x: 0, y: 193 }
var varDiscoveryEnabled = !empty(parDiscoveryRules)
var varAuthenticationSettingName = 'managed-identity'
// Guard: a rule set must never be supplied without a discovery identity.
var varDiscoveryIdentityResourceId = varDiscoveryEnabled && empty(parDiscoveryIdentityResourceId)
  ? fail('parDiscoveryIdentityResourceId is required when parDiscoveryRules is non-empty.')
  : parDiscoveryIdentityResourceId
var varHealthModelTags = union(parTags, {
  alzHealthModelRole: 'domain'
  alzHealthModelDomain: parDomain
  alzHealthModelParent: parHealthModelParentModelName
})

//========================================
// Resources
//========================================

resource resHealthModel 'Microsoft.CloudHealth/healthmodels@2026-05-01-preview' = {
  name: parHealthModelName
  location: parHealthModelLocation
  tags: varHealthModelTags
  identity: varDiscoveryEnabled ? {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '${varDiscoveryIdentityResourceId}': {}
    }
  } : {
    type: 'SystemAssigned'
  }
  properties: {}
}

resource resAuthenticationSetting 'Microsoft.CloudHealth/healthmodels/authenticationsettings@2026-05-01-preview' = if (varDiscoveryEnabled) {
  parent: resHealthModel
  name: varAuthenticationSettingName
  properties: {
    displayName: 'Health model discovery identity'
    authenticationKind: 'ManagedIdentity'
    managedIdentityName: varDiscoveryIdentityResourceId
  }
}

resource resDiscoveryRules 'Microsoft.CloudHealth/healthmodels/discoveryrules@2026-05-01-preview' = [for discoveryRule in parDiscoveryRules: if (varDiscoveryEnabled) {
  parent: resHealthModel
  name: discoveryRule.name
  properties: {
    displayName: discoveryRule.displayName
    authenticationSetting: resAuthenticationSetting.name
    addRecommendedSignals: discoveryRule.?addRecommendedSignals ?? 'Enabled'
    addResourceHealthSignal: discoveryRule.?addResourceHealthSignal ?? 'Disabled'
    discoverRelationships: discoveryRule.?discoverRelationships ?? 'Disabled'
    specification: {
      kind: 'ResourceGraphQuery'
      resourceGraphQuery: discoveryRule.resourceGraphQuery
    }
  }
}]

resource resRootToDiscoveryRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [for (discoveryRule, i) in parDiscoveryRules: if (varDiscoveryEnabled) {
  parent: resHealthModel
  name: 'root-to-${discoveryRule.name}'
  properties: {
    displayName: 'Root to ${discoveryRule.displayName}'
    parentEntityName: parHealthModelName
    childEntityName: resDiscoveryRules[i].name
  }
}]

resource resDummyEntity 'Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview' = {
  parent: resHealthModel
  name: varDummyEntityName
  properties: {
    displayName: '${parDomainDisplayName} dummy health'
    impact: 'Standard'
    canvasPosition: varDummyEntityCanvasPosition
  }
}

resource resRootToDummyRelationship 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = {
  parent: resHealthModel
  name: 'root-to-${varDummyEntityName}'
  properties: {
    displayName: 'Root to ${parDomainDisplayName} dummy health'
    parentEntityName: parHealthModelName
    childEntityName: resDummyEntity.name
  }
}

resource resHealthModelLock 'Microsoft.Authorization/locks@2020-05-01' = if (parGlobalResourceLock.kind != 'None') {
  scope: resHealthModel
  name: parGlobalResourceLock.?name ?? 'lock-${parHealthModelName}'
  properties: {
    level: parGlobalResourceLock.kind
    notes: parGlobalResourceLock.?notes
  }
}

//========================================
// Outputs
//========================================

@description('The resource ID of the domain health model.')
output outHealthModelResourceId string = resHealthModel.id

@description('The name of the domain health model.')
output outHealthModelName string = resHealthModel.name

@description('The name of the dummy entity seeded by deployment verification.')
output outDummyEntityName string = resDummyEntity.name

//========================================
// Definitions
//========================================

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}
