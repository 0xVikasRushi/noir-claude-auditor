# Bug Taxonomy — Detection Heuristics

Reference during Phases 3-4. For each class: what triggers investigation,
the canonical missed pattern, and what to actually check.

---

## 1. Field Arithmetic Confusion

**Trigger:** Arithmetic on `Field` type without range bounds. Any comparison
intended as ordering. Equality between values from different field contexts.

**The pattern you'll miss:** `assert(a == b)` where a and b originate from different
moduli. Constraint is satisfied when `a = 0, b = r mod p` — unequal but accepted.
(Aztec non-native field bug.)

**Check:**
- Every subtraction `a - b` — wraps in F_p. Is that handled?
- Every division — zero has no inverse. Is non-zero enforced?
- Every `assert(x < MAX)` — what is MAX relative to p?
- Does this constraint mean the same thing in F_p as in the integers?

---

## 2. Specification Mismatch

**Trigger:** A variable is computed but never appears in any `assert()`.
Return values used by callers without being asserted on.

**The pattern you'll miss:** A gadget returns a boolean `check` value. The
variable is assigned but never constrained. Malicious prover sets `check = 0`
and the proof still validates. (Summa proof-of-solvency bug.)

**Check:**
- Every value from an `unconstrained` block used in constrained context — re-validated?
- Every function return value — does the caller assert on it or just use it as a hint?
- Every boolean — constrained to {0, 1}, or can it be any field element?
- Grep for the pattern: `let result = gadget(inputs);` where `result` never appears in `assert()`

---

## 3. Composition Flaws

**Trigger:** Function A calls function B and uses the output without binding it
to A's own signals.

**The pattern you'll miss:** A nullifier circuit calls `compute_nullifier(private_key, utxo_id)`.
Hash is correct. But nothing asserts that `private_key` belongs to the owner of `utxo_id`.
Prover uses anyone's UTXO with their own key.

**Check:**
- Authentication: does the circuit verify the caller owns the private input?
- Binding: when two functions each validate one part of a compound object,
  is there a constraint ensuring both parts belong to the same object?
- Does the caller verify B's output corresponds to *these specific inputs*,
  or just that it's *some* valid output?

---

## 4. Cryptographic Primitive Misuse

**Trigger:** Hash, commitment, signature, or accumulator with non-standard parameters
or usage violating security assumptions.

**The pattern you'll miss:** Poseidon instantiation with fewer rounds than the paper
recommends. Code is correct. Parameters are wrong. ~91-bit security instead of 128.
(RISC Zero bug.)

**Check:**
- **Poseidon:** Verify (t, RF, RP) against the paper's minimums. RF < 8 is a red flag.
  If you can't verify params, flag as "UNVERIFIED — manual review needed." Don't guess.
- **Pedersen:** Is hiding needed? Is blinding factor private?
- **Merkle:** Are leaf indices range-checked? Is depth constrained?
- **Signatures in circuits:** Cofactor clearing? Nonce uniqueness? Message binding?
- **Set vs multiset:** Does the proof check set membership or multiset membership?
  These are different. (EZKL shuffle bug.)

---

## 5. Protocol Logic Errors

**Trigger:** The circuit is mathematically correct but proves the wrong thing
relative to what the protocol needs.

**The pattern you'll miss:** A balance proof uses an old state root. Circuit is
correct for the old root. Protocol needs the current root. Users with zero
current balance pass the check.

**Check:**
- Is the proof bound to a specific contract address, chain ID, or epoch?
- Current state or potentially stale state?
- Does the proof expire?
- Is the nullifier globally unique or only unique within some scope?

---

## 6. Unconstrained Boundary Violations

**Trigger:** Any call to an `unconstrained` function where the return value is
used in constrained code.

**The pattern you'll miss:**
```noir
unconstrained fn compute_hint(x: Field) -> Field { ... }
fn main(x: Field) {
    let hint = compute_hint(x);
    assert(hint == expected);  // Is 'expected' independently derived?
}
```
The prover can return anything from `unconstrained`. If constraints don't
independently re-derive or validate the hint, the prover controls the proof.

**Check:**
- Every `unconstrained` call site
- Is the return value used in an `assert()` that re-derives it from constrained inputs?
- Or is it just compared against another witness the prover also controls?

---

## 7. Recursive Proof Composition

**Trigger:** Any use of `verify_proof()` or recursive verification.

**The pattern you'll miss:** Verification key is a private input. Prover substitutes
the VK for a trivial circuit that always passes, along with a valid proof for that
trivial circuit. Outer circuit accepts.

**Check:**
- Is the VK hardcoded or derived deterministically? If prover-supplied, almost certainly a bug.
- Are inner proof public inputs bound to outer circuit signals via `assert()`?
- If inner circuit uses a different curve (e.g., Grumpkin), is the field transition range-checked?

---

## 8. Oracle & External Data

**Trigger:** Private inputs representing prices, timestamps, exchange rates,
or any real-world data.

**The pattern you'll miss:** A `price` private input used in a liquidation check.
No signature verification inside the circuit. Prover submits `price = 0` and
liquidates a healthy position.

**Check:**
- For every private input representing external data: what prevents the prover
  from choosing any value?
- If "a signature" — is it verified *inside* the circuit?
- If authenticated — is there a freshness guarantee?

---

## Quick Detection — Code Patterns

Scan for these patterns during Phase 3:

```
let x = some_function();
// x never in assert()              -> CLASS 2 candidate

assert(a == b)
// a, b from different origins      -> CLASS 1 candidate

fn verify(...) -> bool {
// caller never asserts return      -> CLASS 3 candidate

unconstrained fn hint(...) -> Field {
// return used without re-deriving  -> CLASS 6 candidate

verify_proof(vk, proof, inputs)
// vk is private input              -> CLASS 7 candidate

fn main(price: Field, ...) {
// price not authenticated          -> CLASS 8 candidate
```
