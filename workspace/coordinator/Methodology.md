# Methodology (locked)

**Approved by:** user (PI) · **2026-11-07**

**Hypothesis:** Label smoothing improves test accuracy of a small network trained with symmetric noisy labels, vs hard-label cross-entropy.

**Dataset and noise:** MNIST, 5 000 train / 1 000 test subset. Inject **40%** symmetric label noise on the training set only.

**Model:** 2-layer MLP (784 → 256 → 10), ReLU, no dropout in the comparison arms.

**Metric:** Test accuracy (%) on clean test labels.

**Baseline:** Hard-label cross-entropy (no label smoothing).

**Comparison:** Baseline vs label smoothing with ε = 0.1; same architecture, optimizer (Adam, lr=1e-3), batch size 128, 5 epochs.

**Seeds:** 3 (seeds 0, 1, 2).

**Claim rule:** Claim an effect only if label smoothing’s mean test accuracy beats hard labels by more than the larger of the two standard deviations (across seeds).

**Compute budget:** laptop CPU; under 1 minute per experiment script (as stated by the PI).

**Budget fit:** Small MNIST subset + tiny MLP + 5 epochs keeps each script under 1 minute on CPU. Full plan: 2 methods × 3 seeds = 6 runs.
