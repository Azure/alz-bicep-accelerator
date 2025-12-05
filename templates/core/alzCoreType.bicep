// ================ //
// Definitions
// ================ //

@export()
type alzCoreType = {
  @description('Optional. Boolean to create or update the management group. If set to false, the module will only check if the management group exists and do a GET on it before it continues to deploy resources to it.')
  createOrUpdateManagementGroup: bool

  @description('The name of the management group to create or update.')
  managementGroupName: string?

  @description('The display name of the management group to create or update.')
  managementGroupDisplayName: string?

  @description('The display name of the policy assignment that you would like to put in DoNotEnforce mode.')
  managementGroupDoNotEnforcePolicyAssignments: array?

  @description('The display name of the policy assignments to exclude from the management group.')
  managementGroupExcludedPolicyAssignments: array?

  @description('The parent management group ID to use for the management group to create or update. If not specified, the tenant root management group will be used.')
  managementGroupParentId: string?

  @description('The intermediate root management group name of your ALZ hierarchy. This is used for replacing Resource IDs in policy assignments and role assignments etc. If not specified, `alz` will be used.')
  managementGroupIntermediateRootName: string?

  @description('Optional. Additional customer provided RBAC role definitions to be used in tandem with the ALZ RBAC role definitions.')
  customerRbacRoleDefs: array?

  @description('Optional. Customer provided RBAC role assignments for the management group. These are general role assignments separate from policy assignment role definitions, which are automatically handled.')
  customerRbacRoleAssignments: array?

  @description('Optional. Additional customer provided policy definitions to be used in tandem with the ALZ policy definitions.')
  customerPolicyDefs: array?

  @description('Optional. Additional customer provided policy set definitions to be used in tandem with the ALZ policy set definitions.')
  customerPolicySetDefs: array?

  @description('Optional. Set to true to enable telemetry for the deployment. Set to false to opt-out of telemetry.')
  customerPolicyAssignments: array?

  @description('Optional. An array of subscription IDs to place in the management group. If not specified, no subscriptions will be placed in the management group.')
  subscriptionsToPlaceInManagementGroup: array?

  @description('Optional. The number of consistency counters to wait for before creating or updating custom policy definitions. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeCustomPolicyDefinitions: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating custom policy set definitions. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeCustomPolicySetDefinitions: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating custom role definitions. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeCustomRoleDefinitions: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating policy assignments. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforePolicyAssignments: int?

  @description('Optional. The number of consistency counters to wait for before creating or updating role assignments. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeRoleAssignments: int?

  @description('Optional. The number of consistency counters to wait for before sub placement. If not specified, the default value is 10.')
  waitForConsistencyCounterBeforeSubPlacement: int?
}
