metadata name = 'ALZ Bicep Accelerator - Platform Health Model Resources'
metadata description = 'Used to deploy the Microsoft.CloudHealth health model, flow entities, and Resource Graph discovery rules.'

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

@description('Required. The top-level flow categories under the model root.')
param parFlowCategories flowCategoryType[]

@description('Required. The flow entities nested under categories.')
param parFlows flowType[]

@description('Required. Discovery rules that represent flow resource-type sets.')
param parDiscoveryRules discoveryRuleType[]

@description('Required. Flow-to-discovery relationships. One discovery rule can be linked from many flows.')
param parFlowDiscoveryLinks flowDiscoveryLinkType[]

@description('Optional. Explicit AMBA-backed reference entities with inline active threshold signals.')
param parAmbaReferenceEntities ambaReferenceEntityType[] = []

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
var varFlowCategoryNames = [for flowCategory in parFlowCategories: flowCategory.name]
var varFlowNames = [for flow in parFlows: flow.name]
var varDiscoveryRuleNames = [for discoveryRule in parDiscoveryRules: discoveryRule.name]
var varAmbaReferenceEntityNames = [for ambaEntity in parAmbaReferenceEntities: ambaEntity.name]

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
      // The discovery rule references the authentication setting by name, not by resource ID.
      authenticationSetting: resAuthenticationSetting.name
      addRecommendedSignals: 'Enabled'
      addResourceHealthSignal: parEnableResourceHealthSignal ? 'Enabled' : 'Disabled'
      discoverRelationships: 'Enabled'
      specification: {
        kind: 'ResourceGraphQuery'
        resourceGraphQuery: 'resources | where subscriptionId =~ \'${discoveryRule.subscriptionId}\' | where type in~ (\'${join(discoveryRule.resourceTypes, '\',\'')}\') | project id'
      }
    }
  }
]

resource resFlowCategories 'Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview' = [
  for flowCategory in parFlowCategories: {
    parent: resHealthModel
    name: flowCategory.name
    properties: {
      displayName: flowCategory.displayName
      impact: 'Standard'
      signalGroups: {
        dependencies: {
          aggregationType: 'WorstOf'
          ignoreUnknown: true
        }
      }
    }
  }
]

resource resFlows 'Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview' = [
  for flow in parFlows: {
    parent: resHealthModel
    name: flow.name
    properties: {
      displayName: flow.displayName
      impact: 'Standard'
      signalGroups: {
        dependencies: {
          aggregationType: 'WorstOf'
          ignoreUnknown: true
        }
      }
    }
  }
]

resource resAmbaReferenceEntities 'Microsoft.CloudHealth/healthmodels/entities@2026-05-01-preview' = [
  for ambaEntity in parAmbaReferenceEntities: {
    parent: resHealthModel
    name: ambaEntity.name
    properties: {
      displayName: ambaEntity.displayName
      impact: 'Standard'
      signalGroups: {
        dependencies: {
          aggregationType: 'WorstOf'
          ignoreUnknown: true
        }
        azureResource: {
          authenticationSetting: resAuthenticationSetting.name
          azureResourceId: ambaEntity.azureResourceId
          azureResourceKind: ambaEntity.azureResourceKind
          resourceHealth: {
            enabled: 'Disabled'
          }
          signals: [
            for signal in ambaEntity.signals: {
              name: signal.name
              displayName: signal.displayName
              signalKind: 'AzureResourceMetric'
              metricNamespace: signal.metricNamespace
              metricName: signal.metricName
              aggregationType: signal.aggregationType
              timeGrain: signal.timeGrain
              refreshInterval: signal.refreshInterval
              dataUnit: signal.?dataUnit
              evaluationRules: {
                unhealthyRule: signal.?unhealthySensitivity != null
                  ? {
                      operator: 'Dynamic'
                      sensitivity: signal.?unhealthySensitivity!
                      lookBackWindow: signal.?lookBackWindow!
                    }
                  : {
                      operator: signal.?unhealthyOperator!
                      threshold: signal.?unhealthyThreshold!
                    }
              }
            }
          ]
        }
      }
    }
  }
]

// The resource provider creates the model root entity named after the model itself.
// Rooting each category there manages that built in root rather than adding a second
// childless root beside it.
resource resRootToCategoryRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for (flowCategory, index) in parFlowCategories: {
    parent: resHealthModel
    name: 'root-to-${flowCategory.name}'
    properties: {
      displayName: 'Root to ${flowCategory.displayName}'
      parentEntityName: parHealthModelName
      childEntityName: resFlowCategories[index].name
    }
  }
]

resource resCategoryToFlowRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for (flow, index) in parFlows: {
    parent: resHealthModel
    name: '${flow.categoryName}-to-${flow.name}'
    properties: {
      displayName: '${flow.categoryName} to ${flow.displayName}'
      parentEntityName: resFlowCategories[indexOf(varFlowCategoryNames, flow.categoryName)].name
      childEntityName: resFlows[index].name
    }
  }
]

resource resFlowToDiscoveryRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for flowDiscoveryLink in parFlowDiscoveryLinks: {
    parent: resHealthModel
    name: '${flowDiscoveryLink.flowName}-to-${flowDiscoveryLink.discoveryRuleName}'
    properties: {
      displayName: '${flowDiscoveryLink.flowName} to ${flowDiscoveryLink.discoveryRuleName}'
      parentEntityName: resFlows[indexOf(varFlowNames, flowDiscoveryLink.flowName)].name
      childEntityName: resDiscoveryRules[indexOf(varDiscoveryRuleNames, flowDiscoveryLink.discoveryRuleName)].name
    }
  }
]

resource resFlowToAmbaEntityRelationships 'Microsoft.CloudHealth/healthmodels/relationships@2026-05-01-preview' = [
  for ambaEntity in parAmbaReferenceEntities: {
    parent: resHealthModel
    name: '${ambaEntity.flowName}-to-${ambaEntity.name}'
    properties: {
      displayName: '${ambaEntity.flowName} to ${ambaEntity.displayName}'
      parentEntityName: resFlows[indexOf(varFlowNames, ambaEntity.flowName)].name
      childEntityName: resAmbaReferenceEntities[indexOf(varAmbaReferenceEntityNames, ambaEntity.name)].name
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
@description('The shape of a top-level user or system flow category.')
type flowCategoryType = {
  @description('Required. The entity name for the flow category.')
  name: string

  @description('Required. The display name shown for the flow category.')
  displayName: string
}

@export()
@description('The shape of a flow entity nested under a flow category.')
type flowType = {
  @description('Required. The entity name for the flow.')
  name: string

  @description('Required. The display name shown for the flow.')
  displayName: string

  @description('Required. The parent flow category entity name.')
  categoryName: string
}

@export()
@description('The shape of a flow discovery rule.')
type discoveryRuleType = {
  @description('Required. The name of the discovery rule and the discovered entity root.')
  name: string

  @description('Required. The display name shown for the discovery rule.')
  displayName: string

  @description('Required. The resource types the discovery query matches.')
  resourceTypes: array

  @description('Required. The subscription ID that the discovery query is scoped to.')
  subscriptionId: string
}

@export()
@description('Relationship shape that links a flow entity to a discovery rule.')
type flowDiscoveryLinkType = {
  @description('Required. The parent flow entity name.')
  flowName: string

  @description('Required. The child discovery rule name.')
  discoveryRuleName: string
}

@export()
@description('Explicit AMBA-backed reference entity with inline threshold signals.')
type ambaReferenceEntityType = {
  @description('Required. The entity name.')
  name: string

  @description('Required. The display name shown for the entity.')
  displayName: string

  @description('Required. The flow entity name that will parent this AMBA entity.')
  flowName: string

  @description('Required. Azure resource ID bound to the signal group.')
  azureResourceId: string

  @description('Required. Azure resource kind, used for icon rendering.')
  azureResourceKind: string

  @description('Required. AMBA-derived signals assigned to this entity.')
  signals: ambaReferenceSignalType[]
}

@export()
@description('Metric signal shape for explicit AMBA-backed entities.')
type ambaReferenceSignalType = {
  @description('Required. Unique signal name within the entity.')
  name: string

  @description('Required. Display name shown in the health model UI.')
  displayName: string

  @description('Required. Metric namespace.')
  metricNamespace: string

  @description('Required. Metric name.')
  metricName: string

  @description('Required. Metric aggregation type.')
  aggregationType: ('Average' | 'Count' | 'Maximum' | 'Minimum' | 'None' | 'Total')

  @description('Required. Signal time grain.')
  timeGrain: string

  @description('Required. Signal refresh interval.')
  refreshInterval: ('PT1M' | 'PT5M' | 'PT10M' | 'PT15M' | 'PT30M' | 'PT1H' | 'PT2H')

  @description('Optional. Unit of the metric value. This is non-AMBA-derived when AMBA does not specify units.')
  dataUnit: string?

  @description('Optional. Static unhealthy operator. Required when unhealthySensitivity is null.')
  unhealthyOperator: ('GreaterThan' | 'GreaterThanOrEqual' | 'LessThan' | 'LessThanOrEqual' | 'Equal' | 'NotEqual')?

  @description('Optional. Static unhealthy threshold. Required when unhealthySensitivity is null.')
  unhealthyThreshold: int?

  @description('Optional. Dynamic unhealthy sensitivity. When set, this signal omits static thresholds.')
  unhealthySensitivity: ('High' | 'Medium' | 'Low')?

  @description('Optional. Dynamic look-back window. This is non-AMBA-derived when AMBA does not specify it.')
  lookBackWindow: string?

  @description('Required. AMBA source pointer used for traceability in docs and validation.')
  ambaSource: string
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
