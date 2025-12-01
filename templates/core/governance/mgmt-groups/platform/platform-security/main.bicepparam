using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param platformSecurityConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'security'
  managementGroupParentId: 'platform'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Security'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: ['{{security_subscription_id}}']
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 20
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 20
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 20
  waitForConsistencyCounterBeforePolicyAssignments: 20
  waitForConsistencyCounterBeforeRoleAssignment: 20
  waitForConsistencyCounterBeforeSubPlacement: 20
}

// Only specify the parameters you want to override - others will use defaults from JSON files
param parPolicyAssignmentParameterOverrides = {
  // No policy assignments in platform-security currently
}
