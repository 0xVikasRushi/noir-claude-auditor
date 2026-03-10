# Audit Report Template

Use this template for generating the final audit report. Only include findings that passed the 3-gate false positive filter.

---

## Report Structure

```markdown
# Noir Circuit Security Audit

**Circuit:** [name from Nargo.toml]
**Date:** [YYYY-MM-DD]
**Noir Version:** [version]
**Backend:** Barretenberg (BN254)
**Auditor:** Noir Circuit Auditor
**Scope:** Business logic and mathematical vulnerabilities only

---

## Executive Summary

[2-3 sentences summarizing:]
- Number of files/lines reviewed
- Number of confirmed findings by severity
- Number of unconfirmed findings
- Overall risk assessment: CRITICAL / HIGH / MEDIUM / LOW

Example:
> Audited 12 Noir source files (~2,400 lines) implementing a privacy-preserving payment circuit. Found 2 confirmed vulnerabilities (1 CRITICAL, 1 HIGH) and 1 unconfirmed finding requiring manual review. Overall risk: CRITICAL.

---

## Findings Summary

| # | Title | Severity | Status | Bug Class |
|---|-------|----------|--------|-----------|
| 1 | [title] | CRITICAL | PROVEN | [class] |
| 2 | [title] | HIGH | PROVEN | [class] |
| 3 | [title] | MEDIUM | UNCONFIRMED | [class] |

---

## Confirmed Findings

### [CRITICAL] [Title] — [BUG_CLASS]

**Location:** `[function]` in `[file.nr]`, line ~[N]
**Status:** EXPLOIT PROVEN
**Bug Class:** [CLASS_NAME]

---

**What the circuit should prove:**
[Plain English statement of intended security property]

**What the constraints actually enforce:**
[Mathematically precise statement of what's actually proven]

**The Gap:**
[One sentence describing the difference]

---

**Attack Scenario:**

1. Attacker constructs witness with [specific values]
2. Circuit accepts because [constraint analysis]
3. Verifier is fooled into believing [false statement]

**Malicious Witness:**

```toml
# Prover.toml values that exploit this bug
public_input_1 = "[value]"
private_witness_1 = "[value]"

# Satisfies constraints: YES
# Violates intended property: YES
```

**nargo execute result:**

```
[paste nargo execute output showing success with malicious witness]
```

---

**Recommended Fix:**

```noir
// In function [name], add:
assert([specific predicate], "[error message]");
```

This enforces [specific property] which closes the gap because [explanation].

**Severity Rationale:**
[Why this severity — impact, exploitability, attack surface]

---

[Repeat for each confirmed finding]

---

## Unconfirmed Findings

### [Title] — [BUG_CLASS]

**Location:** `[function]` in `[file.nr]`
**Status:** UNCONFIRMED
**Bug Class:** [CLASS_NAME]

**Why Unconfirmed:**
[Reason — couldn't construct witness, nargo error, etc.]

**Mathematical Argument:**
[Rigorous reasoning for why this may be a bug]

**What to Check:**
[Specific guidance for manual reviewer]

**Potential Impact if Confirmed:**
[What would be possible]

---

[Repeat for each unconfirmed finding]

---

## Areas Checked (No Issues Found)

- [x] Field arithmetic boundaries
- [x] Specification alignment
- [x] Function composition
- [x] Cryptographic primitive usage
- [x] Protocol logic
- [x] Unconstrained boundaries
- [x] Recursive proof composition (if applicable)
- [x] Oracle/external data (if applicable)

---

## Test Results

```
[paste nargo test output]
```

**Vulnerability tests found:** [list or "None"]
**Tests passing that indicate bugs:** [list or "None"]

---

## Files Audited

| File | Lines | Description |
|------|-------|-------------|
| `src/main.nr` | ~150 | Main circuit entry point |
| `src/merkle.nr` | ~200 | Merkle tree verification |
| ... | ... | ... |

**Total:** [N] files, ~[M] lines

---

## Assumptions

- [e.g., "BN254 scalar field (Barretenberg backend)"]
- [e.g., "Poseidon hash in standard library is correctly implemented"]
- [e.g., "Smart contract layer enforces proof uniqueness"]

---

## Scope and Limitations

**In scope:**
- Business logic vulnerabilities (8 bug classes)
- Mathematical constraint gaps
- Specification mismatches

**Out of scope:**
- Underconstrained signals (use `nargo compile --pedantic-solving`)
- Type errors and syntax issues
- Smart contract integration
- Trusted setup assumptions
- Standard library implementation bugs

**Important:** This is an AI-assisted audit. It does not constitute formal verification. Novel vulnerability classes may not be detected. Manual review recommended for production circuits.

---

## Appendix: Severity Definitions

| Severity | Definition |
|----------|------------|
| CRITICAL | Malicious prover proves false statement violating core security |
| HIGH | Significant violation with constraints (limited scope) |
| MEDIUM | Completeness failures or privacy violations |
| LOW | Theoretical weaknesses, no known exploit path |
```

---

## Formatting Rules

1. **Severity in title:** Must be `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, or `[LOW]`
2. **Bug class:** Must be from 8-class taxonomy
3. **PROVEN findings:** Must include populated "Malicious Witness" section
4. **Fixes:** Must be specific — not "add more constraints"
5. **No speculation:** No hedging ("might", "could potentially") in confirmed findings
6. **No padding:** No speculative risks or informational notes as numbered findings
