metadata name = 'ALZ Bicep - Azure Monitor Agent Logging'
metadata description = 'This module deploys the Azure Monitoring Agent resources for ALZ Bicep'

//========================================
// Parameters
//========================================

// User Assigned Identity Parameters
@description('Required. The name of the User Assigned Identity utilized for Azure Monitoring Agent.')
param parUserAssignedIdentityName string

@description('Required. The location of the User Assigned Identity utilized for Azure Monitoring Agent.')
param parUserAssignedManagedIdentityLocation string

// Data Collection Rule Parameters
@description('Required. The resource ID of the Log Analytics Workspace.')
param resLogAnalyticsWorkspaceId string

@description('Required. The location of the Data Collection Rules.')
param parLogAnalyticsWorkspaceLocation string

@description('Required. The name of the data collection rule for VM Insights.')
param parDataCollectionRuleVMInsightsName string

@description('Optional. The lock configuration for the Data Collection Rule for VM Insights.')
param parDataCollectionRuleVMInsightsLock lockType

@description('Required. The name of the data collection rule for Change Tracking.')
param parDataCollectionRuleChangeTrackingName string

@description('Optional. The lock configuration for the Data Collection Rule for Change Tracking.')
param parDataCollectionRuleChangeTrackingLock lockType

@description('The name of the data collection rule for Microsoft Defender for SQL.')
param parDataCollectionRuleMDFCSQLName string

@description('Optional. The lock configuration for the Data Collection Rule for Microsoft Defender for SQL.')
param parDataCollectionRuleMDFCSQLLock lockType

// General Parameters
@description('Tags to be applied to resources.')
param parTags object

//========================================
// Resources
//========================================

// User Assigned Identity
module resUserAssignedManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: 'userAssignedIdentityDeployment'
  params: {
    name: parUserAssignedIdentityName
    location: parUserAssignedManagedIdentityLocation
    tags: parTags
  }
}

resource resDataCollectionRuleVMInsights 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: parDataCollectionRuleVMInsightsName
  location: parLogAnalyticsWorkspaceLocation
  tags: parTags
  properties: {
    description: 'Data collection rule for VM Insights'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          counterSpecifiers: [
            '\\VMInsights\\DetailedMetrics'
          ]
          samplingFrequencyInSeconds: 60
        }
      ]
      extensions: [
        {
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          extensionSettings: {}
          name: 'DependencyAgentDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: resLogAnalyticsWorkspaceId
          name: 'VMInsightsPerf-Logs-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
}

// Create a resource lock for the Data Collection Rule if parGlobalResourceLock.kind != 'None' or if parDataCollectionRuleVMInsightsLock.kind != 'None'
resource resDataCollectionRuleVMInsightsLock 'Microsoft.Authorization/locks@2020-05-01' = if (parDataCollectionRuleVMInsightsLock.kind != 'None') {
  scope: resDataCollectionRuleVMInsights
  name: parDataCollectionRuleVMInsightsLock.?name ?? '${resDataCollectionRuleVMInsights.name}-lock'
  properties: {
    level: parDataCollectionRuleVMInsightsLock.?kind
    notes: parDataCollectionRuleVMInsightsLock.?notes
  }
}

resource resDataCollectionRuleChangeTracking 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: parDataCollectionRuleChangeTrackingName
  location: parLogAnalyticsWorkspaceLocation
  tags: parTags
  properties: {
    description: 'Data collection rule for CT.'
    dataSources: {
      extensions: [
        {
          streams: [
            'Microsoft-ConfigurationChange'
            'Microsoft-ConfigurationChangeV2'
            'Microsoft-ConfigurationData'
          ]
          extensionName: 'ChangeTracking-Windows'
          extensionSettings: {
            enableFiles: true
            enableSoftware: true
            enableRegistry: true
            enableServices: true
            enableInventory: true
            registrySettings: {
              registryCollectionFrequency: 3000
              registryInfo: [
                {
                  name: 'Registry_1'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Startup'
                  valueName: ''
                }
                {
                  name: 'Registry_2'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Group Policy\\Scripts\\Shutdown'
                  valueName: ''
                }
                {
                  name: 'Registry_3'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Run'
                  valueName: ''
                }
                {
                  name: 'Registry_4'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Active Setup\\Installed Components'
                  valueName: ''
                }
                {
                  name: 'Registry_5'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\ShellEx\\ContextMenuHandlers'
                  valueName: ''
                }
                {
                  name: 'Registry_6'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Background\\ShellEx\\ContextMenuHandlers'
                  valueName: ''
                }
                {
                  name: 'Registry_7'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Classes\\Directory\\Shellex\\CopyHookHandlers'
                  valueName: ''
                }
                {
                  name: 'Registry_8'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers'
                  valueName: ''
                }
                {
                  name: 'Registry_9'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\ShellIconOverlayIdentifiers'
                  valueName: ''
                }
                {
                  name: 'Registry_10'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects'
                  valueName: ''
                }
                {
                  name: 'Registry_11'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Browser Helper Objects'
                  valueName: ''
                }
                {
                  name: 'Registry_12'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Internet Explorer\\Extensions'
                  valueName: ''
                }
                {
                  name: 'Registry_13'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Internet Explorer\\Extensions'
                  valueName: ''
                }
                {
                  name: 'Registry_14'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32'
                  valueName: ''
                }
                {
                  name: 'Registry_15'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32'
                  valueName: ''
                }
                {
                  name: 'Registry_16'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\Session Manager\\KnownDlls'
                  valueName: ''
                }
                {
                  name: 'Registry_17'
                  groupTag: 'Recommended'
                  enabled: false
                  recurse: true
                  description: ''
                  keyName: 'HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon\\Notify'
                  valueName: ''
                }
              ]
            }
            fileSettings: {
              fileCollectionFrequency: 2700
            }
            softwareSettings: {
              softwareCollectionFrequency: 1800
            }
            inventorySettings: {
              inventoryCollectionFrequency: 36000
            }
            serviceSettings: {
              serviceCollectionFrequency: 1800
            }
          }
          name: 'CTDataSource-Windows'
        }
        {
          streams: [
            'Microsoft-ConfigurationChange'
            'Microsoft-ConfigurationChangeV2'
            'Microsoft-ConfigurationData'
          ]
          extensionName: 'ChangeTracking-Linux'
          extensionSettings: {
            enableFiles: true
            enableSoftware: true
            enableRegistry: false
            enableServices: true
            enableInventory: true
            fileSettings: {
              fileCollectionFrequency: 900
              fileInfo: [
                {
                  name: 'ChangeTrackingLinuxPath_default'
                  enabled: true
                  destinationPath: '/etc/.*.conf'
                  useSudo: true
                  recurse: true
                  maxContentsReturnable: 5000000
                  pathType: 'File'
                  type: 'File'
                  links: 'Follow'
                  maxOutputSize: 500000
                  groupTag: 'Recommended'
                }
              ]
            }
            softwareSettings: {
              softwareCollectionFrequency: 300
            }
            inventorySettings: {
              inventoryCollectionFrequency: 36000
            }
            serviceSettings: {
              serviceCollectionFrequency: 300
            }
          }
          name: 'CTDataSource-Linux'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: resLogAnalyticsWorkspaceId
          name: 'Microsoft-CT-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ConfigurationChange'
          'Microsoft-ConfigurationChangeV2'
          'Microsoft-ConfigurationData'
        ]
        destinations: [
          'Microsoft-CT-Dest'
        ]
      }
    ]
  }
}

// Create a resource lock for the Data Collection Rule if parGlobalResourceLock.kind != 'None' or if parDataCollectionRuleChangeTrackingLock.kind != 'None'
resource resDataCollectionRuleChangeTrackingLock 'Microsoft.Authorization/locks@2020-05-01' = if (parDataCollectionRuleChangeTrackingLock.kind != 'None') {
  scope: resDataCollectionRuleChangeTracking
  name: parDataCollectionRuleChangeTrackingLock.?name ?? '${resDataCollectionRuleChangeTracking.name}-lock'
  properties: {
    level: parDataCollectionRuleChangeTrackingLock.?kind
    notes: parDataCollectionRuleChangeTrackingLock.?notes
  }
}

resource resDataCollectionRuleMDFCSQL 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: parDataCollectionRuleMDFCSQLName
  location: parLogAnalyticsWorkspaceLocation
  tags: parTags
  properties: {
    description: 'Data collection rule for Defender for SQL.'
    dataSources: {
      extensions: [
        {
          extensionName: 'MicrosoftDefenderForSQL'
          name: 'MicrosoftDefenderForSQL'
          streams: [
            'Microsoft-DefenderForSqlAlerts'
            'Microsoft-DefenderForSqlLogins'
            'Microsoft-DefenderForSqlTelemetry'
            'Microsoft-DefenderForSqlScanEvents'
            'Microsoft-DefenderForSqlScanResults'
          ]
          extensionSettings: {
            enableCollectionOfSqlQueriesForSecurityResearch: true
          }
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: resLogAnalyticsWorkspaceId
          name: 'Microsoft-DefenderForSQL-Dest'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-DefenderForSqlAlerts'
          'Microsoft-DefenderForSqlLogins'
          'Microsoft-DefenderForSqlTelemetry'
          'Microsoft-DefenderForSqlScanEvents'
          'Microsoft-DefenderForSqlScanResults'
        ]
        destinations: [
          'Microsoft-DefenderForSQL-Dest'
        ]
      }
    ]
  }
}

// Create a resource lock for the Data Collection Rule if parGlobalResourceLock.kind != 'None' or if parDataCollectionRuleMDFCSQLLock.kind != 'None'
resource resDataCollectionRuleMDFCSQLLock 'Microsoft.Authorization/locks@2020-05-01' = if (parDataCollectionRuleMDFCSQLLock.kind != 'None') {
  scope: resDataCollectionRuleMDFCSQL
  name: parDataCollectionRuleMDFCSQLLock.?name ?? '${resDataCollectionRuleMDFCSQL.name}-lock'
  properties: {
    level: parDataCollectionRuleMDFCSQLLock.?kind
    notes: parDataCollectionRuleMDFCSQLLock.?notes
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
