using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param intRootConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'alz'
  managementGroupParentId: '{{root_parent_management_group_id}}'
  managementGroupDisplayName: 'Azure Landing Zones'
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
  'Deploy-MDFC-Config-H224': {
    parameters: {
      logAnalytics: {
        value: '/subscriptions/{{management_subscription_id}}/resourcegroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
      emailSecurityContact: {
        value: 'security@yourcompany.com'
      }
      ascExportResourceGroupName: {
        value: 'rg-alz-asc-${parLocations[0]}'
      }
      ascExportResourceGroupLocation: {
        value: parLocations[0]
      }
    }
  }
  'Deploy-AzActivity-Log': {
    parameters: {
      logAnalytics: {
        value: '/subscriptions/{{management_subscription_id}}/resourcegroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
      logsEnabled: {
        value: 'True'
      }
    }
  }
  'Deploy-Diag-LogsCat': {
    parameters: {
      logAnalytics: {
        value: '/subscriptions/{{management_subscription_id}}/resourcegroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
    }
  }
  'Deploy-SvcHealth-BuiltIn': {
    parameters: {
      resourceGroupLocation: {
        value: parLocations[0]
      }
      actionGroupResources: {
        value: {
          actionGroupEmail: ['triage@yourcompany.com']
          eventHubResourceId: []
          functionResourceId: ''
          functionTriggerUrl: ''
          logicappCallbackUrl: ''
          logicappResourceId: ''
          webhookServiceUri: []
        }
      }
    }
  }
  'Deploy-AzSqlDb-Auditing': {
    parameters: {
      logAnalyticsWorkspaceResourceId: {
        value: '/subscriptions/{{management_subscription_id}}/resourcegroups/rg-alz-mgmt-${parLocations[0]}/providers/Microsoft.OperationalInsights/workspaces/law-alz-${parLocations[0]}'
      }
    }
  }
}
