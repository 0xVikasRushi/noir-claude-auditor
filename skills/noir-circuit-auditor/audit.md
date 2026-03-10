# Audit Protocol

Focus: business logic and mathematical bugs. Not syntax, not underconstrained signals
nargo already catches.

Check `Nargo.toml` for `compiler_version` (target >=0.30) and backend (default: Barretenberg/BN254).

## Route by Circuit Size

| Size | Strategy | What changes |
|------|----------|-------------|
| Small (<200 lines) | DEEP | Analyze every function, full boundary analysis |
| Medium (200-1000) | FOCUSED | Prioritize public entry points, unconstrained boundaries, crypto |
| Large (1000+) | SURGICAL | Entry points and high-risk functions only; skip pure helpers |

Pick a strategy before starting Phase 2. State it explicitly.

---

## Phase 1 — Read

Read everything before forming opinions.

1. Every `.nr` file top to bottom
2. `Nargo.toml` — dependencies, compiler version, backend
3. README, specs, comments, linked papers
4. ACIR output if available (`nargo info --print-acir`)
5. Run `nargo test` if tests exist

After reading, state:
- File count and approximate line count
- Noir version and backend
- What's missing (no README? no tests? no comments?)

Do not analyze yet.

---

## Phase 2 — Map

Build a structured map. This is cartography, not analysis.

**For every function:**
- Name, visibility, parameters (public/private), return type
- Every `assert()` and what it enforces in plain English
- Whether it contains `unconstrained` blocks
- Generic type parameters that affect constraint behavior

**Signal flow:**
- Trace every public output backward through the call chain
- Which private inputs influence which public outputs?
- Flag outputs produced inside `unconstrained` blocks

**Constraint inventory:**
List every `assert()` with: what it enforces, what breaks if removed.

**State the intended behavior:**
"This circuit is intended to prove that [X]."
If no docs exist, infer from naming and structure. Say so explicitly.

---

## Phase 3 — Analyze

Extract what the constraints actually prove. This is where bugs hide.

**Prioritize** (for FOCUSED/SURGICAL strategies):
1. `main` and public entry points
2. Functions with `unconstrained` blocks
3. Functions using crypto primitives (hash, verify, commit)
4. Value transfer / balance / ownership logic
5. Internal helpers (DEEP only)

For each function:

### 3a. Translate constraints to predicates

Every `assert()` becomes a formal predicate. Be precise, not vague.

- `assert(a == b)` means `a = b (mod p)` — modular, not integer equality
- `assert(a < b)` only works if both are range-checked to small integers.
  In F_p there is no ordering. If inputs aren't range-checked, this assert
  may not mean what the developer thinks.
- Loops unroll: `for i in 0..N { assert(P(i)) }` becomes `P(0) AND P(1) AND ... AND P(N-1)`.
  Check the bounds — off-by-one changes the constraint set.
- Generic functions: constraints depend on concrete type at call site.
  Sound for `u32` does not mean sound for `Field`.

### 3b. Derive the satisfying set

"A prover can generate a valid proof if and only if [conditions]."

Think adversarially. The prover is not honest. They will:
- Choose witnesses that satisfy constraints while violating intent
- Exploit field wrap-around (p-1 + 1 = 0)
- Use zero values where non-zero is assumed but not enforced

### 3c. Check composition

When function A calls function B and uses B's output:
- What does B guarantee?
- Does A add constraints binding B's output to A's own signals?
- Or does A just trust that B returned something valid?

Key question: does A verify that B's output corresponds to *these specific inputs*,
or just that it's *some* valid output of B? "Some valid output" is almost always
insufficient.

### 3d. Check field boundaries

BN254 scalar field: `p = 21888242871839275222246405745257275088548364400416034343698204186575808495617`

For every arithmetic operation, check:
- Input = 0 (division by zero? bypass a check?)
- Input = p-1 (wrap-around?)
- Two inputs equal when they should be distinct
- Intermediate overflow and wrap

Also: are booleans constrained to {0, 1}? `x * (x - 1) == 0` is sound in F_p.
Other mechanisms may not be.

---

## Phase 4 — Compare

You now have:
- What the circuit **actually proves** (Phase 3)
- What it **should prove** (Phase 2)

For each function:

| Relationship | Meaning | Action |
|---|---|---|
| Equivalent | No bug | Move on |
| Stronger than intended | Completeness bug — honest provers may fail | Document, lower severity |
| Weaker than intended | **Soundness bug** — malicious prover can prove false statements | Escalate |

For every weakness:

```
FUNCTION: [name]
INTENDED: Should prove [X]
ACTUAL:   Constraints only prove [Y]
GAP:      A malicious prover can [describe what they can do]
```

If this phase reveals your Phase 2 map was wrong, go back and fix it.
That's rigor, not failure.

---

## Phase 5 — Verify

Every candidate bug must pass the false positive filter (`false-positive-filter.md`).

Construct a concrete malicious witness for each candidate:
- Specific field values that satisfy all constraints
- That violate the intended security property

Per bug class:
- **Field arithmetic:** Start with 0 or p-1, verify each constraint
- **Spec mismatch:** Find the unasserted variable, set it to the violating value
- **Composition:** Construct a valid output of the callee that doesn't correspond to the caller's inputs
- **Unconstrained boundary:** Set the hint to an adversarial value, check if constraints catch it
- **Protocol logic:** Describe the off-chain attack sequence
- **Oracle data:** Set unvalidated external input to attacker-optimal value

Classification:
- Witness constructed = **CONFIRMED**
- Airtight math argument but can't compute witness inline = **HIGH CONFIDENCE UNCONFIRMED**
- Can't construct witness and argument is shaky = **DROP**

---

## Phase 6 — Report

Use `report-template.md`. Only findings that passed Phase 5.

Every finding needs:
- The gap (intended vs actual)
- A concrete witness or rigorous argument
- A specific fix — which constraint, where, enforcing what

Write the report to a file. A clean report with zero findings is valid.

---

## Severity

| Level | Meaning |
|-------|---------|
| CRITICAL | Malicious prover proves false statement violating core security property |
| HIGH | Significant violation with constraints on the attack |
| MEDIUM | Completeness failure or privacy leak |
| LOW | Theoretical weakness, no known exploit path |
