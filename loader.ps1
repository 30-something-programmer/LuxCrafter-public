#requires -Version 5.1
<#
LuxCrafter client setup loader. Downloaded and run by the one-liner in this repo's README.
Finds a Planet Crafter install, confirms with the operator, then installs BepInEx + the
LuxCrafter client plugin (pinned versions, from this repo's GitHub releases). Safe to re-run:
it never deletes or overwrites an existing BepInEx/config/luxcrafter.client/ identity.
#>

$ErrorActionPreference = 'Stop'

$Repo = '30-something-programmer/LuxCrafter-public'
$ReleaseBase = "https://github.com/$Repo/releases/latest/download"
$BepInExAsset = 'BepInEx_win_x64_5.4.23.5.zip'
$PluginAssets = @('LuxCrafter.Client.dll', 'LuxCrafter.ClientIdentity.dll')

function Write-Banner {
    Write-Host ''
    Write-Host 'LUXFORGE // CLIENT SETUP' -ForegroundColor Cyan
    Write-Host ''
}

function Write-Step($Text) {
    Write-Host "  $Text" -ForegroundColor Cyan
}

function Write-Ok($Text) {
    Write-Host "  $([char]0x25CF) $Text" -ForegroundColor Green
}

function Write-Note($Text) {
    Write-Host "  $Text" -ForegroundColor DarkGray
}

function Write-Warn2($Text) {
    Write-Host "  ! $Text" -ForegroundColor Yellow
}

function Write-Fail($Text) {
    Write-Host "  $Text" -ForegroundColor Red
}

# --- 1. Locate Planet Crafter -------------------------------------------------------------

function Get-SteamLibraryFolders {
    $steamPath = $null
    foreach ($probe in @(
        @{ Hive = 'HKCU:\Software\Valve\Steam'; Value = 'SteamPath' },
        @{ Hive = 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'; Value = 'InstallPath' },
        @{ Hive = 'HKLM:\SOFTWARE\Valve\Steam'; Value = 'InstallPath' }
    )) {
        $prop = Get-ItemProperty -Path $probe.Hive -Name $probe.Value -ErrorAction SilentlyContinue
        if ($prop) { $steamPath = $prop.($probe.Value); break }
    }
    if (-not $steamPath) { return @() }
    $steamPath = $steamPath -replace '/', '\'

    $libraries = [System.Collections.Generic.List[string]]::new()
    $libraries.Add($steamPath)

    $vdf = Join-Path $steamPath 'steamapps\libraryfolders.vdf'
    if (Test-Path $vdf) {
        $text = Get-Content $vdf -Raw
        # Each library entry has a `"path"  "D:\\SomeFolder"` line; a plain regex pull is
        # enough here - this is a read-only probe, not a general VDF parser.
        foreach ($m in [regex]::Matches($text, '"path"\s*"([^"]+)"')) {
            $libraries.Add(($m.Groups[1].Value -replace '\\\\', '\'))
        }
    }
    return $libraries | Select-Object -Unique
}

function Find-PlanetCrafter {
    Write-Step 'Looking for your Planet Crafter install...'
    foreach ($lib in (Get-SteamLibraryFolders)) {
        $candidate = Join-Path $lib 'steamapps\common\The Planet Crafter'
        if (Test-Path (Join-Path $candidate 'Planet Crafter.exe')) {
            return $candidate
        }
    }
    return $null
}

function Select-PlanetCrafterManually {
    Write-Warn2 "Couldn't find it automatically."
    Write-Note 'In Steam: right-click The Planet Crafter -> Manage -> Browse local files.'
    Write-Note 'That folder is what to pick next.'
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = 'Select your "The Planet Crafter" install folder'
    $dialog.ShowNewFolderButton = $false
    if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }
    return $dialog.SelectedPath
}

$gameDir = Find-PlanetCrafter
if (-not $gameDir) {
    $gameDir = Select-PlanetCrafterManually
}
if (-not $gameDir -or -not (Test-Path (Join-Path $gameDir 'Planet Crafter.exe'))) {
    Write-Fail 'No valid Planet Crafter install selected. Nothing was changed.'
    exit 1
}

# --- 2. Confirm -----------------------------------------------------------------------------

Write-Banner
Write-Host "  Found: " -NoNewline
Write-Host $gameDir -ForegroundColor White
Write-Host ''
Write-Warn2 'This will MOD your current game installation (adds BepInEx + a plugin).'
Write-Note 'Nothing outside this folder is touched, and this is fully reversible - see the README.'
Write-Host ''
$answer = Read-Host '  Proceed? (y/N)'
if ($answer -notmatch '^(y|yes|ok)$') {
    Write-Note 'Cancelled. Nothing was changed.'
    exit 0
}
Write-Host ''

# --- 3. Install BepInEx (only if not already present) ---------------------------------------

$bepinexMarker = Join-Path $gameDir 'BepInEx\core\BepInEx.dll'
if (Test-Path $bepinexMarker) {
    Write-Ok 'BepInEx is already installed - leaving it as-is.'
} else {
    Write-Step 'Downloading BepInEx...'
    $zipPath = Join-Path $env:TEMP "luxcrafter-$([guid]::NewGuid()).zip"
    Invoke-WebRequest -Uri "$ReleaseBase/$BepInExAsset" -OutFile $zipPath
    Write-Step 'Installing BepInEx...'
    Expand-Archive -Path $zipPath -DestinationPath $gameDir -Force
    Remove-Item $zipPath -Force
    Write-Ok 'BepInEx installed.'
}

# --- 4. Install the LuxCrafter client plugin (safe to update every run) --------------------

$pluginsDir = Join-Path $gameDir 'BepInEx\plugins'
New-Item -ItemType Directory -Path $pluginsDir -Force | Out-Null

Write-Step 'Downloading the LuxCrafter client plugin...'
foreach ($asset in $PluginAssets) {
    Invoke-WebRequest -Uri "$ReleaseBase/$asset" -OutFile (Join-Path $pluginsDir $asset)
}
Write-Ok 'Plugin installed.'

# The identity file, if one already exists, is never touched by anything above - only the
# plugin DLLs and (on a fresh install only) the BepInEx loader files are written.
$identityFile = Join-Path $gameDir 'BepInEx\config\luxcrafter.client\client-identity.private'
Write-Host ''
if (Test-Path $identityFile) {
    Write-Ok 'Existing client identity kept.'
} else {
    Write-Note 'A new client identity will be generated the first time you launch the game.'
    Write-Note 'An operator will need to authorise it before it can load an existing character.'
}
Write-Host ''
Write-Host '  Done.' -ForegroundColor Green
Write-Host ''
