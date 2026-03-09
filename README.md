# Noir Circuit Auditor — Skills README

## What This Is

A set of Claude skills for auditing Noir ZK circuits for business logic
and mathematical vulnerabilities. Not a replacement for static analysis
(run nargo separately). Specifically targets bugs that compilers cannot find.

## Files

```
NOIR_AUDIT.md              Master skill — orchestration and phase protocol
NOIR_BUG_TAXONOMY.md       Knowledge base of 6 bug classes with examples  
NOIR_MATH_REASONING.md     How to reason mathematically about constraints
NOIR_FALSE_POSITIVE_FILTER.md  Three-gate filter before reporting findings
NOIR_REPORT_TEMPLATE.md    Output format for the final report
```

## How to Use Manually

### Option 1 — Claude.ai (simplest)

1. Start a new Claude conversation
2. Paste the contents of all 5 skill files as your first message,
   prefixed with: "These are your operating instructions for this session:"
3. Then paste your Noir circuit code
4. Then type: "Begin the audit protocol."

Enable extended thinking if available. The mathematical reasoning phases
require it.

### Option 2 — Claude Code (recommended for real codebases)

1. Add the skills to your CLAUDE.md in your project root:

```bash
cat NOIR_AUDIT.md >> CLAUDE.md
cat NOIR_BUG_TAXONOMY.md >> CLAUDE.md  
cat NOIR_MATH_REASONING.md >> CLAUDE.md
cat NOIR_FALSE_POSITIVE_FILTER.md >> CLAUDE.md
cat NOIR_REPORT_TEMPLATE.md >> CLAUDE.md
```

2. Run:
```bash
nargo compile
nargo info --print-acir > acir_output.txt
```

3. Open Claude Code in your circuit directory and say:
"Audit this Noir circuit using the audit protocol in CLAUDE.md.
The ACIR output is in acir_output.txt."

### Option 3 — API with extended thinking

```python
import anthropic

skills = ""
for skill in ["NOIR_AUDIT.md", "NOIR_BUG_TAXONOMY.md", 
              "NOIR_MATH_REASONING.md", "NOIR_FALSE_POSITIVE_FILTER.md",
              "NOIR_REPORT_TEMPLATE.md"]:
    skills += open(skill).read() + "\n\n---\n\n"

circuit = open("src/main.nr").read()
acir = open("acir_output.txt").read()

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-opus-4-5-20251101",
    max_tokens=16000,
    thinking={"type": "enabled", "budget_tokens": 10000},
    system=skills,
    messages=[{
        "role": "user",
        "content": f"Audit this circuit:\n\nSource:\n{circuit}\n\nACIR:\n{acir}"
    }]
)
print(response.content[-1].text)
```

## What It Finds

| Bug Class | Example |
|---|---|
| Field arithmetic confusion | Equality checks that pass for unintended field values |
| Spec mismatch | Constraints that prove Y when spec requires X (Y ⊂ X) |
| Composition flaws | Caller trusts called function without binding constraints |
| Crypto primitive misuse | Poseidon params not achieving claimed security level |
| Protocol logic errors | Valid proof used in wrong context enables replay |
| Unconstrained boundary | Hint values used without re-validation |

## What It Does NOT Find

- Underconstrained signals → use `nargo compile`
- Range check issues → use `nargo compile --pedantic-solving`  
- Type errors → use `nargo check`
- Novel bug classes with no precedent in audit literature

## Expected Output

The audit produces a structured report with:
- Confirmed findings (concrete malicious witness specified)
- High confidence unconfirmed findings (rigorous argument, witness not computed)
- Clean bill of health if no issues found

A clean report is a good outcome. The tool does not manufacture findings.
