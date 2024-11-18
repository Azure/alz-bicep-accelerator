//==================================
// Parameters
//==================================

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

@sys.description('Prefix value which will be prepended to all resource names.')
param parCompanyPrefix string = 'alz'

@allowed([
  '1'
  '2'
  '3'
])
@sys.description('Availability Zones to deploy the VPN/ER PIP across. Region must support Availability Zones to use. If it does not then leave empty. Ensure that you select a zonal SKU for the ER/VPN Gateway if using Availability Zones for the PIP.')
param parAzVpnGatewayAvailabilityZones array = []

param parVirtualNetworkGatewayName string

param parVirtualNetworkGatewayType string

param parVirtualNetworkGatewaySkuName string

param parVirtualNetworkResourceId string

param parVirtualNetworkGatewayActiveActive bool

param parVirtualNetworkGatewayVpnType string

param parVirtualNetworkGatewayGeneration string

param parVirtualNetworkGatewayEnableBgp bool

param parVirtualNetworkGatewayBgpRouteTranslation bool

param parVirtualNetworkGatewayEnableDnsForwarding bool

param parVirtualNetworkGatewayBgpPeeringAddress string

param parVirtualNetworkGatewayAsn int



//==================================
// Resources
//==================================

module virtualNetworkGateway 'br/public:avm/res/network/virtual-network-gateway:0.4.0' = {
  name: 'virtualNetworkGw-${uniqueString(resourceGroup().id,parLocation)}'
  params: {
    name: parVirtualNetworkGatewayName
    gatewayType: parVirtualNetworkGatewayType
    skuName: 'ErGw1AZ'
    clusterSettings: {
      clusterMode: 'activePassiveBgp'
    }
    vNetResourceId: parVirtualNetworkResourceId
    vpnType: parVirtualNetworkGatewayVpnType
    vpnGatewayGeneration: parVirtualNetworkGatewayGeneration
    enableBgpRouteTranslationForNat: parVirtualNetworkGatewayBgpRouteTranslation
    enableDnsForwarding: parVirtualNetworkGatewayEnableDnsForwarding
    publicIpZones: parAzVpnGatewayAvailabilityZones
    enableTelemetry: parTelemetryOptOut
    vpnClientAadConfiguration: {
      
    }
  }
}