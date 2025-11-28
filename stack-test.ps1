$stackParameters = @{
  Name                  = "alz-avm-int-root-test"
  TemplateFile          = ".\templates\core\governance\mgmt-groups\int-root\main.bicep"
  TemplateParameterFile = ".\templates\core\governance\mgmt-groups\int-root\main.bicepparam"
  DenySettingsMode      = "None"
  ActionOnUnmanage      = "DeleteAll"
  Force                 = $true
  Verbose               = $true
  ManagementGroupId     = "d878a7c9-c765-4363-9cb7-28d659a97f53"
  Location              = "uksouth"
}