using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param landingZonesOnlineConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: '{{management_group_id_prefix}}{{management_group_online_id||online}}{{management_group_id_postfix}}'
  managementGroupParentId: '{{management_group_id_prefix}}{{management_group_landingzones_id||landingzones}}{{management_group_id_postfix}}'
  managementGroupIntermediateRootName: '{{management_group_id_prefix}}{{management_group_int_root_id||alz}}{{management_group_id_postfix}}'
  managementGroupDisplayName: 'Online'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: []
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 10
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 10
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 10
  waitForConsistencyCounterBeforePolicyAssignments: 40
  waitForConsistencyCounterBeforeRoleAssignments: 40
  waitForConsistencyCounterBeforeSubPlacement: 10
}

// Currently no policy assignments for online landing zones
// When policies are added, specify parameter overrides here
param parPolicyAssignmentParameterOverrides = {
  // No policy assignments in platform-security currently
}
