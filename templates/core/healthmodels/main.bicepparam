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
param parGovernanceSubscriptionId = '{{management_subscription_id}}'
param parObservabilitySubscriptionId = '{{management_subscription_id}}'

// Discovery Resource Type Parameters
param parIncludedResourceTypesGlobal = []
param parSecurityResourceTypes = [
  'Microsoft.KeyVault/vaults'
]
param parConnectivityEdgeResourceTypes = [
  'Microsoft.Network/publicIPAddresses'
  'Microsoft.Network/loadBalancers'
  'Microsoft.Network/applicationGateways'
  'Microsoft.Network/natGateways'
  'Microsoft.Network/azureFirewalls'
  'Microsoft.Network/firewallPolicies'
  'Microsoft.Network/ddosProtectionPlans'
]
param parHybridConnectivityResourceTypes = [
  'Microsoft.Network/virtualNetworkGateways'
  'Microsoft.Network/expressRouteCircuits'
  'Microsoft.Network/connections'
  'Microsoft.Network/vpnGateways'
  'Microsoft.Network/vpnSites'
  'Microsoft.Network/expressRouteGateways'
]
param parNetworkControlPlaneResourceTypes = [
  'Microsoft.Network/virtualNetworks'
  'Microsoft.Network/routeTables'
  'Microsoft.Network/networkSecurityGroups'
  'Microsoft.Network/virtualWans'
  'Microsoft.Network/virtualHubs'
]
param parNameResolutionResourceTypes = [
  'Microsoft.Network/privateDnsZones'
  'Microsoft.Network/dnsResolvers'
]
param parSecureOperationsAccessResourceTypes = [
  'Microsoft.Network/bastionHosts'
]
param parManagementResourceTypes = [
  'Microsoft.Automation/automationAccounts'
  'Microsoft.RecoveryServices/vaults'
]
param parIdentityResourceTypes = [
  'Microsoft.ManagedIdentity/userAssignedIdentities'
]
param parGovernanceResourceTypes = [
  'Microsoft.Authorization/policyAssignments'
  'Microsoft.Authorization/policyDefinitions'
  'Microsoft.Authorization/policySetDefinitions'
  'Microsoft.Authorization/roleAssignments'
  'Microsoft.Authorization/roleDefinitions'
  'Microsoft.Management/managementGroups'
]
param parObservabilityResourceTypes = [
  'Microsoft.Insights/actionGroups'
  'Microsoft.Insights/dataCollectionRules'
  'Microsoft.Insights/scheduledQueryRules'
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.AlertsManagement/smartDetectorAlertRules'
  'Microsoft.Insights/components'
  'Microsoft.Storage/storageAccounts'
]
param parWorkloadRequestPathResourceTypes = [
  'Microsoft.Web/sites'
  'Microsoft.App/containerApps'
  'Microsoft.ContainerService/managedClusters'
]
param parWorkloadComputeResourceTypes = [
  'Microsoft.Web/sites'
  'Microsoft.App/containerApps'
  'Microsoft.ContainerService/managedClusters'
  'Microsoft.Compute/virtualMachines'
]
param parWorkloadDataResourceTypes = [
  'Microsoft.DocumentDB/databaseAccounts'
  'Microsoft.DBforPostgreSQL/flexibleServers'
  'Microsoft.DBforPostgreSQL/servers'
  'Microsoft.Sql/servers'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.KeyVault/vaults'
]

// Optional explicit AMBA signal anchor
param parAmbaReferenceKeyVaultResourceId = '{{amba_reference_keyvault_resource_id||}}'

// Discovery Signal Parameters
param parEnableResourceHealthSignal = false
