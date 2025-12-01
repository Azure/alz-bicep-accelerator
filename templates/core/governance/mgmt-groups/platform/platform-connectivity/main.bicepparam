using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param platformConnectivityConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'connectivity'
  managementGroupParentId: 'platform'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Connectivity'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: ['{{connectivity_subscription_id}}']
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 20
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 20
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 20
  waitForConsistencyCounterBeforePolicyAssignments: 20
  waitForConsistencyCounterBeforeRoleAssignment: 20
  waitForConsistencyCounterBeforeSubPlacement: 20
}

// Only specify the parameters you want to override - others will use defaults from JSON files
param parPolicyAssignmentParameterOverrides = {
  'Enable-DDoS-VNET': {
    ddosPlan: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-conn-${parLocations[0]}/providers/Microsoft.Network/ddosProtectionPlans/ddos-alz-${parLocations[0]}'
    }
  }
}
