metadata name = 'ALZ Bicep Accelerator - Test Resource Group'
metadata description = 'Used to test resource group deployment.'

targetScope = 'subscription'

//========================================
// Parameters
//========================================

// Resource Group Parameters
@description('Required. The name of the Resource Group.')
param parResourceGroup string

@description('''Resource Lock Configuration for Resource Group.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parResourceGroupLock lockType?

// General Parameters
@description('Required. The locations to deploy resources to.')
param parLocations array = [
  deployment().location
]

@description('Optional. Tags to be applied to resources.')
param parTags object = {}

@sys.description('''Global Resource Lock Configuration used for all resources deployed in this module.
- `name` - The name of the lock.
- `kind` - The lock settings of the service which can be CanNotDelete, ReadOnly, or None.
- `notes` - Notes about this lock.
''')
param parGlobalResourceLock lockType

@description('Optional. Enable or disable telemetry.')
param parEnableTelemetry bool = true

//========================================
// Resources
//========================================

module modMgmtLoggingResourceGroup 'br/public:avm/res/resources/resource-group:0.4.2' = {
  name: 'modMgmtLoggingResourceGroup-${uniqueString(parResourceGroup,parLocations[0])}'
  scope: subscription()
  params: {
    name: parResourceGroup
    location: parLocations[0]
    lock: parGlobalResourceLock ?? parResourceGroupLock
    tags: parTags
    enableTelemetry: parEnableTelemetry
  }
}

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
}?
