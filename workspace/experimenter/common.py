"""Shared setup that follows the locked Methodology (2026-11-07).

MNIST 5000 train / 1000 test subset, 40% symmetric label noise on train only,
MLP 784-256-10 ReLU, Adam lr=1e-3, batch 128, 5 epochs, metric = clean test acc (%).
"""
import os
import time

import numpy as np
import torch
import torch.nn as nn

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(HERE, "data", "mnist_subset.npz")

N_TRAIN, N_TEST = 5000, 1000
NOISE = 0.40
NUM_CLASSES = 10
LR, BATCH, EPOCHS = 1e-3, 128, 5
SEEDS = [0, 1, 2]
SUBSET_SEED = 12345  # fixed so every run sees the same 5k/1k images


def prepare_data():
    """Download MNIST once (original idx files) and cache the fixed 5k/1k subset."""
    if os.path.exists(DATA_FILE):
        return
    import gzip
    import urllib.request
    raw = os.path.join(HERE, "data", "raw")
    os.makedirs(raw, exist_ok=True)
    base = "https://ossci-datasets.s3.amazonaws.com/mnist/"
    names = ["train-images-idx3-ubyte", "train-labels-idx1-ubyte",
             "t10k-images-idx3-ubyte", "t10k-labels-idx1-ubyte"]
    arrs = []
    for n in names:
        path = os.path.join(raw, n + ".gz")
        if not os.path.exists(path):
            urllib.request.urlretrieve(base + n + ".gz", path)
        with gzip.open(path, "rb") as f:
            buf = f.read()
        if "images" in n:
            arrs.append(np.frombuffer(buf, np.uint8, offset=16).reshape(-1, 784))
        else:
            arrs.append(np.frombuffer(buf, np.uint8, offset=8))
    X = np.concatenate([arrs[0], arrs[2]]).astype(np.float32) / 255.0
    y = np.concatenate([arrs[1], arrs[3]]).astype(np.int64)
    # standard split: first 60k train, last 10k test
    rng = np.random.default_rng(SUBSET_SEED)
    tr = rng.choice(60000, N_TRAIN, replace=False)
    te = 60000 + rng.choice(10000, N_TEST, replace=False)
    np.savez_compressed(DATA_FILE, Xtr=X[tr], ytr=y[tr], Xte=X[te], yte=y[te])


def load_data():
    d = np.load(DATA_FILE)
    return d["Xtr"], d["ytr"], d["Xte"], d["yte"]


def add_symmetric_noise(y, rate, seed):
    """Flip `rate` fraction of labels to a different class, chosen uniformly."""
    rng = np.random.default_rng(seed)
    y = y.copy()
    n_flip = int(round(rate * len(y)))
    idx = rng.choice(len(y), n_flip, replace=False)
    offsets = rng.integers(1, NUM_CLASSES, size=n_flip)
    y[idx] = (y[idx] + offsets) % NUM_CLASSES
    return y


def make_model():
    return nn.Sequential(nn.Linear(784, 256), nn.ReLU(), nn.Linear(256, NUM_CLASSES))


def run(seed, label_smoothing):
    """Train one model and return clean test accuracy (%)."""
    torch.manual_seed(seed)
    np.random.seed(seed)
    torch.set_num_threads(min(8, os.cpu_count() or 1))
    Xtr, ytr, Xte, yte = load_data()
    ytr_noisy = add_symmetric_noise(ytr, NOISE, seed)
    Xtr_t, ytr_t = torch.from_numpy(Xtr), torch.from_numpy(ytr_noisy)
    Xte_t, yte_t = torch.from_numpy(Xte), torch.from_numpy(yte)

    model = make_model()
    opt = torch.optim.Adam(model.parameters(), lr=LR)
    loss_fn = nn.CrossEntropyLoss(label_smoothing=label_smoothing)
    g = torch.Generator().manual_seed(seed)
    for _ in range(EPOCHS):
        model.train()
        perm = torch.randperm(N_TRAIN, generator=g)
        for i in range(0, N_TRAIN, BATCH):
            b = perm[i:i + BATCH]
            opt.zero_grad()
            loss_fn(model(Xtr_t[b]), ytr_t[b]).backward()
            opt.step()
    model.eval()
    with torch.no_grad():
        acc = (model(Xte_t).argmax(1) == yte_t).float().mean().item() * 100
    return acc


def timed(fn):
    t0 = time.time()
    out = fn()
    return out, time.time() - t0
