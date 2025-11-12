using './main.bicep'

// Resource Group Parameters
param parHubNetworkingResourceGroupName = 'rg-alz-conn-${parLocations[0]}'
param parDnsResourceGroupName = 'rg-alz-dns-${parLocations[0]}'
param parDnsPrivateResolverResourceGroupName = 'rg-alz-dnspr-${parLocations[0]}'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-alz-${parLocations[0]}'
    location: parLocations[0]
    vpnGatewayEnabled: true
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    privateDnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
      privateDnsZones: []
    }
    azureFirewallSettings: {
      azureSkuTier: 'Standard'
    }
    enableAzureFirewall: true
    enableBastion: true
    bastionHost: {
      skuName: 'Standard'
    }
    enablePeering: true
    dnsServers: []
    routes: []
    virtualNetworkGatewayConfig: {
      gatewayType: 'Vpn'
      publicIpZones: [
        1
        2
        3
      ]
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      asn: 65515
      vpnType: 'RouteBased'
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.15.0/24'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.20.0/24'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.254.0/24'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.0.253.0/24'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '10.0.4.0/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '10.0.4.16/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
  }
  {
    name: 'vnet-alz-${parLocations[1]}'
    location: parLocations[1]
    vpnGatewayEnabled: false
    addressPrefixes: [
      '20.0.0.0/16'
    ]
    enableAzureFirewall: false
    enableBastion: false
    enablePeering: false
    privateDnsSettings: {
      enableDnsPrivateResolver: false
      enablePrivateDnsZones: false
    }
    dnsServers: []
    routes: []
    azureFirewallSettings: {
      azureSkuTier: 'Basic'
      location: parLocations[1]
      zones: []
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '20.0.15.0/24'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '20.0.20.0/24'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '20.0.254.0/24'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '20.0.253.0/24'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '20.0.4.0/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '20.0.4.16/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
  }
]

// General Parameters
param parLocations = [
  'eastus'
  'westus'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = true
