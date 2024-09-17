using './route-table.bicep'

param parLocation = 'uksouth'
param parTags = {}
param parCompanyPrefix = 'alz'
param parRouteTableName = '${parCompanyPrefix}-hub-${parLocation}'
param parRoutes = []
param parDisableBgpRoutePropagation = false
param parTelemetryOptOut = false

