# Lab notebook

## 2026-11-07
- **Question:** Does label smoothing help a small network trained on noisy labels?
- **Result:** Hard CE mean 88.80±0.53; LS ε=0.1 mean 88.93±0.40 (MNIST 5k/1k, 40% train noise, MLP 784→256→10, Adam 1e-3, batch 128, 5 epochs, seeds 0–2). Diff = 0.13 points.
- **Decision:** Effect does not clear the claim rule; do not claim LS helps under this setup.
- **No claim** — diff 0.13, larger std 0.53
