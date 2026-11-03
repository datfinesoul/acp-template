---
name: acp-submodule-workflow
description: "Operate this ACP super-repo's Git submodule workflow. USE WHEN: cloning, initializing, adding, updating, or troubleshooting submodules."
---

# Submodule Workflow

This repository is an ACP super-repo. It holds instructions, configuration, and Pi resources. All application code lives in Git submodules.

## How it works

1. All application code lives in submodules. The super-repo holds only docs, configuration, and Pi resources.
2. Submodules live at the super-repo root. Do not nest them.
3. Every submodule uses `ignore = all`. The super-repo does not show changes inside submodules.
4. Each submodule is its own Git repository with its own remote and CI/CD.
5. The agent never commits, pushes, or tags in the super-repo or in any submodule. Only the user performs these operations.
6. Submodule maintenance is an exception to the Git write restriction. The agent may clone, initialize, add, and update submodules. These operations must not create commits, tags, or remote refs.

> `git submodule add` records an initial pointer (gitlink) for each submodule.
> Because every entry sets `ignore = all`, the super-repo never shows submodules as
> dirty. **Never commit submodule pointer updates from the super-repo.** Manage each
> submodule entirely from inside its own directory.

## Conventions

- Submodules live at the super-repo root, not nested.
- Default branch: `main`. Override per submodule only when needed.
- `branch` in `.gitmodules` is the default tracking branch for `git submodule update --remote`. It is not an expectation about the checked-out branch. The user controls that branch.
- `ignore = all` must be set in `.gitmodules` for every submodule.
- Do not add `acp-role` or other role metadata in this template.
- Do not add nested submodules.
- Use the remote URL pattern that your host or organization uses, for example `git@github.com:ORG/REPO.git`.

## First-time setup

After cloning the super-repo:

```bash
# Clone with submodules in one step
git clone --recursive <super-repo-url>

# Or, if the repository is already cloned without submodules:
git submodule update --init --recursive
```

## Adding a new submodule

### From an existing remote repository

```bash
git submodule add -b main <repo-url> <path>
git config -f .gitmodules submodule.<path>.ignore all
```

### From scratch

Creating a new repository and its first commit and push are the user's work. The agent never commits or pushes. If asked, prepare the files and a `.gitignore` (never secrets or `.env` files) and ask the user to initialize, commit, and push. After the remote exists, add it with the existing-remote procedure.

After adding:

1. Confirm the new `.gitmodules` entry looks like this:

   ```ini
   [submodule "<name>"]
       path = <name>
       url = <repo-url>
       branch = main
       ignore = all
   ```

2. Verify the configured branch, remote, and submodule status.
3. Tell the user to run `/reload` in the active Pi session because `AGENTS.md` is a context file. Pi reloads context files and skills with `/reload`.

## Daily commands

| Action | Command |
|--------|---------|
| Initialize after clone | `git submodule update --init --recursive` |
| Update all to latest remote | `git submodule update --remote` |
| Pull a specific submodule | `cd <name> && git pull origin main` |
| Check submodule status | `git submodule status` |
| Run a command in every submodule | `git submodule foreach 'git status'` |

## Update all submodules

Run `scripts/update-submodules.bash` from the super-repo root. It skips dirty working trees. It checks out the configured branch. It fast-forwards only. It prints a summary. It never commits or pushes.

## Working inside a submodule

```bash
cd <name>
git checkout <configured-branch>
git pull
# Make and validate changes.
```

Never commit, push, or tag in the super-repo or in a submodule, even when asked or given permission. Leave module changes in the working tree for the user to stage, commit, and push. Initial registration may stage a new gitlink through `git submodule add`. Leave that registration for the user to review and commit. Do not stage pointer updates for existing submodules.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Detached HEAD in submodule | `cd <name> && git checkout main && git pull` |
| Submodule shows dirty in super-repo | Expected. `ignore = all` suppresses this. If it still shows, confirm `.gitmodules` has `ignore = all` for that entry. |
| Submodule directory is empty | `git submodule update --init --recursive` |
| Push rejected (remote diverged) | The user runs `cd <name> && git pull --rebase origin main`, then pushes. |
| Forgot `.gitignore` before first commit | The user runs, inside the submodule: `git rm -r --cached .`, add `.gitignore`, commit. |
