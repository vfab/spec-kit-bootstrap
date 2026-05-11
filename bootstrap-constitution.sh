#!/usr/bin/env bash
# bootstrap-constitution.sh
# Installs or merges the best-practice constitution.md into a target project at
# .specify/memory/constitution.md
#
# Usage:
#   ./bootstrap-constitution.sh [TARGET_DIR]
#
#   TARGET_DIR — path to the root of the target project (defaults to $PWD)
#
# Behaviour:
#   1. Target does not exist          → copy source verbatim
#   2. Target is a SpecKit stub       → replace with source
#      (file contains only headings, HTML comments, and blank lines)
#   3. Target has real content        → AI merge via GitHub Models API
#      Falls back to a .conflict file if no GitHub token is available.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/constitution.md"
TARGET_DIR="${1:-$PWD}"
TARGET="$TARGET_DIR/.specify/memory/constitution.md"

# ── Guards ────────────────────────────────────────────────────────────────────

if [ ! -f "$SOURCE" ]; then
  echo "Error: source constitution.md not found at $SOURCE" >&2
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: target directory '$TARGET_DIR' does not exist" >&2
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo "Error: python3 is required but not found" >&2
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

# is_stub FILE
# Returns 0 (true) if the file contains only headings, HTML comments, and blank
# lines — i.e. a SpecKit skeleton with no substantive content yet.
is_stub() {
  python3 - "$1" << 'PYEOF'
import re, sys
content = open(sys.argv[1]).read()
# Remove multiline HTML comments
content = re.sub(r'<!--.*?-->', '', content, flags=re.DOTALL)
# Remove markdown headings
content = re.sub(r'^#{1,6}\s.*$', '', content, flags=re.MULTILINE)
# If nothing substantive remains, it is a stub
sys.exit(0 if not content.strip() else 1)
PYEOF
}

# ai_merge SOURCE TARGET OUTPUT
# Calls the GitHub Models API to produce a unified merged constitution.
# Writes the result to OUTPUT.  Returns 0 on success, 1 on failure.
ai_merge() {
  local src="$1" tgt="$2" out="$3"

  local gh_token=""
  if command -v gh &>/dev/null; then
    gh_token=$(gh auth token 2>/dev/null || true)
  fi
  gh_token="${gh_token:-${GITHUB_TOKEN:-}}"

  if [ -z "$gh_token" ]; then
    echo "  No GitHub token found (gh auth token / \$GITHUB_TOKEN)." >&2
    return 1
  fi

  echo "  Calling GitHub Models API for AI merge..."

  python3 - "$src" "$tgt" "$gh_token" "$out" << 'PYEOF'
import json, os, sys, tempfile, urllib.request, urllib.error

src_path, tgt_path, token, out_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(src_path) as f:
    src_text = f.read()
with open(tgt_path) as f:
    tgt_text = f.read()

payload = json.dumps({
    "model": "gpt-4o-mini",
    "messages": [
        {
            "role": "system",
            "content": (
                "You merge two SpecKit constitution.md files into one unified document. "
                "Preserve ALL unique rules, principles, and non-negotiable items from both. "
                "Where there are conflicts, prefer the more specific or stricter rule. "
                "Output ONLY the merged markdown — no preamble, no explanation, no code fences."
            )
        },
        {
            "role": "user",
            "content": (
                f"CONSTITUTION A (bootstrap best practices):\n\n{src_text}\n\n"
                f"---\n\n"
                f"CONSTITUTION B (existing project constitution):\n\n{tgt_text}"
            )
        }
    ]
}).encode()

req = urllib.request.Request(
    "https://models.inference.ai.azure.com/chat/completions",
    data=payload,
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    },
    method="POST"
)

try:
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read())
    merged = data["choices"][0]["message"]["content"]
    if not merged.strip():
        raise ValueError("AI returned empty content")
    # Write atomically via temp file
    tmp_fd, tmp_path = tempfile.mkstemp(dir=os.path.dirname(out_path), suffix=".md")
    try:
        with os.fdopen(tmp_fd, "w") as f:
            f.write(merged)
            if not merged.endswith("\n"):
                f.write("\n")
        os.replace(tmp_path, out_path)
    except Exception:
        os.unlink(tmp_path)
        raise
except urllib.error.HTTPError as e:
    print(f"  API error {e.code}: {e.read().decode(errors='replace')}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"  AI merge error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
}

# ── Main ──────────────────────────────────────────────────────────────────────

mkdir -p "$(dirname "$TARGET")"

# ── Case 1: target does not exist ─────────────────────────────────────────────
if [ ! -f "$TARGET" ]; then
  echo "Installing constitution.md → $TARGET"
  cp "$SOURCE" "$TARGET"
  echo "Done."
  exit 0
fi

# ── Case 2: target is a SpecKit stub ─────────────────────────────────────────
if is_stub "$TARGET"; then
  echo "Target is a SpecKit stub. Replacing → $TARGET"
  cp "$SOURCE" "$TARGET"
  echo "Done."
  exit 0
fi

# ── Case 3: target has real content — AI merge ────────────────────────────────
echo "Target $TARGET has existing content. Attempting AI merge..."

cp "$TARGET" "${TARGET}.bak"
echo "  Backup created: ${TARGET}.bak"

if ai_merge "$SOURCE" "$TARGET" "$TARGET"; then
  echo "Merged → $TARGET"
else
  echo "" >&2
  echo "AI merge unavailable. Creating ${TARGET}.conflict for manual review." >&2
  {
    printf '<!-- MERGE REQUIRED: Reconcile the two constitutions below, then save as %s -->\n\n' \
      "$(basename "$TARGET")"
    printf '<!-- ===== BOOTSTRAP CONSTITUTION ===== -->\n\n'
    cat "$SOURCE"
    printf '\n<!-- ===== EXISTING PROJECT CONSTITUTION ===== -->\n\n'
    cat "${TARGET}.bak"
  } > "${TARGET}.conflict"
  echo "  Resolve: ${TARGET}.conflict" >&2
  exit 1
fi
