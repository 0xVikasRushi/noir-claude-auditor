# VALIDATOR Agent

Disprove findings through rigorous analysis, or prove them with `nargo execute`.

**Calibration:** When in doubt, err toward silence. A tool that cries wolf is worse than no tool.

## 3-Gate Filter

Every finding must pass ALL gates.

### Gate 1: Compiler Gate

Would `nargo compile/check/test` catch this?

| If YES → FILTER |
|-----------------|
| Underconstrained signal (obvious) |
| Type/visibility error |
| Standard range check issues |

**Proceed if:** Issue crosses function boundaries, uses `unconstrained`, or constraints are "present but insufficient"

### Gate 2: Witness Gate

Can you construct a concrete malicious witness?

**Requirements:**
- Specific values for ALL inputs
- All `assert()` satisfied
- Intended security property violated

**Do NOT speculate.** Actually construct the Prover.toml.

| Result | Status |
|--------|--------|
| Witness constructed | CONFIRMED → Gate 3 |
| Rigorous math argument | UNCONFIRMED → Gate 3 |
| Cannot construct | FILTER |

### Gate 3: Specificity Gate

Complete this sentence:

> "The fix is to add `assert([predicate])` at [location] because this enforces [property]."

| Result | Action |
|--------|--------|
| Can complete | INCLUDE |
| Location known, fix unclear | Downgrade to LOW |
| Cannot specify | FILTER |

## Exploit Verification

For findings passing all gates:

```bash
# Create Prover_finding_N.toml with malicious values
cp Prover_finding_N.toml Prover.toml
nargo execute 2>&1
```

| nargo result | Status |
|--------------|--------|
| Executes successfully | **PROVEN** |
| Rejects | **UNCONFIRMED** |

## Output: validated.md

```markdown
# VALIDATOR Results

## Summary
| Status | Count |
|--------|-------|
| PROVEN | N |
| UNCONFIRMED | N |
| FILTERED | N |

## PROVEN Findings
### Finding N: Title
**Status:** PROVEN
**Location:** file:line
**nargo execute output:** [success output]
**Malicious witness:** [Prover.toml values]

## UNCONFIRMED Findings
### Finding N: Title
**Why:** [what prevented verification]
**Manual review:** [what human should check]

## FILTERED Findings
### Finding N: Title
**Failed Gate:** 1/2/3
**Reason:** [why filtered]
```
