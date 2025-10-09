using 'main.bicep'

// Resource Group Parameters
param parMgmtLoggingResourceGroup = 'rg-alz-prod-001'

// Automation Account Parameters
param parAutomationAccountName = 'aa-alz-prod-001'
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
param parLogAnalyticsWorkspaceName = 'law-alz-prod-001'
param parLogAnalyticsWorkspaceLocation = parPrimaryLocation
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceOnboardSentinel = true

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'mi-alz-prod-001'
param parDataCollectionRuleVMInsightsName = 'dcr-vmi-alz-prod-001'
param parDataCollectionRuleChangeTrackingName = 'dcr-ct-alz-prod-001'
param parDataCollectionRuleMDFCSQLName = 'dcr-mdfcsql-alz-prod-001'

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'ReadOnly'
  notes: 'This lock was created by the ALZ Bicep Accelerator Management and Logging Module.'
}
param parTags = {}
param parPrimaryLocation = 'eastus'
param parEnableTelemetry = false
