#!/usr/bin/env bash
#
# Check the ACP super-repo skeleton.
# Runs deterministic checks only and prints a suggested fix for every failure.
#
# Usage:
#   scripts/is-it-ready.bash
#
# Exit status: 0 when nothing failed, 1 when a check failed, 2 on usage error.

set -uo pipefail

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$script_directory/.." && pwd)
gitmodules="$root/.gitmodules"
project_settings="$root/.pi/settings.json"
gitignore="$root/.gitignore"
docs_directory="$root/docs"
docs_readme="$root/docs/README.md"
root_readme="$root/README.md"

for arg in "$@"; do
  case "$arg" in
    -h|--help) sed -n '3,9p' "$0"; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

fail_count=0
warn_count=0
pass_count=0

section() { printf '\n== %s\n' "$1"; }

report() { # kind message [fix]
  local kind=$1 message=$2 fix=${3:-}
  case "$kind" in
    ok) pass_count=$((pass_count + 1)); printf '  [ok]   %s\n' "$message" ;;
    warn)
      warn_count=$((warn_count + 1))
      printf '  [warn] %s\n' "$message"
      [[ -n "$fix" ]] && printf '         fix: %s\n' "$fix"
      ;;
    fail)
      fail_count=$((fail_count + 1))
      printf '  [fail] %s\n' "$message"
      [[ -n "$fix" ]] && printf '         fix: %s\n' "$fix"
      ;;
  esac
}

section "Environment"
if command -v git >/dev/null 2>&1; then
  report ok "git found"
else
  report fail "git not found" "install Git"
fi
if command -v node >/dev/null 2>&1; then
  report ok "node found ($(node -p 'process.versions.node' 2>/dev/null || printf 'unknown'))"
else
  report fail "node not found" "install Node.js"
fi

section "Super-repo files"
required_files=(
  AGENTS.md
  .gitignore
  .gitmodules
  .pi/settings.json
  scripts/is-it-ready.bash
  scripts/update-submodules.bash
)
for file in "${required_files[@]}"; do
  if [[ -f "$root/$file" ]]; then
    report ok "$file present"
  else
    report fail "$file missing" "restore $file"
  fi
done

if [[ -f "$root_readme" ]]; then
  report ok "root README.md present"
  if [[ -f "$docs_readme" ]]; then
    report warn "docs/README.md is temporary; remove it now that root README.md exists" "rm docs/README.md"
  fi
elif [[ -f "$docs_readme" ]]; then
  report ok "bootstrap docs/README.md present (root README.md not created yet)"
else
  report fail "no README.md at the repository root or docs/README.md" "create docs/README.md for bootstrap, or README.md at the root"
fi

if [[ -d "$docs_directory" ]]; then
  extra_docs=$(find "$docs_directory" -mindepth 1 -maxdepth 1 ! -name README.md -print -quit 2>/dev/null || true)
  if [[ -n "$extra_docs" ]]; then
    report fail "docs/ contains files other than README.md: $extra_docs" "keep docs/README.md only; move other files elsewhere"
  else
    report ok "docs/ contains only README.md"
  fi
else
  if [[ -f "$root_readme" ]]; then
    report ok "docs/ removed (root README.md present)"
  else
    report fail "docs/ missing" "create docs/README.md for bootstrap"
  fi
fi

if [[ -f "$project_settings" ]]; then
  if node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$project_settings" 2>/dev/null; then
    report ok ".pi/settings.json is valid JSON"
  else
    report fail ".pi/settings.json is not valid JSON" "fix the JSON syntax in .pi/settings.json"
  fi
  if node -e '
    const fs = require("fs");
    const settings = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (settings.enableSkillCommands !== true) process.exit(1);
    const expected = ["read", "bash", "edit", "write", "grep", "find", "ls"];
    if (!Array.isArray(settings.defaultTools) || expected.some((tool) => !settings.defaultTools.includes(tool))) process.exit(2);
  ' "$project_settings" 2>/dev/null; then
    report ok ".pi/settings.json has the baseline keys"
  else
    report fail ".pi/settings.json is missing baseline keys" "set enableSkillCommands to true and include the default tools"
  fi
fi

for entry in ".pi/npm/" ".pi/git/" ".env"; do
  if grep -qxF "$entry" "$gitignore" 2>/dev/null; then
    report ok ".gitignore ignores $entry"
  else
    report fail ".gitignore does not ignore $entry" "add '$entry' to .gitignore"
  fi
done

section "Skills"
required_skills=(acp-submodule-workflow acp-ste100 acp-repo-template)
for skill in "${required_skills[@]}"; do
  if [[ -f "$root/.pi/skills/$skill/SKILL.md" ]]; then
    report ok "skill $skill present"
  else
    report fail "skill $skill missing" "add .pi/skills/$skill/SKILL.md"
  fi
done

skill_count=0
while IFS= read -r skill_file; do
  [[ -z "$skill_file" ]] && continue
  skill_directory=$(basename "$(dirname "$skill_file")")
  case "$skill_directory" in
    acp-*) ;;
    *) continue ;;
  esac
  skill_count=$((skill_count + 1))
  declared_name=$(sed -n 's/^name:[[:space:]]*//p' "$skill_file" | head -n 1 | tr -d '\r' | sed -E 's/^["'\''](.*)["'\'']$/\1/')
  if [[ "$declared_name" == "$skill_directory" ]]; then
    report ok "$skill_directory has matching frontmatter name"
  else
    report fail "$skill_directory has frontmatter name '${declared_name:-missing}'" "set name: $skill_directory in $skill_file"
  fi
done < <(find "$root/.pi/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print 2>/dev/null | sort)

if (( skill_count == 0 )); then
  report fail "no ACP-owned skills found" "add .pi/skills/acp-*/SKILL.md"
fi

section "Submodules"
if [[ ! -f "$gitmodules" ]]; then
  report fail ".gitmodules missing" "restore .gitmodules"
else
  if ! git config --file "$gitmodules" --list >/dev/null 2>&1; then
    report fail ".gitmodules is not valid" "fix the syntax in .gitmodules"
  else
    report ok ".gitmodules is valid"
    submodule_entries=$(git config --file "$gitmodules" --get-regexp '^submodule\..*\.path$' || true)
    if [[ -z "$submodule_entries" ]]; then
      report ok "no submodules configured (template state)"
    else
    while read -r key path; do
      [[ -z "${key:-}" ]] && continue
      name=${key#submodule.}
      name=${name%.path}
      absolute="$root/$path"
      if [[ "$path" == */* ]]; then
        report fail "$path is a nested submodule" "move the submodule to the repository root"
      else
        report ok "$path is at the repository root"
      fi
      if [[ -e "$absolute/.git" ]]; then
        report ok "$path is initialized"
      else
        report fail "$path is not initialized" "run: git submodule update --init --recursive"
      fi
      ignore=$(git config --file "$gitmodules" --get "submodule.$name.ignore" || true)
      if [[ "$ignore" == "all" ]]; then
        report ok "$path uses ignore = all"
      else
        report fail "$path does not use ignore = all" "run: git config -f .gitmodules submodule.$name.ignore all"
      fi
      branch=$(git config --file "$gitmodules" --get "submodule.$name.branch" || true)
      if [[ -n "$branch" ]]; then
        report ok "$path tracks branch $branch"
      else
        report fail "$path has no tracking branch" "set submodule.$name.branch in .gitmodules"
      fi
    done <<< "$submodule_entries"
    fi
  fi
fi

section "Templates"
for file in templates/repository-settings.json templates/default-branch-ruleset.json; do
  if [[ ! -f "$root/$file" ]]; then
    report fail "$file missing" "restore $file"
  elif node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$root/$file" 2>/dev/null; then
    report ok "$file is valid JSON"
  else
    report fail "$file is not valid JSON" "fix the JSON syntax in $file"
  fi
done

section "Result"
printf '  %d ok, %d warn, %d fail\n' "$pass_count" "$warn_count" "$fail_count"
if (( fail_count == 0 )); then
  printf 'Result: ready\n'
  exit 0
fi
printf 'Result: attention required (exit status 1)\n' >&2
exit 1
