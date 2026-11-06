$ErrorActionPreference = 'Stop'

$manifest = Get-Content "$PSScriptRoot/../bucket/openidea.json" -Raw | ConvertFrom-Json
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('openidea-test-' + [guid]::NewGuid())
$originalAppData = $env:APPDATA
$originalLocalAppData = $env:LOCALAPPDATA

try {
    $env:APPDATA = Join-Path $testRoot 'Roaming'
    $env:LOCALAPPDATA = Join-Path $testRoot 'Local'
    $project = Join-Path $testRoot 'project/.openidea/settings.toml'
    New-Item -ItemType Directory -Path (Split-Path $project) -Force | Out-Null
    Set-Content -LiteralPath $project 'project settings'
    foreach ($root in @($env:APPDATA, $env:LOCALAPPDATA)) {
        foreach ($name in @('ai.l0ng.openidea', 'other-app')) {
            $folder = Join-Path $root $name
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $folder 'data.txt') 'keep until purge'
        }
    }

    $hook = [scriptblock]::Create($manifest.post_uninstall -join "`n")
    $purge = $false
    & $hook
    foreach ($root in @($env:APPDATA, $env:LOCALAPPDATA)) {
        if (!(Test-Path -LiteralPath (Join-Path $root 'ai.l0ng.openidea/data.txt'))) {
            throw 'Normal uninstall removed user data.'
        }
    }

    $purge = $true
    & $hook
    & $hook # Missing data must also be safe to purge.
    foreach ($root in @($env:APPDATA, $env:LOCALAPPDATA)) {
        if (Test-Path -LiteralPath (Join-Path $root 'ai.l0ng.openidea')) {
            throw 'Purge left OpenIDEA data behind.'
        }
        if (!(Test-Path -LiteralPath (Join-Path $root 'other-app/data.txt'))) {
            throw 'Purge removed another application.'
        }
    }
    if (!(Test-Path -LiteralPath $project)) { throw 'Purge removed project settings.' }
    Write-Output 'OpenIDEA uninstall checks passed.'
} finally {
    $env:APPDATA = $originalAppData
    $env:LOCALAPPDATA = $originalLocalAppData
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolvedTestRoot.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to clean up outside the temporary directory.'
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) { Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force }
}
