using './virtual-network.bicep'

param parLocation = 'uksouth'
param parCompanyPrefix = 'alz'
param parHubNetworkName = '${parCompanyPrefix}-hub-${parLocation}'
param parHubNetworkAddressPrefix = '10.10.0.0/16'
param parSubnets = [
  {
    name: 'AzureBastionSubnet'
    ipAddressRange: '10.10.15.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'GatewaySubnet'
    ipAddressRange: '10.10.252.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'AzureFirewallSubnet'
    ipAddressRange: '10.10.254.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
  {
    name: 'AzureFirewallManagementSubnet'
    ipAddressRange: '10.10.253.0/24'
    networkSecurityGroupId: ''
    routeTableId: ''
  }
]
param parDnsServerIps = []
param parDdosEnabled = true
param parDdosProtectionPlanResourceId = ''


