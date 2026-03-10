---
name: noir-circuit-auditor
user_invocable: true
description: >-
  Audit Noir ZK circuits for business logic vulnerabilities by analyzing the gap
  between intended claims and actual constraints.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Task
  - Write
  - Edit
disallowed-tools:
  - AskUserQuestion
---

# Noir Circuit Auditor

Find novel business logic vulnerabilities by analyzing what a circuit CLAIMS to prove vs what it ACTUALLY proves.

## Quick Start

```bash
/noir-circuit-auditor              # Audit current directory
/noir-circuit-auditor /path/to/project
```

## Core Methodology: Gap Analysis

```
INTENDED: What should this circuit prove?
ACTUAL:   What do the constraints enforce?
GAP:      What can a malicious prover exploit?
```

**The most critical bugs are MISSING constraints** - things that SHOULD be checked but AREN'T. Pattern matching won't find these.

## Principles

1. **Run tests first** - Passing "vulnerability" tests = confirmed bugs
2. **State the claim** - Before code analysis, write what circuit SHOULD prove
3. **Concrete witnesses** - CRITICAL/HIGH findings need specific exploit values
4. **Silence is valid** - Don't manufacture findings

## Scope

**In:** Business logic gaps, binding failures, specification mismatches
**Out:** Underconstrained signals (`nargo compile --pedantic-solving`), type errors

## Output

```
audit/
├── candidates.md    # Gap analysis findings
├── validated.md     # PROVEN / UNCONFIRMED / FILTERED
├── results.json     # Machine-readable
└── report.md        # Final report
```

## Requirements

- `nargo` CLI in PATH
- Valid `Nargo.toml`
