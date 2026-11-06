#!/usr/bin/env bash
# check-setup.sh (macOS and Linux; Windows uses check-setup.ps1)
# Checks everything Et Al. needs before you touch Switch Console.
# Run from anywhere:  bash scripts/check-setup.sh
# Fix FAIL lines from the top down. WARN lines are worth a look but won't
# stop the demo. Uses no AI.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL="$ROOT/local"
ANSWERS="$LOCAL/answers.json"
FAILS=0
WARNS=0

if [ -t 1 ]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi

pass() { echo "${GREEN}PASS${RESET}  $1"; }
warn() { WARNS=$((WARNS + 1)); echo "${YELLOW}WARN${RESET}  $1"; [ -z "${2:-}" ] || echo "      -> $2"; }
fail() { FAILS=$((FAILS + 1)); echo "${RED}FAIL${RESET}  $1"; [ -z "${2:-}" ] || echo "      -> $2"; }
have() { command -v "$1" >/dev/null 2>&1; }
first_line() { "$@" 2>&1 | head -n 1; }
section() { echo; echo "${CYAN}== $1 ==${RESET}"; }

json_get() {
  [ -f "$ANSWERS" ] || return 0
  tr -d '\r' < "$ANSWERS" |
    sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\".*/\1/p" |
    head -n 1 | sed 's/\\"/"/g; s/\\\\/\\/g'
}

section "Tools"

if have git; then pass "$(git --version)"; else fail "git not found" "Install Git (macOS: brew install git; Linux: sudo apt install git)"; fi

if have docker; then
  if docker ps >/dev/null 2>&1; then
    pass "Docker is running"
    if docker ps --format '{{.Names}} {{.Image}}' 2>/dev/null | grep -qiE 'switch|mattermost'; then
      pass "Switch / Mattermost containers are up"
    else
      warn "No Switch or Mattermost container running" "Start the local server from Switch Console (Add a server, then Run a server on this computer)"
    fi
  elif [ "$(uname)" = "Linux" ] && sudo -n true 2>/dev/null && sudo docker ps >/dev/null 2>&1; then
    fail "Docker only works with sudo" "sudo usermod -aG docker \$USER, then log out and back in"
  else
    fail "Docker is installed but not running" "macOS: open Docker Desktop. Linux: sudo systemctl start docker"
  fi
else
  fail "docker not found" "macOS: install Docker Desktop. Linux: sudo apt install docker.io docker-compose-v2"
fi

for c in node npx; do
  if have "$c"; then pass "$c $(first_line "$c" -v)"; else fail "$c not found" "Install Node.js LTS from nodejs.org"; fi
done
if have curl; then pass "curl found"; else fail "curl not found" "Switch needs curl"; fi

if have claude; then pass "Claude Code $(first_line claude --version)"
else fail "claude not found" "npm install -g @anthropic-ai/claude-code, then run claude and log in"; fi

if have cursor-agent; then pass "cursor-agent $(first_line cursor-agent --version)"
else fail "cursor-agent not found (coordinator and scout need it)" "Install the Cursor CLI, or switch those agents to Claude Code"; fi

section "Repo"

cd "$ROOT" || exit 1
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  pass "et-al is a git repo"
  remote="$(git remote get-url origin 2>/dev/null || true)"
  if [ -n "$remote" ]; then pass "origin = $remote"; else fail "No origin remote" "git remote add origin https://github.com/YOUR-USERNAME/et-al.git"; fi
  branch="$(git branch --show-current 2>/dev/null || true)"
  if [ "$branch" = "main" ]; then pass "On branch main"; else warn "On branch '$branch'" "Expected main"; fi
else
  fail "et-al is not a git repo" "Clone the repo with git clone (README, Getting started, step 1)"
fi

for entry in ".venv/" "local/"; do
  if grep -qxF "$entry" .gitignore 2>/dev/null; then pass ".gitignore has $entry"; else fail ".gitignore is missing $entry" "Add a line: $entry"; fi
done

need="README.md agents/coordinator.md agents/scout.md agents/experimenter.md room/instructions.md templates/et-al.template.yaml demo/script.md docs/notes.md workspace/coordinator workspace/scout workspace/experimenter"
missing=""; empty=""
for f in $need; do
  if [ ! -e "$f" ]; then missing="$missing $f"
  elif [ -f "$f" ] && [ ! -s "$f" ]; then empty="$empty $f"; fi
done
if [ -n "$missing" ]; then fail "Missing:$missing" "Clone the full repo; files are missing"; else pass "All repo files and workspace folders exist"; fi
[ -z "$empty" ] || warn "Empty files:$empty" "Restore them with git checkout -- ."

grep -q "YOUR-EMAIL"  agents/scout.md 2>/dev/null        || warn "agents/scout.md has no YOUR-EMAIL placeholder" "Real values in the repo become public"
grep -q "PYTHON-PATH" agents/experimenter.md 2>/dev/null || warn "agents/experimenter.md has no PYTHON-PATH placeholder" "Real values in the repo become public"
grep -q "PI-USERNAME" room/instructions.md 2>/dev/null   || warn "room/instructions.md has no PI-USERNAME placeholder" "Real values in the repo become public"

# Secrets and personal details in files Git would publish
patterns='AIza[0-9A-Za-z_-]{30,}|AQ\.[0-9A-Za-z_-]{30,}|sk-ant-[0-9A-Za-z_-]{20,}|sk-[0-9A-Za-z]{32,}|xai-[0-9A-Za-z]{30,}|gh[pousr]_[0-9A-Za-z]{30,}|AKIA[0-9A-Z]{16}|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'
hits="$(git ls-files -co --exclude-standard -z 2>/dev/null |
  xargs -0 grep -I -o -n -E "$patterns" 2>/dev/null |
  grep -viE 'noreply|example\.com|@anthropic\.com' |
  awk -F: '{ v = $3; if (length(v) > 12) v = substr(v, 1, 12) "..."; print "      " $1 ":" $2 " (" v ")" }' | sort -u)"
if [ -n "$hits" ]; then
  fail "Possible keys or personal details in files Git would publish:" "Move them to local/ or delete them before pushing"
  echo "$hits"
else
  pass "No keys, tokens or email addresses in files Git would publish"
fi

section "Filled copies (local/)"

if [ -f "$ANSWERS" ]; then pass "fill-local answers: PI=@$(json_get PI), student=@$(json_get STUDENT)"
else fail "local/answers.json missing" "Run: bash scripts/fill-local.sh"; fi

for f in agents/coordinator.md agents/scout.md agents/experimenter.md room/instructions.md templates/et-al.template.yaml; do
  p="$LOCAL/$f"
  if [ ! -f "$p" ]; then fail "local/$f missing" "Run: bash scripts/fill-local.sh"; continue; fi
  left=""
  for k in PI-USERNAME STUDENT-USERNAME YOUR-EMAIL PYTHON-PATH WORKSPACE-DIR; do grep -q -- "$k" "$p" && left="$left $k"; done
  grep -qE '^[[:space:]]*#include[[:space:]]' "$p" && left="$left #include"
  if [ -n "$left" ]; then fail "local/$f still has$left" "Rerun: bash scripts/fill-local.sh"
  elif [ "$ROOT/$f" -nt "$p" ]; then warn "local/$f is older than $f" "Rerun fill-local.sh, then re-paste into Switch Console"
  else pass "local/$f filled"; fi
done

section "Experimenter Python"

py="$(json_get PYTHON)"
[ -n "$py" ] || py="$(dirname "$ROOT")/.venv/bin/python"
if [ -x "$py" ]; then
  pass "Found $py"
  case "$py" in *" "*) warn "The Python path contains a space" "Agents can trip over it; a path without spaces is safer" ;; esac
  out="$("$py" -c 'import sys, torch, sklearn, numpy, matplotlib; print(sys.version.split()[0], torch.__version__, sklearn.__version__)' 2>&1)"
  if [ $? -eq 0 ]; then pass "python / torch / sklearn: $out"
  else fail "Python is missing a package" "Activate the venv and pip install torch scikit-learn numpy matplotlib. Error: $(echo "$out" | tail -n 1)"; fi

  # Same setup the experiment uses: digits, 20% flipped labels, small MLP, smoothing 0.1.
  out="$("$py" - 2>&1 <<'PY'
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
PY
)"
  secs="$(printf '%s' "$out" | sed -n 's/.*acc=[0-9.]* secs=\([0-9.]*\).*/\1/p' | tail -n 1)"
  if [ -n "$secs" ]; then
    if awk -v s="$secs" 'BEGIN { exit !(s < 30) }'; then pass "Smoke experiment ran: $out"
    else warn "Smoke experiment was slow: $out" "The 3-seed comparison may go past 60 seconds"; fi
  else
    fail "Smoke experiment failed" "$(echo "$out" | tail -n 1)"
  fi
else
  fail "No Python at $py" "Create the venv (README, Getting started, step 1), or rerun fill-local.sh with the right path"
fi

section "Network"

email="$(json_get EMAIL)"
mail=""; [ -z "$email" ] || mail="&mailto=$email"
resp="$(curl -fsS --max-time 20 "https://api.openalex.org/works?search=label%20smoothing&sort=cited_by_count:desc&per_page=1$mail" 2>&1)"
if [ $? -eq 0 ] && printf '%s' "$resp" | grep -q '"results"'; then
  title="$(printf '%s' "$resp" | grep -o '"title":"[^"]*"' | head -n 1 | sed 's/^"title":"//; s/"$//')"
  pass "OpenAlex works${title:+: top hit '$title'}"
else
  fail "Could not reach OpenAlex" "The scout needs api.openalex.org. Error: $(echo "$resp" | tail -n 1)"
fi

if curl -fsS -I --max-time 20 https://docs.switchagents.ai >/dev/null 2>&1; then pass "docs.switchagents.ai reachable"
else warn "Could not reach docs.switchagents.ai" "Only matters for the switch-docs MCP"; fi

echo
if [ "$FAILS" -gt 0 ]; then
  echo "${RED}$FAILS FAIL, $WARNS WARN. Fix the FAIL lines from the top down, then rerun.${RESET}"
  exit 1
fi
echo "${GREEN}All checks passed ($WARNS WARN). Next: onboard the agents in Switch Console.${RESET}"
