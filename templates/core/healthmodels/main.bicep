metadata name = 'ALZ Bicep Accelerator - Platform Health Model'
metadata description = 'Used to deploy a platform parent health model and its ALZ domain child health models.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('Required. The name of the Resource Group that hosts the platform health models.')
param parHealthModelResourceGroup string

// Health Model Parameters
@description('Required. The name of the platform parent health model.')
@minLength(3)
param parHealthModelName string = 'ahm-alz-platform'

@description('Optional. The location of the platform health model. Must be a region where the Microsoft.CloudHealth resource provider offers health models, which is a smaller set than the regions available to the rest of the platform.')
param parHealthModelLocation string = 'swedencentral'

// Discovery Identity Parameters
@description('Required. The name of the User Assigned Identity used by the health model discovery rules.')
@minLength(3)
@maxLength(128)
param parDiscoveryIdentityName string

@description('Optional. Management subscription ID for domain discovery. Defaults to the deployment subscription.')
param parManagementSubscriptionId string = subscription().subscriptionId

@description('Optional. Connectivity subscription ID for domain discovery.')
param parConnectivitySubscriptionId string = ''

@description('Optional. Identity subscription ID for domain discovery.')
param parIdentitySubscriptionId string = ''

@description('Optional. Security subscription ID for domain discovery.')
param parSecuritySubscriptionId string = ''

@description('Optional. Per-domain resource-type overrides, keyed by domain (management/connectivity/identity/security). Empty domain omitted uses the built-in default.')
param parDomainResourceTypes object = {}

@description('Optional. Domains (by name) that should get a subscription-wide discovery rule even when their resource-type list is empty.')
param parSubscriptionWideDiscoveryDomains array = []

@description('Optional. Management group IDs whose subtree the Application Landing Zones model scans for other (non platform/domain) health models. Empty = no landing-zone discovery rule.')
param parLandingZoneDiscoveryManagementGroupIds array = []

@description('Optional. Opt-in: also grant the discovery identity Reader on the Connectivity, Identity, and Security subscriptions the domain queries target. Landing-zone management-group Reader is NOT granted here (a subscription-scoped deployment cannot assign at management-group scope); deploy discoveryReaderMg.bicep separately for that. Default false (no scope escalation).')
param parEnableCrossScopeDiscoveryReader bool = false

// General Parameters
@description('Required. The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@description('Optional. Tags to be applied to resources.')
param parTags object = {}

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType

@description('Optional. Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Variables
//========================================

// Reader is the role the health model identity needs over the deployment subscription scope.
// Monitoring Reader is not sufficient and leaves every discovered signal Unknown.
var varReaderRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

var varResourceTypeHealthModel = 'microsoft.cloudhealth/healthmodels'
var varResourceTypeSubscription = 'microsoft.resources/subscriptions'
var varHealthModelRoleParent = 'parent'
var varHealthModelRoleDomain = 'domain'

var varDefaultDomainResourceTypes = {
  management: [
    'microsoft.operationalinsights/workspaces'
    'microsoft.automation/automationaccounts'
    'microsoft.insights/datacollectionrules'
    'microsoft.managedidentity/userassignedidentities'
  ]
  connectivity: [
    'microsoft.network/virtualnetworks'
    'microsoft.network/azurefirewalls'
    'microsoft.network/firewallpolicies'
    'microsoft.network/bastionhosts'
    'microsoft.network/virtualnetworkgateways'
    'microsoft.network/expressroutegateways'
    'microsoft.network/p2svpngateways'
    'microsoft.network/vpngateways'
    'microsoft.network/vpnserverconfigurations'
    'microsoft.network/virtualwans'
    'microsoft.network/virtualhubs'
    'microsoft.network/dnsresolvers'
    'microsoft.network/ddosprotectionplans'
    'microsoft.network/routetables'
    'microsoft.network/networksecuritygroups'
    'microsoft.network/publicipaddresses'
    'microsoft.network/privatednszones'
  ]
  identity: [
    'microsoft.keyvault/vaults'
    'microsoft.compute/virtualmachines'
    'microsoft.network/virtualnetworks'
    'microsoft.managedidentity/userassignedidentities'
  ]
  security: [
    'microsoft.keyvault/vaults'
    'microsoft.storage/storageaccounts'
    'microsoft.network/networksecuritygroups'
    'microsoft.operationalinsights/workspaces'
  ]
}

var varDomainSubscriptionIds = {
  management: empty(parManagementSubscriptionId) ? subscription().subscriptionId : parManagementSubscriptionId
  connectivity: parConnectivitySubscriptionId
  identity: parIdentitySubscriptionId
  security: parSecuritySubscriptionId
}

var varEffectiveDomainResourceTypes = {
  management: parDomainResourceTypes.?management ?? varDefaultDomainResourceTypes.management
  connectivity: parDomainResourceTypes.?connectivity ?? varDefaultDomainResourceTypes.connectivity
  identity: parDomainResourceTypes.?identity ?? varDefaultDomainResourceTypes.identity
  security: parDomainResourceTypes.?security ?? varDefaultDomainResourceTypes.security
}

var varDomainHealthModelsBase = [
  {
    domain: 'security'
    displayName: 'Security'
    healthModelName: 'ahm-alz-security'
    kind: 'resourceTypes'
    subscriptionId: varDomainSubscriptionIds.security
    resourceTypes: varEffectiveDomainResourceTypes.security
  }
  {
    domain: 'identity'
    displayName: 'Identity'
    healthModelName: 'ahm-alz-identity'
    kind: 'resourceTypes'
    subscriptionId: varDomainSubscriptionIds.identity
    resourceTypes: varEffectiveDomainResourceTypes.identity
  }
  {
    domain: 'connectivity'
    displayName: 'Connectivity'
    healthModelName: 'ahm-alz-connectivity'
    kind: 'resourceTypes'
    subscriptionId: varDomainSubscriptionIds.connectivity
    resourceTypes: varEffectiveDomainResourceTypes.connectivity
  }
  {
    domain: 'management'
    displayName: 'Management'
    healthModelName: 'ahm-alz-management'
    kind: 'resourceTypes'
    subscriptionId: varDomainSubscriptionIds.management
    resourceTypes: varEffectiveDomainResourceTypes.management
  }
  {
    domain: 'landing-zones'
    displayName: 'Application Landing Zones'
    healthModelName: 'ahm-alz-landing-zones'
    kind: 'healthModels'
    subscriptionId: ''
    resourceTypes: []
  }
]

var varDomainHealthModels = [for domainHealthModel in varDomainHealthModelsBase: union(domainHealthModel, {
  discoveryRules: domainHealthModel.kind == 'healthModels'
    ? (empty(parLandingZoneDiscoveryManagementGroupIds) ? [] : [
        {
          name: 'discover-landing-zone-health-models'
          displayName: 'Application landing zone health models'
          resourceGraphQuery: 'resources | where type =~ \'${varResourceTypeHealthModel}\' | where tostring(tags[\'alzHealthModelRole\']) !in~ (\'${varHealthModelRoleParent}\',\'${varHealthModelRoleDomain}\') | where name !~ \'${domainHealthModel.healthModelName}\' | join kind=inner (resourcecontainers | where type =~ \'${varResourceTypeSubscription}\' | mv-expand mg = properties.managementGroupAncestorsChain | where tostring(mg.name) in~ (${join(map(parLandingZoneDiscoveryManagementGroupIds, mgId => '\'${mgId}\''), ',')}) | distinct subscriptionId) on subscriptionId | project id'
          addRecommendedSignals: 'Enabled'
          addResourceHealthSignal: 'Disabled'
          discoverRelationships: 'Enabled'
        }
      ])
    : ((empty(domainHealthModel.subscriptionId) || (empty(domainHealthModel.resourceTypes) && !contains(parSubscriptionWideDiscoveryDomains, domainHealthModel.domain))) ? [] : [
        {
          name: 'discover-${domainHealthModel.domain}-resources'
          displayName: '${domainHealthModel.displayName} resources'
          resourceGraphQuery: empty(domainHealthModel.resourceTypes)
            ? 'resources | where subscriptionId =~ \'${domainHealthModel.subscriptionId}\' | project id'
            : 'resources | where subscriptionId =~ \'${domainHealthModel.subscriptionId}\' | where type in~ (${join(map(domainHealthModel.resourceTypes, resType => '\'${resType}\''), ',')}) | project id'
          addRecommendedSignals: 'Enabled'
          addResourceHealthSignal: 'Disabled'
          discoverRelationships: 'Enabled'
        }
      ])
})]

var varLayoutColumnStep = 250
var varLayoutEntityRowY = 193

var varParentEntities = [
  for (domainHealthModel, index) in varDomainHealthModels: {
    name: 'entity-domain-${domainHealthModel.domain}'
    displayName: domainHealthModel.displayName
    canvasPosition: {
      x: index * varLayoutColumnStep
      y: varLayoutEntityRowY
    }
  }
]

var varParentDiscoveryRules = [
  for domainHealthModel in varDomainHealthModels: {
    name: 'discover-domain-${domainHealthModel.domain}'
    displayName: '${domainHealthModel.displayName} domain health model'
    resourceGraphQuery: 'resources | where type =~ \'${varResourceTypeHealthModel}\' | where subscriptionId =~ \'${subscription().subscriptionId}\' | where resourceGroup =~ \'${parHealthModelResourceGroup}\' | where tostring(tags[\'alzHealthModelRole\']) =~ \'${varHealthModelRoleDomain}\' | where tostring(tags[\'alzHealthModelDomain\']) =~ \'${domainHealthModel.domain}\' | where tostring(tags[\'alzHealthModelParent\']) =~ \'${parHealthModelName}\' | project id'
    addRecommendedSignals: 'Disabled'
    addResourceHealthSignal: 'Disabled'
    discoverRelationships: 'Disabled'
  }
]

var varParentEntityDiscoveryLinks = [
  for domainHealthModel in varDomainHealthModels: {
    entityName: 'entity-domain-${domainHealthModel.domain}'
    discoveryRuleName: 'discover-domain-${domainHealthModel.domain}'
  }
]

var varParentHealthModelTags = union(parTags, {
  alzHealthModelRole: varHealthModelRoleParent
})

var varCrossScopePlatformSubscriptionIds = union([], map(filter([
  varDomainSubscriptionIds.connectivity
  varDomainSubscriptionIds.identity
  varDomainSubscriptionIds.security
], subId => !empty(subId) && toLower(subId) != toLower(subscription().subscriptionId)), subId => toLower(subId)))

//========================================
// Resources
//========================================

module modHealthModelResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'modHealthModelResourceGroup-${uniqueString(parHealthModelResourceGroup,parLocations[0])}'
  scope: subscription()
  params: {
    name: parHealthModelResourceGroup
    location: parLocations[0]
    lock: parGlobalResourceLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

resource resResourceGroupPointer 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: parHealthModelResourceGroup
  scope: subscription()
  dependsOn: [
    modHealthModelResourceGroup
  ]
}

// Discovery Identity
module modDiscoveryIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.6.0' = {
  name: 'modDiscoveryIdentity-${uniqueString(parHealthModelResourceGroup,parDiscoveryIdentityName,parLocations[0])}'
  scope: resResourceGroupPointer
  params: {
    name: parDiscoveryIdentityName
    location: parLocations[0]
    tags: parTags
    lock: parGlobalResourceLock
    enableTelemetry: parEnableTelemetry
  }
}

// Reader for the discovery identity on the deployment subscription
module modDiscoverySubscriptionReader 'discoveryReader.bicep' = {
  name: 'rbac-ahmdisc-${substring(uniqueString(subscription().subscriptionId, varReaderRoleId), 0, 8)}'
  scope: subscription(subscription().subscriptionId)
  params: {
    parPrincipalId: modDiscoveryIdentity.outputs.principalId
    parRoleDefinitionId: varReaderRoleId
  }
}

module modDiscoveryCrossScopeSubscriptionReader 'discoveryReader.bicep' = [for targetSubscriptionId in varCrossScopePlatformSubscriptionIds: if (parEnableCrossScopeDiscoveryReader) {
  name: 'rbac-ahmdisc-sub-${substring(uniqueString(targetSubscriptionId, varReaderRoleId), 0, 8)}'
  scope: subscription(targetSubscriptionId)
  params: {
    parPrincipalId: modDiscoveryIdentity.outputs.principalId
    parRoleDefinitionId: varReaderRoleId
  }
}]

// ALZ domain Health Models
module modDomainHealthModels 'domainHealthModel.bicep' = [
  for domainHealthModel in varDomainHealthModels: {
    name: 'modDomainHealthModel-${domainHealthModel.domain}-${uniqueString(parHealthModelResourceGroup, domainHealthModel.healthModelName, parHealthModelLocation)}'
    scope: resResourceGroupPointer
    dependsOn: [
      modHealthModelResourceGroup
      modDiscoverySubscriptionReader
    ]
    params: {
      parHealthModelName: domainHealthModel.healthModelName
      parHealthModelParentModelName: parHealthModelName
      parDomain: domainHealthModel.domain
      parDomainDisplayName: domainHealthModel.displayName
      parHealthModelLocation: parHealthModelLocation
      parGlobalResourceLock: parGlobalResourceLock
      parDiscoveryIdentityResourceId: modDiscoveryIdentity.outputs.resourceId
      parDiscoveryRules: domainHealthModel.discoveryRules
      parTags: parTags
    }
  }
]

// Parent Health Model
module modParentHealthModel 'healthModel.bicep' = {
  name: 'modParentHealthModel-${uniqueString(parHealthModelResourceGroup,parHealthModelName,parHealthModelLocation)}'
  scope: resResourceGroupPointer
  dependsOn: [
    modDiscoverySubscriptionReader
    modDomainHealthModels
  ]
  params: {
    parHealthModelName: parHealthModelName
    parHealthModelLocation: parHealthModelLocation
    parDiscoveryIdentityResourceId: modDiscoveryIdentity.outputs.resourceId
    parEntities: varParentEntities
    parDiscoveryRules: varParentDiscoveryRules
    parEntityDiscoveryLinks: varParentEntityDiscoveryLinks
    parHealthModelLock: parGlobalResourceLock
    parTags: varParentHealthModelTags
  }
}

//========================================
// Outputs
//========================================

@description('The resource ID of the platform health model.')
output outHealthModelResourceId string = modParentHealthModel.outputs.outHealthModelResourceId

@description('The resource ID of the parent platform health model.')
output outParentHealthModelResourceId string = modParentHealthModel.outputs.outHealthModelResourceId

@description('The resource ID of the health model discovery identity.')
output outDiscoveryIdentityResourceId string = modDiscoveryIdentity.outputs.resourceId

@description('The principal ID of the health model discovery identity.')
output outDiscoveryIdentityPrincipalId string = modDiscoveryIdentity.outputs.principalId

//========================================
// Definitions
//========================================

// Lock Type
type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}?
