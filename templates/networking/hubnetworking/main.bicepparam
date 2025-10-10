using './main.bicep'

// Resource Group Parameters
param parHubNetworkingResourceGroupName = 'rg-hubnetworking-alz-${hubNetworks[0].location}'
param parDnsResourceGroupName = 'rg-dns-alz-${hubNetworks[0].location}'

// Hub Networking Parameters
param hubNetworks = [
  {
    hubName: 'vnet-alz-eastus'
    location: 'eastus'
    vpnGatewayEnabled: false
    addressPrefixes: [
      '10.0.0.0/16'
    ]

    enablePrivateDnsZones: true
    privateDnsZones: []
    azureFirewallSettings:{
      azureSkuTier: 'Standard'
    }
    enableAzureFirewall: true
    enableBastion: true
    bastionHost: {
      skuName: 'Standard'
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
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.20.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.0.254.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.0.253.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
    ]
  }
  {
    hubName: 'vnet-alz-westus'
    location: 'westus'
    vpnGatewayEnabled: false
    addressPrefixes: [
      '20.0.0.0/16'
    ]
    enableAzureFirewall: true
    enableBastion: false
    enablePeering: false
    dnsServers: []
    routes: []
    azureFirewallSettings: {
      azureSkuTier: 'Basic'
      location: 'westus'
      zones: []
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '20.0.15.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '20.0.252.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '20.0.254.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '20.0.253.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
    ]
  }
]

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator Management and Logging Module.'
}
param parTags = {}
param parEnableTelemetry = true
