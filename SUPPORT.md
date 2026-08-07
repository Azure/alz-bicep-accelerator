# Support

## How to file issues and get help  

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates.  For new issues, file your bug or feature request as a new Issue.

For help and questions about using this project, please raise an Issue.

## Microsoft Support Policy

Support for this project is limited to the resources listed above.
## Known limitations

### Azure Government and Sovereign Clouds

This accelerator relies on Azure Policy built-in definitions and initiatives. Built-in policy versions available in Azure Government and other sovereign cloud environments may differ from those available in commercial Azure.

### Policy Assignment Parameter Overrides

The `parPolicyAssignmentParameterOverrides` parameter supports overriding policy assignment parameters only.

Overriding built-in policy `definitionVersion` values is not supported. If a required built-in policy version is unavailable in the target cloud environment, use a supported version available in that environment or update to an ALZ Library release that references supported policy versions.
