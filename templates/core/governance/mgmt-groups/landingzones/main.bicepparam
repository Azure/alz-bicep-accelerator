using './main.bicep'

extends '../../../../root.bicepparam'

param landingZonesConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'landingzones-online'
  managementGroupParentId: 'landingzones'
  managementGroupDisplayName: 'Landing Zones'
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
  'Deploy-VM-Backup': {
    exclusionTagName: {
      value: 'BackupExclusion'
    }
    exclusionTagValue: {
      value: 'true'
    }
    vaultLocation: {
      value: parLocations[0]
    }
  }
  'Enable-DDoS-VNET': {
    ddosPlan: {
      value: '/subscriptions/{{your-connectivity-subscription-id}}/resourceGroups/rg-alz-${parLocations[0]}/providers/Microsoft.Network/ddosProtectionPlans/ddos-alz-${parLocations[0]}'
    }
  }
  'Deploy-AzSqlDb-Auditing': {
    logAnalyticsWorkspaceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/log-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmArc-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-changetracking-${parLocations[0]}'
    }
  }
  'Deploy-VM-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-changetracking-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-changetracking-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmHybr-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-vminsights-${parLocations[0]}'
    }
  }
  'Deploy-VM-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-vminsights-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-vminsights-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-MDFC-DefSQL-AMA': {
    userWorkspaceResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/log-alz-${parLocations[0]}'
    }
    dcrResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-mdfcsql-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{your-management-subscription-id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
}
