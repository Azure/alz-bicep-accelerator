using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param sandboxConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: '{{intermediate_root_management_group_id}}'
  managementGroupParentId: '{{root_parent_management_group_id}}'
  managementGroupDisplayName: 'Test'
}
