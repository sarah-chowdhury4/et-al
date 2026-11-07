"""Comparison: hard CE vs label smoothing eps=0.1, seeds 0,1,2 (per Methodology)."""
import time

import numpy as np

from common import prepare_data, run, NOISE, SEEDS

SETTINGS = [("hard CE", 0.0), ("label smoothing eps=0.1", 0.1)]

if __name__ == "__main__":
    t0 = time.time()
    prepare_data()
    results = {}
    for name, eps in SETTINGS:
        accs = [run(seed=s, label_smoothing=eps) for s in SEEDS]
        results[name] = accs
        print(f"{name}: per-seed {['%.2f' % a for a in accs]}")
    print(f"\nnoise={NOISE:.0%}, seeds={SEEDS}, metric=clean test accuracy (%)")
    print(f"{'setting':<26}{'mean':>8}{'std':>8}")
    stats = {}
    for name, accs in results.items():
        m, sd = float(np.mean(accs)), float(np.std(accs, ddof=1))
        stats[name] = (m, sd)
        print(f"{name:<26}{m:>8.2f}{sd:>8.2f}")
    (m0, s0), (m1, s1) = stats["hard CE"], stats["label smoothing eps=0.1"]
    diff, thr = m1 - m0, max(s0, s1)
    print(f"\nclaim rule: diff (LS - CE) = {diff:.2f}, larger std = {thr:.2f} -> "
          f"{'CLAIM' if diff > thr else 'NO CLAIM'}")
    print(f"elapsed: {time.time() - t0:.1f}s")
