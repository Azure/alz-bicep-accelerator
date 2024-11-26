using './main.bicep'

param parLocation = 'eastus2'
param parCompanyPrefix = 'alz'
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
param alzNetworking = {
  networkType: 'hub-and-spoke'
}

param virtualWan = {
  name: 'alz-vwan'
  location: 'eastus2'
  allowBranchToBranchTraffic: true
  allowVnetToVnetTraffic: true
  disableVpnEncryption: false
  type: 'Standard'
}

param hubNetworks = [
  {
    hubName: 'hub1'
    location: 'eastus'
    vpnGatewayEnabled: true
    addressPrefixes: [
      '20.0.0.0/16'
    ]
    enableAzureFirewall: true
    enableBastion: true
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
        addressPrefix: '20.0.15.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '20.0.20.0/24'
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
  {
    hubName: 'hub2'
    location: 'uksouth'
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    enableAzureFirewall: false
    enablePeering: false
    azureFirewallSettings: {
      azureSkuTier: 'Basic'
      location: 'uksouth'
    }
    vpnGatewayEnabled: false
    enableBastion: false
    dnsServers: []
    routes: []
    subnets: [
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.0.15.0/24'
        networkSecurityGroupId: ''
        routeTable: ''
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.0.252.0/24'
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
]
