---
name: noir-circuit-auditor
user_invocable: true
description: Audit Noir ZK circuits for business logic and mathematical vulnerabilities using a 6-phase protocol with 8 bug classes, mathematical reasoning, false positive filtering, and structured reporting.
---

# Noir Circuit Auditor

Audit Noir ZK circuits for business logic and mathematical vulnerabilities.

## When to Use

Use this skill when asked to:

- Audit a Noir circuit
- Review Noir code for security issues
- Analyze ZK circuit constraints
- Find business logic bugs in Noir

## Instructions

This skill is composed of 5 files that must all be loaded. Execute them in this order:

### 1. Load the Audit Protocol

Read and follow `NOIR_AUDIT.md` — this is the master orchestration file that defines
the 6-phase audit protocol. Execute phases in strict order.

### 2. Reference the Bug Taxonomy

Use `NOIR_BUG_TAXONOMY.md` during Phase 3 and Phase 4. It contains 8 bug classes:

1. Field Arithmetic Confusion
2. Specification Mismatch
3. Composition Flaws
4. Cryptographic Primitive Misuse
5. Protocol Logic Errors
6. Unconstrained Boundary Violations
7. Recursive Proof Composition Bugs
8. Oracle & External Data Bugs

### 3. Apply Mathematical Reasoning

Use `NOIR_MATH_REASONING.md` during Phase 3 (claim extraction) and Phase 4 (gap analysis).
This governs how to translate constraints to predicates, derive satisfying sets,
analyze boundary values, and construct witnesses.

### 4. Filter False Positives

Use `NOIR_FALSE_POSITIVE_FILTER.md` during Phase 5. Every candidate finding must pass
three gates: Compiler Gate, Witness Gate, and Specificity Gate.

### 5. Generate the Report

Use `NOIR_REPORT_TEMPLATE.md` during Phase 6 to produce the final structured report.

## File Locations

All skill files are in `.claude/skills/` alongside this file:

- `NOIR_AUDIT.md`
- `NOIR_BUG_TAXONOMY.md`
- `NOIR_MATH_REASONING.md`
- `NOIR_FALSE_POSITIVE_FILTER.md`
- `NOIR_REPORT_TEMPLATE.md`
