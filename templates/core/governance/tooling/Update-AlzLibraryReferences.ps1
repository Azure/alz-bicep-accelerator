param(
    [string]$LibraryRoot = (Join-Path $PSScriptRoot '../lib/alz'),
    [string]$ModulePath = (Join-Path $PSScriptRoot '../mgmt-groups/int-root/main.bicep'),
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

$moduleDirectory = Split-Path -Parent (Resolve-Path -Path $ModulePath)
$libraryDirectory = Resolve-Path -Path $LibraryRoot

if (-not (Test-Path -Path $moduleDirectory)) {
    throw "Module directory '$moduleDirectory' was not found."
}

if (-not (Test-Path -Path $libraryDirectory)) {
    throw "Library root '$libraryDirectory' was not found."
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

$originalContent = Get-Content -Path $ModulePath -Raw

$newContent = $originalContent
$newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzRbacRoleDefsJson' -Lines $roleLines
$newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyDefsJson' -Lines $policyLines
$newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicySetDefsJson' -Lines $policySetLines
$newContent = Set-ArrayBlock -Content $newContent -VariableName 'alzPolicyAssignmentsDefs' -Lines $policyAssignmentLines

if ($WhatIf) {
    $diff = Compare-Object -ReferenceObject ($originalContent -split "`r`n") -DifferenceObject ($newContent -split "`r`n") -PassThru
    $diff
    return
}

Set-Content -Path $ModulePath -Value $newContent

Write-Host "Updated '$ModulePath' with references from '$libraryDirectory'."
