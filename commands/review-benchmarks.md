---
name: review-benchmarks
description: Analyze past audit benchmarks and suggest skill improvements
argument-hint: "[path-to-reports-directory]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
---

# Review Audit Benchmarks

**Reports directory:** $ARGUMENTS (default: search current directory for `audit_report*.md`)

## Instructions

1. Find all audit report files matching `audit_report*.md` or `*_audit.md`
2. Extract the `benchmark:` YAML block from each report
3. Aggregate the data across all audits
4. Produce an improvement report

## Analysis to Perform

### False Positive Patterns
- Which near-miss descriptions repeat across audits?
- Any pattern appearing 3+ times should become a new entry in `false-positive-filter.md`

### Taxonomy Gaps
- Collect all `missing_from_taxonomy` entries across audits
- Any new pattern appearing 2+ times should be proposed as a new entry in `bug-taxonomy.md`
- Include the detection heuristic and false positive risk

### Phase Effectiveness
- Which phases consistently struggled?
- Suggest specific wording changes to `audit.md` for those phases

### Human Feedback Analysis
- Calculate overall true positive rate: `confirmed_by_human / total_reported`
- Calculate miss rate: `missed_by_human / (missed_by_human + confirmed_by_human)`
- If TP rate < 80%, the filter is too loose — suggest tightening
- If miss rate > 20%, the skill is too conservative — suggest loosening

### Bug Class Distribution
- Which classes trigger most often?
- Which classes never trigger? (may indicate the skill is weak at detecting them)

### Rationalizations
- Which rationalizations from the SKILL.md table are caught most often?
- Any new rationalizations discovered should be proposed for the table

## Output

Write the improvement report to `benchmark_review.md` with:

1. **Summary stats** — audits analyzed, total findings, TP rate, miss rate
2. **Proposed changes** — specific edits to skill files, with before/after
3. **New taxonomy entries** — ready to paste into `bug-taxonomy.md`
4. **New false positive patterns** — ready to paste into `false-positive-filter.md`
5. **New rationalizations** — ready to add to the SKILL.md table
