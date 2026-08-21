using './main.bicep'

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
param parHealthModelResourceGroup = '{{resource_group_health_model_name_prefix||rg-alz-healthmodels}}-${parLocations[0]}'

// Health Model Parameters
// The health model location is chosen separately from the platform locations because the
// Microsoft.CloudHealth resource provider offers health models in a smaller set of regions.
param parHealthModelName = '{{health_model_platform_name||ahm-alz-platform}}'
param parHealthModelLocation = '{{health_model_location||swedencentral}}'

// Discovery Identity Parameters
param parDiscoveryIdentityName = 'mi-ahm-alz-${parLocations[0]}'
