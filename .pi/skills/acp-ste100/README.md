# ACP STE100 trial

Project-local adaptation of [danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill), upstream version `0.4.0`, pinned to commit [`3944283c183eea13fe5bd902b572da3b4de8bf44`](https://github.com/danyuchn/asd-ste100-skill/tree/3944283c183eea13fe5bd902b572da3b4de8bf44).

## Try it

Run `/reload` in Pi after changing the skill. Agents must read and apply it to all text that they write in an ACP repository. This includes documentation, user replies, user feedback, code comments, and PR titles or descriptions. Use strict mode for procedures and STE-flavored mode for explanatory prose.

For other text, or to test the skill, invoke it explicitly:

```text
/skill:acp-ste100 Rewrite this tool description. Preserve every condition. Show the before/after comparison: <text>
```

The skill returns rewritten text by default. Ask for a before/after comparison to see the rules behind each change. The standard is the default for agent-authored text. The user can override it for a request or thread. Do not rewrite verbatim user text, code, identifiers, paths, or command syntax.

The optional linter requires Python 3 and uses only the standard library. From the repository root:

```bash
python3 .pi/skills/acp-ste100/scripts/ste-lint.py --selftest
python3 .pi/skills/acp-ste100/scripts/ste-lint.py --json path/to/document.md
```

The linter reports possible structural issues. It does not verify meaning, requirement strength, or full ASD-STE100 compliance. Review each finding. No STE lint gate is added to readiness or CI.

## Included files and local changes

- `SKILL.md`: upstream instructions, renamed to `acp-ste100`, with license, compatibility, source metadata, and ACP default-scope changes.
- `scripts/ste-lint.py`: unchanged upstream linter and built-in tests.
- `references/writing-rules.md`: unchanged upstream summary and sources.
- `examples/`: unchanged upstream examples and intentionally invalid linter fixture.
- `LICENSE`: unchanged upstream MIT license, copyright 2026 Dustin Yuchen Teng.

This is a vendored snapshot, not a submodule or global installation. Updates are manual. Review upstream changes and record the new revision when updating the snapshot. The official ASD dictionary is not included.
