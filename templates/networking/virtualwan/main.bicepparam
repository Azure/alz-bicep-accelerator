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
param parVirtualWanResourceGroupNamePrefix = '{{resource_group_virtual_wan_name_prefix||rg-alz-conn-}}'
param parDnsResourceGroupNamePrefix = '{{resource_group_dns_name_prefix||rg-alz-dns-}}'
param parDnsPrivateResolverResourceGroupNamePrefix = '{{resource_group_private_dns_resolver_name_prefix||rg-alz-dnspr-}}'

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
    azureFirewallSettings: {
      deployAzureFirewall: true
      name: 'afw-alz-${parLocations[0]}'
    }
    expressRouteGatewaySettings: {
      deployExpressRouteGateway: true
      name: 'ergw-alz-${parLocations[0]}'
      minScaleUnits: 1
      maxScaleUnits: 1
      allowNonVirtualWanTraffic: false
    }
    s2sVpnGatewaySettings: {
      deployS2sVpnGateway: false
      name: 's2s-alz-${parLocations[0]}'
      scaleUnit: 1
    }
    p2sVpnGatewaySettings: {
      deployP2sVpnGateway: false
      name: 'p2s-alz-${parLocations[0]}'
      scaleUnit: 1
      vpnServerConfiguration: {
        vpnAuthenticationTypes: ['AAD']
      }
      vpnClientAddressPool: {
        addressPrefixes: ['172.16.0.0/24']
      }
    }
    ddosProtectionPlanSettings: {
      deployDdosProtectionPlan: true
      name: 'ddos-alz-${parLocations[0]}'
      tags: {}
    }
    dnsSettings: {
      deployPrivateDnsZones: true
      deployDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-alz-${parLocations[0]}'
    }
    bastionSettings: {
      deployBastion: true
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
    azureFirewallSettings: {
      deployAzureFirewall: true
      name: 'afw-alz-${parLocations[1]}'
    }
    expressRouteGatewaySettings: {
      deployExpressRouteGateway: true
      name: 'ergw-alz-${parLocations[1]}'
      minScaleUnits: 1
      maxScaleUnits: 1
      allowNonVirtualWanTraffic: false
    }
    s2sVpnGatewaySettings: {
      deployS2sVpnGateway: false
      name: 's2s-alz-${parLocations[1]}'
      scaleUnit: 1
    }
    p2sVpnGatewaySettings: {
      deployP2sVpnGateway: false
      name: 'p2s-alz-${parLocations[1]}'
      scaleUnit: 1
      vpnServerConfiguration: {
        vpnAuthenticationTypes: ['AAD']
      }
      vpnClientAddressPool: {
        addressPrefixes: ['172.16.1.0/24']
      }
    }
    ddosProtectionPlanSettings: {
      deployDdosProtectionPlan: false
    }
    dnsSettings: {
      deployPrivateDnsZones: true
      deployDnsPrivateResolver: true
      privateDnsResolverName: 'dnspr-alz-${parLocations[1]}'
    }
    bastionSettings: {
      deployBastion: true
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


