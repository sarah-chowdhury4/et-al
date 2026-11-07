# fill-local.ps1
# Makes filled copies of every instruction file in local\ for setting up
# the agents by hand (README, Option B). The template doesn't need this:
# import templates\et-al.template.yaml directly.
# Copies go in local\
# (Git ignores local\). The files in the repo keep their placeholders:
#   PI-USERNAME, STUDENT-USERNAME, YOUR-EMAIL, PYTHON-PATH
# Paste into Console from local\, never from the placeholder files.
#
# Run from the et-al folder:  .\scripts\fill-local.ps1
# Rerun any time you edit agents\ or room\. Your answers are
# remembered in local\answers.json, so you can just press Enter.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$local = Join-Path $root 'local'
$answersFile = Join-Path $local 'answers.json'

New-Item -ItemType Directory -Force -Path $local | Out-Null

# Previous answers, or sensible defaults
$prev = @{
    PI      = ''
    STUDENT = ''
    EMAIL   = ''
    # The venv next to the repo: Scripts\python.exe on Windows, bin/python on macOS and Linux
    PYTHON  = if ($IsWindows) { Join-Path (Split-Path -Parent $root) '.venv\Scripts\python.exe' } else { Join-Path (Split-Path -Parent $root) '.venv/bin/python' }
}
if (Test-Path $answersFile) {
    $saved = Get-Content $answersFile -Raw | ConvertFrom-Json
    foreach ($k in @('PI', 'STUDENT', 'EMAIL', 'PYTHON')) {
        if ($saved.$k) { $prev[$k] = $saved.$k }
    }
}

function Ask([string]$question, [string]$default) {
    $shown = if ($default) { " [$default]" } else { '' }
    while ($true) {
        $a = Read-Host "$question$shown"
        if ([string]::IsNullOrWhiteSpace($a)) { $a = $default }
        if (-not [string]::IsNullOrWhiteSpace($a)) { return $a.Trim() }
        Write-Host '  This one is required.' -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host 'Four questions. Press Enter to keep the value in [brackets].' -ForegroundColor Cyan
$pi      = (Ask 'PI Mattermost username (your main account, no @)' $prev.PI).TrimStart('@')
$student = (Ask 'Student Mattermost username (second account, no @)' $prev.STUDENT).TrimStart('@')
$email   = Ask 'Email for OpenAlex (goes in the scout''s API links)' $prev.EMAIL
$python  = Ask 'Full path to the experimenter''s Python' $prev.PYTHON

if ($pi -eq $student) { throw 'PI and student must be different usernames.' }
if ($email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') { throw "That doesn't look like an email: $email" }
if (-not (Test-Path $python)) {
    Write-Host "  Warning: $python doesn't exist yet. check-setup.ps1 will flag it." -ForegroundColor Yellow
}

@{ PI = $pi; STUDENT = $student; EMAIL = $email; PYTHON = $python } |
    ConvertTo-Json | Set-Content -Path $answersFile -Encoding utf8

$map = [ordered]@{
    'STUDENT-USERNAME' = $student
    'PI-USERNAME'      = $pi
    'YOUR-EMAIL'       = $email
    'PYTHON-PATH'      = $python
}

function Fill([string]$text) {
    foreach ($k in $map.Keys) { $text = $text.Replace($k, $map[$k]) }
    return $text
}

function Read-Text([string]$rel) {
    $p = Join-Path $root $rel
    if (-not (Test-Path $p)) { throw "Missing file: $rel" }
    # Normalise line endings so the template indents cleanly
    return ((Get-Content $p -Raw) -replace "`r`n", "`n").TrimEnd()
}

$written = @()

# 1. Agent and room instruction files
$sources = @('agents\coordinator.md', 'agents\scout.md', 'agents\experimenter.md', 'room\instructions.md')
foreach ($rel in $sources) {
    $out = Join-Path $local $rel
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $out) | Out-Null
    $filled = Fill (Read-Text $rel)
    Set-Content -Path $out -Value $filled -Encoding utf8 -NoNewline
    $written += "local\$rel"
}

# 2. Leftover placeholders?
$left = @()
foreach ($w in $written) {
    $t = Get-Content (Join-Path $root $w) -Raw
    foreach ($k in $map.Keys) { if ($t.Contains($k)) { $left += "$w still has $k" } }
}

Write-Host ''
Write-Host 'Wrote:' -ForegroundColor Green
$written | ForEach-Object { Write-Host "  $_" }
if ($left.Count) {
    Write-Host 'Leftover placeholders:' -ForegroundColor Red
    $left | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host ''
Write-Host 'Copy one to the clipboard, for example:'
Write-Host '  Get-Content .\local\agents\coordinator.md -Raw | Set-Clipboard'
Write-Host 'Next: .\scripts\check-setup.ps1'
