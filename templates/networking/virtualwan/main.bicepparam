using './main.bicep'


//Resource Group Parameters
param parVirtualWanResourceGroupName = 'rg-virtualwan-alz-${virtualWan.location}'
param parDnsResourceGroupName = 'rg-dns-alz-${virtualWan.location}'


// Virtual WAN Parameters
param virtualWan = {
  name: 'vwan-alz-eastus'
  location: 'eastus'
  allowBranchToBranchTraffic: true
  type: 'Standard'
  lock: {
    kind: 'None'
    name: 'vwan-lock'
    notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
  }
}

// Virtual WAN Hub Parameters
param virtualWanHubs = [
  {
    hubName: 'hub1'
    location: 'eastus'
    addressPrefix: '10.100.0.0/23'
    allowBranchToBranchTraffic: true
    ddosProtectionPlanSettings:{
      enableDDosProtection: true
      name: 'ddos-eastus'
      tags: {}
    }
    azureFirewallSettings: {
      enableAzureFirewall: true
    }
    enableTelemetry: parEnableTelemetry
  }
  {
    hubName: 'hub2'
    location: 'westus2'
    addressPrefix: '10.200.0.0/23'
    allowBranchToBranchTraffic: true
    azureFirewallSettings: {
      enableAzureFirewall: true
    }
    enableTelemetry: parEnableTelemetry
  }
]

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator Management and Logging Module.'
}
param parTags = {}
param parEnableTelemetry = true
