metadata name = 'ALZ Bicep Accelerator - Platform Health Model'
metadata description = 'Used to deploy an Azure Monitor health model for the ALZ platform, with per-domain Resource Graph discovery rules.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('Required. The name of the Resource Group that hosts the platform health model.')
param parHealthModelResourceGroup string

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

// Health Model Parameters
@description('Required. The name of the platform health model.')
@minLength(3)
@maxLength(44)
param parHealthModelName string

@description('Optional. The location of the platform health model. Must be a region where the Microsoft.CloudHealth resource provider offers health models, which is a smaller set than the regions available to the rest of the platform.')
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

// Discovery Identity Parameters
@description('Required. The name of the User Assigned Identity used by the health model discovery rules.')
@minLength(3)
@maxLength(128)
param parDiscoveryIdentityName string

@description('''Resource Lock Configuration for the discovery User Assigned Identity.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parDiscoveryIdentityLock lockType?

@description('''Resource Lock Configuration for the Health Model.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parHealthModelLock lockType?

// Discovery Scope Parameters
@description('Optional. The ID of the subscription that the Security domain discovery rule queries.')
param parSecuritySubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the Connectivity domain discovery rule queries.')
param parConnectivitySubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the Management domain discovery rule queries.')
param parManagementSubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the Identity domain discovery rule queries.')
param parIdentitySubscriptionId string = subscription().subscriptionId

// Discovery Resource Type Parameters
@description('Optional. Resource types added to every domain discovery rule in addition to the resource types of that domain.')
param parIncludedResourceTypesGlobal array = []

@description('Optional. The resource types discovered by the Security domain rule.')
@minLength(1)
param parSecurityResourceTypes array = [
  'Microsoft.KeyVault/vaults'
  'Microsoft.Network/azureFirewalls'
  'Microsoft.Network/firewallPolicies'
  'Microsoft.Network/ddosProtectionPlans'
]

@description('Optional. The resource types discovered by the Connectivity domain rule.')
@minLength(1)
param parConnectivityResourceTypes array = [
  'Microsoft.Network/virtualNetworks'
  'Microsoft.Network/virtualNetworkGateways'
  'Microsoft.Network/expressRouteCircuits'
  'Microsoft.Network/publicIPAddresses'
  'Microsoft.Network/loadBalancers'
  'Microsoft.Network/applicationGateways'
  'Microsoft.Network/privateDnsZones'
  'Microsoft.Network/bastionHosts'
  'Microsoft.Network/natGateways'
  'Microsoft.Network/connections'
]

@description('Optional. The resource types discovered by the Management domain rule.')
@minLength(1)
param parManagementResourceTypes array = [
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.Automation/automationAccounts'
  'Microsoft.RecoveryServices/vaults'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.Insights/components'
  'Microsoft.Insights/actionGroups'
]

@description('Optional. The resource types discovered by the Identity domain rule.')
@minLength(1)
param parIdentityResourceTypes array = [
  'Microsoft.ManagedIdentity/userAssignedIdentities'
  'Microsoft.Compute/virtualMachines'
  'Microsoft.KeyVault/vaults'
  'Microsoft.Network/privateDnsZones'
]

// Discovery Signal Parameters
@description('Optional. Adds the Azure Resource Health signal to every discovered resource. Disabled by default because Resource Health is not supported for every resource type, and an unsupported type reports a false Degraded state.')
param parEnableResourceHealthSignal bool = false

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

// Reader is the role the health model identity needs over every scope it discovers.
// Monitoring Reader is not sufficient and leaves every discovered signal Unknown.
var varReaderRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

// A single data array drives both the discovery rule loop and the relationship loop,
// so adding or removing a platform domain is a one line change.
var varDomains = [
  {
    name: 'discover-security'
    displayName: 'Security platform resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parSecurityResourceTypes)
    subscriptionId: parSecuritySubscriptionId
  }
  {
    name: 'discover-connectivity'
    displayName: 'Connectivity platform resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parConnectivityResourceTypes)
    subscriptionId: parConnectivitySubscriptionId
  }
  {
    name: 'discover-management'
    displayName: 'Management platform resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parManagementResourceTypes)
    subscriptionId: parManagementSubscriptionId
  }
  {
    name: 'discover-identity'
    displayName: 'Identity platform resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parIdentityResourceTypes)
    subscriptionId: parIdentitySubscriptionId
  }
]

// Domains commonly share a subscription, so grant Reader once per distinct subscription.
var varDiscoverySubscriptionIds = union(
  [parSecuritySubscriptionId],
  [parConnectivitySubscriptionId],
  [parManagementSubscriptionId],
  [parIdentitySubscriptionId]
)

//========================================
// Resources
//========================================

module modHealthModelResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'modHealthModelResourceGroup-${uniqueString(parHealthModelResourceGroup,parLocations[0])}'
  scope: subscription()
  params: {
    name: parHealthModelResourceGroup
    location: parLocations[0]
    lock: parResourceGroupLock ?? parGlobalResourceLock
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
    lock: parDiscoveryIdentityLock ?? parGlobalResourceLock
    enableTelemetry: parEnableTelemetry
  }
}

// Reader for the discovery identity on every distinct subscription the rules query
module modDiscoverySubscriptionReader 'discoveryReader.bicep' = [
  for discoverySubscriptionId in varDiscoverySubscriptionIds: {
    name: 'rbac-ahmdisc-${substring(uniqueString(discoverySubscriptionId, varReaderRoleId), 0, 8)}'
    scope: subscription(discoverySubscriptionId)
    params: {
      parPrincipalId: modDiscoveryIdentity.outputs.principalId
      parRoleDefinitionId: varReaderRoleId
    }
  }
]

// Health Model
module modHealthModel 'healthModel.bicep' = {
  name: 'modHealthModel-${uniqueString(parHealthModelResourceGroup,parHealthModelName,parHealthModelLocation)}'
  scope: resResourceGroupPointer
  params: {
    parHealthModelName: parHealthModelName
    parHealthModelLocation: parHealthModelLocation
    parDiscoveryIdentityResourceId: modDiscoveryIdentity.outputs.resourceId
    parDomains: varDomains
    parEnableResourceHealthSignal: parEnableResourceHealthSignal
    parHealthModelLock: parHealthModelLock ?? parGlobalResourceLock
    parTags: parTags
  }
}

//========================================
// Outputs
//========================================

@description('The resource ID of the platform health model.')
output outHealthModelResourceId string = modHealthModel.outputs.outHealthModelResourceId

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
