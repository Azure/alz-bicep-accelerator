using './main.bicep'

// General Parameters
param parLocations = [
  'eastus2'
]
param parEnableTelemetry = true

param landingZonesConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'landingzones'
  managementGroupParentId: 'met'
  managementGroupIntermediateRootID: 'met'
  managementGroupDisplayName: 'Landing zones'
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
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-conn-${parLocations[0]}/providers/Microsoft.Network/ddosProtectionPlans/ddos-alz-${parLocations[0]}'
    }
  }
  'Deploy-AzSqlDb-Auditing': {
    logAnalyticsWorkspaceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/log-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmArc-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-changetracking-${parLocations[0]}'
    }
  }
  'Deploy-VM-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-changetracking-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-ChangeTrack': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-changetracking-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-vmHybr-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-vminsights-${parLocations[0]}'
    }
  }
  'Deploy-VM-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-vminsights-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-VMSS-Monitoring': {
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-vminsights-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
  'Deploy-MDFC-DefSQL-AMA': {
    userWorkspaceResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/log-alz-${parLocations[0]}'
    }
    dcrResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.Insights/dataCollectionRules/dcr-alz-mdfcsql-${parLocations[0]}'
    }
    userAssignedIdentityResourceId: {
      value: '/subscriptions/{{management_subscription_id}}/resourceGroups/rg-alz-logging-${parLocations[0]}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uami-alz-${parLocations[0]}'
    }
  }
}
