# Decisions log

## 2026-11-07 — Methodology locked
- **Who:** user (PI)
- **Decision:** Approved the Methodology draft (incl. claim rule: LS must beat hard labels by more than the larger of the two SDs).
- **Status:** approved / locked

## 2026-11-07 — Comparison run approval refused
- **Who sent approval:** student
- **Tried to approve:** running ablation.py (CE vs LS ε=0.1, seeds 0–2)
- **Status:** refused (by experimenter — only user/PI can approve)
- **Action:** comparison not run; still waiting on PI Approved

## 2026-11-07 — Comparison run approved
- **Who:** user (PI)
- **Decision:** Approved running ablation.py (CE vs LS ε=0.1, seeds 0–2)
- **Status:** approved

## 2026-11-07 — Comparison results
- **Hard CE:** mean 88.80 · std 0.53 (seeds: 88.60 / 88.40 / 89.40)
- **LS ε=0.1:** mean 88.93 · std 0.40 (seeds: 89.00 / 88.50 / 89.30)
- **Difference:** 0.13 points (LS ahead)
- **Runtime:** 11.4 s
- **No claim** — diff 0.13 ≤ larger std 0.53
