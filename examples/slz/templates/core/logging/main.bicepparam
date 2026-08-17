using 'main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parGlobalResourceLock = {
  name: 'GlobalResourceLock'
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Accelerator.'
}
param parTags = {}
param parEnableTelemetry = true

// Resource Group Parameters
param parMgmtLoggingResourceGroup = '{{resource_group_logging_name_prefix||rg-alz-logging}}-${parLocations[0]}'

// Automation Account Parameters
param parAutomationAccountName = 'aa-alz-${parLocations[0]}'
param parAutomationAccountLocation = parLocations[0]
param parDeployAutomationAccount = false
param parAutomationAccountUseManagedIdentity = true
param parAutomationAccountPublicNetworkAccess = true
param parAutomationAccountSku = 'Basic'

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName = 'law-alz-${parLocations[0]}'
param parLogAnalyticsWorkspaceLocation = parLocations[0]
param parLogAnalyticsWorkspaceSku = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel = 100
param parLogAnalyticsWorkspaceLogRetentionInDays = 365
param parLogAnalyticsWorkspaceDailyQuotaGb = null
param parLogAnalyticsWorkspaceReplication = null
param parLogAnalyticsWorkspaceFeatures = null
param parLogAnalyticsWorkspaceDataExports = null
param parLogAnalyticsWorkspaceDataSources = null
param parLogAnalyticsWorkspaceSolutions = [
  'ChangeTracking'
]

// Data Collection Rule Parameters
param parUserAssignedIdentityName = 'mi-alz-${parLocations[0]}'
param parDataCollectionRuleVMInsightsName = 'dcr-vmi-alz-${parLocations[0]}'
param parDataCollectionRuleChangeTrackingName = 'dcr-ct-alz-${parLocations[0]}'
param parDataCollectionRuleMDFCSQLName = 'dcr-mdfcsql-alz-${parLocations[0]}'
