metadata name = 'ALZ Bicep - Logging Module'
metadata description = 'This module deploys the Logging and Monitoring resources for ALZ Bicep'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('The name of the Resource Group.')
param parResourceGroupName string = 'rg-alz-logging-001'

@description('The location of the Resource Group.')
param parResourceGroupLocation string = 'eastus'

// Automation Account Parameters
@description('The name of the Automation Account.')
param parAutomationAccountName string = 'alz-automation-account'

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
''')
param parAutomationAccountLock lockType

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
param parLogAnalyticsWorkspaceLock lockType

// User Assigned Identity Parameters
@description('The name of the User Assigned Identity utilized for Azure Monitoring Agent.')
param parUserAssignedIdentityName string = 'alz-logging-mi'

@description('The location of the User Assigned Identity utilized for Azure Monitoring Agent.')
param parUserAssignedManagedIdentityLocation string = 'eastus'

// Data Collection Rule Parameters
@description('The name of the data collection rule for VM Insights.')
param parDataCollectionRuleVMInsightsName string = 'alz-ama-vmi-dcr'

@description('''The lock configuration for the data collection rule for VM Insights.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parDataCollectionRuleVMInsightsLock lockType

@description('The name of the data collection rule for Change Tracking.')
param parDataCollectionRuleChangeTrackingName string = 'alz-ama-ct-dcr'

@description('''The lock configuration for the data collection rule for Change Tracking.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parDataCollectionRuleChangeTrackingLock lockType

@description('The name of the data collection rule for Microsoft Defender for SQL.')
param parDataCollectionRuleMDFCSQLName string = 'alz-ama-mdfcsql-dcr'

@description('''The lock configuration for the data collection rule for Microsoft Defender for SQL.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parDataCollectionRuleMDFCSQLLock lockType

// General Parameters
@description('The location to deploy resources to.')
param parLocation string = deployment().location

@description('Tags to be applied to resources.')
param parTags object = {
  Environment: 'Live'
}

//========================================
// Resources
//========================================

resource resResourceGroup 'Microsoft.Resources/resourceGroups@2024-07-01' = {
  name: parResourceGroupName
  location: !empty(parResourceGroupLocation) ? parResourceGroupLocation : parLocation
  tags: parTags
}

// Automation Account
module resAutomationAccount 'br/public:avm/res/automation/automation-account:0.10.0' = {
  name: '${parAutomationAccountName}-automationAccount-${uniqueString(parResourceGroupName,parAutomationAccountLocation,parLocation)}'
  scope: resourceGroup(parResourceGroupName)
  params: {
    name: parAutomationAccountName
    location: !(empty(parAutomationAccountLocation)) ? parAutomationAccountLocation : parLocation
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
        workspaceResourceId: resLogAnalyticsWorkspace.outputs.resourceId
      }
    ]
    lock: parAutomationAccountLock.kind != 'None'
      ? parAutomationAccountLock
      : { name: null, kind: 'None', notes: null }
  }
}

// Log Analytics Workspace
module resLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.8.0' = {
  name: '${parLogAnalyticsWorkspaceName}-logAnalyticsWorkspace-${uniqueString(parResourceGroupName,parLogAnalyticsWorkspaceLocation,parLocation)}'
  scope: resourceGroup(parResourceGroupName)
  params: {
    name: parLogAnalyticsWorkspaceName
    location: !empty(parLogAnalyticsWorkspaceLocation) ? parLogAnalyticsWorkspaceLocation : parLocation
    skuName: parLogAnalyticsWorkspaceSku == 'CapacityReservation' ? parLogAnalyticsWorkspaceSku : null
    tags: parTags
    skuCapacityReservationLevel: parLogAnalyticsWorkspaceCapacityReservationLevel
    dataRetention: parLogAnalyticsWorkspaceLogRetentionInDays
    onboardWorkspaceToSentinel: parLogAnalyticsWorkspaceOnboardSentinel
    lock: parLogAnalyticsWorkspaceLock.kind != 'None'
      ? parLogAnalyticsWorkspaceLock
      : { name: null, kind: 'None', notes: null }
  }
}

module ptnAzureMonitoringAgent 'ama/main.bicep' = {
  name: 'uami-dcrs-ama-${uniqueString(parResourceGroupName,parLocation)}'
  scope: resourceGroup(parResourceGroupName)
  params: {
    resLogAnalyticsWorkspaceId: resLogAnalyticsWorkspace.outputs.resourceId
    parUserAssignedIdentityName: parUserAssignedIdentityName
    parUserAssignedManagedIdentityLocation: !empty(parUserAssignedManagedIdentityLocation)
      ? parUserAssignedManagedIdentityLocation
      : parLocation
    parLogAnalyticsWorkspaceLocation: !empty(parLogAnalyticsWorkspaceLocation)
      ? parLogAnalyticsWorkspaceLocation
      : parLocation
    parDataCollectionRuleVMInsightsName: parDataCollectionRuleVMInsightsName
    parDataCollectionRuleVMInsightsLock: parDataCollectionRuleVMInsightsLock != 'None'
      ? parDataCollectionRuleVMInsightsLock
      : { name: null, kind: 'None', notes: null }
    parDataCollectionRuleChangeTrackingName: parDataCollectionRuleChangeTrackingName
    parDataCollectionRuleChangeTrackingLock: parDataCollectionRuleChangeTrackingLock != 'None'
      ? parDataCollectionRuleChangeTrackingLock
      : { name: null, kind: 'None', notes: null }
    parDataCollectionRuleMDFCSQLName: parDataCollectionRuleMDFCSQLName
    parDataCollectionRuleMDFCSQLLock: parDataCollectionRuleMDFCSQLLock.kind != 'None'
      ? parDataCollectionRuleMDFCSQLLock
      : { name: null, kind: 'None', notes: null }
    parTags: parTags
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
}
