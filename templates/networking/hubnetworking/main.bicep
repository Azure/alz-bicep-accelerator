metadata name = 'ALZ Bicep Accelerator - Hub Networking'
metadata description = 'Used to deploy hub networking resources for ALZ.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('The name of the Resource Group.')
param parHubNetworkingResourceGroupName string = 'rg-alz-hubnetworking-001'

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

@description('The name of the DNS Resource Group.')
param parDnsResourceGroupName string = 'rg-alz-dns-001'

// Hub Networking Parameters
@description('The hub virtual networks to create.')
param hubNetworks hubVirtualNetworkType?

// Resource Lock Parameters
@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for DDoS Plan.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parDdosLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for Virtual Network.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parVirtualNetworkLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for Bastion.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parBastionLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for Azure Firewall.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parAzureFirewallLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for Private DNS Zone(s).
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parPrivateDNSZonesLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

@sys.description('''Resource Lock Configuration for ExpressRoute Virtual Network Gateway.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parVirtualNetworkGatewayLock lockType = {
  kind: 'None'
  notes: 'This lock was created by the ALZ Bicep Hub Networking Module.'
}

// General Parameters
@description('The primary location to deploy resources to.')
param parPrimaryLocation string = deployment().location

@description('Tags to be applied to all resources.')
param parTags object = {}

@description('Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Resources
//========================================

// Resource Group
module modHubNetworkingResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: 'modResourceGroup-${uniqueString(parHubNetworkingResourceGroupName,parPrimaryLocation)}'
  scope: subscription()
  params: {
    name: parHubNetworkingResourceGroupName
    location: parPrimaryLocation
    lock: parGlobalResourceLock ?? parResourceGroupLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

resource resHubNetworkingResourceGroupPointer 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: parHubNetworkingResourceGroupName
  scope: subscription()
  dependsOn: [
    modHubNetworkingResourceGroup
  ]
}

module modDnsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: 'modDnsResourceGroup-${uniqueString(parDnsResourceGroupName,parPrimaryLocation)}'
  scope: subscription()
  params: {
    name: parDnsResourceGroupName
    location: parPrimaryLocation
    lock: parGlobalResourceLock ?? parResourceGroupLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

resource resDnsResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: parDnsResourceGroupName
  scope: subscription()
  dependsOn: [
    modDnsResourceGroup
  ]
}

// Bastion Network Security Group
module resBastionNsg 'br/public:avm/res/network/network-security-group:0.5.0' = [
  for (hub, i) in hubNetworks!: if (hub.enableBastion) {
    name: '${hub.hubName}-bastionNsg-${uniqueString(parHubNetworkingResourceGroupName,hub.location)}'
    scope: resHubNetworkingResourceGroupPointer
    params: {
      name: 'nsg-bas-alz-${hub.location}'
      location: hub.location
      lock: parGlobalResourceLock ?? parBastionLock
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
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Hub Networking
//=====================
module resHubNetwork 'br/public:avm/ptn/network/hub-networking:0.5.0' = [
  for (hub, i) in hubNetworks!: if (!empty(hubNetworks)) {
    name: 'hubNetwork-${hub.hubName}-${uniqueString(parHubNetworkingResourceGroupName,hub.location)}'
    scope: resHubNetworkingResourceGroupPointer
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
          routes: hub.?routes ?? null
          routeTableName: hub.?routeTableName ?? null
          bastionHost: hub.enableBastion
            ? {
                bastionHostName: hub.?bastionHost.?bastionHostName ?? '${hub.hubName}-bastion'
                skuName: hub.?bastionHost.?skuName ?? 'Standard'
              }
            : null
          vnetEncryptionEnforcement: hub.?vnetEncryptionEnforcement ?? 'AllowUnencrypted'
          enableAzureFirewall: hub.enableAzureFirewall
          azureFirewallSettings: hub.enableAzureFirewall
            ? {
                azureSkuTier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
                location: hub.?azureFirewallSettings.?location
                firewallPolicyId: hub.?azureFirewallSettings.?firewallPolicyId ?? resAzFirewallPolicy[i].?outputs.resourceId
                threatIntelMode: (hub.?azureFirewallSettings.?azureSkuTier == 'Standard')
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
                    ? resBastionNsg[i].?outputs.resourceId
                    : subnet.?networkSecurityGroupId ?? null
                  routeTable: subnet.?routeTable ?? null
                }
              : null
          ]
          lock: parGlobalResourceLock ?? parVirtualNetworkLock
          tags: parTags
          enableTelemetry: parEnableTelemetry
        }
      }
    }
  }
]

//=====================
// Network Security
//=====================

module resDdosProtectionPlan 'br/public:avm/res/network/ddos-protection-plan:0.3.2' = [
  for (hub, i) in hubNetworks!: if (!empty(hub.?ddosProtectionPlanResourceId) && (parDdosLock.kind != 'None' || parGlobalResourceLock.kind != 'None')) {
    name: 'ddosPlan-${uniqueString(parHubNetworkingResourceGroupName,hub.?ddosProtectionPlanResourceId ?? '',hub.location)}'
    scope: resHubNetworkingResourceGroupPointer
    params: {
      name: 'ddos-alz-${hub.location}'
      location: hub.location
      lock: parGlobalResourceLock ?? parDdosLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resAzFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.2' = [
  for (hub, i) in hubNetworks!: if ((hub.enableAzureFirewall) && empty(hub.?azureFirewallSettings.?firewallPolicyId)) {
    name: 'azFirewallPolicy-${uniqueString(parHubNetworkingResourceGroupName,hub.hubName,hub.location)}'
    scope: resHubNetworkingResourceGroupPointer
    params: {
      name: 'afwp-alz-${hub.location}'
      location: hub.location
      tier: hub.?azureFirewallSettings.?azureSkuTier ?? 'Standard'
      threatIntelMode: (hub.?azureFirewallSettings.?azureSkuTier == 'Standard')
        ? 'Alert'
        : hub.?azureFirewallSettings.?threatIntelMode ?? 'Alert'
      enableProxy: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? false
        : hub.?azureFirewallSettings.?dnsProxyEnabled
      servers: hub.?azureFirewallSettings.?azureSkuTier == 'Basic'
        ? null
        : hub.?azureFirewallSettings.?firewallDnsServers
      lock: parGlobalResourceLock ?? parAzureFirewallLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

//=====================
// Hybrid Connectivity
//=====================

module resVirtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.10.0' = [
  for (hub, i) in hubNetworks!: if (hub.vpnGatewayEnabled && !empty(hub.?virtualNetworkGatewayConfig)) {
    name: 'virtualNetworkGateway-${uniqueString(parHubNetworkingResourceGroupName,hub.hubName,hub.location)}'
    scope: resHubNetworkingResourceGroupPointer
    dependsOn: [
      resHubNetwork[i]
    ]
    params: {
      name: 'vgw-${hub.hubName}-${hub.location}'
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
      enableBgpRouteTranslationForNat: hub.?virtualNetworkGatewayConfig.?enableBgpRouteTranslationForNat ?? false
      enableDnsForwarding: hub.?virtualNetworkGatewayConfig.?enableDnsForwarding ?? false
      vpnGatewayGeneration: hub.?virtualNetworkGatewayConfig.?vpnGatewayGeneration ?? 'None'
      virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', hub.hubName)
      domainNameLabel: hub.?virtualNetworkGatewayConfig.?domainNameLabel ?? []
      publicIpAvailabilityZones: hub.?virtualNetworkGatewayConfig.?skuName != 'Basic'
        ? hub.?virtualNetworkGatewayConfig.?publicIpZones ?? [1, 2, 3]
        : []
      lock: parGlobalResourceLock ?? parVirtualNetworkGatewayLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

module resPrivateDNSZones 'br/public:avm/ptn/network/private-link-private-dns-zones:0.7.0' = [
  for (hub, i) in hubNetworks!: if (hub.?enablePrivateDnsZones ?? false) {
    name: 'privateDnsZone-${hub.hubName}-${uniqueString(parDnsResourceGroupName,hub.location)}'
    scope: resDnsResourceGroup
    params: {
      location: hub.location
      privateLinkPrivateDnsZones: empty(hub.?privateDnsZones) ? null : hub.?privateDnsZones
      virtualNetworkLinks: [
        for id in union(
          [
            resourceId(
              subscription().subscriptionId,
              parHubNetworkingResourceGroupName,
              'Microsoft.Network/virtualNetworks',
              hub.hubName
            )
          ],
          !empty(hub.?virtualNetworkIdToLinkFailover) ? [hub.?virtualNetworkIdToLinkFailover] : [],
          hub.?virtualNetworkResourceIdsToLinkTo ?? []
        ): {
          virtualNetworkResourceId: id
        }
      ]
      lock: parGlobalResourceLock ?? parPrivateDNSZonesLock
      tags: parTags
      enableTelemetry: parEnableTelemetry
    }
  }
]

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

// Hub Networking Types
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

  @description('Optional. Enable/Disable private DNS zones.')
  enablePrivateDnsZones: bool?

  @description('Optional. The resource group name for private DNS zones.')
  privateDnsZonesResourceGroup: string?

  @description('Array of Resource IDs of VNets to link to Private DNS Zones. Hub VNet is automatically included by module.')
  virtualNetworkResourceIdsToLinkTo: array?

  @description('Array of DNS Zones to provision and link to  Hub Virtual Network. Default: All known Azure Private DNS Zones, baked into underlying AVM module see: https://github.com/Azure/bicep-registry-modules/tree/main/avm/ptn/network/private-link-private-dns-zones#parameter-privatelinkprivatednszones')
  privateDnsZones: array?

  @description('Resource ID of Failover VNet for Private DNS Zone VNet Failover Links')
  virtualNetworkIdToLinkFailover: string?

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

  @description('Optional. The name of the route table.')
  routeTableName: string?

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

    @description('Optional. Enable/Disable Kerberos authentication.')
    enableKerberos: bool?

    @description('Optional. The number of scale units for the Bastion host. Defaults to 4.')
    scaleUnits: int?

    @description('Optional. The SKU name of the Bastion host. Defaults to Standard.')
    skuName: 'Basic' | 'Developer' | 'Premium' | 'Standard'?

    @description('Optional. The name of the bastion host.')
    bastionHostName: string?

    @description('Optional. The bastion\'s outbound ssh and rdp ports\'.')
    outboundSshRdpPorts: array?
  }?
}[]

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
  @description('Optional. The name of the Azure Firewall.')
  azureFirewallName: string?

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
