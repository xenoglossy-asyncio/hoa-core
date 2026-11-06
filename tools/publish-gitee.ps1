param(
    [string]$Version,
    [string]$Repository,
    [string]$Tag,
    [string]$PackageTag,
    [string]$AssetsDir,
    [string]$Target = 'main',
    [string]$Token,
    [switch]$Clobber,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$releaseConfig = Get-Content (Join-Path $RepoRoot 'config\release.json') -Raw | ConvertFrom-Json

if (-not $Repository) { $Repository = $releaseConfig.giteeRepository }
if (-not $Repository) { throw 'No Gitee repository: set giteeRepository in config/release.json.' }
if (-not $Version) { $Version = (Get-Content (Join-Path $RepoRoot 'VERSION') -Raw).Trim() }
if (-not $Tag) { $Tag = "v$Version" }
if (-not $PackageTag) { $PackageTag = "packages-$Tag" }
if (-not $AssetsDir) { $AssetsDir = Join-Path $RepoRoot "release\$Version\assets" }
if (-not (Test-Path $AssetsDir)) { throw "Missing release assets at ${AssetsDir}; run tools/release.ps1 first." }
if (-not $Token) { $Token = $env:HOA_GITEE_TOKEN }
if (-not $Token) { $Token = [Environment]::GetEnvironmentVariable('HOA_GITEE_TOKEN', 'User') }
if (-not $Token -and -not $DryRun) { throw 'Set HOA_GITEE_TOKEN (a Gitee personal access token with repo write access).' }
if (-not $Token) { $Token = 'dry-run' }

$api = "https://gitee.com/api/v5/repos/$Repository"
$tokenQuery = "access_token=$([Uri]::EscapeDataString($Token))"

function Invoke-Gitee([string]$Method, [string]$Path, $Form, [switch]$Multipart) {
    $uri = "$api$Path"
    switch ($Method) {
        'Get' { return Invoke-RestMethod -Method Get -Uri "$uri$(if ($uri.Contains('?')) { '&' } else { '?' })$tokenQuery" }
        'Delete' { return Invoke-RestMethod -Method Delete -Uri "$uri$(if ($uri.Contains('?')) { '&' } else { '?' })$tokenQuery" }
        default {
            if ($Multipart) {
                return Invoke-RestMethod -Method $Method -Uri "$uri$(if ($uri.Contains('?')) { '&' } else { '?' })$tokenQuery" -Form $Form
            }
            return Invoke-RestMethod -Method $Method -Uri $uri -Body $Form
        }
    }
}

function Ensure-DefaultBranch {
    if ($DryRun) { return }
    $info = Invoke-Gitee 'Get' '' $null
    if ($info.default_branch -ne $Target) {
        Invoke-Gitee 'Patch' '' @{ access_token = $Token; default_branch = $Target } | Out-Null
        Write-Host "default branch -> $Target"
    }
}

function Get-Release([string]$Name) {
    if ($DryRun) { return $null }
    try {
        return Invoke-Gitee 'Get' "/releases/tags/$([Uri]::EscapeDataString($Name))"
    } catch {
        if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 404) { return $null }
        throw
    }
}

function Ensure-Release([string]$Name, [string]$Title, [string]$Body, [bool]$Prerelease) {
    $release = Get-Release $Name
    if ($release) {
        Write-Host "release $Name already exists (id $($release.id))"
        return $release
    }
    if ($DryRun) {
        Write-Host "would create release $Name (prerelease=$Prerelease) with $($Body.Length) bytes of notes"
        return [pscustomobject]@{ id = 0; tag_name = $Name; assets = @() }
    }
    $form = @{
        access_token = $Token
        tag_name = $Name
        name = $Title
        body = $Body
        target_commitish = $Target
        prerelease = $Prerelease.ToString().ToLowerInvariant()
    }
    $release = Invoke-Gitee 'Post' '/releases' $form
    Write-Host "created release $Name (id $($release.id))"
    return $release
}

function Get-Attachments($Release) {
    if ($DryRun) { return @() }
    return @(Invoke-Gitee 'Get' "/releases/$($Release.id)/attach_files")
}

function Send-Assets($Release, [string[]]$Files, [string[]]$Skip) {
    $existing = @(Get-Attachments $Release | ForEach-Object { $_.name })
    foreach ($file in $Files) {
        $item = Get-Item $file
        if ($Skip -contains $item.Name) { continue }
        if ($existing -contains $item.Name) {
            if (-not $Clobber) {
                Write-Host "  skip $($item.Name) (already attached; -Clobber replaces it)"
                continue
            }
            $old = @(Get-Attachments $Release | Where-Object { $_.name -eq $item.Name })
            foreach ($attachment in $old) {
                if (-not $DryRun) {
                    Invoke-Gitee 'Delete' "/releases/$($Release.id)/attach_files/$($attachment.id)" $null
                }
                Write-Host "  removed old $($item.Name)"
            }
        }
        if ($DryRun) {
            Write-Host "  would upload $($item.Name) ($([math]::Round($item.Length / 1MB, 1)) MB)"
            continue
        }
        $form = @{ file = $item }
        Invoke-Gitee 'Post' "/releases/$($Release.id)/attach_files" $form -Multipart | Out-Null
        Write-Host "  uploaded $($item.Name) ($([math]::Round($item.Length / 1MB, 1)) MB)"
    }
}

$notesPath = Join-Path $RepoRoot "release\$Version\notes.md"
$notes = if (Test-Path $notesPath) { (Get-Content $notesPath -Raw).Trim() } else { $releaseConfig.productName }
$title = "$($releaseConfig.productName) $Version"

# Packages first: Gitee's "latest" release must be the launcher release, which carries the manifest.
Ensure-DefaultBranch
$packageFiles = @(Get-ChildItem $AssetsDir -Filter '*.zip' -File | ForEach-Object FullName | Sort-Object)
$packages = Ensure-Release $PackageTag "$title update packages" "Packages the launcher downloads for $Tag. Players don't need anything here: get the launcher from the $Tag release." $true
if ($packageFiles.Count) {
    Write-Host "packages -> $PackageTag ($($packageFiles.Count) zip files)"
    Send-Assets $packages $packageFiles @()
}

$launcherFiles = @(
    (Join-Path $AssetsDir 'manifest.json'),
    (Join-Path $AssetsDir 'manifest-linux.json'),
    (Join-Path $AssetsDir 'HoALauncher.exe'),
    (Join-Path $AssetsDir 'HoALauncher-linux.tar.gz')
) | Where-Object { Test-Path $_ }
$launcher = Ensure-Release $Tag $title $notes $false
Write-Host "launcher -> $Tag ($($launcherFiles.Count) files)"
Send-Assets $launcher $launcherFiles @()

Write-Host "Gitee releases ready: https://gitee.com/$Repository/releases"
