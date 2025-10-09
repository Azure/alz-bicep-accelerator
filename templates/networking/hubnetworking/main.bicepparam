using './main.bicep'

param parGlobalResourceLock = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}
param parDdosLock = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}
param parTags = {}
param parTelemetryOptOut = false

param hubNetworks = [
  {
    hubName: 'hub1'
    location: 'eastus'
    vpnGatewayEnabled: false
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    enablePrivateDnsZones: true
    privateDnsZones: [
      'privatelink.azconfig.io'
  'privatelink.azure-api.net'
  'privatelink.azure-automation.net'
    ]
    enableAzureFirewall: false
    enableBastion: false
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
    hubName: 'hub2'
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
