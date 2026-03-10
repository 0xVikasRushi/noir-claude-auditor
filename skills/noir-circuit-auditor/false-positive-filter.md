# False Positive Filter

Every candidate finding must pass all three gates before appearing in the report.
One false positive erodes trust in all real findings.

**Default stance:** When confidence is 50/50, drop it. Report at 80%+.

---

## Gate 1 — Compiler Gate

Would `nargo compile`, `nargo check`, or `nargo test` catch this?

- Underconstrained signal that nargo's detection would flag?
- Missing assert that `--pedantic-solving` would catch?
- Type error or visibility error?
- Range issue that bit decomposition already enforces?

YES to any -> **DROP.** Out of scope.

**Exception:** Nargo's underconstrained detection has known false negatives for:
values crossing function boundaries, values through `unconstrained` blocks,
constraints that are present but insufficient. If you believe nargo would miss it,
proceed to Gate 2.

---

## Gate 2 — Witness Gate

Can you construct a concrete malicious witness?

Specific values for all inputs and witnesses such that:
1. All `assert()` statements satisfied
2. Intended security property violated

Actually construct it. Don't say "probably exists."

- Field arithmetic: show the field element values
- Spec mismatch: show what the unconstrained variable is set to
- Composition: show the output of the callee used by the caller
- Protocol logic: show the sequence of valid proofs
- Oracle data: show the adversarial input values

| Result | Action |
|--------|--------|
| Witness constructed | **CONFIRMED** -> Gate 3 |
| Rigorous argument, can't compute inline | **UNCONFIRMED** -> Gate 3 with label |
| Can't construct, argument shaky | **DROP** |

---

## Gate 3 — Specificity Gate

Can the developer act on this finding?

Test: complete this sentence:

"Add `assert([predicate])` in `[function]` at [location] to enforce [property]."

| Result | Action |
|--------|--------|
| Can complete sentence | **INCLUDE** |
| Know location and nature, fix needs design decisions | **Downgrade to LOW** |
| Can't identify location or missing property | **DROP** |

---

## Common False Positives in ZK Audits

Apply extra scrutiny when about to report these:

**"This value is not range checked"**
Irrelevant unless the range matters for security. What attack does the missing check enable?
If you can't describe the attack, it's not a finding.

**"This function trusts its caller"**
In ZK, everything trusts the prover. The question is whether constraints enforce consistency.
Frame findings around constraints, not trust.

**"Information could be inferred from public outputs"**
True by design for most circuits. Only a vulnerability if the inferable information
should be private per the protocol spec.

**"This hash could have collisions"**
Collision resistance is assumed. Don't report unless you have a specific structural
reason it's compromised (weak parameters, known attack for these params).

**"The circuit doesn't check X"**
May be intentional — the smart contract layer may check X. Ask: is this the circuit's
responsibility?

**"The verification key could be substituted"**
Only valid if the VK is actually a private input. Many circuits hardcode the VK.

---

## Clean Reports

Zero findings is a valid outcome. It means:
- Business logic correctly encodes intended security properties
- No gaps between spec and implementation

Do not add findings to justify the audit.
