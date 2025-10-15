using 'main.bicep'

// Resource Group Parameters
param parMgmtLoggingResourceGroup = 'rg-alz-${parPrimaryLocation}'

// Automation Account Parameters
param parAutomationAccountName = 'aa-alz-${parPrimaryLocation}'
param parAutomationAccountLocation = parPrimaryLocation
param parDisableAutomationAccount = true
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'law-alz-${parPrimaryLocation}'
param parLogAnalyticsWorkspaceLocation = parPrimaryLocation
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceOnboardSentinel = true

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'mi-alz-${parPrimaryLocation}'
param parDataCollectionRuleVMInsightsName = 'dcr-vmi-alz-${parPrimaryLocation}'
param parDataCollectionRuleChangeTrackingName = 'dcr-ct-alz-${parPrimaryLocation}'
param parDataCollectionRuleMDFCSQLName = 'dcr-mdfcsql-alz-${parPrimaryLocation}'

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator Management and Logging Module.'
}
param parTags = {}
param parPrimaryLocation = 'eastus'
param parEnableTelemetry = true
