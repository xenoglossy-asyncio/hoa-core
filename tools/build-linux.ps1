# SPDX-License-Identifier: GPL-3.0-only
param(
    [ValidateSet('all', 'server', 'client')][string]$Part = 'all',
    [string]$ClientSource,
    [string]$ServerSource,
    [string]$Out,
    [switch]$Docker,
    [string]$Image = 'hoa-linux-builder:22.04',
    [int]$Jobs = 0
)

. "$PSScriptRoot\common.ps1"

$distro = 'Ubuntu-22.04'

if (-not $ClientSource) { $ClientSource = Join-Path $RepoRoot 'client' }
if (-not $ServerSource) { $ServerSource = Join-Path $RepoRoot 'server' }
if (-not $Out) { $Out = Join-Path $RepoRoot 'release\build\linux' }

function ConvertTo-WslPath([string]$Path) {
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    '/mnt/' + $full.Substring(0, 1).ToLowerInvariant() + ($full.Substring(2) -replace '\\', '/')
}

New-Item -ItemType Directory -Force $Out | Out-Null

$installed = (wsl --list --quiet 2>$null) -replace "`0", '' | ForEach-Object { $_.Trim() }
if ($Docker -or $installed -notcontains $distro) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "The Linux build needs WSL ${distro} or Docker: wsl --install -d $distro --no-launch, or install Docker Desktop."
    }
    docker image inspect $Image 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Building the $Image image from tools/linux/Dockerfile..."
        docker build -t $Image -f (Join-Path $PSScriptRoot 'linux\Dockerfile') (Join-Path $PSScriptRoot 'linux')
        if ($LASTEXITCODE -ne 0) { throw "Docker image build failed with exit code $LASTEXITCODE." }
    }
    $repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path -replace '\\', '/'
    $outFull = [System.IO.Path]::GetFullPath($Out) -replace '\\', '/'
    $ErrorActionPreference = 'Continue'
    $jobArgs = @()
    if ($Jobs -gt 0) { $jobArgs = @($Jobs) }
    docker run --rm -v "${repo}:/src" -v "${outFull}:/out" $Image bash /src/tools/linux/build.sh $Part /src/client /src/server /out @jobArgs
    if ($LASTEXITCODE -ne 0) { throw "Linux build failed with exit code $LASTEXITCODE." }
    return
}

$ErrorActionPreference = 'Continue'
$jobArgs = @()
if ($Jobs -gt 0) { $jobArgs = @($Jobs) }
wsl -d $distro -u root -- bash (ConvertTo-WslPath (Join-Path $PSScriptRoot 'linux\build.sh')) $Part `
    (ConvertTo-WslPath $ClientSource) (ConvertTo-WslPath $ServerSource) (ConvertTo-WslPath $Out) @jobArgs
if ($LASTEXITCODE -ne 0) { throw "Linux build failed with exit code $LASTEXITCODE." }
