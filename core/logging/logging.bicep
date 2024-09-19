//========================================
// Parameters
//========================================

// User Assigned Identity Parameters
param parUserAssignedIdentityName string = 'alz-logging-mi'
param parUserAssignedManagedIdentityLocation string = resourceGroup().location

// Automation Account Parameters
param parAutomationAccountName string = 'alz-automation-account'
param parAutomationAccountLocation string = resourceGroup().location
param parAutomationAccountUseManagedIdentity bool = true
param parAutomationAccountPublicNetworkAccess string = 'true'
param parAutomationAccountSku string = 'Basic'

// Log Analytics Workspace Parameters
param parLogAnalyticsWorkspaceName string = 'alz-log-analytics'
param parLogAnalyticsWorkspaceLocation string = resourceGroup().location
param parLogAnalyticsWorkspaceSku string = 'PerGB2018'
param parLogAnalyticsWorkspaceCapacityReservationLevel int = 100
param parLogAnalyticsWorkspaceLogRetentionInDays int = 365

// Log Analytics Workspace Solutions
param parLogAnalyticsWorkspaceSolutions array
param parUseSentinelClassicPricingTiers bool = false

// User Assigned Identities
param parDataCollectionRuleVMInsightsName string = 'alz-ama-vmi-dcr'
param parDataCollectionRuleChangeTrackingName string = 'alz-ama-ct-dcr'
param parDataCollectionRuleMDFCSQLName string = 'alz-ama-mdfcsql-dcr'

// General Parameters
param parTags object = {
  Environment: 'Live'
}


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

// Automation Account
module automationAccount 'br/public:avm/res/automation/automation-account:0.8.0' = {
  name: 'automationAccountDeployment'
  params: {
    name: parAutomationAccountName
    location: parAutomationAccountLocation
    tags: parTags
    managedIdentities: parAutomationAccountUseManagedIdentity ?{
      systemAssigned: true
    } : null
    publicNetworkAccess: parAutomationAccountPublicNetworkAccess
    skuName: parAutomationAccountSku
  }
}

// Log Analytics Workspace
module resLogAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.7.0' = {
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    name: parLogAnalyticsWorkspaceName
    location: parLogAnalyticsWorkspaceLocation
    skuName: parLogAnalyticsWorkspaceSku == 'CapacityReservation' ? parLogAnalyticsWorkspaceSku : null
    tags: parTags
    skuCapacityReservationLevel:  parLogAnalyticsWorkspaceCapacityReservationLevel
    dataRetention: parLogAnalyticsWorkspaceLogRetentionInDays
  }
}

module resDataCollectionRuleVMInsights 'br/public:avm/res/insights/data-collection-rule:0.4.0' = {
  name: 'dataCollectionRuleVMInsightsDeployment'
  params: {
    name: parDataCollectionRuleVMInsightsName
    dataCollectionRuleProperties:{
      kind: 'All'
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
            workspaceResourceId: resLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
            name: 'VMInsightsPerf-Logs-Dest'
          }
        ]
      }
    }
  }
}

module resDataCollectionRuleChangeTracking 'br/public:avm/res/insights/data-collection-rule:0.4.0' = {
  name: 'dataCollectionRuleChangeTrackingDeployment'
  params: {
    name: parDataCollectionRuleChangeTrackingName
    dataCollectionRuleProperties: {
      kind: 'All'
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
            workspaceResourceId: resLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
            name: 'Microsoft-CT-Dest'
          }
        ]
      }
    }
  }
}

module resDataCollectionRuleMDFCSQL 'br/public:avm/res/insights/data-collection-rule:0.4.0' = {
  name: 'dataCollectionRuleMDFCSQLDeployment'
  params: {
    name: parDataCollectionRuleMDFCSQLName
    dataCollectionRuleProperties: {
      kind: 'All'
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
            workspaceResourceId: resLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
            name: 'Microsoft-DefenderForSQL-Dest'
          }
        ]
      }
    }
  }
}

module resLogAnalyticsWorkspaceSolutions 'br/public:avm/res/operations-management/solution:0.1.3' = [for solution in parLogAnalyticsWorkspaceSolutions: {
  name: 'logAnalyticsWorkspaceSolutionsDeployment-${solution}'
  params: {
    name: '${solution}-${parLogAnalyticsWorkspaceName}'
    location: parLogAnalyticsWorkspaceLocation
    workspaceResourceId: solution == 'SecurityInsights' ? {
      workspaceResourceId: resLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
      sku: parUseSentinelClassicPricingTiers ? null : {
        name: 'Unified'
      }
    } : {
      workspaceResourceId: resLogAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
    }
    product: 'OMSGallery/${solution}'
    publisher: 'Microsoft'
  }
}]

