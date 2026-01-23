using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param testConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: '{{management_group_id_prefix}}{{management_group_int_root_id||alz}}{{management_group_id_postfix}}'
  managementGroupParentId: '{{root_parent_management_group_id}}'
  managementGroupDisplayName: '{{management_group_name_prefix}}{{management_group_int_root_name||Azure Landing Zones}}{{management_group_name_postfix}}'
}
