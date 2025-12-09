using './main-rbac.bicep'

param parLandingZonesManagementGroupName = '{{management_group_id_prefix}}{{management_group_landingzones_id||landingzones}}{{management_group_id_postfix}}'
param parPlatformManagementGroupName = '{{management_group_id_prefix}}{{management_group_platform_id||platform}}{{management_group_id_postfix}}'
param parEnableTelemetry = true
