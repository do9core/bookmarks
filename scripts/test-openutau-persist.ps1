param(
    [string] $ScoopPath = (scoop prefix scoop)
)

$ErrorActionPreference = 'Stop'

# Exercise Scoop's real persistence functions without installing applications.
foreach ($file in @('lib/core.ps1', 'lib/install.ps1')) {
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $ScoopPath $file), [ref] $null, [ref] $null
    )
    $functions = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -in @('ensure', 'is_directory', 'persist_def', 'persist_data', 'unlink_persist_data', 'New-DirectoryJunction')
    }, $false)
    foreach ($function in $functions) {
        Invoke-Expression $function.Extent.Text
    }
}

$stable = Get-Content "$PSScriptRoot/../bucket/openutau.json" -Raw | ConvertFrom-Json
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('openutau-persist-test-' + [guid]::NewGuid())
New-Item -Path $testRoot -ItemType Directory | Out-Null

try {
    foreach ($order in @(
        @('openutau-beta', 'stable'), @('stable', 'openutau-beta'),
        @('openutau-lunai', 'stable'), @('stable', 'openutau-lunai'),
        @('utau-v', 'stable'), @('stable', 'utau-v')
    )) {
        $variant = $order | Where-Object { $_ -ne 'stable' }
        $variantManifest = Get-Content "$PSScriptRoot/../bucket/$variant.json" -Raw | ConvertFrom-Json
        $caseRoot = Join-Path $testRoot ($order -join '-')
        $shared = Join-Path $caseRoot 'persist/openutau'
        $private = Join-Path $caseRoot "persist/$variant"
        New-Item -Path $private -ItemType Directory -Force | Out-Null
        Set-Content (Join-Path $private 'old-data.txt') 'preserve me'

        foreach ($app in $order) {
            $manifest = if ($app -eq $variant) { $variantManifest } else { $stable }
            $dir = Join-Path $caseRoot "apps/$app"
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            $persistPath = if ($app -eq $variant) { $private } else { $shared }
            persist_data $manifest $dir $persistPath
        }

        foreach ($folder in @('Dictionaries', 'Resamplers', 'Singers', 'Templates', 'Wavtools')) {
            $marker = Join-Path $caseRoot "apps/stable/$folder/shared.txt"
            Set-Content $marker 'shared'
            if ((Get-Content (Join-Path $caseRoot "apps/$variant/$folder/shared.txt")) -ne 'shared') {
                throw "Folder is not shared: $folder"
            }
        }

        foreach ($mapping in $variantManifest.persist) {
            $folder, $target = persist_def $mapping
            $storage = if ($mapping -is [array]) { $shared } else { $private }
            Set-Content (Join-Path $storage "$folder/shared.txt") 'shared'
            if ((Get-Content (Join-Path $caseRoot "apps/$variant/$folder/shared.txt")) -ne 'shared') {
                throw "Variant folder is not in expected storage: $folder"
            }
            if ($mapping -isnot [array]) {
                Set-Content (Join-Path $caseRoot "apps/$variant/$folder/private.txt") $variant
                if (Test-Path (Join-Path $shared "$folder/private.txt")) {
                    throw "Private data leaked into shared storage: $folder"
                }
            }
        }

        # Removing the variant's links and rebuilding them models an update/reinstall.
        $dir = Join-Path $caseRoot "apps/$variant"
        unlink_persist_data $variantManifest $dir
        persist_data $variantManifest $dir $private
        foreach ($mapping in $variantManifest.persist) {
            $folder, $target = persist_def $mapping
            if (!(Test-Path (Join-Path $dir "$folder/shared.txt"))) {
                throw "Update lost shared data: $folder"
            }
        }

        unlink_persist_data $variantManifest $dir
        if (!(Test-Path (Join-Path $private 'old-data.txt'))) {
            throw 'Existing private variant data was lost'
        }

        # All recursively removed paths are resolved descendants of the test root.
        $resolvedPrivate = (Resolve-Path $private).Path
        if (!$resolvedPrivate.StartsWith($testRoot + [System.IO.Path]::DirectorySeparatorChar)) {
            throw 'Unsafe test cleanup path'
        }
        Remove-Item -LiteralPath $resolvedPrivate -Recurse -Force
        foreach ($mapping in $variantManifest.persist | Where-Object { $_ -is [array] }) {
            $folder, $target = persist_def $mapping
            if (!(Test-Path (Join-Path $shared "$folder/shared.txt"))) {
                throw "Variant purge lost shared data: $folder"
            }
        }
        unlink_persist_data $stable (Join-Path $caseRoot 'apps/stable')
        Write-Output "PASS: $($order -join ' -> '), shared writes, private isolation, variant update, uninstall and purge"
    }
} finally {
    # Never recursively clean up a failed case while it still contains junctions.
    $links = @(Get-ChildItem -LiteralPath $testRoot -Recurse -Force | Where-Object LinkType)
    if ($links.Count -eq 0 -and (Split-Path $testRoot -Leaf) -like 'openutau-persist-test-*') {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    } else {
        Write-Warning "Test files retained for inspection: $testRoot"
    }
}
