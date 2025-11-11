using './main.bicep'

extends '../../../../root.bicepparam'

param platformConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'platform'
  managementGroupParentId: 'int-root'
  managementGroupDisplayName: 'Platform'
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

// Only specify the parameters you want to override - others will use defaults from JSON files
param parPolicyAssignmentParameterOverrides = {
  'Deploy-VM-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.Insights/dataCollectionRules/your-dcr'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/your-identity'
    }
  }
  'Deploy-VMSS-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.Insights/dataCollectionRules/your-dcr'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/your-identity'
    }
  }
  'Deploy-vmArc-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.Insights/dataCollectionRules/your-dcr'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/your-identity'
    }
  }
  'Deploy-vmHybr-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.Insights/dataCollectionRules/your-dcr'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/your-identity'
    }
  }
  'Enable-AUM-CheckUpdates': {
    dcrResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.Insights/dataCollectionRules/your-dcr'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/your-subscription-id/resourceGroups/your-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/your-identity'
    }
  }
}
