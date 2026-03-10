# Noir Circuit Auditor

A Claude Code plugin for auditing Noir ZK circuits for business logic vulnerabilities.

## Installation

```bash
/plugin install github:0xvikasrushi/noir-claude-auditor
```

## Usage

```bash
/noir-circuit-auditor              # Audit current directory
/noir-circuit-auditor /path/to/project
```

## Requirements

- Claude Code CLI
- `nargo` CLI in PATH
- Valid Noir project with `Nargo.toml`

## What It Finds

| Bug Class                   | Example                                                   |
| --------------------------- | --------------------------------------------------------- |
| Field arithmetic confusion  | Equality checks that pass for unintended field values     |
| Spec mismatch               | Constraints that prove Y when spec requires X             |
| Composition flaws           | Caller trusts called function without binding constraints |
| Crypto primitive misuse     | Poseidon params not achieving claimed security level      |
| Protocol logic errors       | Valid proof used in wrong context enables replay          |
| Unconstrained boundary      | Hint values used without re-validation                    |
| Recursive proof composition | Inner proof substituted or public inputs unbound          |
| Oracle & external data      | Unverified price feeds, timestamps, or oracle values      |

## What It Does NOT Find

- Underconstrained signals (use `nargo compile`)
- Range check issues (use `nargo compile --pedantic-solving`)
- Type errors (use `nargo check`)

## Core Methodology: Gap Analysis

```
INTENDED: What should this circuit prove?
ACTUAL:   What do the constraints enforce?
GAP:      What can a malicious prover exploit?
```

## Output

```
audit/
├── candidates.md    # Gap analysis findings
├── validated.md     # PROVEN / UNCONFIRMED / FILTERED
├── results.json     # Machine-readable
└── report.md        # Final report
```

## License

MIT
