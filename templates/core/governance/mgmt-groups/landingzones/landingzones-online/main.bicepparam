using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param landingZonesOnlineConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'online'
  managementGroupParentId: 'landingzones'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Online'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: []
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 20
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 20
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 20
  waitForConsistencyCounterBeforePolicyAssignments: 20
  waitForConsistencyCounterBeforeRoleAssignment: 20
  waitForConsistencyCounterBeforeSubPlacement: 20
}

// Currently no policy assignments for online landing zones
// When policies are added, specify parameter overrides here
param parPolicyAssignmentParameterOverrides = {
  // No policy assignments in platform-security currently
}
