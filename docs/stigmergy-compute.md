# Stigmergic Compute Architecture

> "The queen doesn't tell anyone what to do. In fact, nobody tells anybody what to do."
> — Deborah Gordon

## Overview

ants-worker implements stigmergic coordination for distributed compute. Workers operate autonomously through indirect communication via a shared environment.

```
┌─────────────────────────────────────────────────────────────┐
│                    ENVIRONMENT                               │
│                                                              │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐              │
│   │ region   │   │ region   │   │ region   │   ...        │
│   │ φ=0.2    │   │ φ=5.1    │   │ φ=0.0    │              │
│   └────▲─────┘   └────▲─────┘   └────▲─────┘              │
│        │              │              │                      │
│        │    sense     │    sense     │    sense            │
│        │   deposit    │   deposit    │   deposit           │
│        │              │              │                      │
│   ┌────┴────┐   ┌────┴────┐   ┌────┴────┐                 │
│   │ worker  │   │ worker  │   │ worker  │                 │
│   └─────────┘   └─────────┘   └─────────┘                 │
│                                                              │
│   φ = pheromone (exploration marker)                        │
└─────────────────────────────────────────────────────────────┘
```

## Design Principles

### 1. No Central Coordinator

Workers never receive commands. They sense the environment and decide locally.

### 2. Environment as Memory

All coordination happens through environmental state:

| Pheromone | Meaning | Decay |
|-----------|---------|-------|
| `trail` | "I explored here" | Medium |
| `working` | "I'm working here now" | Fast |
| `quality` | "Found something good here" | Slow |

### 3. Local Rules, Global Behavior

Each worker follows simple rules:

```
1. SENSE  → Query cold regions (low pheromone)
2. DECIDE → Pick one (prefer unexplored)
3. MARK   → Deposit intention pheromone
4. WORK   → Run computation
5. DEPOSIT → Write results to environment
6. REPEAT
```

No worker knows the global state. Coordination emerges.

## Benefits

| Aspect | Traditional | Stigmergic |
|--------|-------------|------------|
| Single point of failure | Coordinator | None |
| Scalability | Limited by coordinator | Unlimited |
| Fault tolerance | Workers orphaned | Workers continue |
| Communication | O(n) messages | O(1) env reads |
| Complexity | In coordinator | Emergent |

## References

- Gordon, Deborah. "Ant Encounters: Interaction Networks and Colony Behavior"
- Dorigo, Marco. "Ant Colony Optimization"
- Grassé, Pierre-Paul. "La reconstruction du nid et les coordinations interindividuelles" (1959)
