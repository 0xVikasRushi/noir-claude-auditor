---
name: noir-circuit-auditor
description: >
  Audits Noir ZK circuits for business logic vulnerabilities by analyzing the gap
  between intended claims and actual constraints. Use when reviewing Noir code for
  security, auditing ZK circuit constraints, or finding soundness bugs. Triggers:
  audit, review, security, Noir, circuit, ZK, constraints.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Write
  - Edit
---

# Noir Circuit Auditor

Finds business logic and mathematical bugs in Noir ZK circuits that compilers miss.

## When to Use

- "Audit this Noir circuit"
- "Review this ZK code for security issues"
- "Find bugs in these constraints"
- "Is this circuit sound?"
- Any Noir codebase with `.nr` files and a `Nargo.toml`

## When NOT to Use

- Syntax errors or type issues (run `nargo compile`)
- Underconstrained signals (run `nargo compile --pedantic-solving`)
- Smart contract integration bugs (out of scope — this is circuit-only)
- Non-Noir code (Circom, Halo2, etc.)
- Performance optimization or gas analysis

## Rationalizations to Reject

If you catch yourself thinking any of these, STOP.

| Rationalization | Why It's Wrong | Required Action |
|---|---|---|
| "This constraint looks correct" | Correct constraints can prove the wrong thing | Compare actual claim vs intended claim |
| "The compiler would catch this" | Nargo misses cross-function and unconstrained boundary bugs | Verify manually if in doubt |
| "No documentation, so I can't determine intent" | Names, types, and structure reveal intent | State your inference explicitly, flag uncertainty |
| "This is just a helper function" | Helpers propagate assumptions that callers depend on | Trace the full call chain |
| "The math checks out" | Math in F_p is not math in the integers | Check boundary values: 0, p-1, duplicates |
| "I should report this to be safe" | False positives destroy credibility | Construct a witness or drop it |
| "A clean report means I missed something" | Clean circuits exist; manufacturing findings is worse | Report zero findings if warranted |

## Instructions

Load and follow these files in order:

### 1. Run the audit protocol
Read `audit.md` — the 6-phase protocol with routing by circuit size.

### 2. Reference bug classes during analysis
Read `bug-taxonomy.md` during Phases 3-4. Detection heuristics for 8 bug classes.

### 3. Filter false positives before reporting
Read `false-positive-filter.md` during Phase 5. Three gates every finding must pass.

### 4. Generate the report
Read `report-template.md` during Phase 6. Structured output format.

## Quality Checklist

Before delivering the report, verify:

- [ ] Every `.nr` file in the project was read
- [ ] Nargo.toml checked for compiler version and backend
- [ ] Every `assert()` catalogued with what it enforces
- [ ] Every `unconstrained` function's outputs traced to where they're re-validated
- [ ] Gap analysis done: actual claim vs intended claim for each function
- [ ] Every finding has a concrete witness or rigorous mathematical argument
- [ ] Every finding has a specific fix (not "add more constraints")
- [ ] False positive filter applied to all candidates
- [ ] Report file generated (not just chat output)
- [ ] Benchmark YAML block appended to report (see report-template.md)

## Improvement Loop

Every audit report includes a `benchmark:` YAML block at the end. This captures
what worked, what didn't, and new patterns discovered.

After multiple audits, run `/review-benchmarks` to analyze accumulated data and
get concrete suggestions for improving the skill files (new taxonomy entries,
new false positive patterns, wording fixes).

The `human_feedback` section in the benchmark is filled in by the human reviewer
after reading the report. This closes the loop.

## Files

All files are alongside this SKILL.md:

- `audit.md` — master protocol + mathematical reasoning
- `bug-taxonomy.md` — 8 bug classes with detection heuristics
- `false-positive-filter.md` — 3-gate filter
- `report-template.md` — output format + benchmark template
