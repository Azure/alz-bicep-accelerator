using './main.bicep'

// General Parameters
param parLocations = [
  'eastus2'
  'westus2'
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
      '10.20.0.0/16'
    ]
    enablePeering: true
    dnsServers: []
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
        addressPrefix: '10.20.0.0/24'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.20.254.0/24'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.20.255.0/24'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.20.253.0/24'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '10.20.4.0/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '10.20.4.16/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
    azureFirewallSettings: {
      enableAzureFirewall: true
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-fw-alz-${parLocations[0]}-01'
      }
      managementIPAddressObject: {
        name: 'pip-fw-mgmt-alz${parLocations[0]}-mgmt'
      }
      zones: [
        1
      ]
    }
    bastionHost: {
      enableBastion: true
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
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
    expressRouteGatewaySettings: {
      enableExpressRouteGateway: true
      skuName: 'ErGw1AZ'
      clusterMode: 'activePassiveNoBgp'
      adminState: 'Enabled'
      resiliencyModel: 'SingleHomed'
      publicIpZones: []
    }
    privateDnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
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
    }
  }
  {
    name: 'vnet-alz-${parLocations[1]}'
    location: parLocations[1]
    addressPrefixes: [
      '10.30.0.0/16'
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
        addressPrefix: '10.30.0.0/24'
      }
      {
        name: 'GatewaySubnet'
        addressPrefix: '10.30.254.0/24'
      }
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.30.255.0/24'
      }
      {
        name: 'AzureFirewallManagementSubnet'
        addressPrefix: '10.30.253.0/24'
      }
      {
        name: 'DNSPrivateResolverInboundSubnet'
        addressPrefix: '10.30.4.0/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
      {
        name: 'DNSPrivateResolverOutboundSubnet'
        addressPrefix: '10.30.4.16/28'
        delegation: 'Microsoft.Network/dnsResolvers'
      }
    ]
    azureFirewallSettings: {
      enableAzureFirewall: true
      azureSkuTier: 'Standard'
      publicIPAddressObject: {
        name: 'pip-fw-alz-${parLocations[1]}-01'
      }
      managementIPAddressObject: {
        name: 'pip-fw-${parLocations[1]}-mgmt'
      }
      zones: [
        1
      ]
    }
    bastionHost: {
      enableBastion: true
      skuName: 'Standard'
    }
    vpnGatewaySettings: {
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
    expressRouteGatewaySettings: {
      enableExpressRouteGateway: true
      skuName: 'ErGw1AZ'
      clusterMode: 'activePassiveNoBgp'
      adminState: 'Enabled'
      resiliencyModel: 'SingleHomed'
      publicIpZones: []
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
]
