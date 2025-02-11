metadata name = 'ALZ Bicep - Hub Networking'
metadata description = 'ALZ Bicep Module used to set up hub networking for Azure Virtual WAN.'

//================================
// Parameters
//================================

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

@description('Optional. The hub virtual networks to create.')
param hubNetworks hubVirtualNetworkType?

//=====================
// Foundational
//=====================

module resBastionNsg 'br/public:avm/res/network/network-security-group:0.5.0' = [
  for (hub, i) in hubNetworks!: if (hub.enableBastion) {
    name: '${hub.hubName}-bastionNsg-${uniqueString(resourceGroup().id,hub.location)}'
    params: {
      name: 'nsg-AzureBastionSubnet-${hub.hubName}-${hub.location}'
      location: hub.location
      securityRules: [
        // Inbound Rules
        {
          name: 'AllowHttpsInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 120
            sourceAddressPrefix: 'Internet'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowGatewayManagerInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 130
            sourceAddressPrefix: 'GatewayManager'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowAzureLoadBalancerInbound'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 140
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: '*'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowBastionHostCommunication'
          properties: {
            access: 'Allow'
            direction: 'Inbound'
            priority: 150
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
          }
        }
        {
          name: 'DenyAllInbound'
          properties: {
            access: 'Deny'
            direction: 'Inbound'
            priority: 4096
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
          }
        }
        // Outbound Rules
        {
          name: 'AllowSshRdpOutbound'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 100
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRanges: hub.?bastionHost.?outboundSshRdpPorts ?? [
              '22'
              '3389'
            ]
          }
        }
        {
          name: 'AllowAzureCloudOutbound'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 110
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'AzureCloud'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '443'
          }
        }
        {
          name: 'AllowBastionCommunication'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 120
            sourceAddressPrefix: 'VirtualNetwork'
            destinationAddressPrefix: 'VirtualNetwork'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRanges: [
              '8080'
              '5701'
            ]
          }
        }
        {
          name: 'AllowGetSessionInformation'
          properties: {
            access: 'Allow'
            direction: 'Outbound'
            priority: 130
            sourceAddressPrefix: '*'
            destinationAddressPrefix: 'Internet'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '80'
          }
        }
        {
          name: 'DenyAllOutbound'
          properties: {
            access: 'Deny'
            direction: 'Outbound'
            priority: 4096
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
            protocol: '*'
            sourcePortRange: '*'
            destinationPortRange: '*'
          }
        }
      ]
    }
  }
]

//=====================
// Hub network
//=====================
module resHubNetwork 'br/public:avm/ptn/network/hub-networking:0.2.1' = [
  for (hub, i) in hubNetworks!: if (!empty(hubNetworks)) {
    name: 'hubNetwork-${hub.hubName}-${uniqueString(resourceGroup().id,hub.location)}'
    dependsOn: [
      resBastionNsg[i]
    ]
    params: {
      hubVirtualNetworks: {
        '${hub.hubName}': {
          addressPrefixes: hub.addressPrefixes
          dnsServers: hub.?dnsServers ?? null
          enablePeering: hub.?enablePeering ?? false
          peeringSettings: (hub.?enablePeering ?? false) ? hub.?peeringSettings : null
          ddosProtectionPlanResourceId: hub.?ddosProtectionPlanResourceId ?? null
          enableBastion: hub.enableBastion
          vnetEncryption: hub.?vnetEncryption ?? false
          location: hub.location
          tags: parTags
          routes: hub.?routes ?? null
          bastionHost: hub.enableBastion
            ? {
                skuName: hub.?bastionHost.?skuName ?? 'Standard'
              }
            : null
          vnetEncryptionEnforcement: hub.?vnetEncryptionEnforcement ?? 'AllowUnencrypted'
          enableAzureFirewall: hub.enableAzureFirewall
          azureFirewallSettings: hub.enableAzureFirewall
            ? {
                azureSkuTier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
                location: hub.?azureFirewallSettings.?location
                firewallPolicyId: hub.?azureFirewallSettings.?firewallPolicyId ?? resAzFirewallPolicy[i].outputs.resourceId
                threatIntelMode: (hub.?azureFirewallSettings.?azureSkuTier == 'Basic')
                  ? 'Alert'
                  : hub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
                zones: hub.?azureFirewallSettings.?zones ?? null
                publicIPAddressObject: {
                  name: '${hub.hubName}-azfirewall-pip-${hub.location}'
                }
              }
            : null
          subnets: [
            for subnet in hub.subnets: !empty(subnet)
              ? {
                  name: subnet.name
                  addressPrefix: subnet.addressPrefix
                  delegations: empty(subnet.?delegation ?? null)
                    ? null
                    : [
                        {
                          name: subnet.?delegation ?? null
                          properties: {
                            serviceName: subnet.?delegation ?? null
                          }
                        }
                      ]
                  networkSecurityGroupResourceId: (subnet.?name == 'AzureBastionSubnet' && hub.enableBastion)
                    ? resBastionNsg[i].outputs.resourceId
                    : subnet.?networkSecurityGroupId ?? null
                  routeTable: subnet.?routeTable ?? null
                }
              : null
          ]
        }
      }
    }
  }
]

//=====================
// Network security
//=====================

module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.0' = [
  for (hub, i) in hubNetworks!: if (!empty(hub.?ddosProtectionPlanResourceId) && (parDdosLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
    name: 'ddosPlan-${uniqueString(resourceGroup().id,hub.?ddosProtectionPlanResourceId ?? '',hub.location)}'
    params: {
      name: '${parCompanyPrefix}-ddos-plan-${hub.location}'
      location: hub.location
      enableTelemetry: parTelemetryOptOut
      tags: parTags
    }
  }
]

module resAzFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.2.0' = [
  for (hub, i) in hubNetworks!: if ((hub.enableAzureFirewall) && empty(hub.?azureFirewallSettings.?firewallPolicyId)) {
    name: 'azFirewallPolicy-${uniqueString(resourceGroup().id,hub.hubName,hub.location)}'
    params: {
      name: '${parCompanyPrefix}-azfwpolicy-${hub.hubName}-${hub.location}'
      location: hub.location
      tier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      enableProxy: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? false
        : hub.?azureFirewallSettings.?dnsProxyEnabled
      servers: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? null
        : hub.?azureFirewallSettings.?firewallDnsServers
    }
  }
]

//=====================
// Hybrid connectivity
//=====================

module resVirtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.5.0' = [
  for (hub, i) in hubNetworks!: if (hub.vpnGatewayEnabled && !empty(hub.?virtualNetworkGatewayConfig)) {
    name: 'virtualNetworkGateway-${uniqueString(resourceGroup().id,hub.hubName,hub.location)}'
    dependsOn: [
      resHubNetwork[i]
    ]
    params: {
      name: '${parCompanyPrefix}-${toLower(hub.?virtualNetworkGatewayConfig.?gatewayType ?? 'vpn')}-${hub.hubName}-${hub.location}'
      clusterSettings: {
        clusterMode: any(hub.?virtualNetworkGatewayConfig.?vpnMode)
        asn: hub.?virtualNetworkGatewayConfig.?asn ?? 65515
        customBgpIpAddresses: (hub.?virtualNetworkGatewayConfig.?vpnMode == 'activePassiveBgp' || hub.?virtualNetworkGatewayConfig.?vpnMode == 'activeActiveBgp')
          ? (hub.?virtualNetworkGatewayConfig.?customBgpIpAddresses)
          : null
      }
      location: hub.location
      gatewayType: hub.?virtualNetworkGatewayConfig.?gatewayType ?? 'Vpn'
      vpnType: hub.?virtualNetworkGatewayConfig.?vpnType ?? 'RouteBased'
      skuName: hub.?virtualNetworkGatewayConfig.?skuName ?? 'VpnGw1AZ'
      enableTelemetry: parTelemetryOptOut
      enableBgpRouteTranslationForNat: hub.?virtualNetworkGatewayConfig.?enableBgpRouteTranslationForNat ?? false
      enableDnsForwarding: hub.?virtualNetworkGatewayConfig.?enableDnsForwarding ?? false
      vpnGatewayGeneration: hub.?virtualNetworkGatewayConfig.?vpnGatewayGeneration ?? 'None'
      vNetResourceId: resourceId('Microsoft.Network/virtualNetworks', hub.hubName)
      domainNameLabel: hub.?virtualNetworkGatewayConfig.?domainNameLabel ?? []
      publicIpZones: hub.?virtualNetworkGatewayConfig.?skuName != 'Basic'
        ? hub.?virtualNetworkGatewayConfig.?publicIpZones ?? [1, 2, 3]
        : []
    }
  }
]

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

  @description('Optional. The location of the virtual network.')
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

  @description('Optional. The virtual network gateway configuration.')
  virtualNetworkGatewayConfig: virtualNetworkGatewayConfigType?

  @description('Optional. Switch to enable/disable VPN virtual network gateway deployment.')
  vpnGatewayEnabled: bool

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
  gatewayType: 'Vpn' | 'ExpressRoute'?
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
  vpnMode: 'activeActiveBgp' | 'activeActiveNoBgp' | 'activePassiveBgp' | 'activePassiveNoBgp'
  vpnType: 'RouteBased' | 'PolicyBased'?
  vpnGatewayGeneration: 'Generation1' | 'Generation2' | 'None'?
  enableBgpRouteTranslationForNat: bool?
  enableDnsForwarding: bool?
  asn: int?
  customBgpIpAddresses: string[]?
  publicIpZones: array?
  clientRootCertData: string?
  vpnClientAddressPoolPrefix: string?
  vpnClientAadConfiguration: object?
  domainNameLabel: string[]?
}
