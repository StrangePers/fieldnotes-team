#requires -Version 5.1
[CmdletBinding()]
param([switch]$Install)

$ErrorActionPreference = 'Stop'
$project = (Get-Location).Path
$parent = Split-Path -Parent $project
$cli = Join-Path $parent 'project-fieldnotes/fieldnotes.py'
$target = Join-Path $parent 'fieldnotes-native'

if (!(Test-Path -LiteralPath (Join-Path $project '.svn') -PathType Container)) {
    throw 'Run this command from the root of your SVN working copy.'
}
if (!(Test-Path -LiteralPath $cli -PathType Leaf) -or
    (!$Install -and !(Test-Path -LiteralPath (Join-Path $target '.git')))) {
    throw 'Follow the native installation steps in the README first. Expected project-fieldnotes and fieldnotes-native next to the SVN working copy.'
}

$openCode = Get-Command opencode.cmd, opencode.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (!$openCode) { throw 'Install the OpenCode CLI and rerun.' }
if (!$Install) {
    git -C $PSScriptRoot pull --ff-only
    if ($LASTEXITCODE -ne 0) { throw 'Could not update fieldnotes-team.' }
}
git -C $PSScriptRoot submodule update --init --recursive
if ($LASTEXITCODE -ne 0) { throw 'Could not update the pinned skill library.' }

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'workspace.json') | ConvertFrom-Json
$expected = @($manifest.projects.native.skills)
if ($expected.Count -ne 26 -or @($expected | Sort-Object -Unique).Count -ne 26) {
    throw 'Expected 26 distinct skill IDs in the native manifest.'
}
if ($Install) {
    if (!(Test-Path -LiteralPath (Join-Path $target '.git/project-fieldnotes'))) {
        if ((Test-Path -LiteralPath $target) -and
            (!(Test-Path -LiteralPath $target -PathType Container) -or
             @(Get-ChildItem -LiteralPath $target -Force | Where-Object Name -ne '.git').Count)) {
            throw "The existing directory $target is not an empty Fieldnotes target."
        }
        git init -q $target
        if ($LASTEXITCODE -ne 0) { throw "Could not initialize $target." }
    }
    python $cli init $target --workspace $PSScriptRoot --project native
} else {
    python $cli apply $PSScriptRoot native $target
}
if ($LASTEXITCODE -ne 0) { throw 'Fieldnotes could not apply the native profile.' }
$plan = @(python $cli plan $PSScriptRoot native $target)
if ($LASTEXITCODE -ne 0 -or $plan -notcontains '0 file(s) to change') {
    $plan | Out-Host
    throw 'The native profile is not fully synchronized.'
}

if ($Install) {
    python (Join-Path $PSScriptRoot 'scripts/connect-native.py') $project
    if ($LASTEXITCODE -ne 0) { throw 'Could not connect the native skills in the OpenCode project config.' }
}
$root = (Resolve-Path -LiteralPath (Join-Path $target '.agents/skills')).Path + '\'
$deadline = (Get-Date).AddMinutes(2)
do {
    $json = & $openCode.Source api GET /api/skill --header "x-opencode-directory: $project"
    if ($LASTEXITCODE -ne 0) { throw 'OpenCode skill query failed.' }
    $result = $json | ConvertFrom-Json
    $rows = @($result.data | Where-Object {
        $_.path -and $_.path.Replace('/', '\').StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
    })
    $valid = @($rows | Where-Object { $_.path.Replace('/', '\') -ieq "$root$($_.id)\SKILL.md" } |
        ForEach-Object { $_.id })
    $missing = @($expected | Where-Object { $valid -cnotcontains $_ })
    if ($missing.Count -eq 0 -and $rows.Count -eq $expected.Count) {
        Write-Output 'OK: OpenCode sees all 26 native skills.'
        return
    }
    if ((Get-Date) -ge $deadline) { break }
    Start-Sleep -Seconds 2
} while ($true)

throw "OpenCode reported $($rows.Count) entries from $root. Missing at expected paths: [$($missing -join ', ')]. Check the skills path in the SVN project's OpenCode config."
