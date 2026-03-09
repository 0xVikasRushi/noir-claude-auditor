# Noir Audit — False Positive Filter

Use this skill during Phase 5 of the audit protocol.
Every candidate finding must pass this filter before appearing in the report.

The purpose of this filter is simple: **a security tool that cries wolf is worse
than no tool.** One false positive that wastes a developer's time erodes trust
in all real findings.

## Calibration

**When in doubt, err toward silence (false negatives) rather than noise (false positives).**

Rationale: A missed finding can be caught by a human auditor or in subsequent review.
A false positive actively harms the tool's credibility and wastes developer time.
The cost of investigating a false alarm in a ZK circuit — re-analyzing constraints,
checking the math, potentially modifying the circuit and re-proving — is high.

This does NOT mean you should ignore real bugs. It means: if your confidence is
50/50, drop it. If your confidence is 80%+, report it with an appropriate label.

---

## The Three Gates

Every finding must pass all three gates. Failure at any gate means the finding
is either dropped or downgraded.

---

### Gate 1 — The Compiler Gate

**Question:** Would `nargo compile`, `nargo check`, or `nargo test` catch this?

Run through this checklist:

- Is this an underconstrained signal that the Noir compiler's underconstrained
  value detection would flag?
- Is this a missing assert on a return value that `--pedantic-solving` would catch?
- Is this a type error or visibility error?
- Is this a range issue that standard bit decomposition checks already enforce?

If YES to any of these → **DROP THE FINDING.** It's out of scope.

If NO → proceed to Gate 2.

**Important caveat:** Nargo's underconstrained detection is heuristic-based and
has known false negatives, especially for:

- Values that cross function boundaries
- Values that pass through `unconstrained` blocks
- Constraints that are "technically present" but insufficient

If you believe a value is underconstrained in a way that nargo would NOT catch —
particularly across function boundaries or unconstrained blocks — it **remains
in scope.** Proceed to Gate 2. When in doubt about whether nargo would catch it,
proceed to Gate 2.

---

### Gate 2 — The Witness Gate

**Question:** Can you construct a concrete malicious witness?

A concrete witness means: specific values for all inputs and private witnesses
such that:

1. All `assert()` statements in the circuit are satisfied
2. The intended security property is violated

Work through this explicitly. Do not assert that a witness "probably exists"
or "can be constructed." Actually construct it.

For field arithmetic bugs: show the specific field element values.
For spec mismatch bugs: show what the unconstrained variable is set to.
For composition bugs: show the specific output of the called function used.
For protocol logic bugs: show the specific sequence of valid proofs.
For recursive composition bugs: show the substituted proof and verification key.
For oracle data bugs: show the adversarial external input values.

**CONFIRMED** — witness constructed, values specified → proceed to Gate 3.

**HIGH CONFIDENCE, UNCONFIRMED** — mathematical argument is rigorous and
complete, but witness requires computation (e.g., finding a hash collision
of a specific form) that you cannot perform inline. State this explicitly.
These findings go in the report with a clear UNCONFIRMED label.

**DROP** — cannot construct witness and mathematical argument is not airtight.

---

### Gate 3 — The Specificity Gate

**Question:** Is the finding specific enough to act on?

The developer reading this report must be able to:

1. Find the exact location (function name, constraint, line)
2. Understand exactly what the bug is (not "this seems risky")
3. Know exactly what fix closes the vulnerability

**Test: can you complete this sentence?**

"The fix is to add `assert([specific predicate])` at [specific location] in
function [specific function], because this enforces [specific missing property]."

If you can → **INCLUDE IN REPORT.**

If you cannot:

- **Downgrade to LOW** if you can identify the location and the general nature of
  the issue, but the precise fix is unclear. This is appropriate when the fix
  requires design decisions (e.g., "which hash function to use," "what binding
  to add") that depend on protocol context you don't have.
- **DROP entirely** if you cannot identify the specific location or cannot
  articulate what property is missing. Vague findings like "this area seems
  risky" or "consider adding more validation" are not findings.

---

## Confidence Classification

After all three gates, classify each finding:

**CONFIRMED**

- Passed Gate 1 (not caught by compiler)
- Passed Gate 2 (concrete witness constructed with specific values)
- Passed Gate 3 (specific fix identified)
- Full details in report. Severity: critical/high/medium/low per taxonomy.

**HIGH CONFIDENCE — UNCONFIRMED**

- Passed Gate 1
- Partially passed Gate 2 (rigorous argument but witness not fully specified)
- Passed Gate 3
- Included in report with explicit UNCONFIRMED label.
- Recommendation: manual verification by human auditor.
- Severity: one level lower than it would be if confirmed.

**DROPPED**

- Failed any gate
- Not included in report
- If pattern seems interesting, may note in "Areas for Further Investigation"
  section without calling it a finding

---

## Common False Positive Patterns

These are the most frequent false positives in LLM-generated ZK audits.
When you find yourself about to report one of these, apply extra scrutiny.

**"This value is not range checked"**
Often true but often irrelevant. A value doesn't need to be range checked unless
it's used in a context where its range matters. Ask: what attack does the missing
range check enable? If you can't describe the attack, it may not be a vulnerability.

**"This function trusts its caller"**
In ZK, all functions trust the prover to provide consistent witnesses. The question
is whether the constraints enforce consistency. "Trust" is not the right frame —
constraints are the right frame.

**"Information could be inferred from public outputs"**
True of most ZK circuits by design. The question is whether the information that
can be inferred is information that the protocol intends to keep private. Check
the spec before reporting privacy leaks.

**"This hash function could have collisions"**
Cryptographic hash functions used in circuits are collision-resistant by assumption.
Do not report "hash collisions are theoretically possible" as a vulnerability unless
you have a specific structural reason the collision resistance is compromised (e.g.,
parameters too small, known attack vector for these parameters).

**"The circuit doesn't check X"**
May be intentional. The circuit may rely on the smart contract layer to check X.
Before reporting a missing check, ask: is this check the circuit's responsibility,
or is it enforced elsewhere in the system?

**"The verification key could be substituted"**
Only a valid finding if the verification key is actually a private input or is
not otherwise bound. Many circuits hardcode the verification key or derive it
deterministically. Check the actual code before reporting.

---

## The Silence Principle

A clean report with zero confirmed findings is a valid and good outcome.

It means:

- The circuit's business logic correctly encodes the intended security properties
- No semantic gaps exist between spec and implementation
- The mathematical claims are precisely what they need to be

Do not add findings to justify the audit. Do not add speculative risks.
Do not add "best practice" recommendations as security findings.

If the circuit is clean, say so clearly:

"No confirmed business logic or mathematical vulnerabilities were found.
Static analysis (nargo compile) should be run separately to catch
syntactic and underconstrained signal issues outside this tool's scope."
