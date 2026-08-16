metadata name = 'ALZ Bicep Accelerator - Platform Health Model'
metadata description = 'Used to deploy an Azure Monitor health model for ALZ platform user and system flows.'

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
@description('Optional. The ID of the subscription that the security foundation discovery rule queries.')
param parSecuritySubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the connectivity discovery rules query.')
param parConnectivitySubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the management operations discovery rules query.')
param parManagementSubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the identity foundation discovery rule queries.')
param parIdentitySubscriptionId string = subscription().subscriptionId

@description('Optional. The ID of the subscription that the governance and compliance discovery rule queries.')
param parGovernanceSubscriptionId string = parManagementSubscriptionId

@description('Optional. The ID of the subscription that the telemetry pipeline discovery rule queries.')
param parObservabilitySubscriptionId string = parManagementSubscriptionId

@description('Optional. The ID of the subscription that the workload platform discovery rule queries.')
param parLandingZonesSubscriptionId string = subscription().subscriptionId

// Discovery Resource Type Parameters
@description('Optional. Resource types added to every discovery rule in addition to the resource types of that rule.')
param parIncludedResourceTypesGlobal array = []

@description('Optional. Security foundation resource types such as key management and edge security controls.')
@minLength(1)
param parSecurityResourceTypes array = [
  'Microsoft.KeyVault/vaults'
]

@description('Optional. Internet edge resource types shared by user and platform traffic flows.')
@minLength(1)
param parConnectivityEdgeResourceTypes array = [
  'Microsoft.Network/publicIPAddresses'
  'Microsoft.Network/loadBalancers'
  'Microsoft.Network/applicationGateways'
  'Microsoft.Network/natGateways'
  'Microsoft.Network/azureFirewalls'
  'Microsoft.Network/firewallPolicies'
  'Microsoft.Network/ddosProtectionPlans'
]

@description('Optional. Hybrid connectivity resource types for ExpressRoute, VPN, and transit gateways.')
@minLength(1)
param parHybridConnectivityResourceTypes array = [
  'Microsoft.Network/virtualNetworkGateways'
  'Microsoft.Network/expressRouteCircuits'
  'Microsoft.Network/connections'
  'Microsoft.Network/vpnGateways'
  'Microsoft.Network/vpnSites'
  'Microsoft.Network/expressRouteGateways'
]

@description('Optional. Network control plane resource types for hub and vWAN route and segment control.')
@minLength(1)
param parNetworkControlPlaneResourceTypes array = [
  'Microsoft.Network/virtualNetworks'
  'Microsoft.Network/routeTables'
  'Microsoft.Network/networkSecurityGroups'
  'Microsoft.Network/virtualWans'
  'Microsoft.Network/virtualHubs'
]

@description('Optional. Name resolution resource types used by hub and vWAN patterns.')
@minLength(1)
param parNameResolutionResourceTypes array = [
  'Microsoft.Network/privateDnsZones'
  'Microsoft.Network/dnsResolvers'
]

@description('Optional. Secure operations access resource types.')
@minLength(1)
param parSecureOperationsAccessResourceTypes array = [
  'Microsoft.Network/bastionHosts'
]

@description('Optional. Management operations resource types.')
@minLength(1)
param parManagementResourceTypes array = [
  'Microsoft.Automation/automationAccounts'
  'Microsoft.RecoveryServices/vaults'
]

@description('Optional. Identity foundation resource types.')
@minLength(1)
param parIdentityResourceTypes array = [
  'Microsoft.ManagedIdentity/userAssignedIdentities'
]

@description('Optional. Governance and compliance control-plane resource types.')
@minLength(1)
param parGovernanceResourceTypes array = [
  'Microsoft.Authorization/policyAssignments'
  'Microsoft.Authorization/policyDefinitions'
  'Microsoft.Authorization/policySetDefinitions'
  'Microsoft.Authorization/roleAssignments'
  'Microsoft.Authorization/roleDefinitions'
  'Microsoft.Management/managementGroups'
]

@description('Optional. Telemetry pipeline resource types.')
@minLength(1)
param parObservabilityResourceTypes array = [
  'Microsoft.Insights/actionGroups'
  'Microsoft.Insights/dataCollectionRules'
  'Microsoft.Insights/scheduledQueryRules'
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.AlertsManagement/smartDetectorAlertRules'
  'Microsoft.Insights/components'
  'Microsoft.Storage/storageAccounts'
]

@description('Optional. Workload request-path resource types used by ALZ landing zones.')
@minLength(1)
param parWorkloadRequestPathResourceTypes array = [
  'Microsoft.Web/sites'
  'Microsoft.App/containerApps'
  'Microsoft.ContainerService/managedClusters'
]

@description('Optional. Workload compute resource types used by ALZ landing zones.')
@minLength(1)
param parWorkloadComputeResourceTypes array = [
  'Microsoft.Web/sites'
  'Microsoft.App/containerApps'
  'Microsoft.ContainerService/managedClusters'
  'Microsoft.Compute/virtualMachines'
]

@description('Optional. Workload data-access resource types used by ALZ landing zones.')
@minLength(1)
param parWorkloadDataResourceTypes array = [
  'Microsoft.DocumentDB/databaseAccounts'
  'Microsoft.DBforPostgreSQL/flexibleServers'
  'Microsoft.DBforPostgreSQL/servers'
  'Microsoft.Sql/servers'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.KeyVault/vaults'
]

@description('Optional. Resource ID of a platform key vault that anchors active AMBA threshold signals in this model. Leave empty to skip the explicit key vault signal entity.')
param parAmbaReferenceKeyVaultResourceId string = ''

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

var varFlowCategories = [
  {
    name: 'group-user-flows'
    displayName: 'User flows'
  }
  {
    name: 'group-system-flows'
    displayName: 'System flows'
  }
]

var varFlows = [
  {
    name: 'flow-user-app-request-path'
    displayName: 'User app request path'
    categoryName: 'group-user-flows'
  }
  {
    name: 'flow-user-app-data-access'
    displayName: 'User app data access'
    categoryName: 'group-user-flows'
  }
  {
    name: 'flow-user-workload-compute'
    displayName: 'User workload compute'
    categoryName: 'group-user-flows'
  }
  {
    name: 'flow-user-workload-recovery'
    displayName: 'User workload recovery'
    categoryName: 'group-user-flows'
  }
  {
    name: 'flow-system-hybrid-connectivity'
    displayName: 'System hybrid connectivity'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-internet-edge'
    displayName: 'System internet edge'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-name-resolution'
    displayName: 'System name resolution'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-network-control-plane'
    displayName: 'System network control plane'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-secure-operations-access'
    displayName: 'System secure operations access'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-secrets-and-keys'
    displayName: 'System secrets and keys'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-telemetry-pipeline'
    displayName: 'System telemetry pipeline'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-platform-automation'
    displayName: 'System platform automation'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-governance-and-compliance'
    displayName: 'System governance and compliance'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-workload-platform-services'
    displayName: 'System workload platform services'
    categoryName: 'group-system-flows'
  }
  {
    name: 'flow-system-azure-platform-health'
    displayName: 'System Azure platform health'
    categoryName: 'group-system-flows'
  }
]

var varDiscoveryRules = [
  {
    name: 'discover-hybrid-connectivity'
    displayName: 'Hybrid connectivity resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parHybridConnectivityResourceTypes)
    subscriptionId: parConnectivitySubscriptionId
  }
  {
    name: 'discover-network-edge'
    displayName: 'Internet edge resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parConnectivityEdgeResourceTypes)
    subscriptionId: parConnectivitySubscriptionId
  }
  {
    name: 'discover-name-resolution'
    displayName: 'Name resolution resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parNameResolutionResourceTypes)
    subscriptionId: parConnectivitySubscriptionId
  }
  {
    name: 'discover-network-control-plane'
    displayName: 'Network control plane resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parNetworkControlPlaneResourceTypes)
    subscriptionId: parConnectivitySubscriptionId
  }
  {
    name: 'discover-secure-operations-access'
    displayName: 'Secure operations access resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parSecureOperationsAccessResourceTypes)
    subscriptionId: parConnectivitySubscriptionId
  }
  {
    name: 'discover-security-foundation'
    displayName: 'Security foundation resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parSecurityResourceTypes)
    subscriptionId: parSecuritySubscriptionId
  }
  {
    name: 'discover-identity-foundation'
    displayName: 'Identity foundation resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parIdentityResourceTypes)
    subscriptionId: parIdentitySubscriptionId
  }
  {
    name: 'discover-telemetry-pipeline'
    displayName: 'Telemetry pipeline resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parObservabilityResourceTypes)
    subscriptionId: parObservabilitySubscriptionId
  }
  {
    name: 'discover-platform-automation'
    displayName: 'Platform automation resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parManagementResourceTypes)
    subscriptionId: parManagementSubscriptionId
  }
  {
    name: 'discover-governance-and-compliance'
    displayName: 'Governance and compliance resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parGovernanceResourceTypes)
    subscriptionId: parGovernanceSubscriptionId
  }
  {
    name: 'discover-workload-request-path'
    displayName: 'Workload request path resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parWorkloadRequestPathResourceTypes)
    subscriptionId: parLandingZonesSubscriptionId
  }
  {
    name: 'discover-workload-compute'
    displayName: 'Workload compute resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parWorkloadComputeResourceTypes)
    subscriptionId: parLandingZonesSubscriptionId
  }
  {
    name: 'discover-workload-data-access'
    displayName: 'Workload data-access resources'
    resourceTypes: union(parIncludedResourceTypesGlobal, parWorkloadDataResourceTypes)
    subscriptionId: parLandingZonesSubscriptionId
  }
]

var varFlowDiscoveryLinks = [
  {
    flowName: 'flow-system-hybrid-connectivity'
    discoveryRuleName: 'discover-hybrid-connectivity'
  }
  {
    flowName: 'flow-system-internet-edge'
    discoveryRuleName: 'discover-network-edge'
  }
  {
    flowName: 'flow-system-name-resolution'
    discoveryRuleName: 'discover-name-resolution'
  }
  {
    flowName: 'flow-system-network-control-plane'
    discoveryRuleName: 'discover-network-control-plane'
  }
  {
    flowName: 'flow-system-secure-operations-access'
    discoveryRuleName: 'discover-secure-operations-access'
  }
  {
    flowName: 'flow-system-secrets-and-keys'
    discoveryRuleName: 'discover-security-foundation'
  }
  {
    flowName: 'flow-system-secrets-and-keys'
    discoveryRuleName: 'discover-identity-foundation'
  }
  {
    flowName: 'flow-system-telemetry-pipeline'
    discoveryRuleName: 'discover-telemetry-pipeline'
  }
  {
    flowName: 'flow-system-platform-automation'
    discoveryRuleName: 'discover-platform-automation'
  }
  {
    flowName: 'flow-system-platform-automation'
    discoveryRuleName: 'discover-telemetry-pipeline'
  }
  {
    flowName: 'flow-system-governance-and-compliance'
    discoveryRuleName: 'discover-governance-and-compliance'
  }
  {
    flowName: 'flow-system-workload-platform-services'
    discoveryRuleName: 'discover-workload-request-path'
  }
  {
    flowName: 'flow-system-workload-platform-services'
    discoveryRuleName: 'discover-workload-compute'
  }
  {
    flowName: 'flow-system-workload-platform-services'
    discoveryRuleName: 'discover-workload-data-access'
  }
  {
    flowName: 'flow-user-app-request-path'
    discoveryRuleName: 'discover-network-edge'
  }
  {
    flowName: 'flow-user-app-request-path'
    discoveryRuleName: 'discover-workload-request-path'
  }
  {
    flowName: 'flow-user-app-data-access'
    discoveryRuleName: 'discover-workload-data-access'
  }
  {
    flowName: 'flow-user-app-data-access'
    discoveryRuleName: 'discover-security-foundation'
  }
  {
    flowName: 'flow-user-workload-compute'
    discoveryRuleName: 'discover-workload-compute'
  }
  {
    flowName: 'flow-user-workload-recovery'
    discoveryRuleName: 'discover-platform-automation'
  }
  {
    flowName: 'flow-user-workload-recovery'
    discoveryRuleName: 'discover-workload-compute'
  }
]

var varAmbaReferenceEntities = empty(parAmbaReferenceKeyVaultResourceId)
  ? []
  : [
      {
        name: 'entity-system-secrets-keys-keyvault'
        displayName: 'Platform key vault thresholds (AMBA)'
        flowName: 'flow-system-secrets-and-keys'
        azureResourceId: parAmbaReferenceKeyVaultResourceId
        azureResourceKind: 'vault'
        signals: [
          {
            name: 'signal-keyvault-service-api-latency'
            displayName: 'Service API latency'
            metricNamespace: 'Microsoft.KeyVault/vaults'
            metricName: 'ServiceApiLatency'
            aggregationType: 'Average'
            timeGrain: 'PT5M'
            refreshInterval: 'PT5M'
            dataUnit: 'MilliSeconds'
            unhealthyOperator: 'GreaterThan'
            unhealthyThreshold: 1000
            unhealthySensitivity: null
            lookBackWindow: null
            ambaSource: 'services/KeyVault/vaults/alerts.yaml#ServiceApiLatency'
          }
          {
            name: 'signal-keyvault-service-api-result'
            displayName: 'Service API result anomaly'
            metricNamespace: 'Microsoft.KeyVault/vaults'
            metricName: 'ServiceApiResult'
            aggregationType: 'Average'
            timeGrain: 'PT5M'
            refreshInterval: 'PT5M'
            dataUnit: 'Percent'
            unhealthyOperator: null
            unhealthyThreshold: null
            unhealthySensitivity: 'Medium'
            lookBackWindow: 'PT15M'
            ambaSource: 'services/KeyVault/vaults/alerts.yaml#ServiceApiResult'
          }
        ]
      }
    ]

// Domains commonly share a subscription, so grant Reader once per distinct subscription.
var varDiscoverySubscriptionIds = union(
  [parSecuritySubscriptionId],
  [parConnectivitySubscriptionId],
  [parManagementSubscriptionId],
  [parIdentitySubscriptionId],
  [parGovernanceSubscriptionId],
  [parObservabilitySubscriptionId],
  [parLandingZonesSubscriptionId]
)

var varPlatformResourceTypeInventory = [
  'Microsoft.AlertsManagement/smartDetectorAlertRules'
  'Microsoft.App/containerApps'
  'Microsoft.Authorization/locks'
  'Microsoft.Authorization/policyAssignments'
  'Microsoft.Authorization/policyDefinitions'
  'Microsoft.Authorization/policySetDefinitions'
  'Microsoft.Authorization/roleAssignments'
  'Microsoft.Authorization/roleDefinitions'
  'Microsoft.Automation/automationAccounts'
  'Microsoft.Compute/virtualMachines'
  'Microsoft.ContainerService/managedClusters'
  'Microsoft.DBforPostgreSQL/flexibleServers'
  'Microsoft.DBforPostgreSQL/servers'
  'Microsoft.DocumentDB/databaseAccounts'
  'Microsoft.Insights/actionGroups'
  'Microsoft.Insights/components'
  'Microsoft.Insights/dataCollectionRules'
  'Microsoft.Insights/scheduledQueryRules'
  'Microsoft.KeyVault/vaults'
  'Microsoft.ManagedIdentity/userAssignedIdentities'
  'Microsoft.Management/managementGroups'
  'Microsoft.Network/applicationGateways'
  'Microsoft.Network/azureFirewalls'
  'Microsoft.Network/bastionHosts'
  'Microsoft.Network/connections'
  'Microsoft.Network/ddosProtectionPlans'
  'Microsoft.Network/dnsResolvers'
  'Microsoft.Network/expressRouteCircuits'
  'Microsoft.Network/expressRouteGateways'
  'Microsoft.Network/firewallPolicies'
  'Microsoft.Network/loadBalancers'
  'Microsoft.Network/natGateways'
  'Microsoft.Network/networkSecurityGroups'
  'Microsoft.Network/privateDnsZones'
  'Microsoft.Network/publicIPAddresses'
  'Microsoft.Network/routeTables'
  'Microsoft.Network/virtualHubs'
  'Microsoft.Network/virtualNetworkGateways'
  'Microsoft.Network/virtualNetworks'
  'Microsoft.Network/virtualWans'
  'Microsoft.Network/vpnGateways'
  'Microsoft.Network/vpnSites'
  'Microsoft.OperationalInsights/workspaces'
  'Microsoft.RecoveryServices/vaults'
  'Microsoft.Resources/resourceGroups'
  'Microsoft.Sql/servers'
  'Microsoft.Storage/storageAccounts'
  'Microsoft.Web/sites'
]

var varSystemFlowResourceHomes = [
  {
    resourceType: 'Microsoft.AlertsManagement/smartDetectorAlertRules'
    flowNames: [
      'flow-system-telemetry-pipeline'
    ]
  }
  {
    resourceType: 'Microsoft.App/containerApps'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.Authorization/policyAssignments'
    flowNames: [
      'flow-system-governance-and-compliance'
    ]
  }
  {
    resourceType: 'Microsoft.Authorization/policyDefinitions'
    flowNames: [
      'flow-system-governance-and-compliance'
    ]
  }
  {
    resourceType: 'Microsoft.Authorization/policySetDefinitions'
    flowNames: [
      'flow-system-governance-and-compliance'
    ]
  }
  {
    resourceType: 'Microsoft.Authorization/roleAssignments'
    flowNames: [
      'flow-system-governance-and-compliance'
    ]
  }
  {
    resourceType: 'Microsoft.Authorization/roleDefinitions'
    flowNames: [
      'flow-system-governance-and-compliance'
    ]
  }
  {
    resourceType: 'Microsoft.Automation/automationAccounts'
    flowNames: [
      'flow-system-platform-automation'
    ]
  }
  {
    resourceType: 'Microsoft.Compute/virtualMachines'
    flowNames: [
      'flow-system-workload-platform-services'
      'flow-system-secrets-and-keys'
    ]
  }
  {
    resourceType: 'Microsoft.ContainerService/managedClusters'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.DBforPostgreSQL/flexibleServers'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.DBforPostgreSQL/servers'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.DocumentDB/databaseAccounts'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.Insights/actionGroups'
    flowNames: [
      'flow-system-telemetry-pipeline'
    ]
  }
  {
    resourceType: 'Microsoft.Insights/components'
    flowNames: [
      'flow-system-telemetry-pipeline'
    ]
  }
  {
    resourceType: 'Microsoft.Insights/dataCollectionRules'
    flowNames: [
      'flow-system-telemetry-pipeline'
    ]
  }
  {
    resourceType: 'Microsoft.Insights/scheduledQueryRules'
    flowNames: [
      'flow-system-telemetry-pipeline'
    ]
  }
  {
    resourceType: 'Microsoft.KeyVault/vaults'
    flowNames: [
      'flow-system-secrets-and-keys'
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.ManagedIdentity/userAssignedIdentities'
    flowNames: [
      'flow-system-secrets-and-keys'
    ]
  }
  {
    resourceType: 'Microsoft.Management/managementGroups'
    flowNames: [
      'flow-system-governance-and-compliance'
    ]
  }
  {
    resourceType: 'Microsoft.Network/applicationGateways'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/azureFirewalls'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/bastionHosts'
    flowNames: [
      'flow-system-secure-operations-access'
    ]
  }
  {
    resourceType: 'Microsoft.Network/connections'
    flowNames: [
      'flow-system-hybrid-connectivity'
      'flow-system-network-control-plane'
    ]
  }
  {
    resourceType: 'Microsoft.Network/ddosProtectionPlans'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/dnsResolvers'
    flowNames: [
      'flow-system-name-resolution'
    ]
  }
  {
    resourceType: 'Microsoft.Network/expressRouteCircuits'
    flowNames: [
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.Network/expressRouteGateways'
    flowNames: [
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.Network/firewallPolicies'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/loadBalancers'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/natGateways'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/networkSecurityGroups'
    flowNames: [
      'flow-system-network-control-plane'
    ]
  }
  {
    resourceType: 'Microsoft.Network/privateDnsZones'
    flowNames: [
      'flow-system-name-resolution'
    ]
  }
  {
    resourceType: 'Microsoft.Network/publicIPAddresses'
    flowNames: [
      'flow-system-internet-edge'
    ]
  }
  {
    resourceType: 'Microsoft.Network/routeTables'
    flowNames: [
      'flow-system-network-control-plane'
    ]
  }
  {
    resourceType: 'Microsoft.Network/virtualHubs'
    flowNames: [
      'flow-system-network-control-plane'
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.Network/virtualNetworkGateways'
    flowNames: [
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.Network/virtualNetworks'
    flowNames: [
      'flow-system-network-control-plane'
    ]
  }
  {
    resourceType: 'Microsoft.Network/virtualWans'
    flowNames: [
      'flow-system-network-control-plane'
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.Network/vpnGateways'
    flowNames: [
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.Network/vpnSites'
    flowNames: [
      'flow-system-hybrid-connectivity'
    ]
  }
  {
    resourceType: 'Microsoft.OperationalInsights/workspaces'
    flowNames: [
      'flow-system-telemetry-pipeline'
      'flow-system-platform-automation'
    ]
  }
  {
    resourceType: 'Microsoft.RecoveryServices/vaults'
    flowNames: [
      'flow-system-platform-automation'
    ]
  }
  {
    resourceType: 'Microsoft.Sql/servers'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
  {
    resourceType: 'Microsoft.Storage/storageAccounts'
    flowNames: [
      'flow-system-workload-platform-services'
      'flow-system-telemetry-pipeline'
    ]
  }
  {
    resourceType: 'Microsoft.Web/sites'
    flowNames: [
      'flow-system-workload-platform-services'
    ]
  }
]

var varDeferredResourceTypes = [
  {
    resourceType: 'Microsoft.Authorization/locks'
    reason: 'Lifecycle guardrail resource created by accelerator modules. It has no operational service-health signal surface of its own.'
  }
  {
    resourceType: 'Microsoft.CloudHealth/healthmodels'
    reason: 'The health model container is the rollup construct. Its health derives from child entities rather than a separate system flow.'
  }
  {
    resourceType: 'Microsoft.CloudHealth/healthmodels/authenticationsettings'
    reason: 'Authentication settings configure discovery identity usage. They are control metadata, not a monitored platform service.'
  }
  {
    resourceType: 'Microsoft.CloudHealth/healthmodels/discoveryrules'
    reason: 'Discovery rules are model metadata. They are represented through relationships and by the discovered entities they create.'
  }
  {
    resourceType: 'Microsoft.CloudHealth/healthmodels/entities'
    reason: 'Entity resources are the health-model topology itself, not external ALZ platform dependencies.'
  }
  {
    resourceType: 'Microsoft.CloudHealth/healthmodels/relationships'
    reason: 'Relationship resources only encode topology edges. They do not expose independent service signals.'
  }
  {
    resourceType: 'Microsoft.Resources/resourceGroups'
    reason: 'Resource groups are deployment containers. They are tracked indirectly through the platform resources they contain.'
  }
]

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
  dependsOn: [
    modDiscoverySubscriptionReader
  ]
  params: {
    parHealthModelName: parHealthModelName
    parHealthModelLocation: parHealthModelLocation
    parDiscoveryIdentityResourceId: modDiscoveryIdentity.outputs.resourceId
    parFlowCategories: varFlowCategories
    parFlows: varFlows
    parDiscoveryRules: varDiscoveryRules
    parFlowDiscoveryLinks: varFlowDiscoveryLinks
    parAmbaReferenceEntities: varAmbaReferenceEntities
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

@description('Resource type coverage evidence used to map accelerator ALZ types to system-flow homes or explicit deferred handling.')
output outSystemFlowCoverageSummary object = {
  inventoryResourceTypes: varPlatformResourceTypeInventory
  systemFlowResourceHomes: varSystemFlowResourceHomes
  deferredResourceTypes: varDeferredResourceTypes
}

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
