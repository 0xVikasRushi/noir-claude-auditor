# Noir Circuit Auditor

A Claude Code plugin that audits Noir ZK circuits for business logic and mathematical
vulnerabilities. Finds bugs compilers miss.

**Target:** Noir >=0.30, Barretenberg backend (BN254).

## Install

### Option 1 — Plugin install (recommended)

In Claude Code:

```
/plugin install github:0xvikasrushi/noir-claude-auditor
```

### Option 2 — Manual copy

```bash
mkdir -p .claude/skills && \
  git clone --depth 1 https://github.com/0xvikasrushi/noir-claude-auditor.git /tmp/noir-auditor && \
  cp -r /tmp/noir-auditor/skills/noir-circuit-auditor .claude/skills/ && \
  rm -rf /tmp/noir-auditor
```

## Usage

### Slash command (after plugin install)

```
/audit path/to/noir/project
```

### Or just ask

```
Audit this Noir circuit
```

The skill runs a 6-phase protocol:

1. **Read** — all `.nr` files, `Nargo.toml`, docs
2. **Map** — function registry, signal flow, constraint inventory
3. **Analyze** — constraint algebra, satisfying sets, boundary analysis
4. **Compare** — gap analysis: intended claims vs actual constraints
5. **Verify** — construct malicious witnesses, filter false positives
6. **Report** — structured report with findings, witnesses, fixes

## What It Finds

| Bug Class | Example |
| --- | --- |
| Field arithmetic confusion | Equality checks passing for unintended field values |
| Specification mismatch | Constraints prove Y when spec requires X |
| Composition flaws | Caller trusts callee without binding constraints |
| Cryptographic primitive misuse | Poseidon params below claimed security level |
| Protocol logic errors | Valid proof replayed in wrong context |
| Unconstrained boundary violations | Hint values used without re-validation |
| Recursive proof composition bugs | Inner proof substituted or public inputs unbound |
| Oracle & external data bugs | Unverified price feeds or timestamps |

## What It Does NOT Find

- Underconstrained signals — `nargo compile`
- Range check issues — `nargo compile --pedantic-solving`
- Type errors — `nargo check`
- Smart contract bugs — out of scope

## Plugin Structure

```
.claude-plugin/
  plugin.json                  Plugin metadata
commands/
  audit.md                     /audit slash command
skills/
  noir-circuit-auditor/
    SKILL.md                   Entry point
    audit.md                   6-phase audit protocol
    bug-taxonomy.md            8 bug classes with detection heuristics
    false-positive-filter.md   3-gate filter
    report-template.md         Output format
```

## Output

Structured report with:
- Confirmed findings with concrete malicious witnesses
- Unconfirmed findings with rigorous mathematical arguments
- Clean bill of health if no issues found

Zero findings is a valid outcome.

## License

MIT
