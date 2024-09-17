using './network-security-group.bicep'

param parLocation = 'uksouth'
param parTags = {}
param parCompanyPrefix = 'alz'
param parNetworkSecurityGroup = '${parCompanyPrefix}-nsg-${parLocation}'
param parNetworkSecurityGroupSecurityRules = []

