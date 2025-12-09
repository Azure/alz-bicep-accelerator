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
    addressPrefix: '10.0.0.0/22'
    allowBranchToBranchTraffic: true
    preferredRoutingGateway: 'ExpressRoute'
    enableTelemetry: parEnableTelemetry
    azureFirewallSettings: {
      enableAzureFirewall: true
      name: 'afw-alz-${parLocations[0]}'
    }
    expressRouteGatewaySettings: {
      enabled: false
      name: 'ergw-alz-${parLocations[0]}'
      minScaleUnits: 1
      maxScaleUnits: 1
      allowNonVirtualWanTraffic: false
    }
    s2sVpnGatewaySettings: {
      name: 's2s-alz-${parLocations[0]}'
      enabled: false
      scaleUnit: 1
    }
    p2sVpnGatewaySettings: {
      name: 'p2s-alz-${parLocations[0]}'
      enabled: false
      scaleUnit: 1
      vpnServerConfiguration: {
        vpnAuthenticationTypes: ['AAD']
      }
      vpnClientAddressPool: {
        addressPrefixes: ['172.16.0.0/24']
      }
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: true
      name: 'ddos-alz-${parLocations[0]}'
      tags: {}
    }
    dnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-alz-${parLocations[0]}'
    }
    bastionSettings: {
      enableBastion: true
      name: 'bas-alz-${parLocations[0]}'
      sku: 'Standard'
    }
    sideCarVirtualNetwork: {
      name: 'vnet-sidecar-alz-${parLocations[0]}'
      sidecarVirtualNetworkEnabled: true
      addressPrefixes: [
        '10.0.4.0/22'
      ]
    }
  }
  {
    hubName: 'vhub-alz-${parLocations[1]}'
    location: parLocations[1]
    addressPrefix: '10.1.0.0/22'
    allowBranchToBranchTraffic: true
    preferredRoutingGateway: 'ExpressRoute'
    enableTelemetry: parEnableTelemetry
    azureFirewallSettings: {
      enableAzureFirewall: true
      name: 'afw-alz-${parLocations[1]}'
    }
    expressRouteGatewaySettings: {
      enabled: false  // Deploy based on connectivity needs
      name: 'ergw-alz-${parLocations[1]}'
      minScaleUnits: 1
      maxScaleUnits: 1
      allowNonVirtualWanTraffic: false
    }
    s2sVpnGatewaySettings: {
      name: 's2s-alz-${parLocations[1]}'
      enabled: false
      scaleUnit: 1  // Baseline scale unit
    }
    p2sVpnGatewaySettings: {
      name: 'p2s-alz-${parLocations[1]}'
      enabled: false
      scaleUnit: 1  // Baseline scale unit
      vpnServerConfiguration: {
        vpnAuthenticationTypes: ['AAD']  // Common auth type
      }
      vpnClientAddressPool: {
        addressPrefixes: ['172.16.1.0/24']  // Example client address pool (different from Hub 1)
      }
    }
    ddosProtectionPlanSettings: {
      enableDdosProtection: true
      name: 'ddos-alz-${parLocations[1]}'
      tags: {}
    }
    dnsSettings: {
      enablePrivateDnsZones: true
      enableDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-alz-${parLocations[1]}'
    }
    bastionSettings: {
      enableBastion: true
      name: 'bas-alz-${parLocations[1]}'
      sku: 'Standard'
    }
    sideCarVirtualNetwork: {
      name: 'vnet-sidecar-alz-${parLocations[1]}'
      sidecarVirtualNetworkEnabled: true
      addressPrefixes: [
        '10.1.4.0/22'
      ]
    }
  }
]


