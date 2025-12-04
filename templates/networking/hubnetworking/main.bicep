metadata name = 'ALZ Bicep Accelerator - Hub Networking'
metadata description = 'Used to deploy hub networking resources for ALZ.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('Required. The prefix for the Resource Group names. Will be combined with location to create: {prefix}-{location}. Can be overridden by parHubNetworkingResourceGroupNameOverrides.')
param parHubNetworkingResourceGroupNamePrefix string = 'rg-alz-conn'

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of locations in parLocations.')
param parHubNetworkingResourceGroupNameOverrides array = []

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

@description('Required. The prefix for the DNS Resource Group names. Will be combined with location to create: {prefix}-{location}. Can be overridden by parDnsResourceGroupNameOverrides.')
param parDnsResourceGroupNamePrefix string = 'rg-alz-dns'

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of locations in parLocations.')
param parDnsResourceGroupNameOverrides array = []

@description('Required. The prefix for the Private DNS Resolver Resource Group names. Will be combined with location to create: {prefix}-{location}. Can be overridden by parDnsPrivateResolverResourceGroupNameOverrides.')
param parDnsPrivateResolverResourceGroupNamePrefix string = 'rg-alz-dnspr'

@description('Optional. Array of complete resource group names to override the default naming. If provided, must match the number of locations in parLocations.')
param parDnsPrivateResolverResourceGroupNameOverrides array = []

// Hub Networking Parameters
@description('Required. The hub virtual networks to create.')
param hubNetworks hubVirtualNetworkType

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
  'eastus'
  'westus'
]

@description('Optional. Tags to be applied to all resources.')
param parTags object = {}

@description('Optional. Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Variables
//========================================

// Compute actual resource group names (either from override arrays or generated from prefix + location)
var hubResourceGroupNames = [for (location, i) in parLocations: empty(parHubNetworkingResourceGroupNameOverrides) ? '${parHubNetworkingResourceGroupNamePrefix}-${location}' : parHubNetworkingResourceGroupNameOverrides[i]]
var dnsResourceGroupNames = [for (location, i) in parLocations: empty(parDnsResourceGroupNameOverrides) ? '${parDnsResourceGroupNamePrefix}-${location}' : parDnsResourceGroupNameOverrides[i]]
var dnsPrivateResolverResourceGroupNames = [for (location, i) in parLocations: empty(parDnsPrivateResolverResourceGroupNameOverrides) ? '${parDnsPrivateResolverResourceGroupNamePrefix}-${location}' : parDnsPrivateResolverResourceGroupNameOverrides[i]]
var hubAzureFirewallRecommendedZones = [for hub in hubNetworks: json(format('[{0}]', join(pickZones('Microsoft.Network', 'azureFirewalls', hub.location), ',')))]
var hubVpnGatewayRecommendedPublicIpZones = [for hub in hubNetworks: json(format('[{0}]', join(pickZones('Microsoft.Network', 'publicIPAddresses', hub.location), ',')))]
var hubExpressRouteGatewayRecommendedPublicIpZones = [for hub in hubNetworks: json(format('[{0}]', join(pickZones('Microsoft.Network', 'publicIPAddresses', hub.location), ',')))]


//========================================
// Resources Groups
//========================================

module modHubNetworkingResourceGroups 'br/public:avm/res/resources/resource-group:0.4.2' = [
  for (location, i) in parLocations: {
    name: 'modHubResourceGroup-${i}-${uniqueString(parHubNetworkingResourceGroupNamePrefix, location)}'
    scope: subscription()
    params: {
      name: hubResourceGroupNames[i]
      location: location
      lock: parGlobalResourceLock ?? parResourceGroupLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module modDnsResourceGroups 'br/public:avm/res/resources/resource-group:0.4.2' = [
  for (location, i) in parLocations: if (length(filter(hubNetworks, hub => hub.location == location && hub.privateDnsSettings.enablePrivateDnsZones)) > 0) {
    name: 'modDnsResourceGroup-${i}-${uniqueString(parDnsResourceGroupNamePrefix, location)}'
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
  for (location, i) in parLocations: if (length(filter(hubNetworks, hub => hub.location == location && hub.privateDnsSettings.enableDnsPrivateResolver)) > 0) {
    name: 'modPrivateDnsResolverResourceGroup-${i}-${uniqueString(parDnsPrivateResolverResourceGroupNamePrefix, location)}'
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

//=====================
// Hub Networking
//=====================
module resHubNetwork 'br/public:avm/ptn/network/hub-networking:0.5.0' = [
  for (hub, i) in hubNetworks: {
    name: 'hubNetwork-${hub.name}-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[indexOf(parLocations, hub.location)])
    dependsOn: [
      resBastionNsg[i]
      modHubNetworkingResourceGroups
    ]
    params: {
      hubVirtualNetworks: {
        '${hub.name}': {
          addressPrefixes: hub.addressPrefixes
          dnsServers: hub.?dnsServers ?? null
          enablePeering: hub.enablePeering
          peeringSettings: hub.enablePeering ? hub.?peeringSettings : null
          ddosProtectionPlanResourceId: hub.?ddosProtectionPlanResourceId ?? null
          enableBastion: hub.bastionHost.enableBastion
          vnetEncryption: hub.?vnetEncryption ?? false
          location: hub.location
          routes: hub.?routes ?? null
          routeTableName: hub.?routeTableName ?? null
          bastionHost: hub.bastionHost.enableBastion
            ? {
                bastionHostName: hub.?bastionHost.?bastionHostName ?? 'bas-alz-${hub.location}'
                skuName: hub.?bastionHost.?skuName ?? 'Standard'
              }
            : null
          vnetEncryptionEnforcement: hub.?vnetEncryptionEnforcement ?? 'AllowUnencrypted'
          enableAzureFirewall: hub.azureFirewallSettings.enableAzureFirewall
          azureFirewallSettings: hub.azureFirewallSettings.enableAzureFirewall
            ? {
                azureFirewallName: hub.?azureFirewallSettings.?azureFirewallName
                additionalPublicIpConfigurations: hub.?azureFirewallSettings.?additionalPublicIpConfigurations
                applicationRuleCollections: hub.?azureFirewallSettings.?applicationRuleCollections
                azureSkuTier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
                firewallPolicyId: hub.?azureFirewallSettings.?firewallPolicyId ?? resFirewallPolicy[i].?outputs.resourceId
                managementIPAddressObject: hub.?azureFirewallSettings.?managementIPAddressObject
                managementIPResourceID: hub.?azureFirewallSettings.?managementIPResourceID
                natRuleCollections: hub.?azureFirewallSettings.?natRuleCollections
                networkRuleCollections: hub.?azureFirewallSettings.?networkRuleCollections
                publicIPAddressObject: hub.?azureFirewallSettings.?publicIPAddressObject ?? (!empty(hub.?azureFirewallSettings.?publicIPResourceID ?? '')
                  ? null
                  : {
                      name: '${hub.name}-azfirewall-pip-${hub.location}'
                    })
                publicIPResourceID: hub.?azureFirewallSettings.?publicIPResourceID
                roleAssignments: hub.?azureFirewallSettings.?roleAssignments
                threatIntelMode: (hub.?azureFirewallSettings.?azureSkuTier == 'Standard')
                  ? 'Alert'
                  : hub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
                zones: hub.?azureFirewallSettings.?zones ?? hubAzureFirewallRecommendedZones[i]
                lock: parGlobalResourceLock ?? hub.?azureFirewallSettings.?lock
                tags: parTags
              }
            : null
          subnets: [
            for subnet in hub.subnets: !empty(subnet)
              ? {
                  name: subnet.name
                  addressPrefix: subnet.addressPrefix
                  delegations: (empty(subnet.?delegation ?? null) || subnet.?delegation == 'Microsoft.Network/dnsResolvers')
                    ? null
                    : [
                        {
                          name: subnet.?delegation ?? null
                          properties: {
                            serviceName: subnet.?delegation ?? null
                          }
                        }
                      ]
                  networkSecurityGroupResourceId: (subnet.?name == 'AzureBastionSubnet' && hub.bastionHost.enableBastion)
                    ? resBastionNsg[i].?outputs.resourceId
                    : subnet.?networkSecurityGroupId ?? null
                  routeTable: subnet.?routeTable ?? null
                }
              : null
          ]
          lock: parGlobalResourceLock ?? hub.?lock
          tags: parTags
          enableTelemetry: parEnableTelemetry
        }
      }
    }
  }
]

//=====================
// Network Security
//=====================
module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.2' = [
  for (hub, i) in hubNetworks: if (hub.ddosProtectionPlanSettings.enableDdosProtection) {
    name: 'ddosPlan-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.?ddosProtectionPlanResourceId ?? '',hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[indexOf(parLocations, hub.location)])
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

module resFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.3' = [
  for (hub, i) in hubNetworks: if (hub.azureFirewallSettings.enableAzureFirewall && empty(hub.?azureFirewallSettings.?firewallPolicyId)) {
    name: 'firewallPolicy-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.name,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[indexOf(parLocations, hub.location)])
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
        : hub.?azureFirewallSettings.?dnsProxyEnabled
      servers: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? null
        : hub.?azureFirewallSettings.?firewallDnsServers
      lock: parGlobalResourceLock ?? hub.?azureFirewallSettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resBastionNsg 'br/public:avm/res/network/network-security-group:0.5.2' = [
  for (hub, i) in hubNetworks: if (hub.bastionHost.enableBastion) {
    name: '${hub.name}-bastionNsg-${uniqueString(parHubNetworkingResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(hubResourceGroupNames[indexOf(parLocations, hub.location)])
    dependsOn: [
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?bastionHost.?bastionNsgName ?? 'nsg-bas-alz-${hub.location}'
      location: hub.location
      lock: parGlobalResourceLock ?? hub.?bastionHost.?bastionNsgLock
      securityRules: hub.?bastionHost.?bastionNsgSecurityRules ?? [
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
          name: 'AllowBastionHostCommunication'
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
            destinationPortRanges: hub.?bastionHost.?outboundSshRdpPorts ?? [
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
    scope: resourceGroup(hubResourceGroupNames[indexOf(parLocations, hub.location)])
    dependsOn: [
      resHubNetwork[i]
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?vpnGatewaySettings.?name ?? 'vgw-${toLower(hub.?vpnGatewaySettings.?gatewayType ?? 'vpn')}-${hub.location}'
      clusterSettings: {
        clusterMode: any(hub.?vpnGatewaySettings.?vpnMode)
        asn: hub.?vpnGatewaySettings.?asn ?? 65515
        customBgpIpAddresses: (hub.?vpnGatewaySettings.?vpnMode == 'activePassiveBgp' || hub.?vpnGatewaySettings.?vpnMode == 'activeActiveBgp')
          ? (hub.?vpnGatewaySettings.?customBgpIpAddresses)
          : null
      }
      location: hub.location
      gatewayType: hub.?vpnGatewaySettings.?gatewayType ?? 'Vpn'
      vpnType: hub.?vpnGatewaySettings.?vpnType ?? 'RouteBased'
      skuName: hub.?vpnGatewaySettings.?skuName ?? 'VpnGw1AZ'
      enableBgpRouteTranslationForNat: hub.?vpnGatewaySettings.?enableBgpRouteTranslationForNat ?? false
      enableDnsForwarding: hub.?vpnGatewaySettings.?enableDnsForwarding ?? false
      vpnGatewayGeneration: hub.?vpnGatewaySettings.?vpnGatewayGeneration ?? 'None'
      virtualNetworkResourceId: resHubNetwork[i]!.outputs.hubVirtualNetworks[0].resourceId
      domainNameLabel: hub.?vpnGatewaySettings.?domainNameLabel ?? []
      publicIpAvailabilityZones: hub.?vpnGatewaySettings.?skuName != 'Basic'
        ? hub.?vpnGatewaySettings.?publicIpZones ?? hubVpnGatewayRecommendedPublicIpZones[i]
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
    scope: resourceGroup(hubResourceGroupNames[indexOf(parLocations, hub.location)])
    dependsOn: [
      resHubNetwork[i]
      modHubNetworkingResourceGroups
    ]
    params: {
      name: hub.?expressRouteGatewaySettings.?name ?? 'ergw-${hub.location}'
      clusterSettings: {
        clusterMode: 'activePassiveNoBgp'
      }
      location: hub.location
      gatewayType: 'ExpressRoute'
      skuName: hub.?expressRouteGatewaySettings.?skuName ?? 'ErGw1AZ'
      enableDnsForwarding: hub.?expressRouteGatewaySettings.?enableDnsForwarding ?? false
      enablePrivateIpAddress: hub.?expressRouteGatewaySettings.?enablePrivateIpAddress ?? false
      virtualNetworkResourceId: resHubNetwork[i]!.outputs.hubVirtualNetworks[0].resourceId
      publicIpAvailabilityZones: hub.?expressRouteGatewaySettings.?publicIpZones ?? hubExpressRouteGatewayRecommendedPublicIpZones[i]
      lock: parGlobalResourceLock ?? hub.?expressRouteGatewaySettings.?lock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

// =====================
// DNS
// =====================
module resPrivateDnsZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.0' = [
  for (hub, i) in hubNetworks: if (hub.privateDnsSettings.enablePrivateDnsZones) {
    name: 'privateDnsZone-${hub.name}-${uniqueString(parDnsResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(dnsResourceGroupNames[indexOf(parLocations, hub.location)])
    dependsOn: [
      resHubNetwork
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
              hubResourceGroupNames[indexOf(parLocations, hub.location)],
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

module resDnsPrivateResolver 'br/public:avm/res/network/dns-resolver:0.5.5' = [
  for (hub, i) in hubNetworks: if (hub.privateDnsSettings.enableDnsPrivateResolver) {
    name: 'dnsResolver-${hub.name}-${uniqueString(parDnsPrivateResolverResourceGroupNamePrefix,hub.location)}'
    scope: resourceGroup(dnsPrivateResolverResourceGroupNames[indexOf(parLocations, hub.location)])
    dependsOn: [
      resHubNetwork[i]
      modPrivateDnsResolverResourceGroups
    ]
    params: {
      name: hub.?privateDnsSettings.?privateDnsResolverName ?? 'dnspr-alz-${hub.location}'
      location: hub.location
      virtualNetworkResourceId: resHubNetwork[i]!.outputs.hubVirtualNetworks[0].resourceId
      inboundEndpoints: hub.?privateDnsSettings.?inboundEndpoints ?? [
        {
          name: 'pip-dnspr-inbound-alz-${hub.location}'
          subnetResourceId: '${resHubNetwork[i]!.outputs.hubVirtualNetworks[0].resourceId}/subnets/DNSPrivateResolverInboundSubnet'
        }
      ]
      outboundEndpoints: hub.?privateDnsSettings.?outboundEndpoints ?? [
         {
          name: 'pip-dnspr-outbound-alz-${hub.location}'
          subnetResourceId: '${resHubNetwork[i]!.outputs.hubVirtualNetworks[0].resourceId}/subnets/DNSPrivateResolverOutboundSubnet'
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

type bastionHostType = {
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

  @description('Optional. The number of scale units for the Bastion host. Defaults to 4.')
  scaleUnits: int?

  @description('Optional. The SKU name of the Bastion host. Defaults to Standard.')
  skuName: 'Basic' | 'Developer' | 'Premium' | 'Standard'?

  @description('Optional. The name of the bastion host.')
  bastionHostName: string?

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

  @description('Optional. The location of the virtual network.')
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

  @description('Optional. The subnets of the virtual network.')
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
  bastionHost: bastionHostType
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

  @description('Optional. The location of the Azure Firewall. Defaults to the location of the resource group.')
  location: string?

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

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. Threat Intel mode.')
  threatIntelMode: ('Alert' | 'Deny' | 'Off')?

  @description('Optional. Availability zones for the Azure Firewall. Defaults to recommended zones for the hub location when not specified.')
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

  @description('Optional. Id of Network Security Group to associate with subnet.')
  networkSecurityGroupId: string?

  @description('Optional. Id of Route Table to associate with subnet.')
  routeTable: string?

  @description('Optional. Name of the delegation to create for the subnet.')
  delegation: string?
})[]

type vpnGatewaySettingsType = {
  @description('Required. Enable/Disable virtual network gateway deployment.')
  enableVirtualNetworkGateway: bool

  @description('Optional. The name of the virtual network gateway.')
  name: string?

  @description('Optional. The gateway type. Set to Vpn for VPN gateway or ExpressRoute for ExpressRoute gateway.')
  gatewayType: 'Vpn' | 'ExpressRoute'?

  @description('Required. The SKU name of the virtual network gateway. Choose based on throughput and feature requirements.')
  skuName:
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

  @description('Required. The VPN gateway configuration mode. Determines active/passive setup and BGP usage.')
  vpnMode: 'activeActiveBgp' | 'activeActiveNoBgp' | 'activePassiveBgp' | 'activePassiveNoBgp'

  @description('Optional. The VPN type. RouteBased is recommended for most scenarios.')
  vpnType: 'RouteBased' | 'PolicyBased'?

  @description('Optional. The VPN gateway generation. Generation2 provides better performance.')
  vpnGatewayGeneration: 'Generation1' | 'Generation2' | 'None'?

  @description('Optional. Enable BGP route translation for NAT scenarios.')
  enableBgpRouteTranslationForNat: bool?

  @description('Optional. Enable DNS forwarding through the VPN gateway.')
  enableDnsForwarding: bool?

  @description('Optional. The Autonomous System Number (ASN) for BGP configuration.')
  asn: int?

  @description('Optional. Custom BGP IP addresses for active-active BGP configurations.')
  customBgpIpAddresses: string[]?

  @description('Optional. Availability zones for the gateway public IP addresses. Defaults to recommended zones for the hub location when not specified.')
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
  skuName: 'ErGw1AZ' | 'ErGw2AZ' | 'ErGw3AZ' | 'ErGwScale'?

  @description('Optional. Enable DNS forwarding through the ExpressRoute gateway.')
  enableDnsForwarding: bool?

  @description('Optional. Enable private IP support on the ExpressRoute gateway.')
  enablePrivateIpAddress: bool?

  @description('Optional. Availability zones for the ExpressRoute gateway public IP addresses. Defaults to recommended zones for the hub location when not specified.')
  publicIpZones: array?

  @description('Optional. Lock settings for the ExpressRoute gateway.')
  lock: lockType?
}
