using 'main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = true

// Resource Group Parameters
param parResourceGroup = 'rg-alz-test-${parLocations[0]}-{{unique_postfix}}'
