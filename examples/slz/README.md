# Update the SLZ Library Package

Use these steps to update the Sovereign Landing Zones (SLZ) Library content.

Run the commands from the `examples/slz` directory. Before starting, complete the [prerequisites](https://azure.github.io/Azure-Landing-Zones/bicep/howtos/modifyingpolicyassets/#prerequisites), including installing `alzlibtool`, PowerShell 7.0 or later, and Git.

## 1. Remove the existing library

Delete the generated ALZ Library content so that files removed upstream are not retained locally.

```powershell
Remove-Item -Path './templates/core/governance/lib/alz' -Recurse -Force
```

## 2. Update the library version

In `templates/core/governance/tooling/alz_library_metadata.json`, update the `ref` for the `platform/slz` dependency to the required SLZ Library version. For example:

```json
{
  "path": "platform/slz",
  "ref": "2026.08.0"
}
```

Use the latest compatible release from the [Azure Landing Zones Library releases](https://github.com/Azure/Azure-Landing-Zones-Library/releases). Do not change the dependency path from `platform/slz`.

## 3. Generate the library content

From the directory containing `alzlibtool.exe`, run:

```powershell
./alzlibtool.exe generate architecture `
  "C:\Path\To\alz-bicep-accelerator\examples\slz\templates\core\governance\tooling" `
  slz `
  --for-alz-bicep `
  -o "C:\Path\To\alz-bicep-accelerator\examples\slz\templates\core\governance\lib"
```

Replace `C:\Path\To\alz-bicep-accelerator` with the path to this repository.

## 4. Rename the generated library

The generator creates the library under `lib/slz`. Rename it to `lib/alz`, which is the path expected by the Bicep modules.

```powershell
Rename-Item `
  -Path './templates/core/governance/lib/slz' `
  -NewName 'alz'
```

## 5. Update the management group ID

The generated policy files use `slz` as the top-level management group ID. This repository uses `alz`. Update only the generated policy JSON files; the `platform/slz` dependency path in the metadata file must remain unchanged.

```powershell
Get-ChildItem -Path './templates/core/governance/lib/alz' `
  -Recurse `
  -File `
  -Filter '*.alz*.json' |
  ForEach-Object {
    $content = Get-Content -Path $_.FullName -Raw
    $content.Replace('slz', 'alz') |
      Set-Content -Path $_.FullName -NoNewline
  }
```

Confirm that no generated policy references still contain `slz`:

```powershell
Get-ChildItem -Path './templates/core/governance/lib/alz' `
  -Recurse `
  -File `
  -Filter '*.alz*.json' |
  Select-String -Pattern 'slz'
```

The command should return no matches.

## 6. Update Bicep module references

Preview the module-reference changes, then apply them using the script included with the example:

```powershell
./templates/core/governance/tooling/Update-AlzLibraryReferences.ps1 -WhatIf
./templates/core/governance/tooling/Update-AlzLibraryReferences.ps1
```

For background on this process, see [Updating the ALZ Library Version](https://azure.github.io/Azure-Landing-Zones/bicep/howtos/modifyingpolicyassets/#step-5-update-bicep-module-references).

## 7. Review the update

Review the generated files and module-reference changes before submitting the update:

```powershell
git status --short
git diff --stat
git diff -- './templates/core/governance/tooling/alz_library_metadata.json'
```

Verify that:

- the metadata references the intended SLZ Library version;
- generated content exists under `templates/core/governance/lib/alz` and not `lib/slz`;
- generated policy files no longer reference the `slz` management group ID; and
- Bicep modules reference all required generated policy, policy set, assignment, and role definition files.