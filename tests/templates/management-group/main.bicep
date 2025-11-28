metadata name = 'ALZ Bicep - Test Management Group'
metadata description = 'ALZ Bicep Module testing.'

targetScope = 'managementGroup'

//================================
// Parameters
//================================

@description('Required. The management group configuration.')
param sandboxConfig alzCoreType

@description('The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@sys.description('Set Parameter to true to Opt-out of deployment telemetry.')
param parEnableTelemetry bool = true

// ============ //
//   Resources  //
// ============ //

module sandbox 'br/public:avm/ptn/alz/empty:0.3.1' = {
  params: {
    createOrUpdateManagementGroup: sandboxConfig.?createOrUpdateManagementGroup
    managementGroupName: sandboxConfig.?managementGroupName ?? 'alz-test'
    managementGroupDisplayName: sandboxConfig.?managementGroupDisplayName ?? 'Testing'
    managementGroupParentId: sandboxConfig.?managementGroupParentId ?? ''
    location: parLocations[0]
    enableTelemetry: parEnableTelemetry
  }
}

// ================ //
// Type Definitions
// ================ //

import { alzCoreType as alzCoreType } from '../../../templates/core/governance/mgmt-groups/int-root/main.bicep'
