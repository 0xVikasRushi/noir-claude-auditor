# Noir Circuit Auditor

A Claude Code plugin that audits Noir ZK circuits for business logic vulnerabilities.

## Install

```
/plugin install github:0xVikasRushi/noir-claude-auditor
```

Or manually:

```bash
mkdir -p .claude/skills .claude/commands && \
  git clone --depth 1 https://github.com/0xVikasRushi/noir-claude-auditor.git /tmp/noir-auditor && \
  cp -r /tmp/noir-auditor/skills/noir-circuit-auditor .claude/skills/ && \
  cp /tmp/noir-auditor/commands/*.md .claude/commands/ && \
  rm -rf /tmp/noir-auditor
```

## Usage

```
/audit path/to/noir/project
```

Or just say "audit this Noir circuit" in Claude Code.

## What It Finds

- Field arithmetic confusion
- Specification mismatch
- Composition flaws
- Cryptographic primitive misuse
- Protocol logic errors
- Unconstrained boundary violations
- Recursive proof composition bugs
- Oracle & external data bugs

## What It Does NOT Find

- Underconstrained signals — use `nargo compile`
- Type errors — use `nargo check`
- Smart contract bugs — out of scope

## Improvement Loop

Every audit appends a `benchmark:` block to the report. After several audits, run `/review-benchmarks` to get suggestions for improving the skill.

## License

MIT
