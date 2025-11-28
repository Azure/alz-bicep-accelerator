using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param sandboxConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'alz-{{unique_postfix}}'
  managementGroupParentId: '{{root_parent_management_group_id}}'
  managementGroupDisplayName: 'Test'
}
