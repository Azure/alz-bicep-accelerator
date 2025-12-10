metadata name = 'ALZ Bicep Accelerator - Hub Networking'
metadata description = 'Used to deploy hub networking resources for ALZ.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('Optional. The prefix for the Hub Networking Resource Group names. Will be combined with location to create: {prefix}-{location}. Can be overridden by parHubNetworkingResourceGroupNameOverrides.')
param parHubNetworkingResourceGroupNamePrefix string = 'rg-alz-conn'

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of hubs in hubNetworks array.')
param parHubNetworkingResourceGroupNameOverrides array = []

@description('''Optional. Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

@description('Optional. The prefix for the DNS Resource Group names. Will be combined with location to create: {prefix}-{location}. Can be overridden by parDnsResourceGroupNameOverrides.')
param parDnsResourceGroupNamePrefix string = 'rg-alz-dns'

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of hubs in hubNetworks array.')
param parDnsResourceGroupNameOverrides array = []

@description('Optional. The prefix for the Private DNS Resolver Resource Group names. Will be combined with location to create: {prefix}-{location}. Can be overridden by parDnsPrivateResolverResourceGroupNameOverrides.')
param parDnsPrivateResolverResourceGroupNamePrefix string = 'rg-alz-dnspr'

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of hubs in hubNetworks array.')
param parDnsPrivateResolverResourceGroupNameOverrides array = []

// Hub Networking Parameters
@description('Required. The hub virtual networks to create.')
param hubNetworks hubVirtualNetworkType

// Resource Lock Parameters
@sys.description('''Optional. Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

// General Parameters
@description('Optional. Array of locations for reference purposes. This parameter is primarily used in parameter files for convenience when defining hubNetworks array.')
#disable-next-line no-unused-params
param parLocations array = []

@description('Optional. Tags to be applied to all resources.')
param parTags object = {}

@description('Optional. Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Variables
//========================================

var hubResourceGroupNames = [for (hub, i) in hubNetworks: empty(parHubNetworkingResourceGroupNameOverrides) ? '${parHubNetworkingResourceGroupNamePrefix}-${hub.location}' : parHubNetworkingResourceGroupNameOverrides[i]]
var dnsResourceGroupNames = [for (hub, i) in hubNetworks: empty(parDnsResourceGroupNameOverrides) ? '${parDnsResourceGroupNamePrefix}-${hub.location}' : parDnsResourceGroupNameOverrides[i]]
var dnsPrivateResolverResourceGroupNames = [for (hub, i) in hubNetworks: empty(parDnsPrivateResolverResourceGroupNameOverrides) ? '${parDnsPrivateResolverResourceGroupNamePrefix}-${hub.location}' : parDnsPrivateResolverResourceGroupNameOverrides[i]]
var publicIpRecommendedZones = [for hub in hubNetworks: empty(pickZones('Microsoft.Network', 'publicIPAddresses', hub.location)) ? [] : json(format('[{0}]', join(pickZones('Microsoft.Network', 'publicIPAddresses', hub.location), ',')))]
var hubAzureFirewallRecommendedZones = [for hub in hubNetworks: empty(pickZones('Microsoft.Network', 'azureFirewalls', hub.location)) ? [] : json(format('[{0}]', join(pickZones('Microsoft.Network', 'azureFirewalls', hub.location), ',')))]
var hubBastionRecommendedZones = [for hub in hubNetworks: empty(pickZones('Microsoft.Network', 'bastionHosts', hub.location)) ? [] : json(format('[{0}]', join(pickZones('Microsoft.Network', 'bastionHosts', hub.location), ',')))]
var expressRouteGatewaySkuMap = {
  zonal: 'ErGw1AZ'
  nonZonal: 'Standard'
}
var hubExpressRouteGatewayRecommendedSku = [for hub in hubNetworks: empty(pickZones('Microsoft.Network', 'virtualNetworkGateways', hub.location)) ? expressRouteGatewaySkuMap.nonZonal : expressRouteGatewaySkuMap.zonal]
var firewallPrivateIpAddresses = [for (hub, i) in hubNetworks: hub.azureFirewallSettings.enableAzureFirewall ? cidrHost(filter(hub.subnets, subnet => subnet.?name == 'AzureFirewallSubnet')[0].addressPrefix, 4) : '']
var dnsResolverInboundIpAddresses = [for (hub, i) in hubNetworks: (hub.privateDnsSettings.enableDnsPrivateResolver && hub.privateDnsSettings.enablePrivateDnsZones) ? cidrHost(filter(hub.subnets, subnet => subnet.?name == 'DNSPrivateResolverInboundSubnet')[0].addressPrefix, 4) : '']

output hubResourceGroupNames array = hubResourceGroupNames
output dnsResourceGroupNames array = dnsResourceGroupNames
output dnsPrivateResolverResourceGroupNames array = dnsPrivateResolverResourceGroupNames
output publicIpRecommendedZones array = publicIpRecommendedZones
output hubAzureFirewallRecommendedZones array = hubAzureFirewallRecommendedZones
output hubBastionRecommendedZones array = hubBastionRecommendedZones
output firewallPrivateIpAddresses array = firewallPrivateIpAddresses
output dnsResolverInboundIpAddresses array = dnsResolverInboundIpAddresses

//========================================
// Resources Groups
//========================================

module modHubNetworkingResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (hub, i) in hubNetworks: {
    name: 'modHubResourceGroup-${i}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: subscription()
    params: {
      name: hubResourceGroupNames[i]
      location: hub.location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module modDnsResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (hub, i) in hubNetworks: if (hub.privateDnsSettings.enablePrivateDnsZones) {
    name: 'modDnsResourceGroup-${i}-${uniqueString(parDnsResourceGroupNamePrefix, hub.location)}'
    scope: subscription()
    params: {
      name: dnsResourceGroupNames[i]
      location: hub.location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module modPrivateDnsResolverResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (hub, i) in hubNetworks: if (hub.privateDnsSettings.enableDnsPrivateResolver) {
    name: 'modPrivateDnsResolverResourceGroup-${i}-${uniqueString(parDnsPrivateResolverResourceGroupNamePrefix, hub.location)}'
    scope: subscription()
    params: {
      name: dnsPrivateResolverResourceGroupNames[i]
      location: hub.location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Virtual Networks
//=====================
module resHubVirtualNetwork 'br/public:avm/res/network/virtual-network:0.7.2' = [
  for (hub, i) in hubNetworks: {
    name: 'vnet-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      modHubNetworkingResourceGroups[i]
      ...(hub.ddosProtectionPlanSettings.enableDdosProtection ? [resDdosProtectionPlan[i]] : [])
    ]
    params: {
      name: hub.name
      location: hub.location
      addressPrefixes: hub.addressPrefixes
      dnsServers: hub.azureFirewallSettings.enableAzureFirewall && hub.privateDnsSettings.enableDnsPrivateResolver && hub.privateDnsSettings.enablePrivateDnsZones
        ? [firewallPrivateIpAddresses[i]]
        : (hub.?dnsServers ?? [])
      ddosProtectionPlanResourceId: hub.?ddosProtectionPlanResourceId ?? (hub.ddosProtectionPlanSettings.enableDdosProtection ? resDdosProtectionPlan[i].?outputs.resourceId : null)
      vnetEncryption: hub.?vnetEncryption ?? false
      vnetEncryptionEnforcement: hub.?vnetEncryptionEnforcement ?? 'AllowUnencrypted'
      subnets: [
        for subnet in hub.subnets: {
          name: subnet.name
          addressPrefix: subnet.addressPrefix
          delegation: subnet.?delegation
          networkSecurityGroupResourceId: (subnet.?name == 'AzureBastionSubnet' && hub.bastionHostSettings.enableBastion)
            ? resBastionNsg[i].?outputs.resourceId
            : subnet.?networkSecurityGroupId
        }
      ]
      lock: parGlobalResourceLock ?? hub.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Azure Firewall
//=====================

module resAzureFirewall 'br/public:avm/res/network/azure-firewall:0.9.2' = [
  for (hub, i) in hubNetworks: if (hub.azureFirewallSettings.enableAzureFirewall) {
    name: 'afw-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork[i]
    ]
    params: {
      name: hub.?azureFirewallSettings.?azureFirewallName ?? 'afw-alz-${hub.location}'
      location: hub.location
      azureSkuTier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      firewallPolicyId: hub.?azureFirewallSettings.?firewallPolicyId ?? resFirewallPolicy[i].?outputs.resourceId
      managementIPAddressObject: hub.?azureFirewallSettings.?managementIPAddressObject
      publicIPAddressObject: hub.?azureFirewallSettings.?publicIPAddressObject ?? (!empty(hub.?azureFirewallSettings.?publicIPResourceID ?? '')
        ? null
        : {
            name: '${hub.name}-azfirewall-pip'
          })
      publicIPResourceID: hub.?azureFirewallSettings.?publicIPResourceID
      roleAssignments: hub.?azureFirewallSettings.?roleAssignments
      threatIntelMode: (hub.?azureFirewallSettings.?azureSkuTier == 'Standard')
        ? 'Alert'
        : hub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
      availabilityZones: hub.?azureFirewallSettings.?zones ?? hubAzureFirewallRecommendedZones[i]
      virtualNetworkResourceId: resHubVirtualNetwork[i].outputs.resourceId
      lock: parGlobalResourceLock ?? hub.?azureFirewallSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Bastion Hosts
//=====================

module resBastion 'br/public:avm/res/network/bastion-host:0.8.2' = [
  for (hub, i) in hubNetworks: if (hub.bastionHostSettings.enableBastion) {
    name: 'bastion-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork[i]
    ]
    params: {
      name: hub.?bastionHostSettings.?bastionHostSettingsName ?? 'bas-alz-${hub.location}'
      location: hub.location
      skuName: hub.?bastionHostSettings.?skuName ?? 'Standard'
      virtualNetworkResourceId: resHubVirtualNetwork[i].outputs.resourceId
      scaleUnits: hub.?bastionHostSettings.?scaleUnits ?? 4
      disableCopyPaste: hub.?bastionHostSettings.?disableCopyPaste ?? false
      enableFileCopy: hub.?bastionHostSettings.?enableFileCopy ?? false
      enableIpConnect: hub.?bastionHostSettings.?enableIpConnect ?? false
      enableKerberos: hub.?bastionHostSettings.?enableKerberos ?? false
      enableShareableLink: hub.?bastionHostSettings.?enableShareableLink ?? false
      availabilityZones: hub.?bastionHostSettings.?zones ?? hubBastionRecommendedZones[i]
      publicIPAddressObject: {
        name: '${hub.name}-bastion-pip'
        availabilityZones: hub.?bastionHostSettings.?zones ?? publicIpRecommendedZones[i]
      }
      lock: parGlobalResourceLock ?? hub.?bastionHostSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// VNet Peerings
//=====================

module resVnetPeering 'br/public:avm/res/network/virtual-network:0.7.2' = [
  for (hub, i) in hubNetworks: if (hub.enablePeering && !empty(hub.?peeringSettings ?? [])) {
    name: 'peering-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork
      resAzureFirewall
    ]
    params: {
      name: hub.name
      location: hub.location
      addressPrefixes: hub.addressPrefixes
      peerings: [
        for peering in hub.?peeringSettings ?? []: {
          allowForwardedTraffic: peering.?allowForwardedTraffic ?? true
          allowGatewayTransit: peering.?allowGatewayTransit ?? false
          allowVirtualNetworkAccess: peering.?allowVirtualNetworkAccess ?? true
          useRemoteGateways: peering.?useRemoteGateways ?? false
          remotePeeringEnabled: true
          remotePeeringAllowForwardedTraffic: peering.?allowForwardedTraffic ?? true
          remotePeeringAllowGatewayTransit: peering.?allowGatewayTransit ?? false
          remotePeeringAllowVirtualNetworkAccess: peering.?allowVirtualNetworkAccess ?? true
          remotePeeringUseRemoteGateways: peering.?useRemoteGateways ?? false
          remoteVirtualNetworkResourceId: resourceId(
            subscription().subscriptionId,
            hubResourceGroupNames[indexOf(map(hubNetworks, h => h.name), peering.remoteVirtualNetworkName)],
            'Microsoft.Network/virtualNetworks',
            peering.remoteVirtualNetworkName
          )
        }
      ]
      enableTelemetry: false
    }
  }
]

//=====================
// Route Tables
//=====================

// Firewall Route Table - for AzureFirewallSubnet with default route to Internet
module resFirewallRouteTable 'br/public:avm/res/network/route-table:0.5.0' = [
  for (hub, i) in hubNetworks: if (hub.azureFirewallSettings.enableAzureFirewall) {
    name: 'rt-fw-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      modHubNetworkingResourceGroups
    ]
    params: {
      name: 'rt-hub-fw-${hub.location}'
      location: hub.location
      routes: [
        {
          name: 'internet'
          properties: {
            addressPrefix: '0.0.0.0/0'
            nextHopType: 'Internet'
          }
        }
      ]
      disableBgpRoutePropagation: false
      lock: parGlobalResourceLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

// User Subnets Route Table - for regular subnets with default route to Firewall
module resUserSubnetsRouteTable 'br/public:avm/res/network/route-table:0.5.0' = [
  for (hub, i) in hubNetworks: if (hub.azureFirewallSettings.enableAzureFirewall) {
    name: 'rt-user-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      modHubNetworkingResourceGroups
    ]
    params: {
      name: 'rt-hub-std-${hub.location}'
      location: hub.location
      routes: [
        {
          name: 'default-via-firewall'
          properties: {
            addressPrefix: '0.0.0.0/0'
            nextHopType: 'VirtualAppliance'
            nextHopIpAddress: firewallPrivateIpAddresses[i]
          }
        }
      ]
      disableBgpRoutePropagation: false
      lock: parGlobalResourceLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Network Security
//=====================
module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.2' = [
  for (hub, i) in hubNetworks: if (hub.ddosProtectionPlanSettings.enableDdosProtection) {
    name: 'ddosPlan-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.?ddosProtectionPlanResourceId ?? '',hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?ddosProtectionPlanSettings.?name ?? 'ddos-alz-${hub.location}'
      location: hub.?ddosProtectionPlanSettings.?location ?? hub.location
      lock: parGlobalResourceLock ?? hub.?ddosProtectionPlanSettings.?lock
      tags: hub.?ddosProtectionPlanSettings.?tags ?? parTags
      enableTelemetry: hub.?ddosProtectionPlanSettings.?enableTelemetry ?? parEnableTelemetry
    }
  }
]

module resFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.4' = [
  for (hub, i) in hubNetworks: if (hub.azureFirewallSettings.enableAzureFirewall && empty(hub.?azureFirewallSettings.?firewallPolicyId)) {
    name: 'firewallPolicy-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.name,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      modHubNetworkingResourceGroups
    ]
    params: {
      name: 'afwp-alz-${hub.location}'
      location: hub.location
      tier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      threatIntelMode: (hub.?azureFirewallSettings.?azureSkuTier == 'Standard')
        ? 'Alert'
        : hub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
      enableProxy: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? false
        : (hub.privateDnsSettings.enableDnsPrivateResolver && hub.privateDnsSettings.enablePrivateDnsZones && hub.azureFirewallSettings.enableAzureFirewall)
          ? true
          : (hub.?azureFirewallSettings.?dnsProxyEnabled ?? false)
      servers: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? null
        : (hub.privateDnsSettings.enableDnsPrivateResolver && hub.privateDnsSettings.enablePrivateDnsZones && hub.azureFirewallSettings.enableAzureFirewall)
          ? [dnsResolverInboundIpAddresses[i]]
          : hub.?azureFirewallSettings.?firewallDnsServers
      lock: parGlobalResourceLock ?? hub.?azureFirewallSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resBastionNsg 'br/public:avm/res/network/network-security-group:0.5.2' = [
  for (hub, i) in hubNetworks: if (hub.bastionHostSettings.enableBastion) {
    name: '${hub.name}-bastionNsg-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?bastionHostSettings.?bastionNsgName ?? 'nsg-bas-alz-${hub.location}'
      location: hub.location
      lock: parGlobalResourceLock ?? hub.?bastionHostSettings.?bastionNsgLock
      securityRules: hub.?bastionHostSettings.?bastionNsgSecurityRules ?? [
        // Inbound Rules
        {
          name: 'AllowHttpsInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 120
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowGatewayManagerInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 130
            sourceAddressPrefix: 'GatewayManager'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowAzureLoadBalancerInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 140
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowbastionHostSettingsCommunication'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 150
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
          }
        }
        {
          name: 'DenyAllInbound'
          properties: {
            access: 'Deny'
            direction: 'Inbound'
            priority: 4096
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
          }
        }
        // Outbound Rules
        {
          name: 'AllowSshRdpOutbound'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 100
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRanges: hub.?bastionHostSettings.?outboundSshRdpPorts ?? [
              '22'
              '3389'
            ]
          }
        }
        {
          name: 'AllowAzureCloudOutbound'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 110
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'AzureCloud'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowBastionCommunication'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 120
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
          }
        }
        {
          name: 'AllowGetSessionInformation'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 130
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'Internet'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '80'
          }
        }
        {
          name: 'DenyAllOutbound'
          properties: {
            access: 'Deny'
            direction: 'Outbound'
            priority: 4096
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
          }
        }
      ]
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Hybrid Connectivity
//=====================
module resVpnGateway 'br/public:avm/res/network/virtual-network-gateway:0.10.0' = [
  for (hub, i) in hubNetworks: if (hub.vpnGatewaySettings.enableVirtualNetworkGateway) {
    name: 'vpnGateway-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.name,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork[i]
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?vpnGatewaySettings.?name ?? 'vgw-alz-${hub.location}'
      clusterSettings: {
        clusterMode: any(hub.?vpnGatewaySettings.?vpnMode)
        asn: hub.?vpnGatewaySettings.?asn ?? 65515
        customBgpIpAddresses: (hub.?vpnGatewaySettings.?vpnMode == 'activePassiveBgp' || hub.?vpnGatewaySettings.?vpnMode == 'activeActiveBgp')
          ? (hub.?vpnGatewaySettings.?customBgpIpAddresses)
          : null
      }
      location: hub.location
      gatewayType: 'Vpn'
      vpnType: hub.?vpnGatewaySettings.?vpnType ?? 'RouteBased'
      skuName: hub.?vpnGatewaySettings.?skuName ?? 'VpnGw1AZ'
      enableBgpRouteTranslationForNat: hub.?vpnGatewaySettings.?enableBgpRouteTranslationForNat ?? false
      enableDnsForwarding: hub.?vpnGatewaySettings.?enableDnsForwarding ?? false
      vpnGatewayGeneration: hub.?vpnGatewaySettings.?vpnGatewayGeneration ?? 'None'
      virtualNetworkResourceId: resHubVirtualNetwork[i].outputs.resourceId
      domainNameLabel: !empty(hub.?vpnGatewaySettings.?domainNameLabel ?? [])
        ? hub.?vpnGatewaySettings.?domainNameLabel
        : ['vgw-alz-${hub.location}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, hub.name, hub.location, 'vpn')}']
      publicIpAvailabilityZones: hub.?vpnGatewaySettings.?skuName != 'Basic'
        ? hub.?vpnGatewaySettings.?publicIpZones ?? publicIpRecommendedZones[i]
        : []
      lock: parGlobalResourceLock ?? hub.?vpnGatewaySettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resExpressRouteGateway 'br/public:avm/res/network/virtual-network-gateway:0.10.0' = [
  for (hub, i) in hubNetworks: if (hub.?expressRouteGatewaySettings.?enableExpressRouteGateway ?? false) {
    name: 'expressRouteGateway-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.name,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork[i]
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?expressRouteGatewaySettings.?name ?? 'ergw-alz-${hub.location}'
      clusterSettings: {
        clusterMode: 'activePassiveNoBgp'
      }
      location: hub.location
      gatewayType: 'ExpressRoute'
      skuName: hub.?expressRouteGatewaySettings.?skuName ?? hubExpressRouteGatewayRecommendedSku[i]
      enableDnsForwarding: hub.?expressRouteGatewaySettings.?enableDnsForwarding ?? false
      enablePrivateIpAddress: hub.?expressRouteGatewaySettings.?enablePrivateIpAddress ?? false
      virtualNetworkResourceId: resHubVirtualNetwork[i]!.outputs.resourceId
      publicIpAvailabilityZones: hub.?expressRouteGatewaySettings.?publicIpZones ?? publicIpRecommendedZones[i]
      lock: parGlobalResourceLock ?? hub.?expressRouteGatewaySettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

// =====================
// DNS
// =====================
module resPrivateDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.1' = [
  for (hub, i) in hubNetworks: if (hub.privateDnsSettings.enablePrivateDnsZones) {
    name: 'privateDnsZone-${hub.name}-${uniqueString(parDnsResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(dnsResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork
      modDnsResourceGroups
    ]
    params: {
      location: hub.location
      privateLinkPrivateDnsZones: empty(hub.?privateDnsSettings.?privateDnsZones) ? null : hub.?privateDnsSettings.?privateDnsZones
      virtualNetworkLinks: [
        for id in union(
        [
            resourceId(
              subscription().subscriptionId,
              hubResourceGroupNames[i],
              'Microsoft.Network/virtualNetworks',
              hub.name
            )
          ],
          !empty(hub.?privateDnsSettings.?virtualNetworkIdToLinkFailover) ? [hub.?privateDnsSettings.?virtualNetworkIdToLinkFailover] : [],
          hub.?privateDnsSettings.?virtualNetworkResourceIdsToLinkTo ?? []
        ): {
          virtualNetworkResourceId: id
        }
      ]
      lock: parGlobalResourceLock ?? hub.?privateDnsSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resDnsPrivateResolver 'br/public:avm/res/network/dns-resolver:0.5.6' = [
  for (hub, i) in hubNetworks: if (hub.privateDnsSettings.enableDnsPrivateResolver) {
    name: 'dnsResolver-${hub.name}-${uniqueString(parDnsPrivateResolverResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(dnsPrivateResolverResourceGroupNames[i])
    dependsOn: [
      resHubVirtualNetwork[i]
      modPrivateDnsResolverResourceGroups
    ]
    params: {
      name: hub.?privateDnsSettings.?privateDnsResolverName ?? 'dnspr-alz-${hub.location}'
      location: hub.location
      virtualNetworkResourceId: resHubVirtualNetwork[i]!.outputs.resourceId
      inboundEndpoints: hub.?privateDnsSettings.?inboundEndpoints ?? [
        {
          name: 'in-${hub.location}'
          subnetResourceId: '${resHubVirtualNetwork[i]!.outputs.resourceId}/subnets/DNSPrivateResolverInboundSubnet'
        }
      ]
      outboundEndpoints: hub.?privateDnsSettings.?outboundEndpoints ?? [
         {
          name: 'out-${hub.location}'
          subnetResourceId: '${resHubVirtualNetwork[i]!.outputs.resourceId}/subnets/DNSPrivateResolverOutboundSubnet'
        }
      ]
      lock: parGlobalResourceLock ?? hub.?privateDnsSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

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

type hubNetworkingType = {
  @description('Required. ALZ network type')
  networkType: 'hub-and-spoke'
}

type bastionHostSettingsType = {
  @description('Required. Enable/Disable Azure Bastion deployment for the virtual network.')
  enableBastion: bool

  @description('Optional. Enable/Disable copy/paste functionality.')
  disableCopyPaste: bool?

  @description('Optional. Enable/Disable file copy functionality.')
  enableFileCopy: bool?

  @description('Optional. Enable/Disable IP connect functionality.')
  enableIpConnect: bool?

  @description('Optional. Enable/Disable shareable link functionality.')
  enableShareableLink: bool?

  @description('Optional. Enable/Disable Kerberos authentication.')
  enableKerberos: bool?

  @description('Optional. The number of scale units for the Bastion host.')
  scaleUnits: int?

  @description('Optional. The SKU name of the Bastion host.')
  skuName: 'Basic' | 'Developer' | 'Premium' | 'Standard'?

  @description('Optional. The name of the bastion host.')
  bastionHostSettingsName: string?

  @description('Optional. The bastion\'s outbound ssh and rdp ports.')
  outboundSshRdpPorts: array?

  @description('Optional. Lock settings for Bastion.')
  lock: lockType?

  @description('Optional. The name of the Bastion NSG.')
  bastionNsgName: string?

  @description('Optional. Custom security rules for the Bastion NSG.')
  bastionNsgSecurityRules: array?

  @description('Optional. Lock settings for Bastion NSG.')
  bastionNsgLock: lockType?

  @description('Optional. Tags for Bastion NSG.')
  bastionNsgTags: object?

  @description('Optional. Enable/Disable usage telemetry for Bastion NSG.')
  bastionNsgEnableTelemetry: bool?

  @description('Optional. Availability zones for the Bastion host.')
  zones: int[]?
}

type hubVirtualNetworkType = {
  @description('Required. The name of the hub.')
  name: string

  @description('Required. The address prefixes for the virtual network.')
  addressPrefixes: array

  @description('Required. Azure Firewall configuration settings.')
  azureFirewallSettings: azureFirewallType

  @description('Required. Private DNS configuration settings.')
  privateDnsSettings: privateDnsType

  @description('Required. DDoS protection plan configuration settings.')
  ddosProtectionPlanSettings: ddosProtectionPlanType

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?

  @description('Required. The location of the virtual network.')
  location: string

  @description('Optional. The lock settings of the virtual network.')
  lock: lockType?

  @description('Optional. The diagnostic settings of the virtual network.')
  diagnosticSettings: diagnosticSettingType?

  @description('Optional. Resource ID of an existing DDoS protection plan to associate with the virtual network. If not specified and enableDdosProtection is true, a new DDoS protection plan will be created.')
  ddosProtectionPlanResourceId: string?

  @description('Optional. The DNS servers of the virtual network.')
  dnsServers: array?

  @description('Optional. The flow timeout in minutes.')
  flowTimeoutInMinutes: int?

  @description('Required. Enable/Disable peering for the virtual network.')
  enablePeering: bool

  @description('Optional. The peerings of the virtual network.')
  peeringSettings: peeringSettingsType?

  @description('Optional. The role assignments to create.')
  roleAssignments: roleAssignmentType?

  @description('Optional. Routes to add to the virtual network route table.')
  routes: array?

  @description('Optional. The name of the route table.')
  routeTableName: string?

  @description('Required. The subnets of the virtual network.')
  subnets: subnetOptionsType

  @description('Optional. The tags of the virtual network.')
  tags: object?

  @description('Optional. Enable/Disable VNet encryption.')
  vnetEncryption: bool?

  @description('Optional. The VNet encryption enforcement settings of the virtual network.')
  vnetEncryptionEnforcement: 'AllowUnencrypted' | 'DropUnencrypted'?

  @description('Required. VPN gateway configuration settings.')
  vpnGatewaySettings: vpnGatewaySettingsType

  @description('Optional. ExpressRoute gateway configuration settings.')
  expressRouteGatewaySettings: expressRouteGatewaySettingsType?

  @description('Required. Azure Bastion configuration settings.')
  bastionHostSettings: bastionHostSettingsType
}[]

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

type ddosProtectionPlanType = {
  @description('Required. Enable/Disable DDoS protection plan for the virtual network.')
  enableDdosProtection: bool

  @description('Optional. The name of the DDoS protection plan.')
  name: string?

  @description('Optional. The location of the DDoS protection plan.')
  location: string?

  @description('Optional. Lock settings for DDoS protection plan.')
  lock: lockType?

  @description('Optional. Tags for DDoS protection plan.')
  tags: object?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?
}

type azureFirewallType = {
  @description('Required. Enable/Disable Azure Firewall deployment for the virtual network.')
  enableAzureFirewall: bool

  @description('Optional. The name of the Azure Firewall to create.')
  azureFirewallName: string?

  @description('Optional. Azure Firewall SKU.')
  azureSkuTier: 'Basic' | 'Standard' | 'Premium'?

  @description('Optional. Resource ID of an existing Azure Firewall Policy to associate with the firewall. If not specified and enableAzureFirewall is true, a new firewall policy will be created.')
  firewallPolicyId: string?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Management IP address configuration.')
  managementIPAddressObject: object?

  @description('Optional. Public IP address object.')
  publicIPAddressObject: object?

  @description('Optional. Public IP resource ID.')
  publicIPResourceID: string?

  @description('Optional. Role assignments.')
  roleAssignments: roleAssignmentType?

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. Threat Intel mode.')
  threatIntelMode: ('Alert' | 'Deny' | 'Off')?

  @description('Optional. Availability zones for the Azure Firewall.')
  zones: int[]?

  @description('Optional. Enable/Disable dns proxy setting.')
  dnsProxyEnabled: bool?

  @description('Optional. Array of custom DNS servers used by Azure Firewall.')
  firewallDnsServers: array?
}

type privateDnsType = {
  @description('Required. Enable/Disable private DNS zones.')
  enablePrivateDnsZones: bool

  @description('Optional. The resource group name for private DNS zones.')
  privateDnsZonesResourceGroup: string?

  @description('Optional. Array of resource IDs of existing virtual networks to link to the Private DNS Zones. The hub virtual network is automatically included.')
  virtualNetworkResourceIdsToLinkTo: array?

  @description('Optional. Array of DNS Zones to provision and link to Hub Virtual Network. Default: All known Azure Private DNS Zones, baked into underlying AVM module see: https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/private-link-private-dns-zones#parameter-privatelinkprivatednszones')
  privateDnsZones: array?

  @description('Optional. Resource ID of an existing failover virtual network for Private DNS Zone VNet failover links.')
  virtualNetworkIdToLinkFailover: string?

  @description('Required. Enable/Disable Private DNS Resolver deployment.')
  enableDnsPrivateResolver: bool

  @description('Optional. Additional virtual network link objects to merge with the automatically generated hub link.')
  virtualNetworkLinks: dnsVirtualNetworkLinkType[]?

  @description('Optional. The name of the Private DNS Resolver.')
  privateDnsResolverName: string?

  @description('Optional. Private DNS Resolver inbound endpoints configuration.')
  inboundEndpoints: array?

  @description('Optional. Private DNS Resolver outbound endpoints configuration.')
  outboundEndpoints: array?

  @description('Optional. The location of the Private DNS Resolver.')
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

type dnsVirtualNetworkLinkType = {
  @description('Optional. The resource name for the virtual network link.')
  name: string?

  @description('Required. The resource ID of the virtual network to link.')
  virtualNetworkResourceId: string

  @description('Optional. Enables auto-registration of DNS records for the linked virtual network.')
  registrationEnabled: bool?

  @description('Optional. Resolution policy for the virtual network link.')
  resolutionPolicy: ('Default' | 'NxDomainRedirect')?

  @description('Optional. Tags for the virtual network link resource.')
  tags: object?
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
  @description('Required. Name of subnet.')
  name: string

  @description('Required. IP-address range for subnet.')
  addressPrefix: string

  @description('Optional. Resource ID of Network Security Group to associate with subnet.')
  networkSecurityGroupId: string?

  @description('Optional. Resource ID of Route Table to associate with subnet.')
  routeTable: string?

  @description('Optional. Name of the delegation to create for the subnet.')
  delegation: string?
})[]

type vpnGatewaySettingsType = {
  @description('Required. Enable/Disable virtual network gateway deployment.')
  enableVirtualNetworkGateway: bool

  @description('Optional. The name of the virtual network gateway.')
  name: string?

  @description('Optional. The SKU name of the virtual network gateway.')
  skuName:
    | 'VpnGw1AZ'
    | 'VpnGw2AZ'
    | 'VpnGw3AZ'
    | 'VpnGw4AZ'
    | 'VpnGw5AZ'

  @description('Optional. The VPN gateway configuration mode. Determines active/passive setup and BGP usage.')
  vpnMode: ('activeActiveBgp' | 'activeActiveNoBgp' | 'activePassiveBgp' | 'activePassiveNoBgp')?

  @description('Optional. The VPN type.')
  vpnType: 'RouteBased' | 'PolicyBased'?

  @description('Optional. The VPN gateway generation.')
  vpnGatewayGeneration: 'Generation1' | 'Generation2' | 'None'?

  @description('Optional. Enable BGP route translation for NAT scenarios.')
  enableBgpRouteTranslationForNat: bool?

  @description('Optional. Enable DNS forwarding through the VPN gateway.')
  enableDnsForwarding: bool?

  @description('Optional. The Autonomous System Number (ASN) for BGP configuration.')
  asn: int?

  @description('Optional. Custom BGP IP addresses for active-active BGP configurations.')
  customBgpIpAddresses: string[]?

  @description('Optional. Availability zones for the VPN gateway public IP addresses.')
  publicIpZones: array?

  @description('Optional. Base64-encoded root certificate data for Point-to-Site VPN authentication.')
  clientRootCertData: string?

  @description('Optional. The address pool prefix for VPN client connections in Point-to-Site scenarios.')
  vpnClientAddressPoolPrefix: string?

  @description('Optional. Azure Active Directory configuration for OpenVPN Point-to-Site connections.')
  vpnClientAadConfiguration: object?

  @description('Optional. Domain name labels for the public IP addresses associated with the gateway.')
  domainNameLabel: string[]?

  @description('Optional. Lock settings for Virtual Network Gateway.')
  lock: lockType?
}

type expressRouteGatewaySettingsType = {
  @description('Required. Enable/Disable ExpressRoute gateway deployment.')
  enableExpressRouteGateway: bool

  @description('Optional. The name of the ExpressRoute gateway.')
  name: string?

  @description('Optional. The SKU name of the ExpressRoute gateway.')
  skuName: 'Standard' | 'HighPerformance' | 'UltraPerformance' | 'ErGw1AZ' | 'ErGw2AZ' | 'ErGw3AZ' | 'ErGwScale'?

  @description('Optional. Enable DNS forwarding through the ExpressRoute gateway.')
  enableDnsForwarding: bool?

  @description('Optional. Enable private IP support on the ExpressRoute gateway.')
  enablePrivateIpAddress: bool?

  @description('Optional. Availability zones for the ExpressRoute gateway public IP addresses.')
  publicIpZones: array?

  @description('Optional. Lock settings for the ExpressRoute gateway.')
  lock: lockType?
}
