metadata name = 'ALZ Bicep'
metadata description = 'ALZ Bicep Module used to set up Azure Landing Zones'

//================================
// Parameters
//================================

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Prefix value which will be prepended to all resource names.')
param parCompanyPrefix string = 'alz'

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for DDoS Plan.

- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.

''')
param parDdosLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

@description('Required. The networking option to select.')
param alzNetworking alzNetworkingType

@description('Optional. The hub virtual networks to create.')
param hubNetworks hubVirtualNetworkType?


//================================
// Variables
//================================


//================================
// Resources
//================================
module hubSpokeNetwork 'hub-and-spoke/main.bicep' = if(alzNetworking.networkType == 'hub-and-spoke' && !empty(hubNetworks)) {
  name: 'hubNetworks'
  params: {
    hubNetworks: [
      {
        location: 'eastus'
        addressPrefixes: ['10.0.0.0/16']
        enableAzureFirewall: false
        enableBastion: true
        enablePeering: false
        hubName: 'hub1'
        subnets: [
          {
            name: 'AzureBastionSubnet'
            addressPrefix: '20.0.15.0/24'
            networkSecurityGroupId: ''
            routeTable: ''
          }
          {
            name: 'GatewaySubnet'
            addressPrefix: '20.0.20.0/24'
            networkSecurityGroupId: ''
            routeTable: ''
          }
          {
            name: 'AzureFirewallSubnet'
            addressPrefix: '20.0.254.0/24'
            networkSecurityGroupId: ''
            routeTable: ''
          }
          {
            name: 'AzureFirewallManagementSubnet'
            addressPrefix: '20.0.253.0/24'
            networkSecurityGroupId: ''
            routeTable: ''
          }
        ]
      }
    ]
  }
}

//================================
// Definitions
//================================

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. The lock settings of the service.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')

  @description('Optional. Notes about this lock.')
  notes: string?
}

type hubNetworkingType = {
  @description('Required. ALZ network type')
  networkType: 'hub-and-spoke'
}

type virtualWanType = {
  @description('Required. ALZ network type')
  networkType: 'virtual-wan'
}

@discriminator('networkType')
type alzNetworkingType = hubNetworkingType | virtualWanType

type hubVirtualNetworkType = {

  @description('Required. The name of the hub.')
  hubName: string

  @description('Required. The address prefixes for the virtual network.')
  addressPrefixes: array

  @description('Optional. The Azure Firewall config.')
  azureFirewallSettings: azureFirewallType?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?

  @description('Optional. Enable/Disable Azure Bastion for the virtual network.')
  enableBastion: bool

  @description('Required. Enable/Disable Azure Firewall for the virtual network.')
  enableAzureFirewall: bool

  @description('Optional. The location of the virtual network. Defaults to the location of the resource group.')
  location: string

  @description('Optional. The lock settings of the virtual network.')
  lock: lockType?

  @description('Optional. The diagnostic settings of the virtual network.')
  diagnosticSettings: diagnosticSettingType?

  @description('Optional. The DDoS protection plan resource ID.')
  ddosProtectionPlanResourceId: string?

  @description('Optional. The DNS servers of the virtual network.')
  dnsServers: array?

  @description('Optional. The flow timeout in minutes.')
  flowTimeoutInMinutes: int?

  @description('Optional. Enable/Disable peering for the virtual network.')
  enablePeering: bool

  @description('Optional. The peerings of the virtual network.')
  peeringSettings: peeringSettingsType?

  @description('Optional. The role assignments to create.')
  roleAssignments: roleAssignmentType?

  @description('Optional. Routes to add to the virtual network route table.')
  routes: array?

  @description('Optional. The subnets of the virtual network.')
  subnets: subnetOptionsType

  @description('Optional. The tags of the virtual network.')
  tags: object?

  @description('Optional. Enable/Disable VNet encryption.')
  vnetEncryption: bool?

  @description('Optional. The VNet encryption enforcement settings of the virtual network.')
  vnetEncryptionEnforcement: 'AllowUnencrypted' | 'DropUnencrypted'?

  @description('Required. The virtual network gateway configuration.')
  virtualNetworkGatewayConfig: virtualNetworkGatewayConfigType

  @description('Optional. The Azure Bastion config.')
  bastionHost: {
    @description('Optional. Enable/Disable copy/paste functionality.')
    disableCopyPaste: bool?

    @description('Optional. Enable/Disable file copy functionality.')
    enableFileCopy: bool?

    @description('Optional. Enable/Disable IP connect functionality.')
    enableIpConnect: bool?

    @description('Optional. Enable/Disable shareable link functionality.')
    enableShareableLink: bool?

    @description('Optional. The number of scale units for the Bastion host. Defaults to 4.')
    scaleUnits: int?

    @description('Optional. The SKU name of the Bastion host. Defaults to Standard.')
    skuName: string?

    @description('Optional. The bastion\'s outbound ssh and rdp ports\'.')
    outboundSshRdpPorts: array?
  }?
}[]?

type peeringSettingsType = {
  @description('Optional. Allow forwarded traffic.')
  allowForwardedTraffic: bool?

  @description('Optional. Allow gateway transit.')
  allowGatewayTransit: bool?

  @description('Optional. Allow virtual network access.')
  allowVirtualNetworkAccess: bool?

  @description('Optional. Use remote gateways.')
  useRemoteGateways: bool?

  @description('Optional. Remote virtual network name.')
  remoteVirtualNetworkName: string?
}[]?

type azureFirewallType = {
  @description('Optional. Hub IP addresses.')
  hubIpAddresses: object?

  @description('Optional. Virtual Hub ID.')
  virtualHub: string?

  @description('Optional. Additional public IP configurations.')
  additionalPublicIpConfigurations: array?

  @description('Optional. Application rule collections.')
  applicationRuleCollections: array?

  @description('Optional. Azure Firewall SKU.')
  azureSkuTier: 'Basic' | 'Standard' | 'Premium'?

  @description('Optional. Diagnostic settings.')
  diagnosticSettings: diagnosticSettingType?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?

  @description('Optional. Firewall policy ID.')
  firewallPolicyId: string?

  @description('Optional. The location of the virtual network. Defaults to the location of the resource group.')
  location: string?

  @description('Optional. Lock settings.')
  lock: lockType?

  @description('Optional. Management IP address configuration.')
  managementIPAddressObject: object?

  @description('Optional. Management IP resource ID.')
  managementIPResourceID: string?

  @description('Optional. NAT rule collections.')
  natRuleCollections: array?

  @description('Optional. Network rule collections.')
  networkRuleCollections: array?

  @description('Optional. Public IP address object.')
  publicIPAddressObject: object?

  @description('Optional. Public IP resource ID.')
  publicIPResourceID: string?

  @description('Optional. Role assignments.')
  roleAssignments: roleAssignmentType?

  @description('Optional. Tags of the resource.')
  tags: object?

  @description('Optional. Threat Intel mode.')
  threatIntelMode: ('Alert' | 'Deny' | 'Off')?

  @description('Optional. Zones.')
  zones: int[]?

  @description('Optional. Enable/Disable dns proxy setting.')
  dnsProxyEnabled: bool?

  @description('Optional. Array of custom DNS servers used by Azure Firewall.')
  firewallDnsServers: array?
}?

type roleAssignmentType = {
  @description('Optional. The name (as GUID) of the role assignment. If not provided, a GUID will be generated.')
  name: string?

  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device')?

  @description('Optional. The description of the role assignment.')
  description: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container".')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}[]?

type diagnosticSettingType = {
  @description('Optional. The name of diagnostic setting.')
  name: string?

  @description('Optional. The name of logs that will be streamed. "allLogs" includes all possible logs for the resource. Set to `[]` to disable log collection.')
  logCategoriesAndGroups: {
    @description('Optional. Name of a Diagnostic Log category for a resource type this setting is applied to. Set the specific logs to collect here.')
    category: string?

    @description('Optional. Name of a Diagnostic Log category group for a resource type this setting is applied to. Set to `allLogs` to collect all logs.')
    categoryGroup: string?

    @description('Optional. Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('Optional. The name of metrics that will be streamed. "allMetrics" includes all possible metrics for the resource. Set to `[]` to disable metric collection.')
  metricCategories: {
    @description('Required. Name of a Diagnostic Metric category for a resource type this setting is applied to. Set to `AllMetrics` to collect all metrics.')
    category: string

    @description('Optional. Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('Optional. A string indicating whether the export to Log Analytics should use the default destination type, i.e. AzureDiagnostics, or use a destination type.')
  logAnalyticsDestinationType: ('Dedicated' | 'AzureDiagnostics')?

  @description('Optional. Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.value.')
  workspaceResourceId: string?

  @description('Optional. Resource ID of the diagnostic storage account. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.value.')
  storageAccountResourceId: string?

  @description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
  eventHubAuthorizationRuleResourceId: string?

  @description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.value.')
  eventHubName: string?

  @description('Optional. The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.')
  marketplacePartnerResourceId: string?
}[]?

type subnetOptionsType = ({
  @description('Name of subnet.')
  name: string

  @description('IP-address range for subnet.')
  addressPrefix: string

  @description('Id of Network Security Group to associate with subnet.')
  networkSecurityGroupId: string?

  @description('Id of Route Table to associate with subnet.')
  routeTable: string?

  @description('Name of the delegation to create for the subnet.')
  delegation: string?
})[]

type virtualNetworkGatewayConfigType = {
  gatewayType: 'Vpn' | 'ExpressRoute'
  skuName:
    | 'Basic'
    | 'VpnGw1'
    | 'VpnGw2'
    | 'VpnGw3'
    | 'VpnGw4'
    | 'VpnGw5'
    | 'VpnGw1AZ'
    | 'VpnGw2AZ'
    | 'VpnGw3AZ'
    | 'VpnGw4AZ'
    | 'VpnGw5AZ'
    | 'Standard'
    | 'HighPerformance'
    | 'UltraPerformance'
    | 'ErGw1AZ'
    | 'ErGw2AZ'
    | 'ErGw3AZ'
  clusterMode: 'activeActiveBgp' | 'activeActiveNoBgp' | 'activePassiveBgp' | 'activePassiveNoBgp'?
  vpnType: 'RouteBased' | 'PolicyBased'?
  vpnGatewayGeneration: 'Generation1' | 'Generation2' | 'None'?
  enableBgpRouteTranslationForNat: bool?
  enableDnsForwarding: bool?
  asn: int?
  customBgpIpAddresses: string?
  publicIpZones: bool
  clientRootCertData: string?
  vpnClientAddressPoolPrefix: string?
  vpnClientAadConfiguration: object?
}?
