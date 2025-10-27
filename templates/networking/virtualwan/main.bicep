metadata name = 'ALZ Bicep'
metadata description = 'ALZ Bicep Module used to set up Azure Landing Zones'

targetScope = 'subscription'

//================================
// Parameters
//================================

// Resource Group Parameters
@description('The name of the Resource Group.')
param parVirtualWanResourceGroupName string = 'rg-alz-hubnetworking-001'

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

@description('The name of the DNS Resource Group.')
param parDnsResourceGroupName string = 'rg-alz-dns-001'

// VWAN Parameters
@description('Optional. The virtual WAN settings to create.')
param virtualWan virtualWanNetworkType

@description('Optional. The virtual WAN hubs to create.')
param virtualWanHubs virtualWanHubType?

// Resource Lock Parameters
@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for Private DNS Zone(s).
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parPrivateDNSZonesLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

// General Parameters
@description('The primary location to deploy resources to.')
param parPrimaryLocation string = deployment().location

@description('Tags to be applied to all resources.')
param parTags object = {}

@description('Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Resources
//========================================

// Resource Group
module modHubNetworkingResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: 'modResourceGroup-${uniqueString(parVirtualWanResourceGroupName,parPrimaryLocation)}'
  scope: subscription()
  params: {
    name: parVirtualWanResourceGroupName
    location: parPrimaryLocation
    lock: parGlobalResourceLock ?? parResourceGroupLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

resource resVwanResourceGroupPointer 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: parVirtualWanResourceGroupName
  scope: subscription()
  dependsOn: [
    modHubNetworkingResourceGroup
  ]
}

module modDnsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: 'modDnsResourceGroup-${uniqueString(parDnsResourceGroupName,parPrimaryLocation)}'
  scope: subscription()
  params: {
    name: parDnsResourceGroupName
    location: parPrimaryLocation
    lock: parGlobalResourceLock ?? parResourceGroupLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

resource resDnsResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: parDnsResourceGroupName
  scope: subscription()
  dependsOn: [
    modDnsResourceGroup
  ]
}

module resVirtualWan 'br/public:avm/res/network/virtual-wan:0.4.2' = {
  name: 'virtualWan-${uniqueString(parVirtualWanResourceGroupName, virtualWan.name)}'
  scope: resVwanResourceGroupPointer
  params: {
    name: virtualWan.?name ?? 'vwan-alz-${parPrimaryLocation}'
    allowBranchToBranchTraffic: virtualWan.?allowBranchToBranchTraffic ?? true
    type: virtualWan.?type ?? 'Standard'
    roleAssignments: virtualWan.?roleAssignments
    location: virtualWan.location
    tags: parTags
    lock: parGlobalResourceLock ?? virtualWan.?lock
    enableTelemetry: parEnableTelemetry
  }
}

module resVirtualWanHub 'br/public:avm/res/network/virtual-hub:0.4.2' = [
  for (virtualWanHub, i) in virtualWanHubs!: if (!empty(virtualWanHubs)) {
    name: 'virtualWanHub-${i}-${uniqueString(parVirtualWanResourceGroupName, virtualWan.name)}'
    scope: resVwanResourceGroupPointer
    params: {
      name: virtualWanHub.?hubName ?? 'vwanhub-alz-${virtualWanHub.location}'
      location: virtualWanHub.location
      addressPrefix: virtualWanHub.addressPrefix
      virtualWanResourceId: resVirtualWan.outputs.resourceId
      virtualRouterAutoScaleConfiguration: virtualWanHub.?virtualRouterAutoScaleConfiguration
      allowBranchToBranchTraffic: virtualWanHub.allowBranchToBranchTraffic
      azureFirewallResourceId: virtualWanHub.?azureFirewallSettings.?azureFirewallResourceID
      expressRouteGatewayResourceId: virtualWanHub.?expressRouteGatewayId ?? resVirtualNetworkGateway[i].?outputs.resourceId
      vpnGatewayResourceId: virtualWanHub.?vpnGatewayId
      p2SVpnGatewayResourceId: virtualWanHub.?p2SVpnGatewayId
      hubRouteTables: virtualWanHub.?routeTableRoutes
      hubRoutingPreference: virtualWanHub.?hubRoutingPreference
      hubVirtualNetworkConnections: virtualWanHub.?hubVirtualNetworkConnections
      preferredRoutingGateway: virtualWanHub.?preferredRoutingGateway ?? 'None'
      routingIntent: virtualWanHub.?routingIntent
      routeTableRoutes: virtualWanHub.?routeTableRoutes
      securityProviderName: virtualWanHub.?securityProviderName
      securityPartnerProviderResourceId: virtualWanHub.?securityPartnerProviderId
      virtualHubRouteTableV2s: virtualWanHub.?virtualHubRouteTableV2s
      virtualRouterAsn: virtualWanHub.?virtualRouterAsn
      virtualRouterIps: virtualWanHub.?virtualRouterIps
      lock: parGlobalResourceLock ?? virtualWanHub.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Network security
//=====================
module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.2' = [
  for (virtualWanHub, i) in virtualWanHubs!: if ((virtualWanHub.?ddosProtectionPlanSettings.?enableDDosProtection ?? false) && (virtualWanHub.?ddosProtectionPlanSettings.?lock != 'None' || parGlobalResourceLock.?kind != 'None')) {
    name: 'ddosPlan-${uniqueString(parVirtualWanResourceGroupName, virtualWanHub.?ddosProtectionPlanSettings.?name ?? '', virtualWanHub.location)}'
    scope: resVwanResourceGroupPointer
    params: {
      name: virtualWanHub.?ddosProtectionPlanSettings.?name ?? 'ddos-alz-${virtualWanHub.location}'
      location: virtualWanHub.location
      lock: parGlobalResourceLock ?? virtualWanHub.?ddosProtectionPlanSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]
module resAzFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.2' = [
  for (virtualWanHub, i) in virtualWanHubs!: if (((virtualWanHub.?azureFirewallSettings.?enableAzureFirewall ?? false)) && empty(virtualWanHub.?azureFirewallSettings.?firewallPolicyId)) {
    name: 'azFirewallPolicy-${uniqueString(parVirtualWanResourceGroupName, virtualWanHub.hubName, virtualWanHub.location)}'
    scope: resVwanResourceGroupPointer
    params: {
      name: virtualWanHub.?azureFirewallSettings.?name ?? 'azfwpolicy-alz-${virtualWanHub.location}'
      threatIntelMode: virtualWanHub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
      location: virtualWanHub.location
      tier: virtualWanHub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      enableProxy: virtualWanHub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? false
        : virtualWanHub.?azureFirewallSettings.?dnsProxyEnabled
      servers: virtualWanHub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? null
        : virtualWanHub.?azureFirewallSettings.?firewallDnsServers
      lock: parGlobalResourceLock ?? virtualWanHub.?azureFirewallSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]


//=====================
// Hybrid connectivity
//=====================
module resVirtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.10.0' = [
  for (virtualWanHub, i) in virtualWanHubs!: if ((virtualWanHub.?virtualNetworkGatewayConfig.?enableVirtualNetworkGateway ?? false) && !empty(virtualWanHub.?virtualNetworkGatewayConfig)) {
    name: 'virtualNetworkGateway-${uniqueString(parVirtualWanResourceGroupName, virtualWanHub.hubName, virtualWanHub.location)}'
    scope: resVwanResourceGroupPointer
    params: {
      allowVirtualWanTraffic: true
      name: virtualWanHub.?virtualNetworkGatewayConfig.?name ?? 'vgw-${virtualWanHub.hubName}-${virtualWanHub.location}'
      clusterSettings: {
        clusterMode: any(virtualWanHub.?virtualNetworkGatewayConfig.?vpnMode)
        asn: virtualWanHub.?virtualNetworkGatewayConfig.?asn ?? 65515
        customBgpIpAddresses: (virtualWanHub.?virtualNetworkGatewayConfig.?vpnMode == 'activePassiveBgp' || virtualWanHub.?virtualNetworkGatewayConfig.?vpnMode == 'activeActiveBgp')
          ? (virtualWanHub.?virtualNetworkGatewayConfig.?customBgpIpAddresses)
          : null
      }
      location: virtualWanHub.location
      gatewayType: virtualWanHub.?virtualNetworkGatewayConfig.?gatewayType ?? 'Vpn'
      vpnType: virtualWanHub.?virtualNetworkGatewayConfig.?vpnType ?? 'RouteBased'
      skuName: virtualWanHub.?virtualNetworkGatewayConfig.?skuName ?? 'VpnGw1AZ'
      enableBgpRouteTranslationForNat: virtualWanHub.?virtualNetworkGatewayConfig.?enableBgpRouteTranslationForNat ?? false
      enableDnsForwarding: virtualWanHub.?virtualNetworkGatewayConfig.?enableDnsForwarding ?? false
      vpnGatewayGeneration: virtualWanHub.?virtualNetworkGatewayConfig.?vpnGatewayGeneration ?? 'None'
      virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', virtualWanHub.hubName)
      domainNameLabel: virtualWanHub.?virtualNetworkGatewayConfig.?domainNameLabel ?? []
      publicIpAvailabilityZones: virtualWanHub.?virtualNetworkGatewayConfig.?skuName != 'Basic'
        ? (virtualWanHub.?virtualNetworkGatewayConfig.?publicIpZones ?? [1, 2, 3])
        : []
      lock: parGlobalResourceLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]
module resPrivateDNSZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.0' = [
  for (virtualWanHub, i) in virtualWanHubs!: if (virtualWanHub.?enablePrivateDnsZones ?? false) {
    name: 'privateDnsZone-${virtualWanHub.hubName}-${uniqueString(parDnsResourceGroupName,virtualWanHub.location)}'
    scope: resDnsResourceGroup
    params: {
      location: virtualWanHub.location
      privateLinkPrivateDnsZones: empty(virtualWanHub.?privateDnsZones) ? null : virtualWanHub.?privateDnsZones
      lock: parGlobalResourceLock ?? parPrivateDNSZonesLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//================================
// Definitions
//================================

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None' |  null)

  @description('Optional. Notes about this lock.')
  notes: string?
}

type virtualWanNetworkType = {
  @description('Required. The name of the virtual WAN.')
  name: string

  @description('Optional. Allow branch to branch traffic.')
  allowBranchToBranchTraffic: bool?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType?

  @description('Required. The location of the virtual WAN. Defaults to the location of the resource group.')
  location: string

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. The type of the virtual WAN.')
  type: 'Basic' | 'Standard'?
}

type virtualWanHubType = {
  @description('Required. The name of the hub.')
  hubName: string

  @description('Required. The location of the virtual WAN hub.')
  location: string

  @description('Required. The address prefixes for the virtual network.')
  addressPrefix: string

  @description('Optional. The virtual router auto scale configuration.')
  virtualRouterAutoScaleConfiguration: {
    minInstances: int
  }?

  @description('Required. The location of the virtual WAN hub.')
  allowBranchToBranchTraffic: bool

  @description('Optional. The Azure Firewall config.')
  azureFirewallSettings: azureFirewallType?

  @description('Optional. The Express Route Gateway resource ID.')
  expressRouteGatewayId: string?

  @description('Optional. The VPN Gateway resource ID.')
  vpnGatewayId: string?

  @description('Optional. The Point-to-Site VPN Gateway resource ID.')
  p2SVpnGatewayId: string?

  @description('Optional. The preferred routing preference for this virtual hub.')
  hubRoutingPreference: ('ASPath' | 'VpnGateway' | 'ExpressRoute' )?

  @description('Optional. The hub virtual network connections and assocaited properties.')
  hubVirtualNetworkConnections: array?

  @description('Optional. The routing intent configuration to create for the virtual hub.')
  routingIntent: {
    privateToFirewall: bool?
    internetToFirewall: bool?
  }?

  @description('Optional. The preferred routing gateway types.')
  preferredRoutingGateway: ('VpnGateway' | 'ExpressRoute' | 'None' )?

  @description('Optional. VirtualHub route tables.')
  routeTableRoutes: array?

  @description('Optional. The Security Partner Provider resource ID.')
  securityPartnerProviderId: string?

  @description('Optional. The Security Provider name.')
  securityProviderName: string?

  @description('Optional. VirtualHub route tables.')
  virtualHubRouteTableV2s: array?

  @description('Optional. The virtual router ASN.')
  virtualRouterAsn: int?

  @description('Optional. The virtual router IPs.')
  virtualRouterIps: array?

  @description('Optional. The virtual network gateway configuration.')
  virtualNetworkGatewayConfig: virtualNetworkGatewayConfigType?

  @description('Optional. The DDoS protection plan resource ID.')
  ddosProtectionPlanSettings: ddosProtectionType?

  @description('Optional. The resource group name for private DNS zones.')
  privateDnsZonesResourceGroup: string?

  @description('Optional. Enable/Disable private DNS zones.')
  enablePrivateDnsZones: bool?

  @description('Optional. The array of private DNS zones to create. Default: All known Azure Private DNS Zones, baked into underlying AVM module see: https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/private-link-private-dns-zones#parameter-privatelinkprivatednszones')
  privateDnsZones: string[]?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?
}[]?

type peeringSettingsType = {
  @description('Optional. Allow forwarded traffic.')
  allowForwardedTraffic: bool?

  @description('Optional. Allow gateway transit.')
  allowGatewayTransit: bool?

  @description('Optional. Allow virtual network access.')
  allowVirtualNetworkAccess: bool?

  @description('Optional. Use remote gateways.')
  useRemoteGateways: bool?

  @description('Optional. Remote virtual network name.')
  remoteVirtualNetworkName: string?
}[]?

type azureFirewallType = {
  @description('Optional. Name of Azure Firewall.')
  name: string?

  @description('Optional. Hub IP addresses.')
  hubIpAddresses: object?

  @description('Optional. Switch to enable/disable AzureFirewall deployment for the hub.')
  enableAzureFirewall: bool

  @description('Optional. Pass an existing Azure Firewall resource ID to use instead of creating a new one.')
  azureFirewallResourceID: string?

  @description('Optional. Additional public IP configurations.')
  additionalPublicIpConfigurations: array?

  @description('Optional. Application rule collections.')
  applicationRuleCollections: array?

  @description('Optional. Azure Firewall SKU.')
  azureSkuTier: 'Basic' | 'Standard' | 'Premium'?

  @description('Optional. Diagnostic settings.')
  diagnosticSettings: diagnosticSettingType?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?

  @description('Optional. Firewall policy ID.')
  firewallPolicyId: string?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Management IP address configuration.')
  managementIPAddressObject: object?

  @description('Optional. Management IP resource ID.')
  managementIPResourceID: string?

  @description('Optional. NAT rule collections.')
  natRuleCollections: array?

  @description('Optional. Network rule collections.')
  networkRuleCollections: array?

  @description('Optional. Public IP address object.')
  publicIPAddressObject: object?

  @description('Optional. Public IP resource ID.')
  publicIPResourceID: string?

  @description('Optional. Role assignments.')
  roleAssignments: roleAssignmentType?

  @description('Optional. Threat Intel mode.')
  threatIntelMode: ('Alert' | 'Deny' | 'Off')?

  @description('Optional. Zones.')
  zones: int[]?

  @description('Optional. Enable/Disable dns proxy setting.')
  dnsProxyEnabled: bool?

  @description('Optional. Array of custom DNS servers used by Azure Firewall.')
  firewallDnsServers: array?
}?

type ddosProtectionType = {
  @description('Optional. Friendly logical name for this DDoS protection configuration instance.')
  name: string?

  @description('Optonal. Enable/Disable DDoS protection.')
  enableDDosProtection: bool?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?
}

type roleAssignmentType = {
  @description('Optional. The name (as GUID) of the role assignment. If not provided, a GUID will be generated.')
  name: string?

  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device')?

  @description('Optional. The description of the role assignment.')
  description: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container".')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}[]?

type diagnosticSettingType = {
  @description('Optional. The name of diagnostic setting.')
  name: string?

  @description('Optional. The name of logs that will be streamed. "allLogs" includes all possible logs for the resource. Set to `[]` to disable log collection.')
  logCategoriesAndGroups: {
    @description('Optional. Name of a Diagnostic Log category for a resource type this setting is applied to. Set the specific logs to collect here.')
    category: string?

    @description('Optional. Name of a Diagnostic Log category group for a resource type this setting is applied to. Set to `allLogs` to collect all logs.')
    categoryGroup: string?

    @description('Optional. Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('Optional. The name of metrics that will be streamed. "allMetrics" includes all possible metrics for the resource. Set to `[]` to disable metric collection.')
  metricCategories: {
    @description('Required. Name of a Diagnostic Metric category for a resource type this setting is applied to. Set to `AllMetrics` to collect all metrics.')
    category: string

    @description('Optional. Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('Optional. A string indicating whether the export to Log Analytics should use the default destination type, i.e. AzureDiagnostics, or use a destination type.')
  logAnalyticsDestinationType: ('Dedicated' | 'AzureDiagnostics')?

  @description('Optional. Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.value.')
  workspaceResourceId: string?

  @description('Optional. Resource ID of the diagnostic storage account. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.value.')
  storageAccountResourceId: string?

  @description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
  eventHubAuthorizationRuleResourceId: string?

  @description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.value.')
  eventHubName: string?

  @description('Optional. The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.')
  marketplacePartnerResourceId: string?
}[]?

type subnetOptionsType = ({
  @description('Name of subnet.')
  name: string

  @description('IP-address range for subnet.')
  addressPrefix: string

  @description('Id of Network Security Group to associate with subnet.')
  networkSecurityGroupId: string?

  @description('Id of Route Table to associate with subnet.')
  routeTable: string?

  @description('Name of the delegation to create for the subnet.')
  delegation: string?
})[]

type virtualNetworkGatewayConfigType = {
  @description('Optional. Name of the virtual network gateway.')
  name: string?

  @description('Optional. Enable/disable the virtual network gateway.')
  enableVirtualNetworkGateway: bool?

  @description('Optional. The gateway type. Set to Vpn or ExpressRoute.')
  gatewayType: 'Vpn' | 'ExpressRoute'?

  @description('Required. The SKU of the gateway.')
  skuName:
    | 'Basic'
    | 'VpnGw1AZ'
    | 'VpnGw2AZ'
    | 'VpnGw3AZ'
    | 'VpnGw4AZ'
    | 'VpnGw5AZ'
    | 'Standard'
    | 'HighPerformance'
    | 'UltraPerformance'
    | 'ErGw1AZ'
    | 'ErGw2AZ'
    | 'ErGw3AZ'

  @description('Required. VPN mode and BGP configuration.')
  vpnMode: 'activeActiveBgp' | 'activeActiveNoBgp' | 'activePassiveBgp' | 'activePassiveNoBgp'

  @description('Optional. The VPN type. Defaults to RouteBased if not specified.')
  vpnType: 'RouteBased' | 'PolicyBased'?

  @description('Optional. The gateway generation.')
  vpnGatewayGeneration: 'Generation1' | 'Generation2' | 'None'?

  @description('Optional. Enable/disable BGP route translation for NAT.')
  enableBgpRouteTranslationForNat: bool?

  @description('Optional. Enable/disable DNS forwarding.')
  enableDnsForwarding: bool?

  @description('Optional. ASN to use for BGP.')
  asn: int?

  @description('Optional. Custom BGP IP addresses (when BGP enabled modes are used).')
  customBgpIpAddresses: string[]?

  @description('Optional. Availability zones for public IPs.')
  publicIpZones: array?

  @description('Optional. Client root certificate data (Base64) for P2S.')
  clientRootCertData: string?

  @description('Optional. VPN client address pool CIDR prefix.')
  vpnClientAddressPoolPrefix: string?

  @description('Optional. Azure AD configuration for VPN client (OpenVPN).')
  vpnClientAadConfiguration: object?

  @description('Optional. Array of domain name labels for public IPs.')
  domainNameLabel: string[]?
}
