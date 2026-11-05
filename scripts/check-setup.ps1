# check-setup.ps1
# Checks everything Et Al. needs before you touch Switch Console.
# Run from the et-al folder:  .\scripts\check-setup.ps1
# Fix FAIL lines from the top down. WARN lines are worth a look but won't
# stop the demo. Costs no AI usage.

$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$local = Join-Path $root 'local'
$script:fails = 0
$script:warns = 0

function Pass([string]$m) { Write-Host "PASS  $m" -ForegroundColor Green }
function Warn([string]$m, [string]$fix) {
    $script:warns++
    Write-Host "WARN  $m" -ForegroundColor Yellow
    if ($fix) { Write-Host "      -> $fix" }
}
function Fail([string]$m, [string]$fix) {
    $script:fails++
    Write-Host "FAIL  $m" -ForegroundColor Red
    if ($fix) { Write-Host "      -> $fix" }
}
function Have([string]$cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function FirstLine([scriptblock]$sb) {
    try { ((& $sb 2>&1) | Select-Object -First 1 | Out-String).Trim() } catch { '' }
}

Write-Host ''
Write-Host '== Tools ==' -ForegroundColor Cyan

if ($PSVersionTable.PSVersion.Major -ge 7) { Pass "PowerShell $($PSVersionTable.PSVersion)" }
else { Fail "PowerShell $($PSVersionTable.PSVersion) (old Windows PowerShell)" 'Open PowerShell 7: type pwsh in the Start menu' }

if (Have git) { Pass (FirstLine { git --version }) } else { Fail 'git not found' 'Install from git-scm.com' }

if (Have docker) {
    docker ps *> $null
    if ($LASTEXITCODE -eq 0) {
        Pass 'Docker is running'
        $names = (docker ps --format '{{.Names}} {{.Image}}' 2>$null) -join "`n"
        if ($names -match '(?i)switch|mattermost') { Pass 'Switch / Mattermost containers are up' }
        else { Warn 'No Switch or Mattermost container running' 'Switch Console: start the local server and wait for "Local server is running"' }
    }
    else { Fail 'Docker is installed but not running' 'Open Docker Desktop and wait for it to finish starting' }
}
else { Fail 'docker not found' 'Install Docker Desktop' }

foreach ($c in @('node', 'npx')) {
    if (Have $c) { Pass "$c $(FirstLine { & $c -v })" } else { Fail "$c not found" 'Install Node.js LTS from nodejs.org' }
}
if (Have curl.exe) { Pass 'curl found' } elseif (Have curl) { Pass 'curl found' } else { Fail 'curl not found' 'Switch needs curl' }

if (Have claude) { Pass "Claude Code $(FirstLine { claude --version })" }
else { Fail 'claude not found' 'npm install -g @anthropic-ai/claude-code, then run claude and log in' }

if (Have cursor-agent) { Pass "cursor-agent $(FirstLine { cursor-agent --version })" }
else { Fail 'cursor-agent not found (coordinator and scout need it)' 'Install the Cursor CLI, or switch those agents to Claude Code' }

Write-Host ''
Write-Host '== Repo ==' -ForegroundColor Cyan

Push-Location $root
try {
    git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -eq 0) {
        Pass 'et-al is a git repo'
        $remote = (git remote get-url origin 2>$null)
        if ($remote) { Pass "origin = $remote" } else { Fail 'No origin remote' 'git remote add origin https://github.com/YOUR-USERNAME/et-al.git' }
        $branch = (git branch --show-current 2>$null)
        if ($branch -eq 'main') { Pass 'On branch main' } else { Warn "On branch '$branch'" 'Normal only while testing Stage 2 or 3' }
    }
    else { Fail 'et-al is not a git repo' 'See Day 1 in the build plan: git init ...' }

    $gi = if (Test-Path .gitignore) { Get-Content .gitignore -Raw } else { '' }
    foreach ($entry in @('.venv/', 'local/')) {
        if ($gi -match [regex]::Escape($entry)) { Pass ".gitignore has $entry" }
        else { Fail ".gitignore is missing $entry" "Add a line: $entry" }
    }

    $need = @('README.md', 'agents\coordinator.md', 'agents\scout.md', 'agents\experimenter.md',
        'room\instructions.md', 'templates\et-al.template.yaml', 'demo\script.md', 'docs\notes.md',
        'workspace\coordinator', 'workspace\scout', 'workspace\experimenter')
    $missing = $need | Where-Object { -not (Test-Path (Join-Path $root $_)) }
    if ($missing) { Fail "Missing: $($missing -join ', ')" 'Unzip the file pack into et-al' }
    else { Pass 'All repo files and workspace folders exist' }

    $empty = $need | Where-Object { (Test-Path (Join-Path $root $_) -PathType Leaf) -and ((Get-Item -Force (Join-Path $root $_)).Length -eq 0) }
    if ($empty) { Warn "Empty files: $($empty -join ', ')" 'Unzip the file pack, replacing the empty files' }

    # Placeholders must stay in the repo copies (real values only in local\)
    $ph = @{ 'agents\scout.md' = 'YOUR-EMAIL'; 'agents\experimenter.md' = 'PYTHON-PATH'; 'room\instructions.md' = 'PI-USERNAME' }
    foreach ($f in $ph.Keys) {
        $p = Join-Path $root $f
        if ((Test-Path $p) -and -not ((Get-Content $p -Raw) -match $ph[$f])) {
            Warn "$f has no $($ph[$f]) placeholder" 'Fine if intended, but real values in the repo become public'
        }
    }

    # Secrets and personal details in files Git would publish
    $files = @(git ls-files 2>$null) + @(git ls-files --others --exclude-standard 2>$null) | Sort-Object -Unique
    $patterns = [ordered]@{
        'Google / Gemini API key' = 'AIza[0-9A-Za-z_\-]{30,}|AQ\.[0-9A-Za-z_\-]{30,}'
        'Anthropic key'           = 'sk-ant-[0-9A-Za-z_\-]{20,}'
        'OpenAI-style key'        = 'sk-[0-9A-Za-z]{32,}'
        'xAI / Grok key'          = 'xai-[0-9A-Za-z]{30,}'
        'GitHub token'            = 'gh[pousr]_[0-9A-Za-z]{30,}'
        'AWS access key'          = 'AKIA[0-9A-Z]{16}'
        'Email address'           = '[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'
    }
    $hits = @()
    foreach ($f in $files) {
        $p = Join-Path $root $f
        if (-not (Test-Path $p -PathType Leaf)) { continue }
        if ((Get-Item -Force $p).Length -gt 2MB) { continue }
        $t = Get-Content $p -Raw -ErrorAction SilentlyContinue
        if (-not $t) { continue }
        foreach ($k in $patterns.Keys) {
            foreach ($m in [regex]::Matches($t, $patterns[$k])) {
                if ($k -eq 'Email address' -and $m.Value -match '(?i)noreply|example\.com|@anthropic\.com') { continue }
                $hits += "$f : $k ($($m.Value.Substring(0, [Math]::Min(12, $m.Value.Length)))...)"
            }
        }
    }
    if ($hits) {
        Fail 'Possible secrets or personal details in files Git would publish:' 'Move them to local\ or delete them before pushing'
        $hits | Select-Object -Unique | ForEach-Object { Write-Host "      $_" }
    }
    else { Pass 'No keys, tokens or email addresses in files Git would publish' }
}
finally { Pop-Location }

Write-Host ''
Write-Host '== Filled copies (local\) ==' -ForegroundColor Cyan

$answers = $null
if (Test-Path (Join-Path $local 'answers.json')) {
    $answers = Get-Content (Join-Path $local 'answers.json') -Raw | ConvertFrom-Json
    Pass "fill-local answers: PI=@$($answers.PI), student=@$($answers.STUDENT)"
}
else { Fail 'local\answers.json missing' 'Run .\scripts\fill-local.ps1' }

$filled = @('agents\coordinator.md', 'agents\scout.md', 'agents\experimenter.md', 'room\instructions.md', 'templates\et-al.template.yaml')
foreach ($f in $filled) {
    $p = Join-Path $local $f
    if (-not (Test-Path $p)) { Fail "local\$f missing" 'Run .\scripts\fill-local.ps1'; continue }
    $t = Get-Content $p -Raw
    $left = @('PI-USERNAME', 'STUDENT-USERNAME', 'YOUR-EMAIL', 'PYTHON-PATH', 'WORKSPACE-DIR') | Where-Object { $t.Contains($_) }
    if ($t -match '(?m)^\s*#include\s') { $left += '#include' }
    if ($left) { Fail "local\$f still has $($left -join ', ')" 'Rerun .\scripts\fill-local.ps1' }
    else {
        $src = Join-Path $root $f
        if ((Test-Path $src) -and ((Get-Item $src).LastWriteTime -gt (Get-Item $p).LastWriteTime)) {
            Warn "local\$f is older than $f" 'Rerun .\scripts\fill-local.ps1, then re-paste into Console'
        }
        else { Pass "local\$f filled" }
    }
}

Write-Host ''
Write-Host '== Experimenter Python ==' -ForegroundColor Cyan

$py = if ($answers -and $answers.PYTHON) { $answers.PYTHON } else { Join-Path (Split-Path -Parent $root) '.venv\Scripts\python.exe' }
if (Test-Path $py) {
    Pass "Found $py"
    if ($py -match ' ') { Warn 'The Python path contains a space' 'Agents can trip over it; a path without spaces is safer' }
    $code = 'import sys, torch, sklearn, numpy, matplotlib; print(sys.version.split()[0], torch.__version__, sklearn.__version__)'
    $out = & $py -c $code 2>&1
    if ($LASTEXITCODE -eq 0) { Pass "python / torch / sklearn: $out" }
    else { Fail 'Python is missing a package' "Activate the venv and pip install torch (CPU) scikit-learn numpy matplotlib. Error: $(($out | Select-Object -Last 1))" }

    # Same setup the experiment uses: digits, 20% flipped labels, small MLP, smoothing 0.1. Should take a few seconds.
    $smoke = @'
import time, numpy as np, torch, torch.nn as nn
from sklearn.datasets import load_digits
from sklearn.model_selection import train_test_split
t = time.time()
X, y = load_digits(return_X_y=True)
X = X / 16.0
Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.25, random_state=0, stratify=y)
rng = np.random.default_rng(0)
idx = rng.choice(len(ytr), int(0.2 * len(ytr)), replace=False)
ytr = ytr.copy(); ytr[idx] = (ytr[idx] + rng.integers(1, 10, len(idx))) % 10
torch.manual_seed(0)
m = nn.Sequential(nn.Linear(64, 64), nn.ReLU(), nn.Linear(64, 10))
opt = torch.optim.Adam(m.parameters(), lr=1e-2)
lf = nn.CrossEntropyLoss(label_smoothing=0.1)
Xt, yt = torch.tensor(Xtr, dtype=torch.float32), torch.tensor(ytr)
for _ in range(100):
    opt.zero_grad(); lf(m(Xt), yt).backward(); opt.step()
acc = (m(torch.tensor(Xte, dtype=torch.float32)).argmax(1).numpy() == yte).mean()
print(f"acc={acc:.3f} secs={time.time() - t:.1f}")
'@
    $out = $smoke | & $py - 2>&1
    if ($LASTEXITCODE -eq 0 -and "$out" -match 'acc=([\d.]+) secs=([\d.]+)') {
        $secs = [double]$Matches[2]
        if ($secs -lt 30) { Pass "Smoke experiment ran: $out" }
        else { Warn "Smoke experiment was slow: $out" 'The 3-seed comparison may go past 60 seconds' }
    }
    else { Fail 'Smoke experiment failed' "$out" }
}
else { Fail "No Python at $py" 'Create the venv (build plan, Nov 1), or rerun fill-local.ps1 with the right path' }

Write-Host ''
Write-Host '== Network ==' -ForegroundColor Cyan

try {
    $mail = if ($answers -and $answers.EMAIL) { "&mailto=$($answers.EMAIL)" } else { '' }
    $r = Invoke-RestMethod -TimeoutSec 20 -Uri "https://api.openalex.org/works?search=label%20smoothing&sort=cited_by_count:desc&per_page=1$mail"
    $top = $r.results[0]
    Pass "OpenAlex works: top hit '$($top.title)' ($($top.cited_by_count) citations)"
}
catch { Fail 'Could not reach OpenAlex' "The scout needs api.openalex.org. Error: $($_.Exception.Message)" }

try {
    Invoke-WebRequest -TimeoutSec 20 -Method Head -Uri 'https://docs.switchagents.ai' -UseBasicParsing | Out-Null
    Pass 'docs.switchagents.ai reachable'
}
catch { Warn 'Could not reach docs.switchagents.ai' 'Only matters for the switch-docs MCP' }

Write-Host ''
if ($script:fails) {
    Write-Host "$($script:fails) FAIL, $($script:warns) WARN. Fix the FAIL lines from the top down, then rerun." -ForegroundColor Red
    exit 1
}
Write-Host "All checks passed ($($script:warns) WARN). Next: onboard the agents in Switch Console." -ForegroundColor Green
