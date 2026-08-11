using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = true

// Resource Group Parameters
param parHealthModelResourceGroup = '{{resource_group_health_model_name_prefix||rg-alz-healthmodels}}-${parLocations[0]}'

// Health Model Parameters
// The health model location is chosen separately from the platform locations because the
// Microsoft.CloudHealth resource provider offers health models in a smaller set of regions.
param parHealthModelName = 'ahm-alz-platform'
param parHealthModelLocation = '{{health_model_location||swedencentral}}'

// Discovery Identity Parameters
param parDiscoveryIdentityName = 'mi-ahm-alz-${parLocations[0]}'

// Discovery Scope Parameters
param parSecuritySubscriptionId = '{{security_subscription_id}}'
param parConnectivitySubscriptionId = '{{connectivity_subscription_id}}'
param parManagementSubscriptionId = '{{management_subscription_id}}'
param parIdentitySubscriptionId = '{{identity_subscription_id}}'

// Discovery Resource Type Parameters
param parIncludedResourceTypesGlobal = []
param parSecurityResourceTypes = [
  'Microsoft.KeyVault/vaults'
  'Microsoft.Network/azureFirewalls'
  'Microsoft.Network/firewallPolicies'
  'Microsoft.Network/ddosProtectionPlans'
]
param parConnectivityResourceTypes = [
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
param parManagementResourceTypes = [
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.Automation/automationAccounts'
  'Microsoft.RecoveryServices/vaults'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.Insights/components'
  'Microsoft.Insights/actionGroups'
]
param parIdentityResourceTypes = [
  'Microsoft.ManagedIdentity/userAssignedIdentities'
  'Microsoft.Compute/virtualMachines'
  'Microsoft.KeyVault/vaults'
  'Microsoft.Network/privateDnsZones'
]

// Discovery Signal Parameters
param parEnableResourceHealthSignal = false
