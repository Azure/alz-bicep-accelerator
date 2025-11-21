using './main.bicep'

// General Parameters
param parLocations = [
  '{{location-0}}'
  '{{location-1}}'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = true

// Resource Group Parameters
param parHubNetworkingResourceGroupNamePrefix = 'rg-alz-conn'
param parDnsResourceGroupNamePrefix = 'rg-alz-dns'
param parDnsPrivateResolverResourceGroupNamePrefix = 'rg-alz-dnspr'

// Hub Networking Parameters
param hubNetworks = [
  {
    name: 'vnet-alz-${parLocations[0]}'
    location: parLocations[0]
    addressPrefixes: [
      '10.0.0.0/16'
    ]
    enablePeering: true
    dnsServers: []
    routes: []
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
    azureFirewallSettings: {
      enableAzureFirewall: true
      azureSkuTier: 'Standard'
    }
    bastionHost: {
      enableBastion: true
      skuName: 'Standard'
    }
    virtualNetworkGatewaySettings: {
      enableVirtualNetworkGateway: true
      gatewayType: 'Vpn'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
      asn: 65515
      publicIpZones: [
        1
        2
        3
      ]
    }
    privateDnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
      privateDnsZones: []
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: true
    }
  }
  {
    name: 'vnet-alz-${parLocations[1]}'
    location: parLocations[1]
    addressPrefixes: [
      '20.0.0.0/16'
    ]
    enablePeering: false
    dnsServers: []
    routes: []
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
    azureFirewallSettings: {
      enableAzureFirewall: false
      azureSkuTier: 'Standard'
    }
    bastionHost: {
      enableBastion: false
      skuName: 'Basic'
    }
    virtualNetworkGatewaySettings: {
      enableVirtualNetworkGateway: false
      gatewayType: 'Vpn'
      skuName: 'VpnGw1AZ'
      vpnMode: 'activePassiveNoBgp'
    }
    privateDnsSettings: {
      enablePrivateDnsZones: false
      enableDnsPrivateResolver: false
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: false
    }
  }
]
