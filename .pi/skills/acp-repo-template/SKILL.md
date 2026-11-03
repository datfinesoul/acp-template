---
name: acp-repo-template
description: "Create a new ACP super-repo or apply the canonical GitHub repository settings. USE WHEN: creating a repository, applying repository settings, or adding the default branch ruleset."
---

# Repository Template

Use this skill to create a new ACP super-repo or to align an existing repository with the canonical GitHub settings.

## Inputs

- `templates/repository-settings.json`
- `templates/default-branch-ruleset.json`

Treat these files as GitHub API payloads. They intentionally omit response fields such as IDs, timestamps, links, and source repository names.

The settings payload does not set `visibility`. Ask the user for the intended visibility and set it explicitly. Never assume `public`. Review the ruleset bypass actor before you apply it.

## Procedure

1. Confirm that the user asked to create or change the repository. Use the `acp-` prefix for the name of an ACP super-repo.
2. Ask the user for the repository visibility. This step is mandatory. Do not continue until the user gives the visibility. Do not default to `public`.
3. Create the repository skeleton from this template:
   - `AGENTS.md`
   - `LICENSE`
   - `docs/README.md` as the temporary bootstrap README
   - `.github/PULL_REQUEST_TEMPLATE.md`
   - `.gitignore`
   - `.gitmodules`
   - `.pi/settings.json`
   - `.pi/skills/`
   - `scripts/`
   - `templates/`
4. Apply `templates/repository-settings.json` with `PATCH /repos/<owner>/<repo>`. Add the `visibility` value that the user confirmed. Only fields that this endpoint accepts belong in the payload. The endpoint ignores unknown fields without an error.
5. Enable Dependabot security updates with `PUT /repos/<owner>/<repo>/automated-security-fixes`. `PATCH /repos/<owner>/<repo>` has no field for this setting.
6. Set the complete topic list with `PUT /repos/<owner>/<repo>/topics`.
7. Apply `templates/default-branch-ruleset.json` with `POST /repos/<owner>/<repo>/rulesets` only when an equivalent ruleset does not exist.
8. Set the repository description. Use a short description from the user or from the repository purpose. Do not overwrite an existing description without reporting the mismatch.
9. Fetch the repository, topics, and ruleset through the API. Verify that the effective configuration matches the template. Verify that the visibility matches the value that the user confirmed. Verify automated security fixes with `GET /repos/<owner>/<repo>/automated-security-fixes`.
10. Report the result. The user reviews and commits.

## Topics and description

- Set a small topic list that matches the repository.
- Do not copy Pi extension module topics unless the repository is a Pi module.
- Keep the description specific and non-empty.

## README rule

- `docs/README.md` is the temporary bootstrap README.
- The real README belongs at `README.md` in the repository root.
- `docs/` must contain only `README.md`.
- Delete `docs/README.md` after the root `README.md` exists.
- Do not add other files under `docs/`.

## Do not include

- Pi extension module layout.
- `package.json`, module CI, or release workflows.
- AWS policy.
- `acp-role` metadata.
- Nested submodules.

Add these only when the user asks and the repository needs them.

## Git rules

- Never commit, push, tag, or commit submodule pointer updates.
- Only the user commits and pushes.
- The agent may apply repository settings and ruleset payloads through the GitHub API.
- Do not merge pull requests or write branches or tags.

## Verification

1. Fetch the repository settings.
2. Check that the visibility matches the value that the user confirmed. Report any other value as a mismatch.
3. Fetch the topic list.
4. Fetch the ruleset.
5. Compare each result with the template.
6. Report every mismatch and its fix.
