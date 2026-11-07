#!/usr/bin/env bash
# fill-local.sh (macOS and Linux; Windows uses fill-local.ps1)
# Makes filled copies of every instruction file in local/ for setting up
# the agents by hand (README, Option B). The template doesn't need this:
# import templates/et-al.template.yaml directly.
# Copies go in local/
# (Git ignores local/). The files in the repo keep their placeholders:
#   PI-USERNAME, STUDENT-USERNAME, YOUR-EMAIL, PYTHON-PATH
# Paste into Switch Console from local/, never from the placeholder files.
#
# Run from anywhere:  bash scripts/fill-local.sh
# Rerun any time you edit agents/ or room/. Your answers are
# remembered in local/answers.json, so you can just press Enter.
# Works with the bash 3.2 and BSD awk that ship with macOS.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL="$ROOT/local"
ANSWERS="$LOCAL/answers.json"
mkdir -p "$LOCAL"

if [ -t 1 ]; then
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'; RESET=$'\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; CYAN=''; RESET=''
fi

# Read one value from the flat answers.json (written by this script or fill-local.ps1)
json_get() {
  [ -f "$ANSWERS" ] || return 0
  tr -d '\r' < "$ANSWERS" |
    sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\(.*\)\".*/\1/p" |
    head -n 1 | sed 's/\\"/"/g; s/\\\\/\\/g'
}

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

prev_pi="$(json_get PI)"
prev_student="$(json_get STUDENT)"
prev_email="$(json_get EMAIL)"
prev_python="$(json_get PYTHON)"
[ -n "$prev_python" ] || prev_python="$(dirname "$ROOT")/.venv/bin/python"

ask() {
  # ask "question" "default" -> echoes the answer
  local question="$1" default="$2" shown="" answer=""
  [ -n "$default" ] && shown=" [$default]"
  while true; do
    read -r -p "$question$shown: " answer || true
    [ -n "$answer" ] || answer="$default"
    if [ -n "$answer" ]; then printf '%s' "$answer"; return 0; fi
    echo "${YELLOW}  This one is required.${RESET}" >&2
  done
}

echo
echo "${CYAN}Four questions. Press Enter to keep the value in [brackets].${RESET}"
pi="$(ask 'PI Mattermost username (your main account, no @)' "$prev_pi")";            pi="${pi#@}"
student="$(ask 'Student Mattermost username (second account, no @)' "$prev_student")"; student="${student#@}"
email="$(ask "Email for OpenAlex (goes in the scout's API links)" "$prev_email")"
python="$(ask "Full path to the experimenter's Python" "$prev_python")"

case "$python" in "~/"*) python="$HOME/${python#\~/}" ;; esac

if [ "$pi" = "$student" ]; then echo "${RED}PI and student must be different usernames.${RESET}" >&2; exit 1; fi
if ! [[ "$email" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]]; then
  echo "${RED}That doesn't look like an email: $email${RESET}" >&2; exit 1
fi
[ -e "$python" ] || echo "${YELLOW}  Warning: $python doesn't exist yet. check-setup.sh will flag it.${RESET}"

cat > "$ANSWERS" <<EOF
{
  "PI": "$(json_escape "$pi")",
  "STUDENT": "$(json_escape "$student")",
  "EMAIL": "$(json_escape "$email")",
  "PYTHON": "$(json_escape "$python")"
}
EOF

export FILL_PI="$pi" FILL_STUDENT="$student" FILL_EMAIL="$email" FILL_PYTHON="$python" FILL_ROOT="$ROOT"

# Literal (non-regex) placeholder replacement, line endings normalised to LF.
# Template mode also strips the repo copy's header comment and expands
# "#include <file>" lines, indenting the included text to match.
FILL_AWK='
function lit(s, from, to,   out, i) {
  out = ""
  while ((i = index(s, from)) > 0) { out = out substr(s, 1, i - 1) to; s = substr(s, i + length(from)) }
  return out s
}
function fill(s) {
  s = lit(s, "STUDENT-USERNAME", ENVIRON["FILL_STUDENT"])
  s = lit(s, "PI-USERNAME",      ENVIRON["FILL_PI"])
  s = lit(s, "YOUR-EMAIL",       ENVIRON["FILL_EMAIL"])
  s = lit(s, "PYTHON-PATH",      ENVIRON["FILL_PYTHON"])
  return s
}
BEGIN {
  if (template) {
    print "# Et Al. template, filled by scripts/fill-local.sh. Import this copy in"
    print "# Switch Console: Templates, then Import template. Edit the repo files and"
    print "# rerun fill-local.sh rather than editing this one."
    header = 1
  }
}
{
  sub(/\r$/, "")
  if (template && header) {
    if ($0 ~ /^[ \t]*#/ || $0 ~ /^[ \t]*$/) next
    header = 0
  }
  if (template && $0 ~ /^[ \t]*#include[ \t]+[^ \t]+[ \t]*$/) {
    match($0, /^[ \t]*/); indent = substr($0, 1, RLENGTH)
    inc = $0; sub(/^[ \t]*#include[ \t]+/, "", inc); sub(/[ \t]*$/, "", inc)
    path = ENVIRON["FILL_ROOT"] "/" inc
    n = 0
    while ((getline line < path) > 0) { sub(/\r$/, "", line); buf[++n] = line }
    close(path)
    if (n == 0) { print "Missing or empty include: " inc > "/dev/stderr"; exit 2 }
    while (n > 0 && buf[n] ~ /^[ \t]*$/) n--
    for (k = 1; k <= n; k++) {
      if (index(buf[k], "{") > 0) braces = braces " " inc
      if (buf[k] ~ /^[ \t]*$/) print ""; else print indent fill(buf[k])
    }
    next
  }
  print fill($0)
}
END { if (braces != "") print "  Warning: {name} is a Switch template parameter; found { in:" braces > "/dev/stderr" }
'

written=()
for rel in agents/coordinator.md agents/scout.md agents/experimenter.md room/instructions.md; do
  [ -f "$ROOT/$rel" ] || { echo "${RED}Missing file: $rel${RESET}" >&2; exit 1; }
  mkdir -p "$(dirname "$LOCAL/$rel")"
  awk -v template=0 "$FILL_AWK" "$ROOT/$rel" > "$LOCAL/$rel"
  written+=("local/$rel")
done

left=0
echo
echo "${GREEN}Wrote:${RESET}"
for w in "${written[@]}"; do
  echo "  $w"
  for k in PI-USERNAME STUDENT-USERNAME YOUR-EMAIL PYTHON-PATH; do
    if grep -q -- "$k" "$ROOT/$w"; then echo "${RED}  $w still has $k${RESET}"; left=1; fi
  done
done
[ "$left" -eq 0 ] || exit 1

echo
echo "Copy one to the clipboard, for example:"
if [ "$(uname)" = "Darwin" ]; then
  echo "  pbcopy < local/agents/coordinator.md"
else
  echo "  xclip -selection clipboard < local/agents/coordinator.md   (Wayland: wl-copy < ...)"
fi
echo "Next: bash scripts/check-setup.sh"
