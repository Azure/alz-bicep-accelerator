using 'main.bicep'

extends '../../root.bicepparam'

// Resource Group Parameters
param parMgmtLoggingResourceGroup = 'rg-alz-${parLocations[0]}'

// Automation Account Parameters
param parAutomationAccountName = 'aa-alz-${parLocations[0]}'
param parAutomationAccountLocation = parLocations[0]
param parDisableAutomationAccount = true
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'law-alz-${parLocations[0]}'
param parLogAnalyticsWorkspaceLocation = parLocations[0]
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceOnboardSentinel = true

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'mi-alz-${parLocations[0]}'
param parDataCollectionRuleVMInsightsName = 'dcr-vmi-alz-${parLocations[0]}'
param parDataCollectionRuleChangeTrackingName = 'dcr-ct-alz-${parLocations[0]}'
param parDataCollectionRuleMDFCSQLName = 'dcr-mdfcsql-alz-${parLocations[0]}'

// General Parameters
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
