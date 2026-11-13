$ErrorActionPreference = 'Stop'

$manifest = Get-Content "$PSScriptRoot/../bucket/open-design.json" -Raw | ConvertFrom-Json
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('open-design-test-' + [guid]::NewGuid())
$originalAppData = $env:APPDATA

try {
    $env:APPDATA = Join-Path $testRoot 'Roaming'
    $dir = Join-Path $testRoot 'scoop/apps/open-design/0.27.1'
    $project = Join-Path $testRoot 'custom-data/project.txt'
    foreach ($folder in @((Join-Path $env:APPDATA 'Open Design'), (Join-Path $env:APPDATA 'other-app'), (Split-Path $project))) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $folder 'project.txt') 'keep until purge'
    }

    # Model the registry in memory so this check never changes real associations.
    function Get-ItemProperty {
        param($LiteralPath, $ErrorAction)
        if ($LiteralPath -ne 'HKCU:\Software\Classes\opendesign\shell\open\command') { throw 'Unexpected registry read.' }
        @{ '(default)' = $script:protocolCommand }
    }
    function Remove-Item {
        param($LiteralPath, [switch]$Recurse, [switch]$Force, $ErrorAction)
        if ($LiteralPath -eq 'HKCU:\Software\Classes\opendesign') {
            $script:protocolCommand = $null
        } else {
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $LiteralPath -Recurse:$Recurse -Force:$Force -ErrorAction Stop
        }
    }

    $hook = [scriptblock]::Create($manifest.post_uninstall -join "`n")
    $purge = $false
    foreach ($version in @('0.26.0', '0.27.1', 'current')) {
        $script:protocolCommand = '"' + (Join-Path (Split-Path $dir) "$version/Open Design.exe") + '" "%1"'
        & $hook
        if ($script:protocolCommand) { throw 'Scoop protocol handler was left behind.' }
    }
    if (!(Test-Path -LiteralPath (Join-Path $env:APPDATA 'Open Design/project.txt'))) { throw 'Normal uninstall removed user data.' }

    $otherCommand = '"C:\standalone\Open Design.exe" "%1"'
    $script:protocolCommand = $otherCommand
    $purge = $true
    & $hook
    & $hook
    if ($script:protocolCommand -ne $otherCommand) { throw 'Removed another installation protocol handler.' }
    if (Test-Path -LiteralPath (Join-Path $env:APPDATA 'Open Design')) { throw 'Purge left application data behind.' }
    foreach ($file in @($project, (Join-Path $env:APPDATA 'other-app/project.txt'))) {
        if (!(Test-Path -LiteralPath $file)) { throw "Purge removed unrelated data: $file" }
    }
    $script:protocolCommand = $null
    & $hook
    Write-Output 'Open Design uninstall checks passed.'
} finally {
    $env:APPDATA = $originalAppData
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    if (!$resolvedTestRoot.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to clean up outside the temporary directory.'
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) { Microsoft.PowerShell.Management\Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force }
}
