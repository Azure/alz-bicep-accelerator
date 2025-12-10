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
param parHubNetworkingResourceGroupNamePrefix = '{{resource_group_hub_networking_name_prefix||rg-alz-conn-}}'
param parDnsResourceGroupNamePrefix = '{{resource_group_dns_name_prefix||rg-alz-dns-}}'
param parDnsPrivateResolverResourceGroupNamePrefix = '{{resource_group_private_dns_resolver_name_prefix||rg-alz-dnspr-}}'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-alz-${parLocations[0]}'
    location: parLocations[0]
    addressPrefixes: [
      '10.0.0.0/22'
    ]
    enablePeering: true
    dnsServers: []
    routes: []
    peeringSettings: [
      {
        remoteVirtualNetworkName: 'vnet-alz-${parLocations[1]}'
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
      }
    ]
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.0.64/26'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.0.128/27'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.0.0/26'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.0.0.192/26'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '10.0.0.160/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '10.0.0.176/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
    azureFirewallSettings: {
      enableAzureFirewall: true
      azureFirewallName: 'afw-alz-${parLocations[0]}'
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-afw-alz-${parLocations[0]}'
      }
      managementIPAddressObject: {
        name: 'pip-afw-mgmt-alz-${parLocations[0]}'
      }
    }
    bastionHostSettings: {
      enableBastion: true
      bastionHostSettingsName: 'bas-alz-${parLocations[0]}'
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
      enableVirtualNetworkGateway: true
      name: 'vgw-alz-${parLocations[0]}'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
    }
    expressRouteGatewaySettings: {
      enableExpressRouteGateway: true
      name: 'ergw-alz-${parLocations[0]}'
    }
    privateDnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-alz-${parLocations[0]}'
      privateDnsZones: []
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: true
      name: 'ddos-alz-${parLocations[0]}'
    }
  }
  {
    name: 'vnet-alz-${parLocations[1]}'
    location: parLocations[1]
    addressPrefixes: [
      '10.1.0.0/22'
    ]
    enablePeering: true
    dnsServers: []
    routes: []
    peeringSettings: [
      {
        remoteVirtualNetworkName: 'vnet-alz-${parLocations[0]}'
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        useRemoteGateways: false
      }
    ]
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.1.0.64/26'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.1.0.128/27'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.1.0.0/26'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.1.0.192/26'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '10.1.0.160/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '10.1.0.176/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
    azureFirewallSettings: {
      enableAzureFirewall: true
      azureFirewallName: 'afw-alz-${parLocations[1]}'
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-afw-alz-${parLocations[1]}'
      }
      managementIPAddressObject: {
        name: 'pip-afw-mgmt-alz-${parLocations[1]}'
      }
    }
    bastionHostSettings: {
      enableBastion: true
      bastionHostSettingsName: 'bas-alz-${parLocations[1]}'
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
      enableVirtualNetworkGateway: true
      name: 'vgw-alz-${parLocations[1]}'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
    }
    expressRouteGatewaySettings: {
      enableExpressRouteGateway: true
      name: 'ergw-alz-${parLocations[1]}'
    }
    privateDnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-alz-${parLocations[1]}'
      privateDnsZones: [
        'privatelink.{regionName}.azurecontainerapps.io'
        'privatelink.{regionName}.kusto.windows.net'
        'privatelink.{regionName}.azmk8s.io'
        'privatelink.{regionName}.prometheus.monitor.azure.com'
        'privatelink.{regionCode}.backup.windowsazure.com'
      ]
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: true
      name: 'ddos-alz-${parLocations[1]}'
    }
  }
]

