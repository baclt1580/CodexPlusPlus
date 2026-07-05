Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-WorkspaceVersion {
    $cargoToml = Join-Path $PSScriptRoot 'Cargo.toml'
    if (-not (Test-Path $cargoToml)) {
        throw "Cannot find Cargo.toml at $cargoToml"
    }

    $content = Get-Content $cargoToml -Raw
    $match = [regex]::Match($content, '(?m)^\s*version\s*=\s*"([^"]+)"\s*$')
    if (-not $match.Success) {
        throw 'Cannot find workspace version in Cargo.toml'
    }

    return $match.Groups[1].Value
}

$root = $PSScriptRoot
$version = Get-WorkspaceVersion
$managerDir = Join-Path $root 'apps\codex-plus-manager'
$installerDir = Join-Path $root 'scripts\installer\windows'
$distAppDir = Join-Path $root 'dist\windows\app'
$makensis = Join-Path ${env:ProgramFiles(x86)} 'NSIS\makensis.exe'

Write-Host "Version: $version"

Push-Location $managerDir
try {
    if (-not (Test-Path 'node_modules')) {
        npm install
    }

    npm run vite:build
}
finally {
    Pop-Location
}

Push-Location $root
try {
    cargo build --release
}
finally {
    Pop-Location
}

New-Item -ItemType Directory -Force $distAppDir | Out-Null
Copy-Item (Join-Path $root 'target\release\codex-plus-plus.exe') $distAppDir -Force
Copy-Item (Join-Path $root 'target\release\codex-plus-plus-manager.exe') $distAppDir -Force

if (-not (Test-Path $makensis)) {
    $makensis = 'makensis'
}

Push-Location $installerDir
try {
    & $makensis '/INPUTCHARSET' 'UTF8' "/DVERSION=$version" 'CodexPlusPlus.nsi'
}
finally {
    Pop-Location
}

Write-Host ''
Write-Host "Installer created at: dist\windows\CodexPlusPlus-$version-windows-x64-setup.exe"
