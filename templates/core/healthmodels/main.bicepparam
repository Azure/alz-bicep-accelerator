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
// Microsoft.CloudHealth supports fewer regions than the rest of the platform, so this
// location is configured separately.
param parHealthModelName = '{{health_model_platform_name||ahm-alz-platform}}'
param parHealthModelLocation = '{{health_model_location||swedencentral}}'

// Discovery Identity Parameters
param parDiscoveryIdentityName = 'mi-ahm-alz-${parLocations[0]}'

param parManagementSubscriptionId = '{{management_subscription_id}}'
param parConnectivitySubscriptionId = '{{connectivity_subscription_id}}'
param parIdentitySubscriptionId = '{{identity_subscription_id}}'
param parSecuritySubscriptionId = '{{security_subscription_id}}'
