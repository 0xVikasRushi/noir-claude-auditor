---
name: audit
description: Audit a Noir ZK circuit for business logic vulnerabilities
argument-hint: "<path-to-noir-project>"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Write
  - Edit
---

# Audit Noir Circuit

**Target:** $ARGUMENTS (default: current directory)

Invoke the `noir-circuit-auditor` skill and run the full 6-phase audit protocol.
Write the final report to `audit_report.md` in the project root.
