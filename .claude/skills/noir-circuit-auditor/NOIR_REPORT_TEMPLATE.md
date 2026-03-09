# Noir Audit — Report Template

Use this skill during Phase 6 to generate the final audit report.
Only include findings that passed the false positive filter.

---

## Report Structure

Generate the report in this exact structure:

---

# Noir Circuit Security Audit

**Circuit:** [circuit name from Nargo.toml]
**Noir version:** [version from Nargo.toml]
**Backend:** [backend name and curve, e.g., "Barretenberg (BN254)"]
**Audited by:** Noir Business Logic Auditor
**Scope:** Business logic and mathematical vulnerabilities only.
Syntactic and underconstrained signal issues are outside scope (use nargo compile).

---

## Files Audited

| File            | Lines | Description                                    |
| --------------- | ----- | ---------------------------------------------- |
| `[filename.nr]` | ~[N]  | [Brief description of what this file contains] |
| ...             | ...   | ...                                            |

**Total:** [N] files, ~[M] lines of Noir code

**Files NOT audited (if any):**
[List any `.nr` files in the project that were excluded and why, or state "All `.nr` files were included."]

---

## Assumptions

The following assumptions were made during this audit:

- [e.g., "The Merkle tree depth is always 32 as indicated by the constant DEPTH"]
- [e.g., "The Poseidon hash implementation in the standard library is correct"]
- [e.g., "The smart contract layer enforces that proofs are only accepted once"]
- [e.g., "The BN254 scalar field is used (default Barretenberg backend)"]

If any of these assumptions are incorrect, the audit conclusions may change.

---

## Executive Summary

[2-4 sentences. State: how many files reviewed, how many confirmed findings,
how many unconfirmed, overall risk level. Example:]

"Reviewed N Noir source files implementing [circuit purpose]. Found X confirmed
vulnerabilities including Y critical/high severity issues. Z additional
unconfirmed findings require manual review. Overall risk: CRITICAL/HIGH/MEDIUM/LOW."

---

## Findings

[One section per confirmed or high-confidence finding, ordered by severity]

### [SEVERITY] [SHORT TITLE] — [BUG CLASS]

**Location:** `[function_name]` in `[filename.nr]`, constraint at line ~[N]

**Status:** CONFIRMED / HIGH CONFIDENCE UNCONFIRMED

**Bug class:** FIELD_ARITHMETIC / SPEC_MISMATCH / COMPOSITION_FLAW /
CRYPTO_MISUSE / PROTOCOL_LOGIC / UNCONSTRAINED_BOUNDARY /
RECURSIVE_COMPOSITION / ORACLE_DATA

---

**What the circuit should prove:**
[Plain English statement of the intended security property]

**What the constraints actually enforce:**
[Plain English statement of what the constraints actually prove —
mathematically precise but readable]

**The gap:**
[One sentence describing the difference between the above two]

---

**Concrete attack scenario:**

A malicious prover can:

1. [Step 1 of the attack]
2. [Step 2]
3. Result: [what false statement the verifier accepts]

**Malicious witness:**

```
public_input_X  = [value or "constructed as follows: ..."]
private_witness_Y = [value]
[all relevant variables]

Satisfies constraints: YES
Violates intended property: YES — because [explanation]
```

_[For UNCONFIRMED findings: "Witness construction requires [computation].
The mathematical argument is: [argument]. Manual verification recommended."]_

---

**Fix:**

Add the following constraint in `[function_name]`:

```noir
assert([specific predicate], "[human readable error message]");
```

This enforces [specific property] which closes the gap because [explanation].

---

**Severity rationale:**
[One sentence explaining why this is critical/high/medium/low]

---

[Repeat for each finding]

---

## Unconfirmed Findings Requiring Manual Review

[List any HIGH CONFIDENCE UNCONFIRMED findings that were downgraded,
with brief description and why they need human review]

---

## Areas for Further Investigation

[Optional section. List patterns that seemed interesting but didn't reach
the threshold for a finding. Do NOT call these vulnerabilities.
Format: "The [function] implementation uses [pattern] which may warrant
review if [condition]." No severity assignment.]

---

## Scope and Limitations

This audit covers business logic and mathematical vulnerabilities in Noir
circuit constraints. The following are explicitly out of scope:

- Underconstrained signals (run `nargo compile` with `--pedantic-solving`)
- Type errors and syntax issues (caught by nargo)
- Smart contract integration bugs (the layer calling this circuit)
- Trusted setup assumptions (backend-specific)
- Implementation bugs in Noir's standard library

This audit does not constitute a formal verification. Findings represent
the auditor's best analysis of the circuit's mathematical properties.
Novel vulnerability classes not represented in the auditor's training
may not be detected.

---

## Formatting Rules

- Severity in finding title must be one of: [CRITICAL] [HIGH] [MEDIUM] [LOW]
- Bug class in finding title must be from the taxonomy (8 classes)
- Every CONFIRMED finding must have a populated "Malicious witness" section
- Every finding must have a specific fix — not "add more constraints"
- Do not include speculative risks, best practices, or informational notes
  as numbered findings
- Do not use hedging language ("might," "could potentially," "possibly")
  in confirmed findings. Hedging is appropriate only in unconfirmed findings.
