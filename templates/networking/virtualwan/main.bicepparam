using './main.bicep'

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

param virtualWan = {
  name: 'alz-vwan'
  location: 'eastus'
  allowBranchToBranchTraffic: true
  allowVnetToVnetTraffic: true
  disableVpnEncryption: false
  type: 'Standard'
  lock: {
    kind: 'None'
    name: 'vwan-lock'
    notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
  }
  tags: {}
}

param virtualWanHubs = [
  {
    hubName: 'hub1'
    location: 'eastus'
    addressPrefix: '10.100.0.0/23'
    allowBranchToBranchTraffic: true
    vpnGatewayEnabled: true
    virtualNetworkGatewayConfig: {
      skuName: 'VpnGw1AZ'
      gatewayType: 'Vpn'
      vpnMode: 'activeActiveNoBgp'
    }
    enableAzureFirewall: true
    enableTelemetry: parTelemetryOptOut
  }
  {
    hubName: 'hub2'
    location: 'westus2'
    addressPrefix: '10.200.0.0/23'
    allowBranchToBranchTraffic: true
    vpnGatewayEnabled: true
    virtualNetworkGatewayConfig: {
      skuName: 'VpnGw1AZ'
      gatewayType: 'Vpn'
      vpnMode: 'activeActiveNoBgp'
    }
    enableAzureFirewall: true
    enableTelemetry: parTelemetryOptOut
  }
]
