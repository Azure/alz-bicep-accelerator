using './main.bicep'

// General Parameters
param parLocations = [
  '{{location-0}}'
  '{{location-1}}'
]
param parEnableTelemetry = true

param sandboxConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'sandbox'
  managementGroupParentId: 'alz'
  managementGroupDisplayName: 'Sandbox'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: []
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 30
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 30
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 30
  waitForConsistencyCounterBeforePolicyAssignments: 30
  waitForConsistencyCounterBeforeRoleAssignment: 30
  waitForConsistencyCounterBeforeSubPlacement: 30
}

// Only specify the parameters you want to override - others will use defaults from JSON files
param parPolicyAssignmentParameterOverrides = {
  // Currently no common parameter overrides needed, but can be added here
}
