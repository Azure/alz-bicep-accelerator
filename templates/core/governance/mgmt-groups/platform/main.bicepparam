using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param platformConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'platform'
  managementGroupParentId: 'alz'
  managementGroupDisplayName: 'Platform'
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
  'Deploy-VM-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-VM-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmArc-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-ct-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmHybr-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-vmi-alz-${parLocations[0]}'
    }
  }
  'Deploy-MDFC-DefSQL-AMA': {
    userWorkspaceResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
    }
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-mdfcsql-alz-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-alz-${parLocations[0]}'
    }
  }
  'DenyAction-DeleteUAMIAMA': {
    resourceName: {
      value: 'mi-alz-${parLocations[0]}'
    }
  }
}
