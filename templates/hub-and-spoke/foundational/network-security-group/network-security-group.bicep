//========================================
// Parameters
//========================================

//TODO: Add locks

@sys.description('The Azure Region to deploy the resources into.')
param parLocation string = resourceGroup().location

@sys.description('Tags you would like to be applied to all resources in this module.')
param parTags object = {}

@sys.description('Prefix value which will be prepended to all resource names.')
param parCompanyPrefix string = 'alz'

@sys.description('Name for network security group.')
param parNetworkSecurityGroup string = '${parCompanyPrefix}-nsg-${parLocation}'

@sys.description('The security rules for the network security group.')
param parNetworkSecurityGroupSecurityRules array = []

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parTelemetryOptOut bool = false

//========================================
// Resources
//========================================

module resNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.0' = {
  name: 'hubVnet-${uniqueString(resourceGroup().id, parNetworkSecurityGroup,parLocation)}'
  params: {
    name: parNetworkSecurityGroup
    location: parLocation
    tags: parTags
    securityRules: parNetworkSecurityGroupSecurityRules
    enableTelemetry: parTelemetryOptOut
  }
}