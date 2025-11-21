metadata name = 'ALZ Bicep'
metadata description = 'ALZ Bicep Module used to set up Azure Landing Zones'

targetScope = 'subscription'

//================================
// Parameters
//================================

// Resource Group Parameters
@description('Required. The name prefix for the Virtual WAN Resource Groups (will append location). Can be overridden by parVirtualWanResourceGroupNameOverrides.')
param parVirtualWanResourceGroupNamePrefix string

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of locations in parLocations.')
param parVirtualWanResourceGroupNameOverrides array = []

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

@description('Required. The name prefix for the DNS Resource Groups (will append location). Can be overridden by parDnsResourceGroupNameOverrides.')
param parDnsResourceGroupNamePrefix string

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of locations in parLocations.')
param parDnsResourceGroupNameOverrides array = []

@description('Required. The name prefix for the Private DNS Resolver Resource Groups (will append location). Can be overridden by parDnsPrivateResolverResourceGroupNameOverrides.')
param parDnsPrivateResolverResourceGroupNamePrefix string

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of locations in parLocations.')
param parDnsPrivateResolverResourceGroupNameOverrides array = []

// VWAN Parameters
@description('Optional. The virtual WAN settings to create.')
param vwan vwanNetworkType

@description('Optional. The virtual WAN hubs to create.')
param vwanHubs vwanHubType?

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

// General Parameters
@description('Required. The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@description('Optional. Tags to be applied to all resources.')
param parTags object = {}

@description('Optional. Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Variables
//========================================

// Compute actual resource group names (either from override arrays or generated from prefix + location)
var vwanResourceGroupNames = [for (location, i) in parLocations: empty(parVirtualWanResourceGroupNameOverrides) ? '${parVirtualWanResourceGroupNamePrefix}-${location}' : parVirtualWanResourceGroupNameOverrides[i]]
var dnsResourceGroupNames = [for (location, i) in parLocations: empty(parDnsResourceGroupNameOverrides) ? '${parDnsResourceGroupNamePrefix}-${location}' : parDnsResourceGroupNameOverrides[i]]
var dnsPrivateResolverResourceGroupNames = [for (location, i) in parLocations: empty(parDnsPrivateResolverResourceGroupNameOverrides) ? '${parDnsPrivateResolverResourceGroupNamePrefix}-${location}' : parDnsPrivateResolverResourceGroupNameOverrides[i]]

//========================================
// Resource Groups
//========================================

// Create resource groups for each location
module modVwanResourceGroups 'br/public:avm/res/resources/resource-group:0.4.2' = [
  for (location, i) in parLocations: {
    name: 'modVwanResourceGroup-${uniqueString(parVirtualWanResourceGroupNamePrefix, location)}'
    scope: subscription()
    params: {
      name: vwanResourceGroupNames[i]
      location: location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module modDnsResourceGroups 'br/public:avm/res/resources/resource-group:0.4.2' = [
  for (location, i) in parLocations: if (!empty(vwanHubs) && length(filter(vwanHubs!, hub => hub.location == location && hub.dnsSettings.enablePrivateDnsZones)) > 0) {
    name: 'modDnsResourceGroup-${uniqueString(parDnsResourceGroupNamePrefix, location)}'
    scope: subscription()
    params: {
      name: dnsResourceGroupNames[i]
      location: location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module modPrivateDnsResolverResourceGroups 'br/public:avm/res/resources/resource-group:0.4.2' = [
  for (location, i) in parLocations: if (!empty(vwanHubs) && length(filter(vwanHubs!, hub => hub.location == location && hub.dnsSettings.enableDnsPrivateResolver)) > 0) {
    name: 'modPrivateDnsResolverResourceGroup-${uniqueString(parDnsPrivateResolverResourceGroupNamePrefix, location)}'
    scope: subscription()
    params: {
      name: dnsPrivateResolverResourceGroupNames[i]
      location: location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//================================
// VWAN Resources
//================================

module resVirtualWan 'br/public:avm/res/network/virtual-wan:0.4.3' = {
  name: 'vwan-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwan.name)}'
  scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwan.location)])
  dependsOn: [
    modVwanResourceGroups
  ]
  params: {
    name: vwan.?name ?? 'vwan-alz-${parLocations[0]}'
    allowBranchToBranchTraffic: vwan.?allowBranchToBranchTraffic ?? true
    type: vwan.?type ?? 'Standard'
    roleAssignments: vwan.?roleAssignments
    location: vwan.location
    tags: parTags
    lock: parGlobalResourceLock ?? vwan.?lock
    enableTelemetry: parEnableTelemetry
  }
}

module resVirtualWanHub 'br/public:avm/res/network/virtual-hub:0.4.2' = [
  for (vwanHub, i) in vwanHubs!: {
    name: 'vwanHub-${i}-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwan.name)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
    ]
    params: {
      name: vwanHub.?hubName ?? 'vwanhub-alz-${vwanHub.location}'
      location: vwanHub.location
      addressPrefix: vwanHub.addressPrefix
      virtualWanResourceId: resVirtualWan.outputs.resourceId
      virtualRouterAutoScaleConfiguration: vwanHub.?virtualRouterAutoScaleConfiguration
      allowBranchToBranchTraffic: vwanHub.allowBranchToBranchTraffic
      azureFirewallResourceId: vwanHub.?azureFirewallSettings.?azureFirewallResourceID
      expressRouteGatewayResourceId: vwanHub.?expressRouteGatewayId
      vpnGatewayResourceId: vwanHub.?vpnGatewayId
      p2SVpnGatewayResourceId: vwanHub.?p2SVpnGatewayId
      hubRouteTables: vwanHub.?routeTableRoutes
      hubVirtualNetworkConnections: vwanHub.?hubVirtualNetworkConnections
      preferredRoutingGateway: vwanHub.?preferredRoutingGateway ?? 'None'
      routingIntent: vwanHub.?routingIntent
      routeTableRoutes: vwanHub.?routeTableRoutes
      securityProviderName: vwanHub.?securityProviderName
      securityPartnerProviderResourceId: vwanHub.?securityPartnerProviderId
      virtualHubRouteTableV2s: vwanHub.?virtualHubRouteTableV2s
      virtualRouterAsn: vwanHub.?virtualRouterAsn
      virtualRouterIps: vwanHub.?virtualRouterIps
      lock: parGlobalResourceLock ?? vwanHub.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resSidecarVirtualNetwork 'br/public:avm/res/network/virtual-network:0.7.1' = [
  for (vwanHub, i) in vwanHubs!: if (vwanHub.?sideCarVirtualNetwork.?sidecarVirtualNetworkEnabled ?? true) {
    name: 'sidecarVnet-${i}-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName, vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
    ]
    params: {
      name: vwanHub.sideCarVirtualNetwork.?name ?? 'vnet-sidecar-alz-${vwanHub.location}'
      location: vwanHub.?sideCarVirtualNetwork.?location ?? vwanHub.location
      addressPrefixes: vwanHub.sideCarVirtualNetwork.addressPrefixes ?? []
      flowTimeoutInMinutes: vwanHub.sideCarVirtualNetwork.?flowTimeoutInMinutes
      ipamPoolNumberOfIpAddresses: vwanHub.sideCarVirtualNetwork.?ipamPoolNumberOfIpAddresses
      lock: parGlobalResourceLock ?? vwanHub.sideCarVirtualNetwork.?lock
      subnets: vwanHub.sideCarVirtualNetwork.?subnets ?? [
        {
          name: 'DNSPrivateResolverInboundSubnet'
          addressPrefix: cidrSubnet(vwanHub.sideCarVirtualNetwork.addressPrefixes[0], 25, 0)
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        {
          name: 'DNSPrivateResolverOutboundSubnet'
          addressPrefix: length(vwanHub.sideCarVirtualNetwork.addressPrefixes) > 1 ? vwanHub.sideCarVirtualNetwork.addressPrefixes[1] : cidrSubnet(vwanHub.sideCarVirtualNetwork.addressPrefixes[0], 25, 1)
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      ]
      vnetEncryption: vwanHub.sideCarVirtualNetwork.?vnetEncryption
      vnetEncryptionEnforcement: vwanHub.sideCarVirtualNetwork.?vnetEncryptionEnforcement
      roleAssignments: vwanHub.sideCarVirtualNetwork.?roleAssignments
      virtualNetworkBgpCommunity: vwanHub.?sideCarVirtualNetwork.?virtualNetworkBgpCommunity
      diagnosticSettings: vwanHub.sideCarVirtualNetwork.?diagnosticSettings
      dnsServers: vwanHub.sideCarVirtualNetwork.?dnsServers
      enableVmProtection: vwanHub.sideCarVirtualNetwork.?enableVmProtection
      ddosProtectionPlanResourceId: resDdosProtectionPlan[i].?outputs.resourceId ?? null
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]


//=====================
// DNS
//=====================
module resPrivateDNSZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.0' = [
  for (vwanHub, i) in vwanHubs!: if (vwanHub.dnsSettings.enablePrivateDnsZones) {
    name: 'privateDnsZone-${vwanHub.hubName}-${uniqueString(parDnsResourceGroupNamePrefix,vwanHub.location)}'
    scope: resourceGroup(dnsResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modDnsResourceGroups
    ]
    params: {
      location: vwanHub.location
      privateLinkPrivateDnsZones: empty(vwanHub.?dnsSettings.?privateDnsZones) ? null : vwanHub.?dnsSettings.?privateDnsZones
      lock: parGlobalResourceLock ?? vwanHub.?dnsSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resDnsPrivateResolver 'br/public:avm/res/network/dns-resolver:0.5.5' = [
  for (vwanHub, i) in vwanHubs!: if (vwanHub.dnsSettings.enableDnsPrivateResolver) {
    name: 'dnsResolver-${vwanHub.hubName}-${uniqueString(parDnsPrivateResolverResourceGroupNamePrefix,vwanHub.location)}'
    scope: resourceGroup(dnsPrivateResolverResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      resSidecarVirtualNetwork[i]
      modPrivateDnsResolverResourceGroups
    ]
    params: {
      name: vwanHub.?dnsSettings.?privateDnsResolverName ?? 'dnspr-alz-${vwanHub.location}'
      location: vwanHub.location
      virtualNetworkResourceId: resSidecarVirtualNetwork[i]!.outputs.resourceId
      inboundEndpoints: vwanHub.?dnsSettings.?inboundEndpoints ?? [
        {
          name: 'pip-dnspr-inbound-alz-${vwanHub.location}'
          subnetResourceId: '${resSidecarVirtualNetwork[i]!.outputs.resourceId}/subnets/DNSPrivateResolverInboundSubnet'
        }
      ]
      outboundEndpoints: vwanHub.?dnsSettings.?outboundEndpoints ?? [
         {
          name: 'pip-dnspr-outbound-alz-${vwanHub.location}'
          subnetResourceId: '${resSidecarVirtualNetwork[i]!.outputs.resourceId}/subnets/DNSPrivateResolverOutboundSubnet'
        }
      ]
      lock: parGlobalResourceLock ?? vwanHub.?dnsSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Network security
//=====================
module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.2' = [
  for (vwanHub, i) in vwanHubs!: if (vwanHub.ddosProtectionPlanSettings.enableDdosProtection) {
    name: 'ddosPlan-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.?ddosProtectionPlanSettings.?name ?? '', vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
    ]
    params: {
      name: vwanHub.?ddosProtectionPlanSettings.?name ?? 'ddos-alz-${vwanHub.location}'
      location: vwanHub.location
      lock: parGlobalResourceLock ?? vwanHub.?ddosProtectionPlanSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resAzFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.3' = [
  for (vwanHub, i) in vwanHubs!: if (vwanHub.azureFirewallSettings.enableAzureFirewall && empty(vwanHub.?azureFirewallSettings.?firewallPolicyId)) {
    name: 'azFirewallPolicy-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName, vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
    ]
    params: {
      name: vwanHub.?azureFirewallSettings.?name ?? 'azfwpolicy-alz-${vwanHub.location}'
      threatIntelMode: vwanHub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
      location: vwanHub.location
      tier: vwanHub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      enableProxy: vwanHub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? false
        : vwanHub.?azureFirewallSettings.?dnsProxyEnabled
      servers: vwanHub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? null
        : vwanHub.?azureFirewallSettings.?firewallDnsServers
      lock: parGlobalResourceLock ?? vwanHub.?azureFirewallSettings.?lock
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
  kind: ('CanNotDelete' | 'ReadOnly' | 'None' | null)

  @description('Optional. Notes about this lock.')
  notes: string?
}

type vwanNetworkType = {
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

type sideCarVirtualNetworkType = {
  @description('Optional. The name of the sidecar virtual network to create.')
  name: string?

  @description('Required. Enable/Disable the sidecar virtual network deployment.')
  sidecarVirtualNetworkEnabled: bool

  @description('Required. The address space of the sidecar virtual network.')
  addressPrefixes: string[]

  @description('Optional. The location of the sidecar virtual network. Defaults to the Virtual WAN hub location.')
  location: string?

  @description('Optional. Resource ID of an existing Virtual WAN hub to associate with the sidecar virtual network.')
  virtualHubIdOverride: string?

  @description('Optional. Flow timeout in minutes for the sidecar virtual network.')
  flowTimeoutInMinutes: int?

  @description('Optional. Number of IP addresses allocated from the pool. To be used only when the addressPrefix param is defined with a resource ID of an IPAM pool.')
  ipamPoolNumberOfIpAddresses: string?

  @description('Optional. Resource lock configuration for the sidecar virtual network.')
  lock: lockType?

  @description('Optional. Virtual network peerings in addition to the primary VWAN Hub peering connection.')
  vnetPeerings: array?

  @description('Optional. Subnets for the sidecar virtual network.')
  subnets: array?

  @description('Optional. Enable/Disable VNet encryption for the sidecar virtual network.')
  vnetEncryption: bool?

  @description('Optional. Whether the encrypted VNet allows VM that does not support encryption. Can only be used when vnetEncryption is enabled.')
  vnetEncryptionEnforcement: 'AllowUnencrypted' | 'DropUnencrypted'?

  @description('Optional. Role assignments for the sidecar virtual network.')
  roleAssignments: array?

  @description('Optional. BGP community for the sidecar virtual network.')
  virtualNetworkBgpCommunity: string?

  @description('Optional. Diagnostic settings for the sidecar virtual network.')
  diagnosticSettings: array?

  @description('Optional. DNS servers for the sidecar virtual network.')
  dnsServers: array?

  @description('Optional. Enable VM protection for the virtual network.')
  enableVmProtection: bool?

  @description('Optional. DDoS protection plan resource ID.')
  ddosProtectionPlanResourceIdOverride: string?
}

type vwanHubType = {
  @description('Required. The name of the Virtual WAN hub.')
  hubName: string

  @description('Required. The location of the Virtual WAN hub.')
  location: string

  @description('Required. The address prefix for the Virtual WAN hub.')
  addressPrefix: string

  @description('Optional. The virtual router auto scale configuration.')
  virtualRouterAutoScaleConfiguration: {
    minInstances: int
  }?

  @description('Required. Enable/Disable branch-to-branch traffic for the Virtual WAN hub.')
  allowBranchToBranchTraffic: bool

  @description('Required. Azure Firewall configuration settings.')
  azureFirewallSettings: azureFirewallType

  @description('Optional. Resource ID of an existing Express Route Gateway to associate with the Virtual WAN hub.')
  expressRouteGatewayId: string?

  @description('Optional. Resource ID of an existing VPN Gateway to associate with the Virtual WAN hub.')
  vpnGatewayId: string?

  @description('Optional. Resource ID of an existing Point-to-Site VPN Gateway to associate with the Virtual WAN hub.')
  p2SVpnGatewayId: string?

  @description('Optional. The hub virtual network connections and associated properties.')
  hubVirtualNetworkConnections: array?

  @description('Optional. The routing intent configuration to create for the Virtual WAN hub.')
  routingIntent: {
    privateToFirewall: bool?
    internetToFirewall: bool?
  }?

  @description('Optional. The preferred routing gateway types.')
  preferredRoutingGateway: ('VpnGateway' | 'ExpressRoute' | 'None')?

  @description('Optional. Virtual WAN hub route tables.')
  routeTableRoutes: array?

  @description('Optional. Resource ID of an existing Security Partner Provider to associate with the Virtual WAN hub.')
  securityPartnerProviderId: string?

  @description('Optional. The Security Provider name.')
  securityProviderName: string?

  @description('Optional. Virtual WAN hub route tables V2 configuration.')
  virtualHubRouteTableV2s: array?

  @description('Optional. The virtual router Autonomous System Number (ASN).')
  virtualRouterAsn: int?

  @description('Optional. The virtual router IP addresses.')
  virtualRouterIps: array?

  @description('Required. Virtual network gateway configuration settings.')
  virtualNetworkGatewaySettings: virtualNetworkGatewaySettingsType

  @description('Required. DDoS protection plan configuration settings.')
  ddosProtectionPlanSettings: ddosProtectionType

  @description('Required. DNS configuration settings including private DNS zones and resolver.')
  dnsSettings: dnsSettingsType

  @description('Optional. Sidecar virtual network configuration.')
  sideCarVirtualNetwork: sideCarVirtualNetworkType

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
  @description('Required. Enable/Disable Azure Firewall deployment for the Virtual WAN hub.')
  enableAzureFirewall: bool

  @description('Optional. The name of the Azure Firewall to create.')
  name: string?

  @description('Optional. Hub IP addresses configuration.')
  hubIpAddresses: object?

  @description('Optional. Resource ID of an existing Azure Firewall to associate with the Virtual WAN hub instead of creating a new one.')
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

  @description('Optional. Resource ID of an existing Azure Firewall Policy to associate with the firewall. If not specified and enableAzureFirewall is true, a new firewall policy will be created.')
  firewallPolicyId: string?

  @description('Optional. Lock settings for Azure Firewall.')
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
}

type ddosProtectionType = {
  @description('Required. Enable/Disable DDoS protection.')
  enableDdosProtection: bool

  @description('Optional. Friendly logical name for this DDoS protection configuration instance.')
  name: string?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?
}

type dnsSettingsType = {
  @description('Required. Enable/Disable Private DNS zones deployment.')
  enablePrivateDnsZones: bool

  @description('Optional. The resource group name for private DNS zones.')
  privateDnsZonesResourceGroup: string?

  @description('Optional. Array of resource IDs of existing virtual networks to link to the Private DNS Zones. The sidecar virtual network is automatically included.')
  virtualNetworkResourceIdsToLinkTo: array?

  @description('Optional. Array of DNS Zones to provision and link to sidecar Virtual Network. Default: All known Azure Private DNS Zones, baked into underlying AVM module see: https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/private-link-private-dns-zones#parameter-privatelinkprivatednszones')
  privateDnsZones: array?

  @description('Optional. Resource ID of an existing failover virtual network for Private DNS Zone VNet failover links.')
  virtualNetworkIdToLinkFailover: string?

  @description('Required. Enable/Disable Private DNS Resolver deployment.')
  enableDnsPrivateResolver: bool

  @description('Optional. The name of the Private DNS Resolver.')
  privateDnsResolverName: string?

  @description('Optional. Private DNS Resolver inbound endpoints configuration.')
  inboundEndpoints: array?

  @description('Optional. Private DNS Resolver outbound endpoints configuration.')
  outboundEndpoints: array?

  @description('Optional. The location of the Private DNS Resolver. Defaults to the location of the resource group.')
  location: string?

  @description('Optional. Lock settings for Private DNS resources.')
  lock: lockType?

  @description('Optional. Tags of the Private DNS resources.')
  tags: object?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?

  @description('Optional. Diagnostic settings for Private DNS resources.')
  diagnosticSettings: diagnosticSettingType?

  @description('Optional. Role assignments for Private DNS resources.')
  roleAssignments: roleAssignmentType?
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

  @description('Optional. Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event vwanHub.value.')
  workspaceResourceId: string?

  @description('Optional. Resource ID of the diagnostic storage account. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event vwanHub.value.')
  storageAccountResourceId: string?

  @description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
  eventHubAuthorizationRuleResourceId: string?

  @description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event vwanHub.value.')
  eventHubName: string?

  @description('Optional. The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.')
  marketplacePartnerResourceId: string?
}[]?

type subnetOptionsType = ({
  @description('Required. Name of subnet.')
  name: string

  @description('Required. IP-address range for subnet.')
  addressPrefix: string

  @description('Optional. Id of Network Security Group to associate with subnet.')
  networkSecurityGroupId: string?

  @description('Optional. Id of Route Table to associate with subnet.')
  routeTable: string?

  @description('Optional. Name of the delegation to create for the subnet.')
  delegation: string?
})[]

type virtualNetworkGatewaySettingsType = {
  @description('Required. Enable/Disable virtual network gateway deployment.')
  enableVirtualNetworkGateway: bool

  @description('Optional. Name of the virtual network gateway.')
  name: string?

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
