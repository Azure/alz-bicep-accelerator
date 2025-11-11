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
  'Deploy-VM-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-VM-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmArc-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmHybr-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
    }
  }
  'Deploy-MDFC-DefSQL-AMA': {
    userWorkspaceResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
    }
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-mdfcsql-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'DenyAction-DeleteUAMIAMA': {
    resourceName: {
      value: 'mi-alz-${parLocations[0]}'
    }
  }
}
