using './main.bicep'

extends '../../root.bicepparam'

//Resource Group Parameters
param parVirtualWanResourceGroupName = 'rg-vwan-alz-${parLocations[0]}'
param parDnsResourceGroupName = 'rg-dns-alz-${parLocations[0]}'
param parDnsPrivateResolverResourceGroupName = 'rg-dnspr-alz-${parLocations[0]}'

// Virtual WAN Parameters
param vwan = {
  name: 'vwan-alz-${parLocations[0]}'
  location: parLocations[0]
  allowBranchToBranchTraffic: true
  type: 'Standard'
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

    ddosProtectionPlanSettings:{
      enableDDosProtection: true
      name: 'ddos-alz-${parLocations[0]}'
      tags: {}
    }
    virtualNetworkGatewayConfig: {
      enableVirtualNetworkGateway: true
      gatewayType: 'ExpressRoute'
      publicIpZones: [
        1
        2
        3
      ]
      skuName: 'ErGw1AZ'
      vpnMode: 'activeActiveBgp'
      vpnType: 'RouteBased'
    }
    azureFirewallSettings: {
      enableAzureFirewall: true
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
    enableTelemetry: parEnableTelemetry
  }
  {
    hubName: 'vhub-alz-${parLocations[1]}'
    location: parLocations[1]
    addressPrefix: '10.200.0.0/23'
    allowBranchToBranchTraffic: true
    azureFirewallSettings: {
      enableAzureFirewall: true
    }
    dnsSettings: {
      enablePrivateDnsZones: false
      enableDnsPrivateResolver: false
    }
    sideCarVirtualNetwork: {
      name: 'vnet-sidecar-alz-${parLocations[1]}'
      sidecarVirtualNetworkEnabled: true
      addressPrefixes: [
        '20.100.1.0/24'
      ]
    }
    enableTelemetry: parEnableTelemetry
  }
]

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
