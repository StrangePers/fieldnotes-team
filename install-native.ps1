#requires -Version 5.1
$ErrorActionPreference = 'Stop'
if (!(Test-Path -LiteralPath '.svn' -PathType Container)) {
    throw 'Run this command from the root of your SVN working copy.'
}

function Install-PackageIfMissing($package) {
    if (!(Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        throw "Install $package or enable Windows App Installer (winget), then rerun."
    }
    winget.exe install --id $package --exact --source winget
    if ($LASTEXITCODE -ne 0) { throw "WinGet could not install $package." }
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User') + ';' + $env:Path
}

function Test-Python {
    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if (!$python -or $python.Source -like '*\Microsoft\WindowsApps\python.exe') { return $false }
    & $python.Source -c "import sys; sys.exit(sys.version_info < (3, 11))"
    return ($LASTEXITCODE -eq 0)
}

function Get-Checkout($name) {
    $path = Join-Path (Split-Path -Parent (Get-Location).Path) $name
    $url = "https://github.com/StrangePers/$name.git"
    if (!(Test-Path -LiteralPath $path)) {
        git clone $url $path
        if ($LASTEXITCODE -ne 0) { throw "Could not clone $name." }
        return
    }
    if (!(Test-Path -LiteralPath (Join-Path $path '.git'))) { throw "Expected a Git checkout at $path." }
    $origin = git -C $path remote get-url origin
    if ($LASTEXITCODE -ne 0 -or $origin -notin @($url, $url.Substring(0, $url.Length-4), "git@github.com:StrangePers/$name.git")) {
        throw "Unexpected origin at $path. Expected $url."
    }
}

if (!(Get-Command git.exe -ErrorAction SilentlyContinue)) { Install-PackageIfMissing 'Git.Git' }
if (!(Test-Python)) {
    Install-PackageIfMissing 'Python.Python.3.13'
    if (!(Test-Python) -and (Get-Command py.exe -ErrorAction SilentlyContinue)) {
        $bin = py.exe -3.13 -c "import sys; print(sys.executable)"
        if ($LASTEXITCODE -eq 0) { $env:Path = (Split-Path -Parent $bin) + ';' + $env:Path }
    }
    if (!(Test-Python)) { throw 'Put Python 3.11+ first on PATH and run the installer again.' }
}
if (!(Get-Command opencode.cmd, opencode.exe -ErrorAction SilentlyContinue)) {
    if (!(Get-Command npm.cmd -ErrorAction SilentlyContinue)) { Install-PackageIfMissing 'OpenJS.NodeJS.LTS' }
    npm.cmd install --global '@opencode/cli@2.3.0'
    if ($LASTEXITCODE -ne 0) { throw 'Could not install OpenCode CLI.' }
    $prefix = npm.cmd prefix --global
    if ($LASTEXITCODE -ne 0) { throw 'Could not locate the OpenCode executable.' }
    $env:Path = "$prefix;$env:Path"
}
Get-Checkout 'project-fieldnotes'
Get-Checkout 'fieldnotes-team'
$team = (Resolve-Path -LiteralPath '../fieldnotes-team').Path
git -C $team pull --ff-only
if ($LASTEXITCODE -ne 0) { throw 'Could not update fieldnotes-team.' }
& (Join-Path $team 'update-native.ps1') -Install
