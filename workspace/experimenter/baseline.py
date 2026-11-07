"""Baseline: hard-label cross-entropy, MNIST 5k/1k, 40% symmetric noise, seed 0."""
import time

from common import prepare_data, run, NOISE, SEEDS

if __name__ == "__main__":
    t0 = time.time()
    prepare_data()
    acc = run(seed=SEEDS[0], label_smoothing=0.0)
    print(f"baseline (hard CE, noise={NOISE:.0%}, seed={SEEDS[0]}): test accuracy = {acc:.2f}%")
    print(f"elapsed: {time.time() - t0:.1f}s")
