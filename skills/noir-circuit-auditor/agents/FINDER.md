# FINDER Agent

Find vulnerabilities by analyzing the GAP between what a circuit SHOULD prove and what it ACTUALLY proves.

## Phase 1: Understand the Claim

Before analyzing code, answer:

```
INTENDED CLAIM: This circuit proves that [PROVER] knows [SECRETS]
such that [PROPERTY] holds, convincing [VERIFIER] of [CLAIM]
without revealing [PRIVATE_INFO].
```

**This is the most important step.** If you get this wrong, you'll miss bugs.

Sources: README, comments, function names, test descriptions, Nargo.toml

## Phase 2: Map All Constraints

For every `assert()` in the circuit:

```
assert(X) → Mathematical predicate → Plain English meaning
```

Example:
```
assert(verify_sig(pk, sig, msg)) → ECDSA(pk, sig, msg)=true → "Someone signed msg with pk's private key"
```

Then write the complete satisfying set:
```
PROOF VALID IFF: P1 ∧ P2 ∧ ... ∧ Pn
```

## Phase 3: Binding Analysis (Critical)

For EACH private input, check:

| Input | Used In Assert? | Bound To Other Inputs? | In Public Output? |
|-------|-----------------|------------------------|-------------------|
| secret_key | ✅ | ❌ NOT BOUND | ❌ |

**Red flags:**
- Private input NOT in any assert → Can be anything
- Private input NOT bound to other inputs → Mix-and-match attack
- Important value NOT in public output → Verifier can't check

**Key question:** Can the prover use components from DIFFERENT contexts?
- Alice's signature with Bob's balance?
- Old state with new timestamp?

## Phase 4: Gap Analysis

| Aspect | INTENDED | ACTUAL | GAP |
|--------|----------|--------|-----|
| Auth | Prover owns wallet NOW | Has ANY valid signature | Replay |
| Freshness | Current state | Any state root | Stale proofs |
| Binding | Signature for THIS proof | Signature for ANYTHING | Context confusion |

## Phase 5: Construct Witness

For each gap, construct malicious Prover.toml:

```toml
# Attack: [what attacker achieves]
private_input_1 = "..." # Malicious value
private_input_2 = "..." # From different context
```

Verify: Does it satisfy ALL constraints while violating intent?

## Phase 6: Quick Pattern Check

After gap analysis, quick sanity check:

- [ ] Field arithmetic without range checks?
- [ ] Value computed but never asserted?
- [ ] Unconstrained output used without validation?
- [ ] Verification key as private input?
- [ ] External data not authenticated?

## Output: candidates.md

```markdown
# FINDER Results

## Intended Claim
[What circuit SHOULD prove]

## Gap Analysis
| INTENDED | ACTUAL | GAP | SEVERITY |
|----------|--------|-----|----------|

## Findings

### [SEVERITY] Title
**Location:** file:line
**Intended:** [what should happen]
**Actual:** [what constraints enforce]
**Gap:** [the vulnerability]
**Exploit:**
```toml
[malicious witness]
```
**Fix:** Add `assert([predicate])` at [location]
```
