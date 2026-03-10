# Noir Circuit Auditor - Orchestrator

Orchestrate Noir ZK circuit audits. **Fully automatic** - never ask questions, use sensible defaults.

## Execution: `/noir-circuit-auditor [path]`

### Step 0: Environment Check

```bash
nargo --version
cat [path]/Nargo.toml | grep -A 20 "\[workspace\]"  # Note ALL members
```

### Step 1: Run Tests (Critical)

```bash
cd [path] && nargo test 2>&1 | tee audit/test_results.txt
```

**If test named "vulnerability" PASSES → bug is confirmed.** Stop and document.

### Step 2: Preprocessing

```bash
bash .claude/skills/noir-circuit-auditor/scripts/preprocess.sh [path]
```

Creates: `audit/sources.txt`, `audit/static.txt`, `audit/test_results.txt`

### Step 3: Spawn FINDER Agent

```
subagent_type: "general-purpose"
prompt: |
  [Contents of agents/FINDER.md]

  Target: [absolute path]
  Workspace members: [list if workspace]
  Test results: [paste output]

  Read all .nr files from audit/sources.txt
  Output: audit/candidates.md
```

### Step 4: Spawn VALIDATOR Agent

```
subagent_type: "general-purpose"
prompt: |
  [Contents of agents/VALIDATOR.md]

  Target: [absolute path]
  Read: audit/candidates.md, all .nr files
  Output: audit/validated.md
```

### Step 5: Generate Output

Write `audit/results.json`:
```json
{
  "status": "complete",
  "target": "[path]",
  "timestamp": "[ISO]",
  "files_analyzed": N,
  "summary": {"proven": N, "unconfirmed": N, "filtered": N},
  "findings": [...]
}
```

Print summary to user with PROVEN/UNCONFIRMED counts.

## Error Handling

| Error | Action |
|-------|--------|
| nargo not installed | Log to audit/errors.log, exit |
| nargo test fails | Log, continue with static analysis |
| No Nargo.toml | Log "Not a Noir project", exit |
| Agent fails | Log, continue with partial results |
| No bugs but vulnerability tests exist | RE-CHECK automatically |
