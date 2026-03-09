# Noir Bug Taxonomy — ZK Business Logic Vulnerabilities

This skill contains the complete taxonomy of business logic and mathematical bugs
found in ZK circuits. Use this as your reference during Phase 3 and Phase 4 of
the audit protocol.

Each bug class includes: what it is, why it's dangerous, how to recognize it in
Noir specifically, and a canonical example from real audit findings.

---

## CLASS 1: Field Arithmetic Confusion

### What it is

The circuit performs arithmetic that is correct in the integers or in a different
field, but produces wrong results in F_p (the Noir field prime).

### Why it's dangerous

The prover operates in a finite field. Operations that "look safe" in regular
arithmetic — comparisons, overflow checks, range assertions — can be satisfied
by unintended values when the field wraps around.

### How to recognize it in Noir

Look for:

- Arithmetic on `Field` type without explicit range bounds
- Comparisons intended to check ordering when the field has no canonical ordering
- Equality checks between values from different moduli
- Any operation where an intermediate value could exceed the field prime

Key question to ask: **"Does this constraint mean the same thing in F_p as it does
in the integers?"**

### Canonical example

Aztec's non-native field equality bug. A circuit checking `a == b` in a field
F_r was intended to check equality modulo p (a different prime). The constraint
was fully satisfied when `a = 0` and `b = r mod p` — they are unequal in F_p
but the circuit accepted the proof.

### What to check

- Every `assert(a == b)` where a and b originate from different field contexts
- Every range check `assert(x < MAX)` — what is MAX relative to p?
- Every subtraction `a - b` — in F_p, this wraps. Is wrap-around handled?
- Every division or inverse — in F_p, zero has no inverse but the circuit may
  not enforce non-zero inputs

---

## CLASS 2: Specification Mismatch

### What it is

The constraints are internally consistent and every signal is properly constrained,
but the set of satisfying witnesses is strictly larger than the set of honest witnesses
the protocol intends to accept.

### Why it's dangerous

This is the hardest class to find. No tool catches it. The circuit compiles clean,
passes all static checks, and works correctly for honest provers. But a malicious
prover can construct witnesses that satisfy the math while violating the protocol's
security guarantee.

### How to recognize it in Noir

This requires explicit comparison between:

1. The formal claim the constraints enforce (what you derive in Phase 3)
2. The intended security property (what you extract from documentation)

The gap between these two is the vulnerability.

### Canonical example

Summa proof-of-solvency circuit. The circuit computed a `check` value from a
LessThan gadget and assigned it to a variable during witness generation. But
`check` was never used in any `assert()`. A malicious prover could set `check = 0`
(false) and still generate a valid proof, proving solvency with zero assets.

Pattern: **assigned but not constrained**. Look for values computed in Noir that
are returned or used in later computation but never appear in an `assert()`.

### What to check

- Every variable assigned inside an `unconstrained` block that is later used
  in a constrained context — is it re-validated?
- Every return value of a function — is the caller asserting anything about it,
  or just using it as a hint?
- Every boolean flag — is it constrained to be 0 or 1? Or can it be any field element?
- The specific pattern: `let result = some_gadget(inputs); // result used but never asserted`

---

## CLASS 3: Composition Flaws

### What it is

Function A calls Function B and uses B's outputs without adding necessary binding
constraints. B proves X. A needs X AND Y. But A only inherits X because it never
asserts Y.

### Why it's dangerous

In ZK, function calls do not automatically propagate all constraints a caller might
assume. A function that proves "this hash equals this value" does not prove "this
hash was computed from inputs that satisfy some other property" unless the caller
adds that constraint explicitly.

### How to recognize it in Noir

Trace every function call chain:

1. What does the called function guarantee about its outputs?
2. What does the caller assume about those outputs beyond what the called function guarantees?
3. Are those additional assumptions enforced by constraints in the caller?

### Canonical example

A UTXO privacy circuit calls `compute_nullifier(private_key, utxo_id)` and uses
the result as the nullifier. The function correctly computes the hash. But the
circuit never asserts that `private_key` corresponds to the owner of `utxo_id`.
A malicious prover can use anyone's `utxo_id` with their own `private_key`,
generating a valid nullifier for a UTXO they don't own.

The called function did its job. The caller failed to bind the private_key to
the correct owner.

### What to check

- Authentication: does the circuit verify the caller owns the private input they claim to own?
- Binding: when two separate functions each validate one component of a compound
  object, is there a constraint ensuring both components belong to the same object?
- Uniqueness: if the protocol requires a value to be unique, is that uniqueness
  enforced in the circuit or assumed from outside?

---

## CLASS 4: Cryptographic Primitive Misuse

### What it is

A cryptographic primitive (hash function, commitment scheme, signature verification,
accumulator) is used in a way that violates its security assumptions, or instantiated
with parameters that don't achieve the claimed security level.

### Why it's dangerous

Cryptographic security proofs hold only under specific conditions. Violating those
conditions — even subtly — can break the security guarantee entirely.

### How to recognize it in Noir

For each cryptographic primitive used, ask:

- What security properties does this primitive guarantee?
- What are the conditions under which those guarantees hold?
- Does the circuit's usage satisfy those conditions?

### Canonical examples

**Parameter security:** RISC Zero's Poseidon instantiation achieved ~91-bit security
instead of claimed 128-bit due to specific parameter choices enabling an interpolation
attack. The code was correct. The parameters were wrong.

**Multiset vs set confusion:** EZKL's shuffle argument checked that the product of
`(x - input_i)` equals the product of `(x - output_i)` at a single random challenge
point. By the Schwartz–Zippel lemma, if the polynomials are different, they agree at
a random point with probability at most d/|F| (where d is the degree). However, the
bug was that verifying equality at one evaluation point of the characteristic polynomial
only proves multiset equality with high probability — it does not prove the _permutation_
relationship the shuffle argument requires. A prover could provide inputs that form the
same multiset but with a different ordering, bypassing the shuffle requirement.

**Missing cofactor checks:** ECDSA verification inside a circuit may accept points
on the curve's cofactor subgroup, allowing signature malleability.

### What to check

- Poseidon: what are the exact parameters (t, RF, RP, prime)? Verify against the
  Poseidon paper's security analysis — see NOIR_MATH_REASONING for details.
- Any hash used as a commitment: is the hiding property required? Is binding enforced?
- Any accumulator or set membership: is the underlying mathematical object a set
  or multiset? Does the circuit enforce the right one?
- Signature verification: cofactor clearing, point validation, nonce uniqueness

---

## CLASS 5: Protocol Logic Errors

### What it is

The circuit's mathematical implementation is correct but the circuit proves the
wrong thing relative to the protocol's security requirements. The bug is at the
protocol design level, not the constraint level.

### Why it's dangerous

These are the hardest bugs to find because the circuit itself is correct. The error
is in what was chosen to be proven, not how it was proven.

### How to recognize it in Noir

These bugs require understanding the full protocol context, not just the circuit:

- What is the circuit's role in the broader system?
- What security guarantee does the protocol need from this circuit?
- Does the circuit actually provide that guarantee?

### Canonical examples

**Balance staleness:** A DeFi circuit proved that a user's balance exceeded a
threshold — but using a balance from an old state root. The circuit was correct
for the old root. But the protocol needed a proof against the current state root.
Users with zero current balance could claim tokens.

**Replay vulnerability:** A nullifier circuit correctly prevented double-spending
within one session. But the nullifier wasn't bound to a specific contract address,
allowing replay across deployments of the same contract.

**Timing attack:** A circuit proved membership in a set at time T. The set could
change. The protocol used the proof at time T+N without requiring re-proof.

### What to check

- Is the circuit proof bound to a specific contract address, chain ID, or epoch?
  If not, replay may be possible.
- Is the circuit proof against the current state or a potentially stale state?
- Does the proof expire or can it be used indefinitely?
- Is there a nullifier? Is it globally unique or only unique within some scope?

---

## CLASS 6: Unconstrained Boundary Violations

### What it is

Noir's `unconstrained` keyword allows hint computation outside the constraint system.
A boundary violation occurs when a value computed in an unconstrained context is
used in a constrained context without being re-validated.

Note: This is distinct from simple "underconstrained signal" bugs that nargo catches.
This is specifically about the trust boundary between constrained and unconstrained
execution.

### Why it's dangerous

Unconstrained functions run in the prover's execution environment with no verifier
oversight. A malicious prover can return any value from an unconstrained function.
If that value influences a constrained computation without re-validation, the prover
controls part of the proof generation.

### How to recognize it in Noir

The pattern to find:

```noir
unconstrained fn compute_hint(x: Field) -> Field {
    // Prover can return anything here
    some_expensive_computation(x)
}

fn main(x: Field, expected: pub Field) {
    let hint = compute_hint(x);
    // Is hint validated before use?
    assert(hint * hint == x); // OK — hint is re-constrained
    // vs
    assert(hint == expected);  // RISK — depends on what expected is
}
```

The critical question: **after the unconstrained boundary, is the returned value
independently validated by constraints, or is it trusted?**

### What to check

- Every call to an `unconstrained` function
- Every value returned from an `unconstrained` function
- Whether that returned value is used in an `assert()` that re-derives or validates it,
  or whether it is used as a hint that directly influences the proof without re-checking
- Whether the constraints checking the hint value are sufficient to prevent a malicious
  prover from returning a different value that still satisfies them

---

## CLASS 7: Recursive Proof Composition Bugs

### What it is

When a Noir circuit verifies another proof recursively (using `verify_proof` or
recursive verification patterns), bugs arise from mismatches between what the
inner proof proves and what the outer circuit assumes it proves.

### Why it's dangerous

Recursive proofs are a trust boundary. The outer circuit trusts the inner proof's
public inputs as verified facts. If the outer circuit doesn't correctly validate
which circuit the inner proof is for, or doesn't bind the inner proof's public
inputs to its own constraints, a malicious prover can substitute a valid proof
from a different circuit entirely.

### How to recognize it in Noir

Look for:

- Any use of `verify_proof()` or recursive verification library calls
- Public inputs passed to the recursive verifier — are they bound to the outer
  circuit's own constraints?
- Verification key handling — is the verification key hardcoded or can the prover
  supply it? If the prover supplies it, they can substitute any circuit.

### Canonical examples

**Wrong circuit proof substitution:** An outer circuit verifies a proof that
"user has balance > 100." The verification key is passed as a private input.
A malicious prover substitutes the verification key for a trivial circuit that
always verifies, along with a valid proof for that trivial circuit. The outer
circuit accepts because `verify_proof` returns true.

**Public input mismatch:** An outer circuit verifies an inner proof and reads
the inner proof's public outputs. But the outer circuit doesn't assert that the
inner proof's public inputs match the outer circuit's expected values. A prover
can use a valid inner proof generated for different inputs.

**Cross-curve confusion:** Recursive circuits in Noir may use different curves
for inner vs. outer proofs (e.g., BN254 outer, Grumpkin inner). Field arithmetic
bugs (CLASS 1) can arise at the boundary if values are moved between fields
without proper range checking or reduction.

### What to check

- Is the verification key for the inner proof hardcoded or derived deterministically?
  If the prover supplies the verification key, this is almost certainly a bug.
- Are the inner proof's public inputs bound to the outer circuit's signals via
  explicit `assert()` statements?
- When consuming values from an inner proof's public outputs, are those values
  range-checked for the outer circuit's field?
- If the inner circuit operates over a different curve, is the field transition
  handled correctly?

---

## CLASS 8: Oracle and External Data Bugs

### What it is

The circuit accepts data from external sources (oracles, price feeds, off-chain
computation results, timestamps, random numbers) and either fails to validate
that data sufficiently or makes assumptions about its freshness, authenticity,
or correctness that are not enforced by constraints.

### Why it's dangerous

External data enters the circuit as private witness values. Unless the circuit
independently validates this data (e.g., via a signed attestation, Merkle proof
against a known root, or re-computation), a malicious prover can substitute
any value. This is different from CLASS 6 (unconstrained boundaries) because the
data doesn't originate from an unconstrained Noir function — it comes from
outside the circuit entirely.

### How to recognize it in Noir

Look for:

- Private inputs that represent prices, exchange rates, timestamps, or other
  real-world data
- Private inputs that are described as "oracle" values in comments or documentation
- Any private input used in a comparison or threshold check (e.g., `assert(balance > threshold)`)
  where `balance` is not independently verified within the circuit
- Signed data inputs where signature verification is incomplete or missing

### Canonical examples

**Unverified price feed:** A DeFi circuit checks that a liquidation position is
underwater by comparing `position_value` against `debt`. But `position_value` is
computed from a `price` private input that is not authenticated. A malicious
prover submits `price = 0` and liquidates a healthy position.

**Missing timestamp validation:** A circuit proves that an action occurred before
a deadline. The timestamp is a private input with no proof of correctness (no
signed attestation, no block hash binding). A prover can submit any timestamp.

**Stale authenticated data:** A circuit verifies a Merkle proof for a balance
against a state root. The state root is authenticated. But the circuit doesn't
check that the state root is recent — the prover uses a stale root where
they had a higher balance.

### What to check

- For every private input that represents external data: what prevents the prover
  from choosing any arbitrary value?
- If the answer is "a signature" or "a Merkle proof" — is that signature/proof
  verified _inside the circuit_? If verified outside, it's not a guarantee.
- If external data is authenticated: is there a freshness guarantee? Can the
  prover use old-but-valid authenticated data?
- Does the circuit's security rely on the correctness of any value that is
  ultimately prover-controlled?

---

## Quick Reference — Bug Detection Heuristics

When reading Noir code, these patterns should immediately trigger deeper investigation:

```
let x = some_function();
// x is never used in assert() → SPEC_MISMATCH candidate

assert(a == b)
// where a and b have different origins → FIELD_ARITHMETIC candidate

fn verify(x: Field) -> bool {
    // returns bool but caller never asserts the return value
} → COMPOSITION candidate

unconstrained fn hint(...) -> Field {
    // caller uses return value without re-constraining
} → UNCONSTRAINED_BOUNDARY candidate

verify_proof(vk, proof, public_inputs)
// vk is a private input, or public_inputs not bound to outer circuit
→ RECURSIVE_COMPOSITION candidate

fn main(price: Field, ...) {
    // price used in comparison but never authenticated
} → ORACLE_DATA candidate

// Comment says "proves X" but constraints only enforce Y
// where Y is strictly weaker than X → SPEC_MISMATCH confirmed candidate
```
