param(
    [ValidateSet('all', 'server', 'client', 'launcher', 'addon', 'i18n', 'check')]
    [string]$Component = 'all',
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Cmake = $null
foreach ($candidate in @(
    'cmake',
    'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe',
    'C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
)) {
    $command = Get-Command $candidate -ErrorAction SilentlyContinue
    if ($command) { $Cmake = $command.Source; break }
}
if (-not $Cmake) { throw 'cmake not found' }

$Luajit = @(
    'luajit',
    "$env:LOCALAPPDATA\Programs\LuaJIT\bin\luajit.exe"
) | ForEach-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
if ($Luajit) { $Luajit = $Luajit.Source }

function Build-Server {
    & $Cmake -S "$Root\server" -B "$Root\server\build" `
        -G 'Visual Studio 17 2022' -A x64 `
        -DSUPPORTED_CLIENT_BUILD=CLIENT_BUILD_1_12_1 `
        -DBUILD_EXTRACTORS=OFF -DENABLE_MAILSENDER=OFF
    if ($LASTEXITCODE -ne 0) { throw 'cmake configure failed' }
    & $Cmake --build "$Root\server\build" --config $Configuration --target mangosd -- /m
    if ($LASTEXITCODE -ne 0) { throw 'server build failed' }
}

function Build-Client {
    Push-Location "$Root\client"
    try {
        cargo build --release -p hoa
        if ($LASTEXITCODE -ne 0) { throw 'client build failed' }
    } finally { Pop-Location }
}

function Build-Launcher {
    dotnet build "$Root\launcher\HordesOfAzerothLauncher.csproj" -c $Configuration
    if ($LASTEXITCODE -ne 0) { throw 'launcher build failed' }
}

function Test-Addon {
    if (-not $Luajit) { throw 'luajit not found; install LuaJIT or add it to PATH' }
    $files = @(
        Get-ChildItem "$Root\addon" -Recurse -Filter *.lua
        Get-ChildItem "$Root\glue" -Recurse -Filter *.lua
    )
    foreach ($file in $files) {
        & $Luajit -bl $file.FullName *> $null
        if ($LASTEXITCODE -ne 0) { throw "addon/glue syntax error: $($file.FullName)" }
    }
    "addon+glue: $($files.Count) Lua files parsed"
}

function Test-I18n {
    python "$Root\tools\i18n\check.py"
    if ($LASTEXITCODE -ne 0) { throw 'i18n check failed' }
    python "$Root\tools\i18n\build.py" --check
    if ($LASTEXITCODE -ne 0) { throw 'generated i18n catalogue is out of date' }
}

function Test-Manifests {
    Push-Location "$Root\client"
    try {
        cargo metadata --no-deps --format-version 1 > $null
        if ($LASTEXITCODE -ne 0) { throw 'client manifests are invalid' }
    } finally { Pop-Location }
    'client: workspace manifests ok'
}

switch ($Component) {
    'server'   { Build-Server }
    'client'   { Build-Client }
    'launcher' { Build-Launcher }
    'addon'    { Test-Addon }
    'i18n'     { Test-I18n }
    'check'    { Test-Manifests; Test-Addon; Test-I18n }
    'all'      { Build-Server; Build-Client; Build-Launcher; Test-Addon; Test-I18n }
}
