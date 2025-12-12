metadata name = 'ALZ Bicep - Int-Root Module'
metadata description = 'ALZ Bicep Module used to deploy the Int-Root Management Group and associated resources such as policy definitions, policy set definitions (initiatives), custom RBAC roles, policy assignments, and policy exemptions.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Int-Root.')
param intRootConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

@description('Optional. Policy assignment overrides. Specify the policy parameter values, location, or scope you want to change (logAnalytics, emailSecurityContact, etc.). Role definitions are hardcoded variables and cannot be overridden.')
param parPolicyAssignmentParameterOverrides object = {}

var builtInRoleDefinitionIds = {
  owner: '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  logAnalyticsContributor: '/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293'
  monitoringContributor: '/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa'
  rbacSecurityAdmin: '/providers/Microsoft.Authorization/roleDefinitions/fb1c8493-542b-48eb-b624-b4c8fea62acd'
  sqlSecurityManager: '/providers/Microsoft.Authorization/roleDefinitions/056cd41c-7e88-42e1-933e-88ba6a50c9c3'
  monitoringPolicyContributor: '/providers/Microsoft.Authorization/roleDefinitions/47be4a87-7950-4631-9daf-b664a405f074'
}

var alzRbacRoleDefsJson = [
  loadJsonContent('../../lib/alz/0d95a564-76a6-5489-9bb7-ee099c979392.alz_role_definition.json')
  loadJsonContent('../../lib/alz/1a71cbe6-6cb7-57f5-9cf1-f3971f40fcfa.alz_role_definition.json')
  loadJsonContent('../../lib/alz/45613b78-4a7e-5d1f-ab20-8c6dec903bb5.alz_role_definition.json')
  loadJsonContent('../../lib/alz/85f7bdaf-24fb-5c33-80ad-ffae9246eeb9.alz_role_definition.json')
  loadJsonContent('../../lib/alz/b0b8fb15-899d-5b9d-af28-c92583a31ed4.alz_role_definition.json')
]

var alzPolicyDefsJson = [
  loadJsonContent('../../lib/alz/Append-AppService-httpsonly.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Append-AppService-latestTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Append-KV-SoftDelete.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Append-Redis-disableNonSslPort.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Append-Redis-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-AzureHybridBenefit.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-Disks-UnusedResourcesCostOptimization.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-Kubernetes-ApprovedHostNetworkAndPorts.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-MachineLearning-PrivateEndpointId.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-PrivateLinkDnsZones.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-PublicIpAddresses-UnusedResourcesCostOptimization.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-ServerFarms-UnusedResourcesCostOptimization.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-Tags-Mandatory-Rg.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Audit-Tags-Mandatory.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AA-child-resources.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-APIM-TLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AppGw-Without-Tls.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AppGW-Without-WAF.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AppService-without-BYOC.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AppServiceApiApp-http.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AppServiceFunctionApp-http.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AppServiceWebApp-http.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-AzFw-Without-Policy.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-CognitiveServices-NetworkAcls.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-CognitiveServices-Resource-Kinds.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-CognitiveServices-RestrictOutboundNetworkAccess.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Databricks-NoPublicIp.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Databricks-Sku.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Databricks-VirtualNetwork.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-EH-minTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-EH-Premium-CMK.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-FileServices-InsecureAuth.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-FileServices-InsecureKerberos.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-FileServices-InsecureSmbChannel.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-FileServices-InsecureSmbVersions.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-LogicApp-Public-Network.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-LogicApps-Without-Https.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-Aks.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-Compute-SubnetId.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-Compute-VmSize.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-ComputeCluster-RemoteLoginPortPublicAccess.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-ComputeCluster-Scale.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-HbiWorkspace.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-PublicAccessWhenBehindVnet.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MachineLearning-PublicNetworkAccess.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MgmtPorts-From-Internet.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-MySql-http.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-PostgreSql-http.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Private-DNS-Zones.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-PublicEndpoint-MariaDB.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-PublicIP.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-RDP-From-Internet.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Redis-http.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Service-Endpoints.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Sql-minTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-SqlMi-minTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-ContainerDeleteRetentionPolicy.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-CopyScope.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-CorsRules.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-LocalUser.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-minTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-NetworkAclsBypass.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-NetworkAclsVirtualNetworkRules.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-ResourceAccessRulesResourceId.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-ResourceAccessRulesTenantId.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-ServicesEncryption.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Storage-SFTP.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-StorageAccount-CustomDomain.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Subnet-Without-Nsg.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Subnet-Without-Penp.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-Subnet-Without-Udr.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-UDR-With-Specific-NextHop.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-VNET-Peer-Cross-Sub.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-VNET-Peering-To-Non-Approved-VNETs.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deny-VNet-Peering.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/DenyAction-ActivityLogs.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/DenyAction-DeleteResources.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/DenyAction-DiagnosticLogs.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-ASC-SecurityContacts.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Budget.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Custom-Route-Table.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-DDoSProtection.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-AA.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-ACI.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-ACR.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-AnalysisService.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-ApiForFHIR.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-APIMgmt.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-ApplicationGateway.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-AVDScalingPlans.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-Bastion.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-CDNEndpoints.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-CognitiveServices.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-CosmosDB.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-Databricks.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-DataExplorerCluster.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-DataFactory.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-DLAnalytics.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-EventGridSub.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-EventGridSystemTopic.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-EventGridTopic.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-ExpressRoute.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-Firewall.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-FrontDoor.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-Function.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-HDInsight.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-iotHub.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-LoadBalancer.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-LogAnalytics.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-LogicAppsISE.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-MariaDB.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-MediaService.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-MlWorkspace.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-MySQL.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-NetworkSecurityGroups.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-NIC.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-PostgreSQL.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-PowerBIEmbedded.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-RedisCache.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-Relay.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-SignalR.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-SQLElasticPools.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-SQLMI.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-TimeSeriesInsights.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-TrafficManager.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-VirtualNetwork.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-VM.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-VMSS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-VNetGW.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-VWanS2SVPNGW.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-WebServerFarm.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-Website.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-WVDAppGroup.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-WVDHostPools.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-WVDWorkspace.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-FirewallPolicy.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-LogicApp-TLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-Arc-SQL-DCR-Association.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-Arc-Sql-DefenderSQL-DCR.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-SQL-AMA.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-SQL-DefenderSQL-DCR.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-SQL-DefenderSQL.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MySQL-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Nsg-FlowLogs-to-LA.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Nsg-FlowLogs.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-PostgreSQL-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Private-DNS-Generic.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-AuditingSettings.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-SQL-minTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-SecurityAlertPolicies.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-Tde.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-vulnerabilityAssessments_20230706.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-vulnerabilityAssessments.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-SqlMi-minTLS.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Storage-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-UserAssignedManagedIdentity-VMInsights.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Vm-autoShutdown.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-VNET-HubSpoke.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Windows-DomainJoin.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Modify-NSG.alz_policy_definition.json')
  loadJsonContent('../../lib/alz/Modify-UDR.alz_policy_definition.json')
]

var alzPolicySetDefsJson = [
  loadJsonContent('../../lib/alz/Audit-TrustedLaunch.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Audit-UnusedResourcesCostOptimization.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deny-PublicPaaSEndpoints.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/DenyAction-DeleteProtection.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-ASC-Monitoring-Tp.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-AUM-CheckUpdates.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Diagnostics-LogAnalytics.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-Config_20240319.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-Config.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-DefenderSQL-AMA.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Private-DNS-Zones.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-Security_20240529.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Deploy-Sql-Security.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-ACSB.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-ALZ-Decomm.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-ALZ-Sandbox.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Backup.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Encryption-CMK_20250218.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-EncryptTransit_20240509.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-EncryptTransit_20241211.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-EncryptTransit.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-APIM.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-AppServices.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Automation.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-BotService.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-CognitiveServices.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Compute.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-ContainerApps.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-ContainerInstance.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-ContainerRegistry.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-CosmosDb.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-DataExplorer.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-DataFactory.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-EventGrid.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-EventHub.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-KeyVault-Sup.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-KeyVault.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Kubernetes.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-MachineLearning.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-MySQL.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Network_20250326.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Network.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-OpenAI.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-PostgreSQL.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-ServiceBus.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-SQL.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Storage.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-Synapse.alz_policy_set_definition.json')
  loadJsonContent('../../lib/alz/Enforce-Guardrails-VirtualDesktop.alz_policy_set_definition.json')
]

var alzPolicyAssignmentsJson = [
  loadJsonContent('../../lib/alz/Audit-ResourceRGLocation.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Audit-TrustedLaunch.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Audit-UnusedResources.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Audit-ZoneResiliency.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deny-Classic-Resources.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deny-UnmanagedDisk.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-ASC-Monitoring-Tp.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-AzActivity-Log.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-Diag-LogsCat.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-MDEndpoints.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-MDEndpointsAMA.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-Config-H224.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-OssDb.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-MDFC-SqlAtp.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Deploy-SvcHealth-BuiltIn.alz_policy_assignment.json')
  loadJsonContent('../../lib/alz/Enforce-ACSB.alz_policy_assignment.json')
]

var alzPolicyAssignmentRoleDefinitions = {
  'Deploy-MDFC-Config-H224': [builtInRoleDefinitionIds.owner]
  'Deploy-MDEndpoints': [builtInRoleDefinitionIds.contributor]
  'Deploy-MDEndpointsAMA': [builtInRoleDefinitionIds.rbacSecurityAdmin]
  'Deploy-AzActivity-Log': [
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
  ]
  'Deploy-Diag-LogsCat': [
    builtInRoleDefinitionIds.logAnalyticsContributor
    builtInRoleDefinitionIds.monitoringContributor
  ]
  'Enforce-ACSB': [builtInRoleDefinitionIds.contributor]
  'Deploy-MDFC-OssDb': [builtInRoleDefinitionIds.contributor]
  'Deploy-MDFC-SqlAtp': [builtInRoleDefinitionIds.sqlSecurityManager]
  'Deploy-SvcHealth-BuiltIn': [builtInRoleDefinitionIds.monitoringPolicyContributor]
}
var managementGroupFinalName = intRootConfig.?managementGroupName ?? 'alz'

var alzPolicyAssignmentsWithOverrides = [
  for policyAssignment in alzPolicyAssignmentsJson: union(
    policyAssignment,
    contains(parPolicyAssignmentParameterOverrides, policyAssignment.name)
      ? {
          location: parPolicyAssignmentParameterOverrides[policyAssignment.name].?location ?? parLocations[0]
          identity: policyAssignment.?identity
          properties: union(
            policyAssignment.properties,
            parPolicyAssignmentParameterOverrides[policyAssignment.name].?scope != null
              ? {
                  scope: parPolicyAssignmentParameterOverrides[policyAssignment.name].scope
                }
              : {
                  scope: '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}'
                },
            contains(parPolicyAssignmentParameterOverrides[policyAssignment.name], 'parameters')
              ? {
                  parameters: union(
                    policyAssignment.properties.?parameters ?? {},
                    parPolicyAssignmentParameterOverrides[policyAssignment.name].parameters
                  )
                }
              : {},
            contains(alzPolicyAssignmentRoleDefinitions, policyAssignment.name)
              ? {
                  roleDefinitionIds: alzPolicyAssignmentRoleDefinitions[policyAssignment.name]
                }
              : {},
            {
              policyDefinitionId: replace(
                policyAssignment.properties.policyDefinitionId,
                '/providers/Microsoft.Management/managementGroups/alz/',
                '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}/'
              )
            }
          )
        }
      : {
          location: parLocations[0]
          identity: policyAssignment.?identity
          properties: union(
            policyAssignment.properties,
            {
              scope: '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}'
            },
            contains(alzPolicyAssignmentRoleDefinitions, policyAssignment.name)
              ? {
                  roleDefinitionIds: alzPolicyAssignmentRoleDefinitions[policyAssignment.name]
                }
              : {},
            {
              policyDefinitionId: replace(
                policyAssignment.properties.policyDefinitionId,
                '/providers/Microsoft.Management/managementGroups/alz/',
                '/providers/Microsoft.Management/managementGroups/${managementGroupFinalName}/'
              )
            }
          )
        }
  )
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, intRootConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, intRootConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, intRootConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsWithOverrides, intRootConfig.?customerPolicyAssignments ?? [])

var unionedPolicyAssignmentNames = [for policyAssignment in unionedPolicyAssignments: policyAssignment.name]

var deduplicatedPolicyAssignments = filter(
  unionedPolicyAssignments,
  (policyAssignment, index) => index == indexOf(unionedPolicyAssignmentNames, policyAssignment.name)
)

var allRbacRoleDefs = [
  for roleDef in unionedRbacRoleDefs: {
    name: roleDef.name
    roleName: replace(roleDef.properties.roleName, '(alz)', '(${managementGroupFinalName})')
    description: roleDef.properties.description
    actions: roleDef.properties.permissions[0].actions
    notActions: roleDef.properties.permissions[0].notActions
    dataActions: roleDef.properties.permissions[0].dataActions
    notDataActions: roleDef.properties.permissions[0].notDataActions
  }
]

var allPolicyDefs = [
  for policy in unionedPolicyDefs: {
    name: policy.name
    properties: {
      description: policy.properties.?description
      displayName: policy.properties.?displayName
      metadata: policy.properties.?metadata
      mode: policy.properties.?mode
      parameters: policy.properties.?parameters
      policyType: policy.properties.?policyType
      policyRule: policy.properties.policyRule
      version: policy.properties.?version
    }
  }
]

var allPolicySetDefinitions = [
  for policySet in unionedPolicySetDefs: {
    name: policySet.name
    properties: {
      description: policySet.properties.?description
      displayName: policySet.properties.?displayName
      metadata: policySet.properties.?metadata
      parameters: policySet.properties.?parameters
      policyType: policySet.properties.?policyType
      version: policySet.properties.?version
      policyDefinitions: policySet.properties.policyDefinitions
      policyDefinitionGroups: policySet.properties.?policyDefinitionGroups
    }
  }
]

var allPolicyAssignments = [
  for policyAssignment in deduplicatedPolicyAssignments: {
    name: policyAssignment.name
    displayName: policyAssignment.properties.?displayName
    description: policyAssignment.properties.?description
    policyDefinitionId: policyAssignment.properties.policyDefinitionId
    parameters: policyAssignment.properties.?parameters
    parameterOverrides: policyAssignment.properties.?parameterOverrides
    identity: policyAssignment.identity.?type ?? 'None'
    userAssignedIdentityId: policyAssignment.properties.?userAssignedIdentityId
    roleDefinitionIds: policyAssignment.properties.?roleDefinitionIds
    nonComplianceMessages: policyAssignment.properties.?nonComplianceMessages
    metadata: policyAssignment.properties.?metadata
    enforcementMode: policyAssignment.properties.?enforcementMode ?? 'Default'
    notScopes: policyAssignment.properties.?notScopes
    location: policyAssignment.?location
    overrides: policyAssignment.properties.?overrides
    resourceSelectors: policyAssignment.properties.?resourceSelectors
    definitionVersion: policyAssignment.properties.?definitionVersion
    additionalManagementGroupsIDsToAssignRbacTo: policyAssignment.properties.?additionalManagementGroupsIDsToAssignRbacTo
    additionalSubscriptionIDsToAssignRbacTo: policyAssignment.properties.?additionalSubscriptionIDsToAssignRbacTo
    additionalResourceGroupResourceIDsToAssignRbacTo: policyAssignment.properties.?additionalResourceGroupResourceIDsToAssignRbacTo
  }
]

// ============ //
// Dependencies //
// ============ //

resource tenantRootMgExisting 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: tenant().tenantId
}

// ============ //
//   Resources  //
// ============ //

module intRoot 'br/public:avm/ptn/alz/empty:0.3.5' = {
  params: {
    createOrUpdateManagementGroup: intRootConfig.?createOrUpdateManagementGroup
    managementGroupName: managementGroupFinalName
    managementGroupDisplayName: intRootConfig.?managementGroupDisplayName ?? 'Azure Landing Zones'
    managementGroupDoNotEnforcePolicyAssignments: intRootConfig.?managementGroupDoNotEnforcePolicyAssignments
    managementGroupExcludedPolicyAssignments: intRootConfig.?managementGroupExcludedPolicyAssignments
    managementGroupParentId: intRootConfig.?managementGroupParentId ?? tenantRootMgExisting.name
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: intRootConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: parLocations[0]
    subscriptionsToPlaceInManagementGroup: intRootConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: intRootConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: intRootConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: intRootConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: intRootConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: intRootConfig.?waitForConsistencyCounterBeforeRoleAssignments
    waitForConsistencyCounterBeforeSubPlacement: intRootConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../alzCoreType.bicep'
