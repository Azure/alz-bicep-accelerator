using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parTags = {}
param parEnableTelemetry = true
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}

// Resource Group Parameters
param parVirtualWanResourceGroupNamePrefix = 'rg-alz-conn'
param parDnsResourceGroupNamePrefix = 'rg-alz-dns'
param parDnsPrivateResolverResourceGroupNamePrefix = 'rg-alz-dnspr'

// Virtual WAN Parameters
param vwan = {
  name: 'vwan-alz-${parLocations[0]}'
  location: parLocations[0]
  type: 'Standard'
  allowBranchToBranchTraffic: true
  lock: {
    kind: 'None'
    name: 'vwan-lock'
    notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
  }
}

// Virtual WAN Hub Parameters
param vwanHubs = [
  {
    hubName: 'vhub-alz-${parLocations[0]}'
    location: parLocations[0]
    addressPrefix: '10.100.0.0/23'
    allowBranchToBranchTraffic: true
    preferredRoutingGateway: 'ExpressRoute'
    enableTelemetry: parEnableTelemetry
    azureFirewallSettings: {
      enableAzureFirewall: true
    }
    virtualNetworkGatewaySettings: {
      enableVirtualNetworkGateway: true
      gatewayType: 'ExpressRoute'
      skuName: 'ErGw1AZ'
      vpnType: 'RouteBased'
      vpnMode: 'activeActiveBgp'
      publicIpZones: [
        1
        2
        3
      ]
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: true
      name: 'ddos-alz-${parLocations[0]}'
      tags: {}
    }
    dnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
    }
    sideCarVirtualNetwork: {
      name: 'vnet-sidecar-alz-${parLocations[0]}'
      sidecarVirtualNetworkEnabled: true
      addressPrefixes: [
        '10.100.1.0/24'
      ]
    }
  }
  {
    hubName: 'vhub-alz-${parLocations[1]}'
    location: parLocations[1]
    addressPrefix: '10.200.0.0/23'
    allowBranchToBranchTraffic: true
    preferredRoutingGateway: 'ExpressRoute'
    enableTelemetry: parEnableTelemetry
    azureFirewallSettings: {
      enableAzureFirewall: true
    }
    virtualNetworkGatewaySettings: {
      enableVirtualNetworkGateway: false
      gatewayType: 'ExpressRoute'
      skuName: 'ErGw1AZ'
      vpnType: 'RouteBased'
      vpnMode: 'activeActiveBgp'
      publicIpZones: []
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: false
      name: 'ddos-alz-${parLocations[1]}'
      tags: {}
    }
    dnsSettings: {
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
    sideCarVirtualNetwork: {
      name: 'vnet-sidecar-alz-${parLocations[1]}'
      sidecarVirtualNetworkEnabled: true
      addressPrefixes: [
        '10.200.1.0/24'
      ]
    }
  }
]
