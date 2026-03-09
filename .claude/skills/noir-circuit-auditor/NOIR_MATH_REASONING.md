# Noir Mathematical Reasoning — Deep Analysis Skill

This skill governs how you perform mathematical analysis of Noir circuits.
Use this during Phase 3 (claim extraction) and Phase 4 (gap analysis).

The goal is to reason about what constraints **actually enforce** rather than
what they **appear to enforce**. These are frequently different.

---

## The Reasoning Protocol

### Step 1 — Constraint Algebra

For every `assert()` in a function, translate it into a formal predicate.

Rules for translation:

- `assert(a == b)` → `a = b (mod p)` — note the modular arithmetic
- `assert(a != b)` → `a ≠ b (mod p)`
- `assert(a as bool)` → `a ∈ {0, 1}` — only if a is constrained to be boolean
- `assert(a < b)` → this is NOT field arithmetic. In F_p there is no ordering.
  This works only if both a and b are range-checked to be small integers first.
  If not range-checked, this assert may not mean what the developer thinks.

After translating all asserts, write the **conjunction**: the system of
simultaneous equations that must all be satisfied.

**For loops:**
Bounded loops in Noir are unrolled at compile time. Treat them as the full
expanded conjunction:

```
for i in 0..N { assert(P(arr[i])); }
→ P(arr[0]) ∧ P(arr[1]) ∧ ... ∧ P(arr[N-1])
```

Be precise about the loop bounds — off-by-one errors in loop ranges directly
affect the constraint set. Check: is the last element included or excluded?

**For generic functions:**
When a function uses generic type parameters (e.g., `fn foo<T>(x: T)`),
the constraints generated depend on the concrete type at the call site.
A function that is sound for `u32` may not be sound for `Field`, because
`u32` has implicit range checking that `Field` does not. Analyze each
concrete instantiation separately.

### Step 2 — Satisfying Set Derivation

From the conjunction, derive: what is the complete set of (input, witness)
assignments that satisfy this system?

This requires asking: beyond the obvious honest assignments, are there other
assignments that also satisfy every constraint?

Think adversarially. The prover is not honest. They will:

- Choose private witnesses that satisfy constraints while violating intent
- Use field arithmetic properties (wrap-around, zero inverses) to their advantage
- Exploit the gap between "satisfies the constraints" and "represents a valid proof"

### Step 3 — Boundary Value Analysis

For every function, explicitly evaluate behavior at:

**Zero values:**

- What if a private input is 0?
- What if a hash output is 0?
- What if a commitment is 0?
- Does the circuit have implicit non-zero assumptions never explicitly checked?

**Field maximum (p-1):**

The field prime depends on the backend. Determine it from `Nargo.toml`:

- **Barretenberg (default):** BN254 scalar field
  `p = 21888242871839275222246405745257275088548364400416034343698204186575808495617`
- **Recursive inner circuits:** may use the Grumpkin scalar field
  `p = 21888242871839275222246405745257275088696311157297823662689037894645226208583`
- **Other backends:** consult the backend documentation for the field prime

If the backend or prime cannot be determined, state this explicitly and proceed
with the BN254 prime as a default assumption.

Values at or near p-1 frequently cause unexpected behavior in:

- Range checks that use bit decomposition
- Comparisons that assume values fit in a certain number of bits
- Arithmetic where intermediate values overflow and wrap

**Duplicated values:**

- What if two inputs that should be distinct are equal?
- What if the same commitment appears twice in a Merkle tree?
- What if the nullifier equals the commitment?

**Boolean canonicity:**
In F_p, the constraint `x * (x - 1) == 0` correctly restricts x to {0, 1}
because p ≡ 0 (mod p), so x = p is the same as x = 0. However, if a boolean
is checked via a different mechanism (e.g., range check to 1 bit), verify that
the mechanism is sound. The key question: does the boolean constraint accept
exactly {0, 1} and nothing else?

---

## Reasoning About Composition

When function A calls function B, reason through this chain:

```
What does B prove?
→ Derive B's satisfying set using the constraint algebra above

What does A assume about B's output?
→ Look at how A uses the return value of B

Is there a gap?
→ Does A's usage assumption hold for ALL elements of B's satisfying set,
  or only for honest witnesses?

If the assumption fails for some element of B's satisfying set,
and a malicious prover could construct that element,
you have a composition flaw.
```

**The key question:**
When A calls B and receives output `y`, does A verify that `y` is the
_specific_ output that corresponds to A's other private inputs? Or does
A just verify that `y` is _some_ valid output of B?

"Some valid output" is almost always insufficient for security. You need
"the specific output corresponding to _these_ inputs."

---

## Reasoning About Cryptographic Primitives

### Poseidon Hash

- Used widely in Noir circuits
- Security depends on parameter selection: (t, RF, RP, prime, MDS matrix)
- **Do NOT use simplified security formulas.** Poseidon's security is determined by:
  1. **Algebraic attack resistance:** depends on the number of full rounds (RF),
     partial rounds (RP), S-box exponent (α), and the MDS matrix properties
  2. **Statistical attack resistance:** depends on RF being sufficient for
     wide trail strategy bounds
  3. The Poseidon paper (Grassi et al., 2019) provides Table 2 with minimum
     round numbers for specific security levels
- **What to do:** Check the actual (t, RF, RP, α, prime) values used against
  the Poseidon paper's recommended minimums for the claimed security level.
  If the circuit claims 128-bit security, verify that RF and RP meet or exceed
  the paper's recommendations for that (t, α, prime) combination.
- **Red flags:** RF < 8, RP < recommended minimum for the state size t,
  custom MDS matrices not proven to have full branch number, non-standard
  S-box exponents without analysis
- If you cannot verify the parameters against the paper, flag the instantiation
  as "UNVERIFIED — manual cryptographic review recommended" and do NOT claim
  it is secure or insecure without evidence.

### Pedersen Commitments

- Hiding: computationally hard to find what was committed to (requires DDH)
- Binding: computationally hard to open commitment two ways (requires DL)
- Check: is hiding required? If so, is the blinding factor truly random (private)?
- Check: is binding relied upon? If so, is the generator point non-trivial?

### Merkle Trees

- Security depends on collision resistance of the hash function used
- Check: are leaf indices range-checked? An unchecked index can allow
  treating a leaf as an internal node (second-preimage in some constructions)
- Check: is the depth of the tree constrained? Or can a prover claim any depth?
- Check: are empty subtrees handled consistently? What is the hash of an empty node?

### ECDSA / Schnorr Verification Inside Circuits

- These are expensive and therefore sometimes implemented with shortcuts
- Check: cofactor clearing — are points validated to be in the prime-order subgroup?
- Check: nonce uniqueness — can the same nonce be reused across signatures?
- Check: message binding — is the message that was signed actually bound to
  the circuit's public inputs?

### Recursive Proof Verification

- Check: is the verification key a public input or hardcoded? If it is a private
  input, the prover can substitute any circuit's verification key.
- Check: are the inner proof's public inputs bound to the outer circuit's signals?
- Check: if the inner proof uses a different curve, is the field transition
  handled with proper range checking?

---

## The Adversarial Mindset

When analyzing, constantly ask:

**"I am a malicious prover. What is the cheapest violation I can achieve?"**

Start with the highest-value violations:

1. Can I prove a false membership claim? (I'm not in a set but I prove I am)
2. Can I double-spend? (Use the same private resource twice)
3. Can I forge identity? (Prove I own a key I don't own)
4. Can I replay a proof? (Use a valid old proof in a new context)
5. Can I substitute a different proof? (Use a proof from a trivial circuit)
6. Can I manipulate external data? (Submit fake prices, timestamps, or oracle values)
7. Can I violate privacy? (Learn someone else's private input from public outputs)

For each, trace backward: what constraints would need to fail for this violation
to be possible? Then check whether those constraints actually hold.

---

## The Witness Construction Protocol

When you believe you've found a bug, construct the witness:

**For FIELD_ARITHMETIC bugs:**
Start with the boundary value (0 or p-1) and verify it satisfies each
constraint in the system. Work through the arithmetic explicitly.

**For SPEC_MISMATCH bugs:**
Identify the variable that is "assigned but not constrained."
Set it to the value that violates the spec (e.g., set a balance to 0
when it should be nonzero). Verify all actual constraints are still satisfied.

**For COMPOSITION bugs:**
Construct a valid output of the called function that is not the output
corresponding to the caller's intended inputs. Verify the caller accepts it.

**For PROTOCOL_LOGIC bugs:**
Construct the off-chain attack scenario: what sequence of valid proofs
can be submitted to the verifier to achieve the violation?

**For RECURSIVE_COMPOSITION bugs:**
Construct a valid proof for a different (simpler) circuit and show the outer
circuit accepts it. Or: construct an inner proof with different public inputs
than the outer circuit expects, and show acceptance.

**For ORACLE_DATA bugs:**
Identify the unvalidated external input and set it to the attacker-optimal value.
Verify all constraints are still satisfied with this adversarial input.

---

## Expressing Findings Precisely

Every confirmed finding must be expressed in this form:

```
CLAIM THE CIRCUIT MAKES:
"For all (pub_inputs, priv_witness) satisfying the constraints, [property P holds]"

WHAT IS ACTUALLY PROVEN:
"The constraints enforce [condition C], which is weaker than P because..."

COUNTEREXAMPLE:
Setting:
  public_input_1 = [value]
  public_input_2 = [value]
  private_witness_1 = [value]
  private_witness_2 = [value]

Satisfies all constraints: YES (verify each assert() explicitly)
Violates property P: YES (explain why this is not a valid honest assignment)

ATTACK:
A malicious prover can submit this witness to the verifier and
the verifier will accept the proof, believing [false statement].
```

If you cannot fill in the COUNTEREXAMPLE section with specific values,
do not report this as a confirmed finding.
