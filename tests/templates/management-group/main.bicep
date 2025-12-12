metadata name = 'ALZ Bicep - Test Management Group'
metadata description = 'ALZ Bicep Module testing.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration.')
param testConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

resource tenantRootMgExisting 'Microsoft.Management/managementGroups@2023-04-01' existing = {
  scope: tenant()
  name: tenant().tenantId
}

// ============ //
//   Resources  //
// ============ //

module sandbox 'br/public:avm/ptn/alz/empty:0.3.5' = {
  params: {
    createOrUpdateManagementGroup: testConfig.?createOrUpdateManagementGroup
    managementGroupName: testConfig.?managementGroupName ?? 'alz-test'
    managementGroupDisplayName: testConfig.?managementGroupDisplayName ?? 'Testing'
    managementGroupParentId: testConfig.?managementGroupParentId ?? tenantRootMgExisting.name
    location: parLocations[0]
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../templates/core/alzCoreType.bicep'
