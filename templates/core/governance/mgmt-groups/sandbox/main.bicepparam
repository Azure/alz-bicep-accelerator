using './main.bicep'

param sandboxConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'sandbox'
  managementGroupParentId: 'int-root'
  managementGroupDisplayName: 'Sandbox'
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
  waitForConsistencyCounterBeforePolicyAssignments: 10
  waitForConsistencyCounterBeforeRoleAssignment: 10
  waitForConsistencyCounterBeforeSubPlacement: 10
}
param parLocations = [
  'eastus'
  'westus'
]
param parEnableTelemetry = true
