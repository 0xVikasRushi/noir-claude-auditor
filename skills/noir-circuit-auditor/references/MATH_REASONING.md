# Field Arithmetic Basics

## BN254 (Barretenberg)
```
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
```

## Key Behaviors

| Operation | Behavior |
|-----------|----------|
| `(p-1) + 1` | `= 0` (wrap) |
| `0 - 1` | `= p - 1` (wrap) |
| `1 / 0` | Undefined |
| `a < b` | Only valid if BOTH range-checked |

## Edge Cases to Test

- Zero values: What if private input is 0?
- Near-max: What if value is near p-1?
- Duplicates: What if two "distinct" inputs are equal?

## Constraint Translation

| Noir | Math | Meaning |
|------|------|---------|
| `assert(a == b)` | `a ≡ b (mod p)` | Equal in field |
| `assert(a < b)` | Requires range check | Not inherently ordered |
| `let b: bool = x` | Must verify `b ∈ {0,1}` | Field can be anything |
