metadata name = 'ALZ Bicep Accelerator - Management and Logging'
metadata description = 'Used to deploy core management and logging resources for ALZ.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('Required. The name of the Resource Group.')
param parMgmtLoggingResourceGroup string

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

// Automation Account Parameters
@description('Required. The name of the Automation Account.')
param parAutomationAccountName string

@description('Optional. The flag to deploy the Automation Account.')
param parDeployAutomationAccount bool = false

@description('Optional. The location of the Automation Account.')
param parAutomationAccountLocation string = 'eastus'

@description('Optional. The flag to enable or disable the use of Managed Identity for the Automation Account.')
param parAutomationAccountUseManagedIdentity bool = true

@description('Optional. The flag to enable or disable the use of Public Network Access for the Automation Account.')
param parAutomationAccountPublicNetworkAccess bool = true

@description('Optional. The SKU of the Automation Account.')
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
@description('Required. The name of the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceName string

@description('Required. The location of the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceLocation string

@description('Optional. The SKU of the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceSku string = 'PerGB2018'

@description('Optional. The capacity reservation level for the Log Analytics Workspace.')
@maxValue(5000)
@minValue(100)
param parLogAnalyticsWorkspaceCapacityReservationLevel int = 100

@description('Optional. The log retention in days for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceLogRetentionInDays int = 365

@description('Optional. The daily ingestion quota in GB for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceDailyQuotaGb int?

@description('Optional. The replication configuration for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceReplication object?

@description('Optional. The feature configuration for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceFeatures object?

@description('Optional. The data export rules for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceDataExports array?

@description('Optional. The data sources for the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceDataSources array?

@description('Optional. The solutions to deploy to the Log Analytics Workspace.')
param parLogAnalyticsWorkspaceSolutions array = [
  'SecurityInsights'
  'ChangeTracking'
]

@description('''Resource Lock Configuration for Log Analytics Workspace.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parLogAnalyticsWorkspaceLock lockType?

// User Assigned Identity Parameters
@description('Required. The name of the User Assigned Identity utilized for Azure Monitoring Agent.')
param parUserAssignedIdentityName string

// Data Collection Rule Parameters
@description('Required. The name of the data collection rule for VM Insights.')
param parDataCollectionRuleVMInsightsName string

@description('Required. The name of the data collection rule for Change Tracking.')
param parDataCollectionRuleChangeTrackingName string

@description('Required. The name of the data collection rule for Microsoft Defender for SQL.')
param parDataCollectionRuleMDFCSQLName string

@description('Optional. The experience for the VM Insights data collection rule.')
param parDataCollectionRuleVMInsightsExperience string = 'PerfAndMap'

@description('''The lock configuration for the data collection rule for VM Insights.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parAmaResourcesLock lockType?

// General Parameters
@description('Required. The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@description('Optional. Tags to be applied to resources.')
param parTags object = {}

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType

@description('Optional. Enable or disable telemetry.')
param parEnableTelemetry bool = true

var varGallerySolutions = [
  for solution in parLogAnalyticsWorkspaceSolutions: {
    name: '${solution}(${parLogAnalyticsWorkspaceName})'
    plan: {
      name: '${solution}(${parLogAnalyticsWorkspaceName})'
      product: solution == 'SecurityInsights'
        ? 'OMSGallery/SecurityInsights'
        : solution == 'ChangeTracking'
          ? 'OMSGallery/ChangeTracking'
          : 'OMSGallery/${solution}'
      publisher: 'Microsoft'
      promotionCode: ''
    }
  }
]

//========================================
// Resources
//========================================

module modMgmtLoggingResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'modMgmtLoggingResourceGroup-${uniqueString(parMgmtLoggingResourceGroup,parLocations[0])}'
  scope: subscription()
  params: {
    name: parMgmtLoggingResourceGroup
    location: parLocations[0]
    lock: parResourceGroupLock ?? parGlobalResourceLock
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
module modAutomationAccount 'br/public:avm/res/automation/automation-account:0.17.1' = if (parDeployAutomationAccount) {
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
    lock: parAutomationAccountLock ?? parGlobalResourceLock
    enableTelemetry: parEnableTelemetry
  }
}

// Log Analytics Workspace
module modLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.14.2' = {
  name: '${parLogAnalyticsWorkspaceName}-logAnalyticsWorkspace-${uniqueString(parMgmtLoggingResourceGroup,parLogAnalyticsWorkspaceLocation,parLocations[0])}'
  scope: resResourceGroupPointer
  params: {
    name: parLogAnalyticsWorkspaceName
    location: !empty(parLogAnalyticsWorkspaceLocation) ? parLogAnalyticsWorkspaceLocation : parLocations[0]
    skuName: parLogAnalyticsWorkspaceSku
    tags: parTags
    skuCapacityReservationLevel: parLogAnalyticsWorkspaceSku == 'CapacityReservation' ? parLogAnalyticsWorkspaceCapacityReservationLevel : null
    dataRetention: parLogAnalyticsWorkspaceLogRetentionInDays
    gallerySolutions: !empty(varGallerySolutions) ? varGallerySolutions : null
    onboardWorkspaceToSentinel: contains(parLogAnalyticsWorkspaceSolutions, 'SecurityInsights')
    dailyQuotaGb: parLogAnalyticsWorkspaceDailyQuotaGb
    replication: parLogAnalyticsWorkspaceReplication
    features: parLogAnalyticsWorkspaceFeatures
    dataExports: parLogAnalyticsWorkspaceDataExports
    dataSources: parLogAnalyticsWorkspaceDataSources
    lock: parLogAnalyticsWorkspaceLock ?? parGlobalResourceLock
    enableTelemetry: parEnableTelemetry
  }
}

// Azure Monitoring Agent Resources
module modAzureMonitoringAgent 'br/public:avm/ptn/alz/ama:0.1.1' = {
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
    lockConfig: parAmaResourcesLock ?? parGlobalResourceLock
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
