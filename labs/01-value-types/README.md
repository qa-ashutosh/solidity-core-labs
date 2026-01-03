## Concept
Solidity value types and their execution behavior.

## What this lab proves
- Value types are copied, not referenced
- Default values are deterministic and exploitable
- Type size and casting affect gas and correctness
- Overflow behavior is compiler-version dependent

## Why this matters in production
- Incorrect assumptions lead to silent fund loss
- Implicit casts can introduce logic bugs
- Gas inefficiencies compound at protocol scale

## Key takeaway
Value types look simple — until you rely on them.