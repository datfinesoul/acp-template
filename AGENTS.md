# ACP template

This repository is a generic ACP (Pi agent control plane) super-repo. It holds instructions, configuration, and Pi resources. Application code lives in Git submodules.

## Read this first

- The real repository README belongs at `README.md` in the repository root.
- `docs/README.md` is a temporary bootstrap file. Delete it after the root README exists.
- `docs/` must contain only `README.md`.
- Load `.pi/skills/acp-submodule-workflow/SKILL.md` before submodule work.
- Load `.pi/skills/acp-repo-template/SKILL.md` before creating a repository.
- Use `.pi/skills/acp-ste100/SKILL.md` for all agent-authored text.

## Scope

- This repository is a template. Add only the parts that a project needs.
- Name ACP repositories with the `acp-` prefix.
- This repository does not define Pi extension module layout, packaging, CI, or AWS policy. Add them only when a project needs them.

## Super-repo and submodules

- Application code lives in submodules at the repository root.
- Each submodule is its own repository with its own remote and CI/CD.
- Each `.gitmodules` entry must have `branch` and `ignore = all`.
- `ignore = all` means the super-repo does not show changes inside submodules.
- Initialize submodules after cloning: `git submodule update --init --recursive`.
- Use `scripts/update-submodules.bash` to update clean submodules to their configured branches.
- Do not add nested submodules.

## Git rules

- Never commit, push, tag, or create, update, or delete remote Git refs in this repository or in any submodule. This rule is absolute. A direct request, a grant of permission, or an inferred intent cannot lift it.
- Do not ask for permission to commit or push. Leave the work in the working tree and say that it is ready.
- Never commit submodule pointer updates. Only the user commits and pushes.
- Submodule maintenance is an exception: the agent may clone, initialize, add, and update submodules. These operations must not create commits, tags, or remote refs.
- Pull request metadata is not Git history. The agent may create or update a pull request when the user asks and the user has pushed the branch. Do not merge pull requests or write branches or tags.
- Never commit secrets, credentials, or private data. Keep `.env` files out of Git.

## Pi configuration

- Project settings: `.pi/settings.json`. Commit this file.
- Global settings: `~/.pi/agent/settings.json`. Do not commit this file.
- Pi reads project settings only after it grants project trust.
- Run `/reload` after you change `AGENTS.md`, a skill, or project settings.

## Skills

- ACP-owned skills live at `.pi/skills/acp-<name>/SKILL.md`.
- The frontmatter `name` must match the directory name.
- The `acp-` prefix is mandatory for ACP-owned skills only. User or project skills may use other names.
- Load the matching skill before the related work:
  - `acp-submodule-workflow` for submodule operations.
  - `acp-repo-template` for a new repository or canonical GitHub settings.
  - `acp-ste100` for agent-authored text.
- Use `/skill:<name>` to load a skill explicitly.
- Skills are project-local. They are not global installs or module packages.

## Communication

- Use `acp-ste100` for all agent-authored text: documentation, user replies, user feedback, code comments, commit-message drafts, and PR text.
- Use strict mode for procedures, instructions, errors, and safety text. Use STE-flavored mode for explanatory prose.
- The user can override the standard for a request or thread.
- Do not rewrite verbatim user text, code, identifiers, paths, or command syntax.
- Keep prose paragraphs on one line. Do not hard-wrap Markdown.
- Use GitHub Flavored Markdown.

## Complexity estimates

- Give a complexity estimate before major work starts. The user then decides if the work is worth it.
- Do not give an estimate after the work is done. Report the result, not the size of the work.
- Report complexity as exactly one of: `low`, `medium`, `hard`, `too-complex`.
- Use `too-complex` when the work is too large or too risky to be worth the change.
- Omit the estimate only for trivial work, such as a question or a single small edit.
- Explain the main source of complexity when it helps.
- Never use hours or other time estimates.

## Readiness

- Run `scripts/is-it-ready.bash` before you report work as done.
- The script checks the super-repo only. It does not test submodule internals.
- The script is intentionally minimal. Add checks as the project grows.
- Resolve every `[fail]`. Review every `[warn]`.

## Repository README

- `docs/README.md` is the bootstrap README for this template.
- The real README belongs at `README.md` in the repository root.
- `docs/` must contain only `README.md`.
- Delete `docs/README.md` after the root `README.md` exists.
- Do not add other files under `docs/`.

## New repositories

- Load `acp-repo-template` and follow it.
- Ask the user for the repository visibility before you apply any setting. Never default to `public`.
- Apply `templates/repository-settings.json` and `templates/default-branch-ruleset.json`.
- Set the repository description and topics.
- Verify the effective settings after you apply them.
- Do not create Pi extension module layout or CI unless the user asks.
