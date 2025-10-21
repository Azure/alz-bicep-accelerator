using './main.bicep'

// Resource Group Parameters
param parHubNetworkingResourceGroupName = 'rg-hubnetworking-alz-${parLocations[0]}'
param parDnsResourceGroupName = 'rg-dns-alz-${parLocations[0]}'
param parPrivateDnsResolverResourceGroupName = 'rg-dnsresolver-alz-${parLocations[0]}'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-alz-${parLocations[0]}'
    location: parLocations[0]
    vpnGatewayEnabled: false
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    privateDnsSettings: {
      enablePrivateDnsZones: true
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
    bastionNsg: {
      name: 'nsg-AzureBastionSubnet'
    }
    enablePeering: false
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
        name: 'PrivateDNSResolverInboundSubnet'
        addressPrefix: '10.0.4.0/28'
      }
      {
        name: 'PrivateDNSResolverOutboundSubnet'
        addressPrefix: '10.0.4.16/28'
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
    dnsServers: []
    routes: []
    azureFirewallSettings: {
      azureSkuTier: 'Basic'
      location: parLocations[1]
      zones: []
    }
    subnets: [
      {
        name: 'snet-bas-alz'
        addressPrefix: '20.0.15.0/24'
      }
      {
        name: 'snet-vgw-alz'
        addressPrefix: '20.0.20.0/24'
      }
      {
        name: 'snet-dnspr-in-alz'
        addressPrefix: '20.0.4.0/28'
      }
      {
        name: 'snet-dnspr-out-alz'
        addressPrefix: '20.0.4.16/28'
      }
      {
        name: 'snet-fw-alz'
        addressPrefix: '20.0.254.0/24'
      }
      {
        name: 'snet-fw-mgmt-alz'
        addressPrefix: '20.0.253.0/24'
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
  notes: 'This lock was created by the ALZ Bicep Accelerator Management and Logging Module.'
}
param parTags = {}
param parEnableTelemetry = true
