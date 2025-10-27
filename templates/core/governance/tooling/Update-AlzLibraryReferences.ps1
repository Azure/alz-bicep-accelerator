param(
    [string]$LibraryRoot = (Join-Path $PSScriptRoot '../lib/alz'),
    [string]$ModulePath,
    [string[]]$ModuleNames,
    [switch]$All,
    [switch]$WhatIf
)

function Get-RelativePath {
    param(
        [string]$From,
        [string]$To
    )

    $relative = [System.IO.Path]::GetRelativePath($From, $To)
    return ($relative -replace '\\', '/')
}

function Get-LibraryFiles {
    param(
        [string]$LibraryRoot,
        [string]$ModuleDirectory
    )

    Get-ChildItem -Path $LibraryRoot -File -Recurse -Filter '*.json' | ForEach-Object {
        [PSCustomObject]@{
            FullName     = $_.FullName
            Name         = $_.Name
            RelativePath = Get-RelativePath -From $ModuleDirectory -To $_.FullName
        }
    }
}

function Format-ArrayLines {
    param(
        [array]$Files
    )

    $Files | Sort-Object RelativePath | ForEach-Object {
        "  loadJsonContent('$($_.RelativePath)')"
    }
}

function Set-ArrayBlock {
    param(
        [string]$Content,
        [string]$VariableName,
        [array]$Lines
    )

    $pattern = "(?s)var\s+$([Regex]::Escape($VariableName))\s*=\s*\[(.*?)\]"
    if (-not [Regex]::IsMatch($Content, $pattern)) {
        throw "Unable to locate array declaration for '$VariableName'."
    }

    $replacement = "var $VariableName = [`r`n"
    if ($Lines.Count -gt 0) {
        $replacement += ($Lines -join "`r`n") + "`r`n"
    }
    $replacement += "]"

    return [Regex]::Replace(
        $Content,
        $pattern,
        [Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement },
        [Text.RegularExpressions.RegexOptions]::Singleline
    )
}

$baseLibraryRoot = (Resolve-Path -Path $LibraryRoot).Path

$targets = @()

if ($ModulePath) {
    $resolvedModulePath = (Resolve-Path -Path $ModulePath).Path
    $moduleName = Split-Path -Leaf (Split-Path -Parent $resolvedModulePath)
    $targets += [PSCustomObject]@{
        Name        = $moduleName
        ModulePath  = $resolvedModulePath
    LibraryRoot = $baseLibraryRoot
    }
} else {
    $mgmtGroupsRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot '../mgmt-groups')).Path

    $availableModuleNames = (Get-ChildItem -Path $mgmtGroupsRoot -Directory | Select-Object -ExpandProperty Name)

    $resolvedModuleNames = @()

    if ($ModuleNames) {
        foreach ($requestedName in $ModuleNames) {
            $match = $availableModuleNames | Where-Object { $_.ToLowerInvariant() -eq $requestedName.ToLowerInvariant() }
            if (-not $match) {
                Write-Warning "Skipping '$requestedName' because no management group module folder was found."
                continue
            }

            $resolvedModuleNames += $match | Sort-Object -Unique
        }
    } elseif ($All) {
        $resolvedModuleNames = $availableModuleNames
    } else {
        $resolvedModuleNames = $availableModuleNames
    }

    if (-not $resolvedModuleNames) {
        Write-Warning 'No management group modules were selected. Nothing to do.'
        return
    }

    foreach ($moduleName in ($resolvedModuleNames | Sort-Object -Unique)) {
        $moduleMainPath = Join-Path $mgmtGroupsRoot "$moduleName/main.bicep"
        if (-not (Test-Path -Path $moduleMainPath)) {
            Write-Warning "Skipping '$moduleName' because '$moduleMainPath' was not found."
            continue
        }

        if ($moduleName -eq 'int-root') {
            $moduleLibraryPath = $baseLibraryRoot
        } else {
            $candidateLibraryPath = Join-Path $baseLibraryRoot $moduleName
            if (-not (Test-Path -Path $candidateLibraryPath)) {
                Write-Warning "Skipping '$moduleName' because no library folder was found at '$candidateLibraryPath'."
                continue
            }

            $moduleLibraryPath = (Resolve-Path -Path $candidateLibraryPath).Path
        }

        $targets += [PSCustomObject]@{
            Name        = $moduleName
            ModulePath  = (Resolve-Path -Path $moduleMainPath).Path
            LibraryRoot = $moduleLibraryPath
        }
    }
}

foreach ($target in $targets) {
    $modulePath = $target.ModulePath
    $moduleName = $target.Name
    $libraryDirectory = $target.LibraryRoot
    $moduleDirectory = Split-Path -Parent $modulePath

    if (-not (Test-Path -Path $moduleDirectory)) {
        Write-Warning "Skipping '$moduleName' because module directory '$moduleDirectory' was not found."
        continue
    }

    if (-not (Test-Path -Path $libraryDirectory)) {
        Write-Warning "Skipping '$moduleName' because library root '$libraryDirectory' was not found."
        continue
    }

    $files = Get-LibraryFiles -LibraryRoot $libraryDirectory -ModuleDirectory $moduleDirectory

    $roleDefinitionFiles = $files | Where-Object { $_.Name -like '*.alz_role_definition.json' }
    $policyDefinitionFiles = $files | Where-Object { $_.Name -like '*.alz_policy_definition.json' }
    $policySetDefinitionFiles = $files | Where-Object { $_.Name -like '*.alz_policy_set_definition.json' }
    $policyAssignmentFiles = $files | Where-Object { $_.Name -like '*.alz_policy_assignment.json' }

    $roleLines = Format-ArrayLines -Files $roleDefinitionFiles
    $policyLines = Format-ArrayLines -Files $policyDefinitionFiles
    $policySetLines = Format-ArrayLines -Files $policySetDefinitionFiles
    $policyAssignmentLines = Format-ArrayLines -Files $policyAssignmentFiles

    $originalContent = Get-Content -Path $modulePath -Raw

    $newContent = $originalContent
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzRbacRoleDefsJson' -Lines $roleLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyDefsJson' -Lines $policyLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicySetDefsJson' -Lines $policySetLines
    $newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyAssignmentsDefs' -Lines $policyAssignmentLines

    if ($WhatIf) {
        Write-Host "--- Module: $moduleName (WhatIf) ---"
        $diff = Compare-Object -ReferenceObject ($originalContent -split "`r`n") -DifferenceObject ($newContent -split "`r`n") -PassThru
        if ($diff) {
            $diff
        } else {
            Write-Host 'No changes detected.'
        }
    } else {
        Set-Content -Path $modulePath -Value $newContent
        Write-Host "Updated module '$moduleName' using library '$libraryDirectory'."
    }
}
