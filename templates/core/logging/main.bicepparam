using 'main.bicep'

// Resource Group Parameters
param parResourceGroupName = 'rg-alz-logging-001'
param parResourceGroupLocation = 'eastus'

// Automation Account Parameters
param parAutomationAccountName = 'alz-automation-account'
param parAutomationAccountLocation = 'eastus'
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'
param parAutomationAccountLock = {
  name: 'AutomationAccountLock'
  kind: 'CanNotDelete'
}

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'alz-log-analytics'
param parLogAnalyticsWorkspaceLocation = 'eastus'
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceOnboardSentinel = true
param parLogAnalyticsWorkspaceLock = {
  name: 'LogAnalyticsWorkspaceLock'
  kind: 'CanNotDelete'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'alz-logging-mi'
param parUserAssignedManagedIdentityLocation = 'eastus'
param parDataCollectionRuleVMInsightsName = 'alz-ama-vmi-dcr'
param parDataCollectionRuleVMInsightsLock = {
  name: 'alz-ama-vmi-dcr-lock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}
param parDataCollectionRuleChangeTrackingName = 'alz-ama-ct-dcr'
param parDataCollectionRuleChangeTrackingLock = {
  name: 'alz-ama-ct-dcr-lock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'

}
param parDataCollectionRuleMDFCSQLName = 'alz-ama-mdfcsql-dcr'
param parDataCollectionRuleMDFCSQLLock = {
  name: 'alz-ama-mdfcsql-dcr-lock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Logging Module.'
}

// General Parameters
param parTags = {
  Environment: 'Live'
}
