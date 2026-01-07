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
param vwanHubs vwanHubType[]?

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

var vwanResourceGroupNames = [for (location, i) in parLocations: empty(parVirtualWanResourceGroupNameOverrides) ? '${parVirtualWanResourceGroupNamePrefix}-${location}' : parVirtualWanResourceGroupNameOverrides[i]]
var dnsResourceGroupNames = [for (location, i) in parLocations: empty(parDnsResourceGroupNameOverrides) ? '${parDnsResourceGroupNamePrefix}-${location}' : parDnsResourceGroupNameOverrides[i]]
var dnsPrivateResolverResourceGroupNames = [for (location, i) in parLocations: empty(parDnsPrivateResolverResourceGroupNameOverrides) ? '${parDnsPrivateResolverResourceGroupNamePrefix}-${location}' : parDnsPrivateResolverResourceGroupNameOverrides[i]]
var publicIpRecommendedZones = [for hub in (vwanHubs ?? []): map(pickZones('Microsoft.Network', 'publicIPAddresses', hub.location, 3), zone => int(zone))]
var vwanBastionRecommendedZones = [for hub in (vwanHubs ?? []): map(pickZones('Microsoft.Network', 'bastionHosts', hub.location, 3), zone => int(zone))]
var dnsResolverInboundIpAddresses = [for (vwanHub, i) in (vwanHubs ?? []): (vwanHub.dnsSettings.deployDnsPrivateResolver && vwanHub.dnsSettings.deployPrivateDnsZones) ? cidrHost(cidrSubnet(vwanHub.sideCarVirtualNetwork.addressPrefixes[0], 28, 0), 4) : '']

//========================================
// Resource Groups
//========================================
module modVwanResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
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

module modDnsResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (location, i) in parLocations: if (!empty(vwanHubs) && length(filter((vwanHubs ?? []), hub => hub.location == location && hub.dnsSettings.deployPrivateDnsZones)) > 0) {
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

module modPrivateDnsResolverResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (location, i) in parLocations: if (!empty(vwanHubs) && length(filter((vwanHubs ?? []), hub => hub.location == location && hub.dnsSettings.deployDnsPrivateResolver)) > 0) {
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
    tags: vwan.?tags ?? parTags
    lock: vwan.?lock ?? parGlobalResourceLock
    enableTelemetry: parEnableTelemetry
  }
}

module resVirtualWanHub 'br/public:avm/res/network/virtual-hub:0.4.3' = [
  for (vwanHub, i) in (vwanHubs ?? []): {
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
      sku: vwanHub.?sku
      virtualRouterAutoScaleConfiguration: vwanHub.?virtualRouterAutoScaleConfiguration ?? { minCount: 2 }
      allowBranchToBranchTraffic: vwanHub.?allowBranchToBranchTraffic ?? true
      azureFirewallResourceId: !empty(vwanHub.?azureFirewallSettings.?azureFirewallResourceID) ? vwanHub!.azureFirewallSettings!.azureFirewallResourceID : null
      expressRouteGatewayResourceId: !empty(vwanHub.expressRouteGatewaySettings.?existingExpressRouteGatewayResourceId) ? vwanHub.expressRouteGatewaySettings!.existingExpressRouteGatewayResourceId : null
      vpnGatewayResourceId: !empty(vwanHub.s2sVpnGatewaySettings.?existingS2sVpnGatewayResourceId) ? vwanHub.s2sVpnGatewaySettings!.existingS2sVpnGatewayResourceId : null
      p2SVpnGatewayResourceId: !empty(vwanHub.p2sVpnGatewaySettings.?existingP2sVpnGatewayResourceId) ? vwanHub.p2sVpnGatewaySettings!.existingP2sVpnGatewayResourceId : null
      hubRouteTables: vwanHub.?routeTableRoutes
      hubVirtualNetworkConnections: vwanHub.?hubVirtualNetworkConnections
      preferredRoutingGateway: vwanHub.?preferredRoutingGateway ?? 'ExpressRoute'
      hubRoutingPreference: vwanHub.?hubRoutingPreference ?? 'ExpressRoute'
      routingIntent: vwanHub.?routingIntent
      routeTableRoutes: vwanHub.?routeTableRoutes
      securityProviderName: vwanHub.?securityProviderName
      securityPartnerProviderResourceId: vwanHub.?securityPartnerProviderId
      virtualHubRouteTableV2s: vwanHub.?virtualHubRouteTableV2s
      virtualRouterAsn: vwanHub.?virtualRouterAsn
      virtualRouterIps: vwanHub.?virtualRouterIps
      lock: vwanHub.?lock ?? parGlobalResourceLock
      tags: vwanHub.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// ExpressRoute Gateways
//=====================
module resExpressRouteGateway 'br/public:avm/res/network/express-route-gateway:0.8.0' = [
  for (vwanHub, i) in (vwanHubs ?? []): if ((vwanHub.expressRouteGatewaySettings.?deployExpressRouteGateway ?? false) && empty(vwanHub.expressRouteGatewaySettings.?existingExpressRouteGatewayResourceId)) {
    name: 'ergw-${i}-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
      resVirtualWanHub
    ]
    params: {
      name: vwanHub.expressRouteGatewaySettings.?name ?? 'ergw-${vwanHub.hubName}'
      location: vwanHub.location
      virtualHubResourceId: resVirtualWanHub[i].outputs.resourceId
      allowNonVirtualWanTraffic: vwanHub.expressRouteGatewaySettings.?allowNonVirtualWanTraffic ?? false
      autoScaleConfigurationBoundsMin: vwanHub.expressRouteGatewaySettings.?minScaleUnits ?? 1
      autoScaleConfigurationBoundsMax: vwanHub.expressRouteGatewaySettings.?maxScaleUnits ?? 1
      lock: vwanHub.expressRouteGatewaySettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.expressRouteGatewaySettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// S2S VPN Gateways
//=====================
module resS2sVpnGateway 'br/public:avm/res/network/vpn-gateway:0.2.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if ((vwanHub.s2sVpnGatewaySettings.?deployS2sVpnGateway ?? false) && empty(vwanHub.s2sVpnGatewaySettings.?existingS2sVpnGatewayResourceId)) {
    name: 'vpnGateway-${i}-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
      resVirtualWanHub
    ]
    params: {
      name: vwanHub.s2sVpnGatewaySettings.?name ?? 'vpngw-${vwanHub.hubName}'
      location: vwanHub.location
      virtualHubResourceId: resVirtualWanHub[i].outputs.resourceId
      bgpSettings: vwanHub.s2sVpnGatewaySettings.?bgpSettings != null ? {
        asn: vwanHub.s2sVpnGatewaySettings.bgpSettings!.asn
        peerWeight: vwanHub.s2sVpnGatewaySettings.bgpSettings!.peerWeight
        bgpPeeringAddresses: union(
          vwanHub.s2sVpnGatewaySettings.bgpSettings!.?instance0BgpPeeringAddress != null ? [
            {
              customBgpIpAddresses: vwanHub.s2sVpnGatewaySettings.bgpSettings!.instance0BgpPeeringAddress!.customIps
            }
          ] : [],
          vwanHub.s2sVpnGatewaySettings.bgpSettings!.?instance1BgpPeeringAddress != null ? [
            {
              customBgpIpAddresses: vwanHub.s2sVpnGatewaySettings.bgpSettings!.instance1BgpPeeringAddress!.customIps
            }
          ] : []
        )
      } : null
      vpnGatewayScaleUnit: vwanHub.s2sVpnGatewaySettings.?scaleUnit ?? 1
      enableBgpRouteTranslationForNat: vwanHub.s2sVpnGatewaySettings.?bgpRouteTranslationForNatEnabled ?? false
      isRoutingPreferenceInternet: (vwanHub.s2sVpnGatewaySettings.?routingPreference ?? 'ExpressRoute') == 'Internet'
      natRules: []
      vpnConnections: []
      lock: vwanHub.s2sVpnGatewaySettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.s2sVpnGatewaySettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// P2S VPN Server Configurations
//=====================
module resVpnServerConfigurations 'br/public:avm/res/network/vpn-server-configuration:0.1.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.p2sVpnGatewaySettings.?deployP2sVpnGateway ?? false) {
    name: 'vpnServerConfig-${i}-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
    ]
    params: {
      name: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?name ?? 'vpnservercfg-${vwanHub.hubName}'
      location: vwanHub.location
      vpnAuthenticationTypes: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.vpnAuthenticationTypes
      vpnProtocols: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?vpnProtocols ?? ['IkeV2', 'OpenVPN']
      aadAudience: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?aadAuthenticationParameters.?aadAudience
      aadIssuer: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?aadAuthenticationParameters.?aadIssuer
      aadTenant: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?aadAuthenticationParameters.?aadTenant
      radiusServers: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?radiusServers
      vpnClientRootCertificates: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?vpnClientRootCertificates
      vpnClientRevokedCertificates: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?vpnClientRevokedCertificates
      lock: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?lock ?? parGlobalResourceLock
      tags: vwanHub.p2sVpnGatewaySettings.vpnServerConfiguration.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// P2S VPN Gateways
//=====================
module resP2sVpnGateway 'br/public:avm/res/network/p2s-vpn-gateway:0.1.3' = [
  for (vwanHub, i) in (vwanHubs ?? []): if ((vwanHub.p2sVpnGatewaySettings.?deployP2sVpnGateway ?? false) && empty(vwanHub.p2sVpnGatewaySettings.?existingP2sVpnGatewayResourceId)) {
    name: 'p2sVpnGateway-${i}-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
      resVirtualWanHub
      resVpnServerConfigurations
    ]
    params: {
      name: vwanHub.p2sVpnGatewaySettings.?name ?? 'p2svpngw-${vwanHub.hubName}'
      location: vwanHub.location
      virtualHubResourceId: resVirtualWanHub[i].outputs.resourceId
      vpnServerConfigurationResourceId: resVpnServerConfigurations[i]!.outputs.resourceId
      p2SConnectionConfigurationsName: 'P2SConnectionConfig'
      vpnClientAddressPoolAddressPrefixes: vwanHub.p2sVpnGatewaySettings.?vpnClientAddressPool.addressPrefixes ?? null
      enableInternetSecurity: vwanHub.p2sVpnGatewaySettings.?enableInternetSecurity ?? true
      customDnsServers: vwanHub.p2sVpnGatewaySettings.?dnsServers ?? []
      vpnGatewayScaleUnit: vwanHub.p2sVpnGatewaySettings.?scaleUnit ?? 1
      isRoutingPreferenceInternet: false
      lock: vwanHub.p2sVpnGatewaySettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.p2sVpnGatewaySettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resSidecarVirtualNetwork 'br/public:avm/res/network/virtual-network:0.7.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.?sideCarVirtualNetwork.?sidecarVirtualNetworkEnabled ?? true) {
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
      lock: vwanHub.sideCarVirtualNetwork.?lock ?? parGlobalResourceLock
      subnets: vwanHub.sideCarVirtualNetwork.?subnets ?? union(
        [
          {
            name: 'DNSPrivateResolverInboundSubnet'
            addressPrefix: cidrSubnet(vwanHub.sideCarVirtualNetwork.addressPrefixes[0], 28, 0)
            privateEndpointNetworkPolicies: 'Enabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
            defaultOutboundAccess: false
          }
          {
            name: 'DNSPrivateResolverOutboundSubnet'
            addressPrefix: length(vwanHub.sideCarVirtualNetwork.addressPrefixes) > 1 ? vwanHub.sideCarVirtualNetwork.addressPrefixes[1] : cidrSubnet(vwanHub.sideCarVirtualNetwork.addressPrefixes[0], 28, 1)
            privateEndpointNetworkPolicies: 'Enabled'
            privateLinkServiceNetworkPolicies: 'Enabled'
            defaultOutboundAccess: false
          }
        ],
        vwanHub.bastionSettings.deployBastion ? [
          {
            name: 'AzureBastionSubnet'
            addressPrefix: vwanHub.bastionSettings.?subnetAddressPrefix ?? cidrSubnet(vwanHub.sideCarVirtualNetwork.addressPrefixes[0], 26, 2)
            defaultOutboundAccess: vwanHub.bastionSettings.?subnetDefaultOutboundAccessEnabled ?? false
          }
        ] : []
      )
      vnetEncryption: vwanHub.?sideCarVirtualNetwork.?vnetEncryption
      vnetEncryptionEnforcement: vwanHub.?sideCarVirtualNetwork.?vnetEncryptionEnforcement
      roleAssignments: vwanHub.?sideCarVirtualNetwork.?roleAssignments
      virtualNetworkBgpCommunity: vwanHub.?sideCarVirtualNetwork.?virtualNetworkBgpCommunity
      diagnosticSettings: vwanHub.?sideCarVirtualNetwork.?diagnosticSettings
      dnsServers: vwanHub.?sideCarVirtualNetwork.?dnsServers
      enableVmProtection: vwanHub.?sideCarVirtualNetwork.?enableVmProtection
      ddosProtectionPlanResourceId: vwanHub.?sideCarVirtualNetwork.?ddosProtectionPlanResourceIdOverride ?? (vwanHub.ddosProtectionPlanSettings.deployDdosProtectionPlan ? resDdosProtectionPlan[i].?outputs.resourceId : vwanHubs[0].ddosProtectionPlanSettings.deployDdosProtectionPlan ? resDdosProtectionPlan[0].?outputs.resourceId : null)
      tags: vwanHub.?sideCarVirtualNetwork.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]


//=====================
// DNS
//=====================
module resPrivateDNSZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.dnsSettings.deployPrivateDnsZones) {
    name: 'privateDnsZone-${vwanHub.hubName}-${uniqueString(parDnsResourceGroupNamePrefix,vwanHub.location)}'
    scope: resourceGroup(dnsResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modDnsResourceGroups
    ]
    params: {
      location: vwanHub.location
      privateLinkPrivateDnsZones: empty(vwanHub.?dnsSettings.?privateDnsZones) ? null : vwanHub.?dnsSettings.?privateDnsZones
      additionalPrivateLinkPrivateDnsZonesToInclude: vwanHub.?dnsSettings.?additionalPrivateLinkPrivateDnsZonesToInclude ?? []
      privateLinkPrivateDnsZonesToExclude: vwanHub.?dnsSettings.?privateLinkPrivateDnsZonesToExclude ?? []
      lock: vwanHub.?dnsSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.?dnsSettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resDnsPrivateResolver 'br/public:avm/res/network/dns-resolver:0.5.6' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.dnsSettings.deployDnsPrivateResolver) {
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
          name: 'dnspr-inbound-${vwanHub.location}'
          subnetResourceId: '${resSidecarVirtualNetwork[i]!.outputs.resourceId}/subnets/DNSPrivateResolverInboundSubnet'
          privateIpAddress: dnsResolverInboundIpAddresses[i]
          privateIpAllocationMethod: 'Static'
        }
      ]
      outboundEndpoints: vwanHub.?dnsSettings.?outboundEndpoints ?? [
         {
          name: 'dnspr-outbound-${vwanHub.location}'
          subnetResourceId: '${resSidecarVirtualNetwork[i]!.outputs.resourceId}/subnets/DNSPrivateResolverOutboundSubnet'
        }
      ]
      lock: vwanHub.?dnsSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.?dnsSettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Network security
//=====================
module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.ddosProtectionPlanSettings.deployDdosProtectionPlan) {
    name: 'ddosPlan-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.?ddosProtectionPlanSettings.?name ?? '', vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
    ]
    params: {
      name: vwanHub.?ddosProtectionPlanSettings.?name ?? 'ddos-alz-${vwanHub.location}'
      location: vwanHub.location
      lock: vwanHub.?ddosProtectionPlanSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.?ddosProtectionPlanSettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resAzFirewall 'br/public:avm/res/network/azure-firewall:0.9.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.azureFirewallSettings.deployAzureFirewall && empty(vwanHub.?azureFirewallSettings.?azureFirewallResourceID)) {
    name: 'azFirewall-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName, vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
      resAzFirewallPolicy
    ]
    params: {
      name: vwanHub.?azureFirewallSettings.?name ?? 'afw-alz-${vwanHub.location}'
      location: vwanHub.location
      azureSkuTier: vwanHub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      virtualHubResourceId: resVirtualWanHub[i].outputs.resourceId
      firewallPolicyId: !empty(vwanHub.?azureFirewallSettings.?firewallPolicyId) ? vwanHub!.azureFirewallSettings!.firewallPolicyId : resAzFirewallPolicy[i].?outputs.resourceId
      hubIPAddresses: {
        publicIPs: {
          count: vwanHub.?azureFirewallSettings.?publicIPCount ?? 1
        }
      }
      availabilityZones: vwanHub.?azureFirewallSettings.?zones ?? []
      threatIntelMode: vwanHub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
      lock: vwanHub.?azureFirewallSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.?azureFirewallSettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resAzFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.4' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.azureFirewallSettings.deployAzureFirewall) {
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
        : (vwanHub.dnsSettings.deployDnsPrivateResolver && vwanHub.dnsSettings.deployPrivateDnsZones && vwanHub.azureFirewallSettings.deployAzureFirewall)
          ? true
          : (vwanHub.?azureFirewallSettings.?dnsProxyEnabled ?? false)
      servers: (vwanHub.dnsSettings.deployDnsPrivateResolver && vwanHub.dnsSettings.deployPrivateDnsZones && vwanHub.azureFirewallSettings.deployAzureFirewall)
        ? [dnsResolverInboundIpAddresses[i]]
        : (vwanHub.?azureFirewallSettings.?azureSkuTier == 'Basic' ? null : vwanHub.?azureFirewallSettings.?firewallDnsServers)
      lock: vwanHub.?azureFirewallSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.?azureFirewallSettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Azure Bastion
//=====================
module resBastionPublicIp 'br/public:avm/res/network/public-ip-address:0.10.0' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.bastionSettings.deployBastion && (vwanHub.sideCarVirtualNetwork.?sidecarVirtualNetworkEnabled ?? true)) {
    name: 'bastionPip-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName, vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      modVwanResourceGroups
      resSidecarVirtualNetwork[i]
    ]
    params: {
      name: vwanHub.bastionSettings.?bastionPublicIp.?name ?? 'pip-bas-${vwanHub.location}'
      location: vwanHub.location
      skuName: vwanHub.bastionSettings.?bastionPublicIp.?sku ?? 'Standard'
      skuTier: vwanHub.bastionSettings.?bastionPublicIp.?skuTier ?? 'Regional'
      publicIPAllocationMethod: vwanHub.bastionSettings.?bastionPublicIp.?allocationMethod ?? 'Static'
      idleTimeoutInMinutes: vwanHub.bastionSettings.?bastionPublicIp.?idleTimeoutInMinutes ?? 4
      availabilityZones: vwanHub.bastionSettings.?bastionPublicIp.?zones ?? vwanHub.bastionSettings.?zones ?? publicIpRecommendedZones[i]
      lock: vwanHub.bastionSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.bastionSettings.?bastionPublicIp.?tags ?? vwanHub.bastionSettings.?tags ?? parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resBastion 'br/public:avm/res/network/bastion-host:0.8.2' = [
  for (vwanHub, i) in (vwanHubs ?? []): if (vwanHub.bastionSettings.deployBastion && (vwanHub.sideCarVirtualNetwork.?sidecarVirtualNetworkEnabled ?? true)) {
    name: 'bastion-${uniqueString(parVirtualWanResourceGroupNamePrefix, vwanHub.hubName, vwanHub.location)}'
    scope: resourceGroup(vwanResourceGroupNames[indexOf(parLocations, vwanHub.location)])
    dependsOn: [
      resSidecarVirtualNetwork[i]
      resBastionPublicIp[i]
    ]
    params: {
      name: vwanHub.bastionSettings.?name ?? 'bas-${vwanHub.location}'
      location: vwanHub.location
      virtualNetworkResourceId: resSidecarVirtualNetwork[i]!.outputs.resourceId
      skuName: vwanHub.bastionSettings.?sku ?? 'Standard'
      scaleUnits: vwanHub.bastionSettings.?scaleUnits ?? 2
      bastionSubnetPublicIpResourceId: resBastionPublicIp[i]!.outputs.resourceId
      availabilityZones: vwanHub.bastionSettings.?zones ?? vwanHub.bastionSettings.?bastionPublicIp.?zones ?? vwanBastionRecommendedZones[i]
      disableCopyPaste: !(vwanHub.bastionSettings.?copyPasteEnabled ?? false)
      enableFileCopy: vwanHub.bastionSettings.?fileCopyEnabled ?? false
      enableIpConnect: vwanHub.bastionSettings.?ipConnectEnabled ?? false
      enableKerberos: vwanHub.bastionSettings.?kerberosEnabled ?? false
      enableShareableLink: vwanHub.bastionSettings.?shareableLinkEnabled ?? false
      lock: vwanHub.bastionSettings.?lock ?? parGlobalResourceLock
      tags: vwanHub.bastionSettings.?tags ?? parTags
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

  @description('Optional. The type of the virtual WAN.')
  type: 'Basic' | 'Standard'?

  @description('Optional. Tags for the virtual WAN.')
  tags: object?
}

type sideCarVirtualNetworkType = {
  @description('Optional. The name of the sidecar virtual network to create.')
  name: string?

  @description('Required. Enable/Disable the sidecar virtual network deployment.')
  sidecarVirtualNetworkEnabled: bool

  @description('Required. The address space of the sidecar virtual network.')
  addressPrefixes: string[]

  @description('Optional. Flow timeout in minutes for the sidecar virtual network.')
  flowTimeoutInMinutes: int?

  @description('Optional. Number of IP addresses allocated from the pool. To be used only when the addressPrefix param is defined with a resource ID of an IPAM pool.')
  ipamPoolNumberOfIpAddresses: string?

  @description('Optional. Resource lock configuration for the sidecar virtual network.')
  lock: lockType?

  @description('Optional. Subnets for the sidecar virtual network.')
  subnets: array?

  @description('Optional. Tags for the sidecar virtual network.')
  tags: object?
}

type vwanHubType = {
  @description('Required. The name of the Virtual WAN hub.')
  hubName: string

  @description('Required. The location of the Virtual WAN hub.')
  location: string

  @description('Required. The address prefix for the Virtual WAN hub.')
  addressPrefix: string

  @description('Optional. The SKU of the Virtual Hub. Possible values are Basic, Standard. Default null (Standard behavior).')
  sku: ('Basic' | 'Standard')?

  @description('Optional. The virtual router auto scale configuration. Minimum capacity defaults to 2.')
  virtualRouterAutoScaleConfiguration: {
    minCount: int
  }?

  @description('Optional. Enable/Disable branch-to-branch traffic for the Virtual WAN hub. Default true.')
  allowBranchToBranchTraffic: bool?

  @description('Optional. The hub routing preference. Possible values are ExpressRoute, VpnGateway, ASPath. Default ExpressRoute.')
  hubRoutingPreference: ('ExpressRoute' | 'VpnGateway' | 'ASPath')?

  @description('Required. Azure Firewall configuration settings.')
  azureFirewallSettings: azureFirewallType

  @description('Optional. Resource ID of an existing Express Route Gateway to associate with the Virtual WAN hub.')
  expressRouteGatewayId: string?

  @description('Optional. Resource ID of an existing VPN Gateway to associate with the Virtual WAN hub.')
  vpnGatewayId: string?

  @description('Optional. Resource ID of an existing Point-to-Site VPN Gateway to associate with the Virtual WAN hub.')
  p2SVpnGatewayId: string?

  @description('Required. Site-to-Site VPN gateway configuration to deploy for this hub.')
  s2sVpnGatewaySettings: s2sVpnGatewayType

  @description('Optional. VPN sites configuration to deploy for this hub.')
  vpnSites: vpnSiteType[]?

  @description('Required. Point-to-Site VPN gateway configuration to deploy for this hub.')
  p2sVpnGatewaySettings: p2sVpnGatewayType

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

  @description('Required. ExpressRoute Gateway configuration to deploy for this hub.')
  expressRouteGatewaySettings: expressRouteGatewaySettingsType

  @description('Required. DDoS protection plan configuration settings.')
  ddosProtectionPlanSettings: ddosProtectionType

  @description('Required. DNS configuration settings including private DNS zones and resolver.')
  dnsSettings: dnsSettingsType

  @description('Required. Azure Bastion configuration settings for the sidecar virtual network.')
  bastionSettings: bastionType

  @description('Required. Sidecar virtual network configuration.')
  sideCarVirtualNetwork: sideCarVirtualNetworkType

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Tags for the Virtual WAN hub.')
  tags: object?
}

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
  @description('Required. Deploy Azure Firewall for the Virtual WAN hub.')
  deployAzureFirewall: bool

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

  @description('Optional. Resource ID of an existing Azure Firewall Policy to associate with the firewall. If not specified and deployAzureFirewall is true, a new firewall policy will be created.')
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

  @description('Optional. Tags for Azure Firewall.')
  tags: object?
}

type ddosProtectionType = {
  @description('Required. Deploy a DDoS protection plan in the same region as the virtual network. Typically only needed in the primary region (the 1st declared in `hubNetworks`).')
  deployDdosProtectionPlan: bool

  @description('Optional. Friendly logical name for this DDoS protection configuration instance.')
  name: string?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Tags of the resource.')
  tags: object?
}

type bastionType = {
  @description('Required. Deploy Azure Bastion for the sidecar virtual network.')
  deployBastion: bool

  @description('Optional. The IPv4 address prefix to use for the Azure Bastion subnet in CIDR format. Defaults to auto-calculated /26.')
  subnetAddressPrefix: string?

  @description('Optional. Should the default outbound access be enabled for the Azure Bastion subnet? Default false.')
  subnetDefaultOutboundAccessEnabled: bool?

  @description('Optional. The name of the Azure Bastion resource.')
  name: string?

  @description('Optional. Should copy-paste be enabled for Azure Bastion? Default false.')
  copyPasteEnabled: bool?

  @description('Optional. Should file copy be enabled for Azure Bastion? Requires Standard SKU. Default false.')
  fileCopyEnabled: bool?

  @description('Optional. Should IP connect be enabled for Azure Bastion? Requires Standard SKU. Default false.')
  ipConnectEnabled: bool?

  @description('Optional. Should Kerberos authentication be enabled for Azure Bastion? Default false.')
  kerberosEnabled: bool?

  @description('Optional. The number of scale units for Azure Bastion. Valid values are between 2 and 50. Default 2.')
  scaleUnits: int?

  @description('Optional. Should shareable links be enabled for Azure Bastion? Requires Standard SKU. Default false.')
  shareableLinkEnabled: bool?

  @description('Optional. The SKU of Azure Bastion. Possible values are Basic, Standard. Default Standard.')
  sku: ('Basic' | 'Standard')?

  @description('Optional. Should tunneling be enabled for Azure Bastion? Requires Standard SKU.')
  tunnelingEnabled: bool?

  @description('Optional. A set of availability zones for Azure Bastion.')
  zones: int[]?

  @description('Optional. Bastion public IP configuration.')
  bastionPublicIp: {
    @description('Optional. The name of the public IP for Azure Bastion.')
    name: string?

    @description('Optional. The allocation method for the public IP.')
    allocationMethod: ('Static' | 'Dynamic')?

    @description('Optional. The SKU of the public IP.')
    sku: ('Basic' | 'Standard')?

    @description('Optional. The SKU tier of the public IP.')
    skuTier: ('Regional' | 'Global')?

    @description('Optional. The idle timeout in minutes for the public IP. Default 4.')
    idleTimeoutInMinutes: int?

    @description('Optional. A set of availability zones for the public IP.')
    zones: int[]?

    @description('Optional. Tags to apply to the public IP.')
    tags: object?

    @description('Optional. The domain name label for the public IP.')
    domainNameLabel: string?
  }?

  @description('Optional. Lock settings for Azure Bastion.')
  lock: lockType?
}

type dnsSettingsType = {
  @description('Required. Deploy Private DNS zones.')
  deployPrivateDnsZones: bool

  @description('Optional. Array of resource IDs of existing virtual networks to link to the Private DNS Zones. The sidecar virtual network is automatically included.')
  virtualNetworkResourceIdsToLinkTo: array?

  @description('Optional. Array of DNS Zones to provision and link to sidecar Virtual Network. Default: All known Azure Private DNS Zones, baked into underlying AVM module see: https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/private-link-private-dns-zones#parameter-privatelinkprivatednszones')
  privateDnsZones: array?

  @description('Optional. Resource ID of an existing failover virtual network for Private DNS Zone VNet failover links.')
  virtualNetworkIdToLinkFailover: string?

  @description('Required. Deploy Private DNS Resolver.')
  deployDnsPrivateResolver: bool

  @description('Optional. The name of the Private DNS Resolver.')
  privateDnsResolverName: string?

  @description('Optional. Private DNS Resolver inbound endpoints configuration.')
  inboundEndpoints: array?

  @description('Optional. Private DNS Resolver outbound endpoints configuration.')
  outboundEndpoints: array?

  @description('Optional. Lock settings for Private DNS resources.')
  lock: lockType?

  @description('Optional. Tags for Private DNS resources.')
  tags: object?

  @description('Optional. An array of additional Private Link Private DNS Zones to include in the deployment on top of the defaults set in the parameter `privateLinkPrivateDnsZones`.')
  additionalPrivateLinkPrivateDnsZonesToInclude: string[]?

  @description('Optional. An array of Private Link Private DNS Zones to exclude from the deployment. The DNS zone names must match what is provided as the default values or any input to the `privateLinkPrivateDnsZones` parameter e.g. `privatelink.api.azureml.ms` or `privatelink.{regionCode}.backup.windowsazure.com` or `privatelink.{regionName}.azmk8s.io` .')
  privateLinkPrivateDnsZonesToExclude: string[]?
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

//=====================
// VWAN Gateway Types
//=====================

type expressRouteGatewaySettingsType = {
  @description('Required. Deploy ExpressRoute Gateway.')
  deployExpressRouteGateway: bool

  @description('Optional. Resource ID of an existing ExpressRoute Gateway. If provided, a new gateway will not be deployed.')
  existingExpressRouteGatewayResourceId: string?

  @description('Optional. Name of the ExpressRoute Gateway. Required when deploying a new gateway.')
  name: string?

  @description('Optional. Enable/Disable accepting traffic from non-Virtual WAN networks. Default false.')
  allowNonVirtualWanTraffic: bool?

  @description('Optional. Minimum number of scale units for the ExpressRoute Gateway. Default 1.')
  minScaleUnits: int?

  @description('Optional. Maximum number of scale units for the ExpressRoute Gateway. Default 1.')
  maxScaleUnits: int?

  @description('Optional. Lock configuration for the ExpressRoute Gateway.')
  lock: lockType?

  @description('Optional. Tags for the ExpressRoute Gateway.')
  tags: object?
}

type s2sVpnGatewayType = {
  @description('Required. Deploy Site-to-Site VPN Gateway.')
  deployS2sVpnGateway: bool

  @description('Optional. Resource ID of an existing S2S VPN Gateway. If provided, a new gateway will not be deployed.')
  existingS2sVpnGatewayResourceId: string?

  @description('Optional. Name of the Site-to-Site VPN Gateway. Required when deploying a new gateway.')
  name: string?

  @description('Optional. The scale unit for the VPN Gateway. Default 1.')
  scaleUnit: int?

  @description('Optional. Enable BGP route translation for NAT. Default false.')
  bgpRouteTranslationForNatEnabled: bool?

  @description('Optional. BGP settings for the VPN Gateway.')
  bgpSettings: {
    @description('Required. The BGP speaker ASN.')
    asn: int

    @description('Required. The weight added to routes learned from this BGP speaker.')
    peerWeight: int

    @description('Optional. BGP peering address with custom IPs for instance 0.')
    instance0BgpPeeringAddress: {
      @description('Required. List of custom BGP IP addresses.')
      customIps: string[]
    }?

    @description('Optional. BGP peering address with custom IPs for instance 1.')
    instance1BgpPeeringAddress: {
      @description('Required. List of custom BGP IP addresses.')
      customIps: string[]
    }?
  }?

  @description('Optional. Routing preference for the VPN Gateway.')
  routingPreference: ('ExpressRoute' | 'VpnGateway' | 'ASPath')?

  @description('Optional. VPN connections configuration for this gateway.')
  vpnConnections: vpnConnectionType[]?

  @description('Optional. Lock configuration for the VPN Gateway.')
  lock: lockType?

  @description('Optional. Tags for the VPN Gateway.')
  tags: object?
}

type vpnSiteType = {
  @description('Required. Name of the VPN site.')
  name: string

  @description('Optional. Device model information.')
  deviceModel: string?

  @description('Optional. Device vendor information.')
  deviceVendor: string?

  @description('Optional. List of IP address CIDRs for the site (required if BGP is not used).')
  addressPrefixes: string[]?

  @description('Required. VPN site links configuration.')
  links: {
    @description('Required. Name of the VPN site link.')
    name: string

    @description('Optional. FQDN of the VPN site link.')
    fqdn: string?

    @description('Optional. IP address of the VPN site link.')
    ipAddress: string?

    @description('Optional. BGP configuration for the link.')
    bgpProperties: {
      @description('Required. BGP ASN.')
      asn: int

      @description('Required. BGP peering address.')
      bgpPeeringAddress: string
    }?

    @description('Optional. Link provider name.')
    linkProviderName: string?

    @description('Optional. Link speed in Mbps.')
    linkSpeedInMbps: int?
  }[]

  @description('Optional. O365 policy configuration.')
  o365Policy: {
    @description('Required. O365 traffic category settings.')
    breakOutCategories: {
      @description('Optional. Allow breakout for optimize category.')
      optimize: bool?

      @description('Optional. Allow breakout for allow category.')
      allow: bool?

      @description('Optional. Allow breakout for default category.')
      default: bool?
    }
  }?

  @description('Optional. Lock configuration for the VPN site.')
  lock: lockType?

  @description('Optional. Tags for the VPN site.')
  tags: object?
}

type vpnConnectionType = {
  @description('Required. Name of the VPN connection.')
  name: string

  @description('Required. Name of the VPN site this connection connects to.')
  vpnSiteName: string

  @description('Optional. Enable internet security for the connection. Default true.')
  enableInternetSecurity: bool?

  @description('Optional. Enable BGP for the connection.')
  enableBgp: bool?

  @description('Optional. Use local Azure IP address for the connection.')
  useLocalAzureIpAddress: bool?

  @description('Optional. Use policy-based traffic selectors.')
  usePolicyBasedTrafficSelectors: bool?

  @description('Optional. VPN connection protocol type. Default IkeV2.')
  vpnConnectionProtocolType: ('IKEv1' | 'IKEv2')?

  @description('Optional. Connection bandwidth in Mbps.')
  connectionBandwidthInMbps: int?

  @description('Optional. Shared key for the connection.')
  sharedKey: string?

  @description('Optional. Routing configuration for the connection.')
  routing: {
    @description('Optional. Associated route table resource ID.')
    associatedRouteTableId: string?

    @description('Optional. Propagated route tables configuration.')
    propagatedRouteTables: {
      @description('Optional. List of route table resource IDs.')
      ids: string[]?

      @description('Optional. List of labels.')
      labels: string[]?
    }?

    @description('Optional. Inbound route map resource ID.')
    inboundRouteMapId: string?

    @description('Optional. Outbound route map resource ID.')
    outboundRouteMapId: string?
  }?

  @description('Optional. IPsec policy for the connection.')
  ipsecPolicies: {
    @description('Required. DH Groups for IPsec.')
    dhGroup: ('DHGroup1' | 'DHGroup2' | 'DHGroup14' | 'DHGroup24' | 'DHGroup2048' | 'ECP256' | 'ECP384' | 'None')

    @description('Required. IKE encryption algorithm.')
    ikeEncryption: ('AES128' | 'AES192' | 'AES256' | 'DES' | 'DES3' | 'GCMAES128' | 'GCMAES256')

    @description('Required. IKE integrity algorithm.')
    ikeIntegrity: ('GCMAES128' | 'GCMAES256' | 'MD5' | 'SHA1' | 'SHA256' | 'SHA384')

    @description('Required. IPsec encryption algorithm.')
    ipsecEncryption: ('AES128' | 'AES192' | 'AES256' | 'DES' | 'DES3' | 'GCMAES128' | 'GCMAES192' | 'GCMAES256' | 'None')

    @description('Required. IPsec integrity algorithm.')
    ipsecIntegrity: ('GCMAES128' | 'GCMAES192' | 'GCMAES256' | 'MD5' | 'SHA1' | 'SHA256')

    @description('Required. PFS Groups for IPsec.')
    pfsGroup: ('ECP256' | 'ECP384' | 'None' | 'PFS1' | 'PFS2' | 'PFS14' | 'PFS24' | 'PFS2048' | 'PFSMM')

    @description('Required. IPsec SA lifetime in seconds.')
    saLifeTimeSeconds: int

    @description('Required. IPsec SA lifetime in kilobytes.')
    saDataSizeKilobytes: int
  }[]?

  @description('Optional. Traffic selector policies for the connection.')
  trafficSelectorPolicies: {
    @description('Required. List of local address ranges.')
    localAddressRanges: string[]

    @description('Required. List of remote address ranges.')
    remoteAddressRanges: string[]
  }[]?
}

type p2sVpnGatewayType = {
  @description('Required. Deploy Point-to-Site VPN Gateway.')
  deployP2sVpnGateway: bool

  @description('Optional. Resource ID of an existing P2S VPN Gateway. If provided, a new gateway will not be deployed.')
  existingP2sVpnGatewayResourceId: string?

  @description('Optional. Name of the Point-to-Site VPN Gateway. Required when deploying a new gateway.')
  name: string?

  @description('Optional. The scale unit for the P2S VPN Gateway. Required when deploying a new gateway.')
  scaleUnit: int?

  @description('Optional. DNS servers for the P2S VPN Gateway.')
  dnsServers: string[]?

  @description('Required. VPN server configuration for P2S clients.')
  vpnServerConfiguration: {
    @description('Optional. Name of the VPN server configuration.')
    name: string?

    @description('Required. VPN authentication types. Options: AAD, Certificate, Radius.')
    vpnAuthenticationTypes: ('AAD' | 'Certificate' | 'Radius')[]

    @description('Optional. VPN protocols. Options: IkeV2, OpenVPN.')
    vpnProtocols: ('IkeV2' | 'OpenVPN')[]?

    @description('Optional. Azure Active Directory authentication configuration.')
    aadAuthenticationParameters: {
      @description('Required. AAD tenant URL.')
      aadTenant: string

      @description('Required. AAD audience.')
      aadAudience: string

      @description('Required. AAD issuer.')
      aadIssuer: string
    }?

    @description('Optional. VPN client root certificate public data (Base64-encoded) for Certificate authentication.')
    vpnClientRootCertificates: {
      @description('Required. Name of the root certificate.')
      name: string

      @description('Required. Public certificate data in Base64 format.')
      publicCertData: string
    }[]?

    @description('Optional. VPN client revoked certificates.')
    vpnClientRevokedCertificates: {
      @description('Required. Name of the revoked certificate.')
      name: string

      @description('Required. Revoked certificate thumbprint.')
      thumbprint: string
    }[]?

    @description('Optional. Radius server configuration for Radius authentication.')
    radiusServers: {
      @description('Required. Radius server address.')
      radiusServerAddress: string

      @description('Required. Radius server secret.')
      radiusServerSecret: string

      @description('Optional. Radius server score.')
      radiusServerScore: int?
    }[]?

    @description('Optional. Lock configuration for the VPN server configuration.')
    lock: lockType?

    @description('Optional. Tags for the VPN server configuration.')
    tags: object?
  }

  @description('Required. VPN client address pool configuration.')
  vpnClientAddressPool: {
    @description('Optional. List of address prefixes for VPN clients.')
    addressPrefixes: string[]
  }

  @description('Optional. Custom DNS configuration for the P2S connection.')
  customDnsConfigs: {
    @description('Optional. FQDN for custom DNS.')
    fqdn: string?

    @description('Required. List of IP addresses for custom DNS.')
    ipAddresses: string[]
  }[]?

  @description('Optional. Enable routing for the connection. Default true.')
  enableInternetSecurity: bool?

  @description('Optional. Routing configuration for P2S.')
  routing: {
    @description('Optional. Associated route table resource ID.')
    associatedRouteTableId: string?

    @description('Optional. Propagated route tables configuration.')
    propagatedRouteTables: {
      @description('Optional. List of route table resource IDs.')
      ids: string[]?

      @description('Optional. List of labels.')
      labels: string[]?
    }?

    @description('Optional. Inbound route map resource ID.')
    inboundRouteMapId: string?

    @description('Optional. Outbound route map resource ID.')
    outboundRouteMapId: string?
  }?

  @description('Optional. Lock configuration for the P2S VPN Gateway.')
  lock: lockType?

  @description('Optional. Tags for the P2S VPN Gateway.')
  tags: object?
}
