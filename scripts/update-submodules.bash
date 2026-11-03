#!/usr/bin/env bash

set -uo pipefail

script_directory=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repository_root=$(cd -- "$script_directory/.." && pwd)
gitmodules="$repository_root/.gitmodules"
status=0
updated=()
unchanged=()
skipped=()
failed=()
branch_switches=()
branch_warnings=()

record_branch_warning() {
  local submodule_path=$1
  local absolute_path=$2
  local expected_branch=$3
  local current_branch

  current_branch=$(git -C "$absolute_path" symbolic-ref --quiet --short HEAD || true)
  if [[ -z "$current_branch" ]]; then
    current_branch="detached at $(git -C "$absolute_path" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  fi

  if [[ "$current_branch" != "$expected_branch" ]]; then
    branch_warnings+=("$submodule_path: on '$current_branch'; expected '$expected_branch'")
  fi
}

print_summary_section() {
  local heading=$1
  shift

  printf '%s (%d):\n' "$heading" "$#"
  if (( $# == 0 )); then
    printf '  - none\n'
    return
  fi

  printf '  - %s\n' "$@"
}

print_summary() {
  printf '\n==> Update summary\n'
  print_summary_section "Updated" "${updated[@]}"
  print_summary_section "Already current" "${unchanged[@]}"
  print_summary_section "Skipped" "${skipped[@]}"
  print_summary_section "Failed" "${failed[@]}"
  print_summary_section "Branch switches" "${branch_switches[@]}"
  print_summary_section "Unresolved branch warnings" "${branch_warnings[@]}"

  if (( status == 0 )); then
    printf 'Result: success\n'
  else
    printf 'Result: attention required (exit status %d)\n' "$status" >&2
  fi
}

if [[ ! -f "$gitmodules" ]]; then
  echo "No .gitmodules file found at $gitmodules" >&2
  exit 2
fi

submodule_keys=$(git config --file "$gitmodules" --name-only --get-regexp '^submodule\..*\.path$')
config_status=$?
if (( config_status > 1 )); then
  echo "Could not read submodule paths from $gitmodules" >&2
  exit 2
fi
if [[ -z "$submodule_keys" ]]; then
  echo "No submodules configured in $gitmodules"
  print_summary
  exit 0
fi

while IFS= read -r key; do
  [[ -z "$key" ]] && continue
  submodule_name=${key#submodule.}
  submodule_name=${submodule_name%.path}
  submodule_path=$(git config --file "$gitmodules" --get "$key" || true)

  if [[ -z "$submodule_path" ]]; then
    echo "==> $submodule_name"
    echo "    Could not read the submodule path." >&2
    failed+=("$submodule_name: could not read the submodule path")
    status=1
    continue
  fi

  absolute_path="$repository_root/$submodule_path"

  echo "==> $submodule_path"

  branch=$(git config --file "$gitmodules" --get "submodule.$submodule_name.branch" || true)

  if [[ ! -e "$absolute_path/.git" ]]; then
    echo "    Not initialized; run: git submodule update --init --recursive" >&2
    if [[ -n "$branch" ]]; then
      skipped+=("$submodule_path: not initialized; expected branch $branch")
    else
      skipped+=("$submodule_path: not initialized")
    fi
    status=1
    continue
  fi

  if [[ -z "$branch" ]]; then
    remote_head=$(git -C "$absolute_path" symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)
    branch=${remote_head#origin/}
  fi
  if [[ -z "$branch" ]]; then
    branch=$(git -C "$absolute_path" ls-remote --symref origin HEAD 2>/dev/null | awk '$1 == "ref:" { sub("refs/heads/", "", $2); print $2; exit }')
  fi

  if [[ -z "$branch" ]]; then
    echo "    Could not determine the default branch." >&2
    failed+=("$submodule_path: could not determine the default branch")
    status=1
    continue
  fi

  if ! working_tree_status=$(git -C "$absolute_path" status --porcelain --untracked-files=normal); then
    echo "    Failed to inspect the working tree." >&2
    failed+=("$submodule_path: git status failed")
    record_branch_warning "$submodule_path" "$absolute_path" "$branch"
    status=1
    continue
  fi

  if [[ -n "$working_tree_status" ]]; then
    echo "    Working tree is not clean; clean up or commit its changes before updating." >&2
    git -C "$absolute_path" status --short >&2
    skipped+=("$submodule_path: working tree is not clean")
    record_branch_warning "$submodule_path" "$absolute_path" "$branch"
    status=1
    continue
  fi

  starting_branch=$(git -C "$absolute_path" symbolic-ref --quiet --short HEAD || true)
  if [[ -z "$starting_branch" ]]; then
    starting_branch="detached at $(git -C "$absolute_path" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
  fi
  if [[ "$starting_branch" != "$branch" ]]; then
    branch_switches+=("$submodule_path: $starting_branch -> $branch")
  fi

  echo "    Checking out $branch"
  if ! git -C "$absolute_path" checkout "$branch"; then
    echo "    Failed to check out $branch." >&2
    failed+=("$submodule_path: could not check out '$branch'")
    record_branch_warning "$submodule_path" "$absolute_path" "$branch"
    status=1
    continue
  fi

  before_revision=$(git -C "$absolute_path" rev-parse --short HEAD 2>/dev/null || printf 'unknown')

  echo "    Pulling origin/$branch"
  if ! git -C "$absolute_path" pull --ff-only origin "$branch"; then
    divergence=$(git -C "$absolute_path" rev-list --left-right --count "HEAD...origin/$branch" 2>/dev/null || true)
    if [[ -n "$divergence" ]]; then
      read -r ahead behind <<< "$divergence"
      detail=" (local branch is $ahead ahead and $behind behind origin/$branch)"
    else
      detail=""
    fi
    echo "    Failed to pull origin/$branch$detail." >&2
    failed+=("$submodule_path: fast-forward pull of origin/$branch failed$detail")
    record_branch_warning "$submodule_path" "$absolute_path" "$branch"
    status=1
    continue
  fi

  after_revision=$(git -C "$absolute_path" rev-parse --short HEAD 2>/dev/null || printf 'unknown')
  if [[ "$before_revision" == "$after_revision" ]]; then
    unchanged+=("$submodule_path ($branch at $after_revision)")
  else
    updated+=("$submodule_path ($branch: $before_revision -> $after_revision)")
  fi
  record_branch_warning "$submodule_path" "$absolute_path" "$branch"

done <<< "$submodule_keys"

print_summary
exit "$status"
