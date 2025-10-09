using 'main.bicep'

// Resource Group Parameters
param parResourceGroupName = 'rg-alz-logging-001'

// Automation Account Parameters
param parAutomationAccountName = 'alz-aa-$()'
param parAutomationAccountLocation = parPrimaryLocation
param parDisableAutomationAccount = true
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'
param parAutomationAccountLock = {
  name: 'AutomationAccountLock'
  kind: 'CanNotDelete'
}

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'alz-log-analytics'
param parLogAnalyticsWorkspaceLocation = parPrimaryLocation
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceOnboardSentinel = true

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'alz-logging-mi'
param parDataCollectionRuleVMInsightsName = 'alz-ama-vmi-dcr'
param parDataCollectionRuleChangeTrackingName = 'alz-ama-ct-dcr'
param parDataCollectionRuleMDFCSQLName = 'alz-ama-mdfcsql-dcr'

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'ReadOnly'
  notes: 'This lock was created by the ALZ Bicep Accelerator Management and Logging Module.'
}
param parTags = {}
param parPrimaryLocation = 'eastus'
param parEnableTelemetry = false
