# ACP template bootstrap README

This is not the repository README.

The real README belongs at `../README.md` in the repository root. Create that file when the ACP is in use. Then delete this file. `docs/` must contain only `README.md`.

This file is temporary. It exists only to start a new ACP repository. After the root README exists, this file has no purpose. Delete it.

## What ACP means

ACP means agent control plane. An ACP repository holds the instructions, configuration, and skills that direct AI coding agents. The current implementation is Pi-specific. The ACP concept is not tied to Pi.

## What this template contains

- `AGENTS.md` is the always-loaded policy file.
- `LICENSE` is the MIT license for this template.
- `docs/README.md` is the temporary bootstrap README. Delete it after the root README exists.
- `.github/PULL_REQUEST_TEMPLATE.md` is the pull request template. It holds hidden agent instructions for the PR text.
- `assets/` holds the social preview source and the rendered image. Upload the image in the repository settings under Social preview.
- `.pi/settings.json` holds the committed Pi project settings.
- `.pi/skills/` holds ACP-owned skills. The `acp-` prefix is mandatory for these skills.
- `scripts/is-it-ready.bash` runs the minimal super-repo readiness checks.
- `scripts/update-submodules.bash` updates clean submodules to their configured branches.
- `templates/` holds canonical GitHub repository settings and ruleset payloads.

## Start

1. Copy this template into a new repository named with the `acp-` prefix.
2. Initialize submodules with `git submodule update --init --recursive`.
3. Start Pi in the repository root.
4. Trust the project when Pi asks.
5. Read `AGENTS.md`.
6. Run `scripts/is-it-ready.bash`.
7. Create the real root `README.md` when the ACP is in use. Then delete this file.

## Submodules

- Application code lives in submodules at the repository root.
- Each submodule is its own repository with its own remote and CI/CD.
- Each `.gitmodules` entry must have `branch` and `ignore = all`.
- `ignore = all` hides changes inside submodules from the super-repo.
- Do not add nested submodules.
- Do not commit submodule pointer updates. The user commits and pushes.

Add a submodule from an existing remote:

```bash
git submodule add -b main <repo-url> <path>
git config -f .gitmodules submodule.<path>.ignore all
```

Update all clean submodules:

```bash
scripts/update-submodules.bash
```

## Skills

Load the matching skill before the related work:

| Skill | Use when |
|---|---|
| `acp-submodule-workflow` | Cloning, initializing, adding, updating, or troubleshooting submodules |
| `acp-repo-template` | Creating a new repository or applying the canonical GitHub settings |
| `acp-ste100` | Writing or changing any agent-authored text |

ACP-owned skills use the `acp-` prefix. User and project skills may use other names. Use `/skill:<name>` to load a skill explicitly.

## Communication

- Use `acp-ste100` for all agent-authored text.
- The user can override the standard for a request or thread.
- Do not rewrite verbatim user text, code, identifiers, paths, or command syntax.
- Keep prose paragraphs on one line. Do not hard-wrap Markdown.

## Complexity estimates

Give a complexity estimate before major work starts, so the user can decide if the work is worth it. Report complexity as exactly one of: `low`, `medium`, `hard`, `too-complex`. Use `too-complex` when the work is too large or too risky to be worth the change. Do not give an estimate after the work is done. Never use hours or other time estimates.

## Git rules

The agent never commits, pushes, tags, or commits submodule pointer updates. Only the user commits and pushes. The agent may clone, initialize, add, and update submodules, but those operations must not create commits, tags, or remote refs.

## Before you finish

1. Run `scripts/is-it-ready.bash`.
2. Resolve every `[fail]`.
3. Review every `[warn]`.
4. Create the root `README.md` when the ACP is in use.
5. Delete this file after the root `README.md` exists.
