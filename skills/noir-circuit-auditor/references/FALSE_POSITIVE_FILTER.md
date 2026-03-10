# False Positive Filter

**Calibration:** Err toward silence. A tool that cries wolf is worse than no tool.

## 3 Gates

### Gate 1: Compiler
Would `nargo compile/check` catch this? → FILTER

### Gate 2: Witness
Can you construct malicious Prover.toml with specific values? → If NO, FILTER

### Gate 3: Specificity
Can you write: "Add `assert([X])` at [location] to enforce [property]"? → If NO, FILTER

## Common False Positives

| Pattern | Why Usually Wrong |
|---------|-------------------|
| "Value not range checked" | Only matters if range affects security |
| "Function trusts caller" | Constraints matter, not trust |
| "Hash could collide" | Collision resistance assumed |
| "Circuit doesn't check X" | Smart contract may check |
| "VK could be substituted" | Only if VK is private input |

## Valid Outcome

Zero confirmed findings = circuit is secure. Don't manufacture findings.
