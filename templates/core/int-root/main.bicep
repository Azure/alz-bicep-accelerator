metadata name = 'ALZ Bicep - Int-Root Module'
metadata description = 'ALZ Bicep Module used to deploy the Int-Root Management Group and associated resources such as policy/policy set definitions, custom RBAC roles, and policy assignments.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration for Int-Root.')
param intRootConfig alzCoreType

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

var alzRbacRoleDefsJson = [
  loadJsonContent('../lib/role_definitions/application_owners.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/network_management.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/network_subnet_contributor.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/security_operations.alz_role_definition.json')
  loadJsonContent('../lib/role_definitions/subscription_owner.alz_role_definition.json')
]

var alzPolicyDefsJson = [
  loadJsonContent('../lib/policy_definitions/Append-AppService-httpsonly.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Append-AppService-latestTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Append-KV-SoftDelete.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Append-Redis-disableNonSslPort.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Append-Redis-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-AzureHybridBenefit.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-Disks-UnusedResourcesCostOptimization.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-MachineLearning-PrivateEndpointId.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-PrivateLinkDnsZones.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-PublicIpAddresses-UnusedResourcesCostOptimization.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-ServerFarms-UnusedResourcesCostOptimization.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-Tags-Mandatory-Rg.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Audit-Tags-Mandatory.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AA-child-resources.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-APIM-TLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AppGw-Without-Tls.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AppGW-Without-WAF.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AppService-without-BYOC.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AppServiceApiApp-http.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AppServiceFunctionApp-http.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AppServiceWebApp-http.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-AzFw-Without-Policy.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-CognitiveServices-NetworkAcls.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-CognitiveServices-Resource-Kinds.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-CognitiveServices-RestrictOutboundNetworkAccess.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Databricks-NoPublicIp.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Databricks-Sku.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Databricks-VirtualNetwork.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-EH-minTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-EH-Premium-CMK.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-FileServices-InsecureAuth.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-FileServices-InsecureKerberos.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-FileServices-InsecureSmbChannel.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-FileServices-InsecureSmbVersions.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-LogicApp-Public-Network.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-LogicApps-Without-Https.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-Aks.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-Compute-SubnetId.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-Compute-VmSize.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-ComputeCluster-RemoteLoginPortPublicAccess.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-ComputeCluster-Scale.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-HbiWorkspace.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-PublicAccessWhenBehindVnet.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MachineLearning-PublicNetworkAccess.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MgmtPorts-From-Internet.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-MySql-http.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-PostgreSql-http.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Private-DNS-Zones.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-PublicEndpoint-MariaDB.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-PublicIP.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-RDP-From-Internet.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Redis-http.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Service-Endpoints.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Sql-minTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-SqlMi-minTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-ContainerDeleteRetentionPolicy.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-CopyScope.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-CorsRules.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-LocalUser.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-minTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-NetworkAclsBypass.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-NetworkAclsVirtualNetworkRules.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-ResourceAccessRulesResourceId.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-ResourceAccessRulesTenantId.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-ServicesEncryption.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Storage-SFTP.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-StorageAccount-CustomDomain.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Subnet-Without-Nsg.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Subnet-Without-Penp.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-Subnet-Without-Udr.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-UDR-With-Specific-NextHop.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-VNET-Peer-Cross-Sub.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-VNET-Peering-To-Non-Approved-VNETs.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deny-VNet-Peering.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/DenyAction-ActivityLogs.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/DenyAction-DeleteResources.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/DenyAction-DiagnosticLogs.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-ASC-SecurityContacts.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Budget.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Custom-Route-Table.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-DDoSProtection.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-AA.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-ACI.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-ACR.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-AnalysisService.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-ApiForFHIR.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-APIMgmt.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-ApplicationGateway.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-AVDScalingPlans.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-Bastion.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-CDNEndpoints.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-CognitiveServices.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-CosmosDB.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-Databricks.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-DataExplorerCluster.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-DataFactory.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-DLAnalytics.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-EventGridSub.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-EventGridSystemTopic.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-EventGridTopic.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-ExpressRoute.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-Firewall.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-FrontDoor.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-Function.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-HDInsight.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-iotHub.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-LoadBalancer.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-LogAnalytics.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-LogicAppsISE.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-MariaDB.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-MediaService.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-MlWorkspace.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-MySQL.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-NetworkSecurityGroups.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-NIC.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-PostgreSQL.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-PowerBIEmbedded.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-RedisCache.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-Relay.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-SignalR.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-SQLElasticPools.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-SQLMI.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-TimeSeriesInsights.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-TrafficManager.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-VirtualNetwork.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-VM.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-VMSS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-VNetGW.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-VWanS2SVPNGW.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-WebServerFarm.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-Website.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-WVDAppGroup.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-WVDHostPools.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Diagnostics-WVDWorkspace.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-FirewallPolicy.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-LogicApp-TLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-MDFC-Arc-SQL-DCR-Association.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-MDFC-Arc-Sql-DefenderSQL-DCR.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-MDFC-SQL-AMA.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-MDFC-SQL-DefenderSQL-DCR.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-MDFC-SQL-DefenderSQL.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-MySQL-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Nsg-FlowLogs-to-LA.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Nsg-FlowLogs.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-PostgreSQL-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Private-DNS-Generic.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Sql-AuditingSettings.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-SQL-minTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Sql-SecurityAlertPolicies.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Sql-Tde.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Sql-vulnerabilityAssessments_20230706.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Sql-vulnerabilityAssessments.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-SqlMi-minTLS.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Storage-sslEnforcement.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-UserAssignedManagedIdentity-VMInsights.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Vm-autoShutdown.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-VNET-HubSpoke.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Deploy-Windows-DomainJoin.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Modify-NSG.alz_policy_definition.json')
  loadJsonContent('../lib/policy_definitions/Modify-UDR.alz_policy_definition.json')
]

var alzPolicySetDefsJson = [
  loadJsonContent('../lib/policy_set_definitions/Audit-TrustedLaunch.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Audit-UnusedResourcesCostOptimization.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deny-PublicPaaSEndpoints.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/DenyAction-DeleteProtection.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-AUM-CheckUpdates.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-Diagnostics-LogAnalytics.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-MDFC-Config_20240319.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-MDFC-Config.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-MDFC-DefenderSQL-AMA.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-Private-DNS-Zones.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-Sql-Security_20240529.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Deploy-Sql-Security.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-ACSB.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-ALZ-Decomm.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-ALZ-Sandbox.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Backup.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Encryption-CMK_20250218.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-EncryptTransit_20240509.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-EncryptTransit_20241211.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-EncryptTransit.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-APIM.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-AppServices.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-Automation.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-BotService.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-CognitiveServices.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-Compute.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-ContainerApps.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-ContainerInstance.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-ContainerRegistry.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-CosmosDb.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-DataExplorer.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-DataFactory.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-EventGrid.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-EventHub.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-KeyVault-Sup.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-KeyVault.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-Kubernetes.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-MachineLearning.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-MySQL.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-Network.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-OpenAI.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-PostgreSQL.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-ServiceBus.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-SQL.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-Storage.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-Synapse.alz_policy_set_definition.json')
  loadJsonContent('../lib/policy_set_definitions/Enforce-Guardrails-VirtualDesktop.alz_policy_set_definition.json')
]

var alzPolicyAssignmentsDefs = [
  loadJsonContent('../lib/policy_assignments/Audit-TrustedLaunch.alz_policy_assignment.json')
]

var unionedRbacRoleDefs = union(alzRbacRoleDefsJson, intRootConfig.?customerRbacRoleDefs ?? [])

var unionedPolicyDefs = union(alzPolicyDefsJson, intRootConfig.?customerPolicyDefs ?? [])

var unionedPolicySetDefs = union(alzPolicySetDefsJson, intRootConfig.?customerPolicySetDefs ?? [])

var unionedPolicyAssignments = union(alzPolicyAssignmentsDefs, intRootConfig.?customerPolicyAssignments ?? [])

var allRbacRoleDefs = [
  for roleDef in unionedRbacRoleDefs: {
    name: roleDef.name
    roleName: roleDef.properties.roleName
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
      description: policy.properties.description
      displayName: policy.properties.displayName
      metadata: policy.properties.metadata
      parameters: policy.properties.parameters
      policyType: policy.properties.policyType
    }
  }
]

var allPolicySetDefinitions = [
  for policySet in unionedPolicySetDefs: {
    name: policySet.name
    properties: {
      description: policySet.properties.description
      displayName: policySet.properties.displayName
      metadata: policySet.properties.metadata
      parameters: policySet.properties.parameters
      policyType: policySet.properties.policyType
      version: policySet.properties.version
      policyDefinitions: policySet.properties.policyDefinitions
    }
  }
]

var allPolicyAssignments = [
  for policyAssignment in unionedPolicyAssignments: {
    name: policyAssignment.name
    description: policyAssignment.properties.description
    displayName: policyAssignment.properties.displayName
    policyDefinitionId: policyAssignment.properties.policyDefinitionId
    enforcementMode: policyAssignment.properties.enforcementMode
    identity: policyAssignment.properties.identity
    userAssignedIdentityId: policyAssignment.properties.userAssignedIdentity
    roleDefinitionIds: policyAssignment.properties.roleDefinitionIds
    parameters: policyAssignment.properties.parameters
    nonComplianceMessages: policyAssignment.properties.nonComplianceMessages
    metadata: policyAssignment.properties.metadata
    overrides: policyAssignment.properties.overrides
    resourceSelectors: policyAssignment.properties.resourceSelectors
    definitionVersion: policyAssignment.properties.?definitionVersion
    notScopes: policyAssignment.properties.notScopes
    additionalManagementGroupsIDsToAssignRbacTo: policyAssignment.properties.additionalManagementGroupsIDsToAssignRbacTo
    additionalSubscriptionIDsToAssignRbacTo: policyAssignment.properties.additionalSubscriptionIDsToAssignRbacTo
    additionalResourceGroupResourceIDsToAssignRbacTo: policyAssignment.properties.additionalResourceGroupResourceIDsToAssignRbacTo
  }
]

// ============ //
// Dependencies //
// ============ //

resource tenantRootMgExisting 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: tenant().tenantId
}

module intRoot 'br/public:avm/ptn/alz/empty:0.2.0' = {
  params: {
    createOrUpdateManagementGroup: intRootConfig.?createOrUpdateManagementGroup
    managementGroupName: intRootConfig.?managementGroupName ?? 'ALZ'
    managementGroupDisplayName: intRootConfig.?managementGroupDisplayName ?? 'Azure Landing Zones'
    managementGroupParentId: tenantRootMgExisting.id
    managementGroupCustomRoleDefinitions: allRbacRoleDefs
    managementGroupRoleAssignments: intRootConfig.?customerRbacRoleAssignments
    managementGroupCustomPolicyDefinitions: allPolicyDefs
    managementGroupCustomPolicySetDefinitions: allPolicySetDefinitions
    managementGroupPolicyAssignments: allPolicyAssignments
    location: intRootConfig.?location
    subscriptionsToPlaceInManagementGroup: intRootConfig.?subscriptionsToPlaceInManagementGroup
    waitForConsistencyCounterBeforeCustomPolicyDefinitions: intRootConfig.?waitForConsistencyCounterBeforeCustomPolicyDefinitions
    waitForConsistencyCounterBeforeCustomPolicySetDefinitions: intRootConfig.?waitForConsistencyCounterBeforeCustomPolicySetDefinitions
    waitForConsistencyCounterBeforeCustomRoleDefinitions: intRootConfig.?waitForConsistencyCounterBeforeCustomRoleDefinitions
    waitForConsistencyCounterBeforePolicyAssignments: intRootConfig.?waitForConsistencyCounterBeforePolicyAssignments
    waitForConsistencyCounterBeforeRoleAssignments: intRootConfig.?waitForConsistencyCounterBeforeRoleAssignment
    waitForConsistencyCounterBeforeSubPlacement: intRootConfig.?waitForConsistencyCounterBeforeSubPlacement
    enableTelemetry: parTelemetryOptOut ? false : true
  }
}

// ================ //
// Type Definitions
// ================ //

@export()
type alzCoreType = {
  @description('Optional. Boolean to create or update the management group. If set to false, the module will only check if the management group exists and do a GET on it before it continues to deploy resources to it.')
  createOrUpdateManagementGroup: bool

  @description('The name of the management group to create or update.')
  managementGroupName: string?

  @description('The display name of the management group to create or update.')
  managementGroupDisplayName: string?

  @description('The parent management group ID to use for the management group to create or update. If not specified, the tenant root management group will be used.')
  managementGroupParentId: string?

  @description('Optional. Additional customer provided RBAC role definitions to be used in tandem with the ALZ RBAC role definitions.')
  customerRbacRoleDefs: array?

  @description('Optional. Customer provided RBAC role assignments.')
  customerRbacRoleAssignments: array?

  @description('Optional. Additional customer provided policy definitions to be used in tandem with the ALZ policy definitions.')
  customerPolicyDefs: array?

  @description('Optional. Additional customer provided policy set definitions to be used in tandem with the ALZ policy set definitions.')
  customerPolicySetDefs: array?

  @description('Optional. Set to true to enable telemetry for the deployment. Set to false to opt-out of telemetry.')
  customerPolicyAssignments: array?

  @description('The location to use for the management group. This is used for the deployment and not the management group itself.')
  location: string?

  @description('Optional. An array of subscription IDs to place in the management group. If not specified, no subscriptions will be placed in the management group.')
  subscriptionsToPlaceInManagementGroup: array?

  @description('Optional. The number of consistency counters to wait for before creating or updating custom policy definitions. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating custom policy set definitions. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating custom role definitions. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeCustomRoleDefinitions: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating policy assignments. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforePolicyAssignments: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating role assignments. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeRoleAssignment: int?

  @description('Optional. The number of consistency counters to wait for before sub placement. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeSubPlacement: int?
}
