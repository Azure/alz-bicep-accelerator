using './main.bicep'

// General Parameters
param parLocations = [
  '{{primary_location}}'
  '{{secondary_location}}'
]
param parEnableTelemetry = true

param landingZonesCorpConfig = {
  createOrUpdateManagementGroup: true
  managementGroupName: 'corp'
  managementGroupParentId: 'landingzones'
  managementGroupIntermediateRootName: 'alz'
  managementGroupDisplayName: 'Corp'
  managementGroupDoNotEnforcePolicyAssignments: []
  managementGroupExcludedPolicyAssignments: []
  customerRbacRoleDefs: []
  customerRbacRoleAssignments: []
  customerPolicyDefs: []
  customerPolicySetDefs: []
  customerPolicyAssignments: []
  subscriptionsToPlaceInManagementGroup: []
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: 10
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: 10
  waitForConsistencyCounterBeforeCustomRoleDefinitions: 10
  waitForConsistencyCounterBeforePolicyAssignments: 10
  waitForConsistencyCounterBeforeRoleAssignment: 10
  waitForConsistencyCounterBeforeSubPlacement: 10
}

// Only specify the parameters you want to override - others will use defaults from JSON files
param parPolicyAssignmentParameterOverrides = {
  // Deploy-Private-DNS-Zones Policy: Configure private DNS zones for Azure services private endpoints
  'Deploy-Private-DNS-Zones': {
    // Azure Container Registry private DNS zone
    azureAcrPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azurecr.io'
    }
    // Azure App Service private DNS zone
    azureAppPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
    }
    // Azure App Services private DNS zone
    azureAppServicesPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
    }
    // Azure Arc Guest Configuration private DNS zone
    azureArcGuestconfigurationPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.guestconfiguration.azure.com'
    }
    // Azure Arc Hybrid Resource Provider private DNS zone
    azureArcHybridResourceProviderPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.his.arc.azure.com'
    }
    // Azure Arc Kubernetes Configuration private DNS zone
    azureArcKubernetesConfigurationPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.dp.kubernetesconfiguration.azure.com'
    }
    // Azure Site Recovery private DNS zone
    azureAsrPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.siterecovery.windowsazure.com'
    }
    // Azure Automation DSC Hybrid private DNS zone
    azureAutomationDSCHybridPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azure-automation.net'
    }
    // Azure Automation Webhook private DNS zone
    azureAutomationWebhookPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azure-automation.net'
    }
    // Azure Batch private DNS zone
    azureBatchPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.batch.azure.com'
    }
    // Azure Bot Service private DNS zone
    azureBotServicePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.directline.botframework.com'
    }
    // Azure Cognitive Search private DNS zone
    azureCognitiveSearchPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.search.windows.net'
    }
    // Azure Cognitive Services private DNS zone
    azureCognitiveServicesPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.cognitiveservices.azure.com'
    }
    // Azure Cosmos DB Cassandra private DNS zone
    azureCosmosCassandraPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.cassandra.cosmos.azure.com'
    }
    // Azure Cosmos DB Gremlin private DNS zone
    azureCosmosGremlinPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.gremlin.cosmos.azure.com'
    }
    // Azure Cosmos DB MongoDB private DNS zone
    azureCosmosMongoPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.mongo.cosmos.azure.com'
    }
    // Azure Cosmos DB SQL API private DNS zone
    azureCosmosSQLPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.documents.azure.com'
    }
    // Azure Cosmos DB Table private DNS zone
    azureCosmosTablePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.table.cosmos.azure.com'
    }
    // Azure Data Factory portal private DNS zone
    azureDataFactoryPortalPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.adf.azure.com'
    }
    // Azure Data Factory private DNS zone
    azureDataFactoryPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.datafactory.azure.net'
    }
    // Azure Databricks private DNS zone
    azureDatabricksPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azuredatabricks.net'
    }
    // Azure Disk Access private DNS zone
    azureDiskAccessPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
    }
    // Azure Event Grid domains private DNS zone
    azureEventGridDomainsPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.eventgrid.azure.net'
    }
    // Azure Event Grid topics private DNS zone
    azureEventGridTopicsPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.eventgrid.azure.net'
    }
    // Azure Event Hub namespace private DNS zone
    azureEventHubNamespacePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net'
    }
    // Azure File private DNS zone
    azureFilePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.afs.azure.net'
    }
    // Azure HDInsight private DNS zone
    azureHDInsightPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azurehdinsight.net'
    }
    // Azure IoT Central private DNS zone
    azureIotCentralPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azureiotcentral.com'
    }
    // Azure IoT Device Update private DNS zone
    azureIotDeviceupdatePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.api.adu.microsoft.com'
    }
    // Azure IoT Hubs private DNS zone
    azureIotHubsPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azure-devices.net'
    }
    // Azure IoT private DNS zone
    azureIotPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azure-devices-provisioning.net'
    }
    // Azure Key Vault private DNS zone
    azureKeyVaultPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.vaultcore.azure.net'
    }
    // Azure Machine Learning workspace private DNS zone
    azureMachineLearningWorkspacePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms'
    }
    // Azure Machine Learning workspace second private DNS zone
    azureMachineLearningWorkspaceSecondPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.notebooks.azure.net'
    }
    // Azure Managed Grafana workspace private DNS zone
    azureManagedGrafanaWorkspacePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.grafana.azure.com'
    }
    // Azure Media Services key private DNS zone
    azureMediaServicesKeyPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.media.azure.net'
    }
    // Azure Media Services live private DNS zone
    azureMediaServicesLivePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.media.azure.net'
    }
    // Azure Media Services stream private DNS zone
    azureMediaServicesStreamPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.media.azure.net'
    }
    // Azure Migrate private DNS zone
    azureMigratePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.prod.migration.windowsazure.com'
    }
    // Azure Monitor private DNS zone 1
    azureMonitorPrivateDnsZoneId1: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.monitor.azure.com'
    }
    // Azure Monitor private DNS zone 2
    azureMonitorPrivateDnsZoneId2: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.oms.opinsights.azure.com'
    }
    // Azure Monitor private DNS zone 3
    azureMonitorPrivateDnsZoneId3: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.ods.opinsights.azure.com'
    }
    // Azure Monitor private DNS zone 4
    azureMonitorPrivateDnsZoneId4: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.agentsvc.azure-automation.net'
    }
    // Azure Monitor private DNS zone 5
    azureMonitorPrivateDnsZoneId5: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
    }
    // Azure Redis Cache private DNS zone
    azureRedisCachePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.redis.cache.windows.net'
    }
    // Azure Service Bus namespace private DNS zone
    azureServiceBusNamespacePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.servicebus.windows.net'
    }
    // Azure SignalR private DNS zone
    azureSignalRPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.service.signalr.net'
    }
    // Azure Site Recovery backup private DNS zone
    azureSiteRecoveryBackupPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.{regionCode}.backup.windowsazure.com'
    }
    // Azure Site Recovery blob private DNS zone
    azureSiteRecoveryBlobPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
    }
    // Azure Site Recovery queue private DNS zone
    azureSiteRecoveryQueuePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net'
    }
    // Azure Storage Blob private DNS zone
    azureStorageBlobPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
    }
    // Azure Storage Blob secondary private DNS zone
    azureStorageBlobSecPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net'
    }
    // Azure Storage DFS private DNS zone
    azureStorageDFSPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net'
    }
    // Azure Storage DFS secondary private DNS zone
    azureStorageDFSSecPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.dfs.core.windows.net'
    }
    // Azure Storage File private DNS zone
    azureStorageFilePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.file.core.windows.net'
    }
    // Azure Storage Queue private DNS zone
    azureStorageQueuePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net'
    }
    // Azure Storage Queue secondary private DNS zone
    azureStorageQueueSecPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.queue.core.windows.net'
    }
    // Azure Storage static web private DNS zone
    azureStorageStaticWebPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.web.core.windows.net'
    }
    // Azure Storage static web secondary private DNS zone
    azureStorageStaticWebSecPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.web.core.windows.net'
    }
    // Azure Storage Table private DNS zone
    azureStorageTablePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net'
    }
    // Azure Storage Table secondary private DNS zone
    azureStorageTableSecondaryPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.table.core.windows.net'
    }
    // Azure Synapse Analytics Development private DNS zone
    azureSynapseDevPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.dev.azuresynapse.net'
    }
    // Azure Synapse Analytics SQL private DNS zone
    azureSynapseSQLPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net'
    }
    // Azure Synapse Analytics SQL On-Demand private DNS zone
    azureSynapseSQLODPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.sql.azuresynapse.net'
    }
    // Azure Virtual Desktop hostpool private DNS zone
    azureVirtualDesktopHostpoolPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.wvd.microsoft.com'
    }
    // Azure Virtual Desktop workspace private DNS zone
    azureVirtualDesktopWorkspacePrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.wvd.microsoft.com'
    }
    // Azure Web private DNS zone
    azureWebPrivateDnsZoneId: {
      value: '/subscriptions/{{connectivity_subscription_id}}/resourceGroups/rg-alz-privatedns-${parLocations[0]}/providers/Microsoft.Network/privateDnsZones/privatelink.azurewebsites.net'
    }
  }

  // Audit-PeDnsZones Policy: Define which private DNS zone names to audit for compliance
  // This ensures private endpoints are using the correct DNS zones
  'Audit-PeDnsZones': {
    privateLinkDnsZones: {
      value: [
        'privatelink.azurecr.io'                          // Azure Container Registry
        'privatelink.azurewebsites.net'                   // Azure App Service & Function Apps
        'privatelink.guestconfiguration.azure.com'       // Azure Arc Guest Configuration
        'privatelink.his.arc.azure.com'                  // Azure Arc Hybrid Resource Provider
        'privatelink.dp.kubernetesconfiguration.azure.com' // Azure Arc Kubernetes Configuration
        'privatelink.siterecovery.windowsazure.com'      // Azure Site Recovery
        'privatelink.azure-automation.net'               // Azure Automation DSC Hybrid & Webhook
        'privatelink.batch.azure.com'                    // Azure Batch
        'privatelink.directline.botframework.com'        // Azure Bot Service
        'privatelink.search.windows.net'                 // Azure Cognitive Search
        'privatelink.cognitiveservices.azure.com'        // Azure Cognitive Services
        'privatelink.cassandra.cosmos.azure.com'         // Azure Cosmos DB Cassandra
        'privatelink.gremlin.cosmos.azure.com'           // Azure Cosmos DB Gremlin
        'privatelink.mongo.cosmos.azure.com'             // Azure Cosmos DB MongoDB
        'privatelink.documents.azure.com'                // Azure Cosmos DB SQL API
        'privatelink.table.cosmos.azure.com'             // Azure Cosmos DB Table
        'privatelink.adf.azure.com'                      // Azure Data Factory Portal
        'privatelink.datafactory.azure.net'              // Azure Data Factory
        'privatelink.azuredatabricks.net'                // Azure Databricks
        'privatelink.eventgrid.azure.net'                // Azure Event Grid (domains & topics)
        'privatelink.servicebus.windows.net'             // Azure Event Hub & Service Bus
        'privatelink.afs.azure.net'                      // Azure Files
        'privatelink.azurehdinsight.net'                 // Azure HDInsight
        'privatelink.azureiotcentral.com'                // Azure IoT Central
        'privatelink.api.adu.microsoft.com'              // Azure IoT Device Update
        'privatelink.azure-devices.net'                  // Azure IoT Hubs
        'privatelink.azure-devices-provisioning.net'     // Azure IoT Device Provisioning
        'privatelink.vaultcore.azure.net'                // Azure Key Vault
        'privatelink.api.azureml.ms'                     // Azure Machine Learning Workspace
        'privatelink.notebooks.azure.net'                // Azure Machine Learning Workspace (notebooks)
        'privatelink.grafana.azure.com'                  // Azure Managed Grafana
        'privatelink.media.azure.net'                    // Azure Media Services
        'privatelink.prod.migration.windowsazure.com'    // Azure Migrate
        'privatelink.monitor.azure.com'                  // Azure Monitor
        'privatelink.oms.opinsights.azure.com'           // Azure Monitor OMS
        'privatelink.ods.opinsights.azure.com'           // Azure Monitor ODS
        'privatelink.agentsvc.azure-automation.net'      // Azure Monitor Agent Service
        'privatelink.redis.cache.windows.net'            // Azure Redis Cache
        'privatelink.service.signalr.net'                // Azure SignalR
        'privatelink.blob.core.windows.net'              // Azure Storage Blob & related services
        'privatelink.dfs.core.windows.net'               // Azure Storage DFS
        'privatelink.file.core.windows.net'              // Azure Storage File
        'privatelink.queue.core.windows.net'             // Azure Storage Queue
        'privatelink.table.core.windows.net'             // Azure Storage Table
        'privatelink.web.core.windows.net'               // Azure Storage Static Web
        'privatelink.dev.azuresynapse.net'               // Azure Synapse Dev
        'privatelink.sql.azuresynapse.net'               // Azure Synapse SQL
        'privatelink.wvd.microsoft.com'                  // Azure Virtual Desktop
        // Add more DNS zone names to audit as needed
      ]
    }
  }
}
