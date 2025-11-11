metadata name = 'ALZ Bicep Accelerator - Management and Logging'
metadata description = 'Used to deploy core management and logging resources for ALZ.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('The name of the Resource Group.')
param parMgmtLoggingResourceGroup string = 'rg-alz-mgmt-001'

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

// Automation Account Parameters
@description('The name of the Automation Account.')
param parAutomationAccountName string = 'alz-automation-account'

@description('The flag to enable or disable the Automation Account.')
param parDisableAutomationAccount bool = true

@description('The location of the Automation Account.')
param parAutomationAccountLocation string = 'eastus'

@description('The flag to enable or disable the use of Managed Identity for the Automation Account.')
param parAutomationAccountUseManagedIdentity bool = true

@description('The flag to enable or disable the use of Public Network Access for the Automation Account.')
param parAutomationAccountPublicNetworkAccess bool = true

@description('The SKU of the Automation Account.')
@allowed([
  'Basic'
  'Free'
])
param parAutomationAccountSku string = 'Basic'

@description('''Resource Lock Configuration for Automation Account.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parAutomationAccountLock lockType?

// Log Analytics Workspace Parameters
@description('The name of the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceName string = 'alz-log-analytics'

@description('The location of the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceLocation string = 'eastus'

@description('The SKU of the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceSku string = 'PerGB2018'

@description('The capacity reservation level for the Log Analytics Workspace.')
@maxValue(5000)
@minValue(100)
param parLogAnalyticsWorkspaceCapacityReservationLevel int = 100

@description('The log retention in days for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceLogRetentionInDays int = 365

@description('The flag to enable or disable onboarding the Log Analytics Workspace to Sentinel.')
param parLogAnalyticsWorkspaceOnboardSentinel bool = true

@description('''Resource Lock Configuration for Log Analytics Workspace.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parLogAnalyticsWorkspaceLock lockType?

// User Assigned Identity Parameters
@description('The name of the User Assigned Identity utilized for Azure Monitoring Agent.')
param parUserAssignedIdentityName string = 'alz-logging-mi'

// Data Collection Rule Parameters
@description('The name of the data collection rule for VM Insights.')
param parDataCollectionRuleVMInsightsName string = 'alz-ama-vmi-dcr'

@description('The name of the data collection rule for Change Tracking.')
param parDataCollectionRuleChangeTrackingName string = 'alz-ama-ct-dcr'

@description('The name of the data collection rule for Microsoft Defender for SQL.')
param parDataCollectionRuleMDFCSQLName string = 'alz-ama-mdfcsql-dcr'

@description('The experience for the VM Insights data collection rule.')
param parDataCollectionRuleVMInsightsExperience string = 'PerfAndMap'

@description('''The lock configuration for the data collection rule for VM Insights.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parAmaResourcesLock lockType?

// General Parameters
@description('The primary locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@description('Tags to be applied to resources.')
param parTags object = {}

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType

@description('Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Resources
//========================================

module modMgmtLoggingResourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'modMgmtLoggingResourceGroup-${uniqueString(parMgmtLoggingResourceGroup,parLocations[0])}'
  scope: subscription()
  params: {
    name: parMgmtLoggingResourceGroup
    location: parLocations[0]
    lock: parGlobalResourceLock ?? parResourceGroupLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

resource resResourceGroupPointer 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: parMgmtLoggingResourceGroup
  scope: subscription()
  dependsOn: [
    modMgmtLoggingResourceGroup
  ]
}

// Automation Account
module modAutomationAccount 'br/public:avm/res/automation/automation-account:0.16.1' = if (!parDisableAutomationAccount) {
  name: '${parAutomationAccountName}-automationAccount-${uniqueString(parMgmtLoggingResourceGroup,parAutomationAccountLocation,parLocations[0])}'
  scope: resResourceGroupPointer
  params: {
    name: parAutomationAccountName
    location: !(empty(parAutomationAccountLocation)) ? parAutomationAccountLocation : parLocations[0]
    tags: parTags
    managedIdentities: parAutomationAccountUseManagedIdentity
      ? {
          systemAssigned: true
        }
      : null
    publicNetworkAccess: parAutomationAccountPublicNetworkAccess ? 'Enabled' : 'Disabled'
    skuName: parAutomationAccountSku
    diagnosticSettings: [
      {
        workspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId
      }
    ]
    lock: parGlobalResourceLock ?? parAutomationAccountLock
    enableTelemetry: parEnableTelemetry
  }
}

// Log Analytics Workspace
module modLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.12.0' = {
  name: '${parLogAnalyticsWorkspaceName}-logAnalyticsWorkspace-${uniqueString(parMgmtLoggingResourceGroup,parLogAnalyticsWorkspaceLocation,parLocations[0])}'
  scope: resResourceGroupPointer
  params: {
    name: parLogAnalyticsWorkspaceName
    location: !empty(parLogAnalyticsWorkspaceLocation) ? parLogAnalyticsWorkspaceLocation : parLocations[0]
    skuName: parLogAnalyticsWorkspaceSku == 'CapacityReservation' ? parLogAnalyticsWorkspaceSku : null
    tags: parTags
    skuCapacityReservationLevel: parLogAnalyticsWorkspaceCapacityReservationLevel
    dataRetention: parLogAnalyticsWorkspaceLogRetentionInDays
    onboardWorkspaceToSentinel: parLogAnalyticsWorkspaceOnboardSentinel
    lock: parGlobalResourceLock ?? parLogAnalyticsWorkspaceLock
    enableTelemetry: parEnableTelemetry
  }
}

// Azure Monitoring Agent Resources
module modAzureMonitoringAgent 'br/public:avm/ptn/alz/ama:0.1.0' = {
  scope: resResourceGroupPointer
  params: {
    dataCollectionRuleChangeTrackingName: parDataCollectionRuleChangeTrackingName
    dataCollectionRuleMDFCSQLName: parDataCollectionRuleMDFCSQLName
    dataCollectionRuleVMInsightsName: parDataCollectionRuleVMInsightsName
    logAnalyticsWorkspaceResourceId: modLogAnalyticsWorkspace.outputs.resourceId
    userAssignedIdentityName: parUserAssignedIdentityName
    dataCollectionRuleVMInsightsExperience: parDataCollectionRuleVMInsightsExperience
    enableTelemetry: parEnableTelemetry
    location: parLocations[0]
    lockConfig: parGlobalResourceLock ?? parAmaResourcesLock
    tags: parTags
  }
}

//========================================
// Definitions
//========================================

// Lock Type
type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}?
