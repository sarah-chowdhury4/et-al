# Demo script

Use these messages word for word in every run. Run each demo in a fresh room.
Two Mattermost windows side by side: **PI** (main account) on the left, **Student** on the right.

Before you start: the room has the coordinator, scout and experimenter, both people, the room instructions from `room/instructions.md`.

## 1. Idea

As the **PI**:

```
@coordinator New project: does label smoothing help a small network trained on noisy labels? Target is a workshop paper, deadline Dec 1. Experiments must run on my laptop CPU in under a minute each. Please set up a plan.
```

Wait for: the coordinator's Timeline (4 to 6 tasks, owners, dates before Dec 1) and its message to @scout.

## 2. Foundations

No message. Wait for the scout to fill the Literature document: 3 to 4 theories, about 10 numbered papers with OpenAlex links, ending with "@coordinator the papers are ready".

## 3. Dig

As the **PI**, pick the most interesting paper number from Literature (3 is used here):

```
@scout dig 3
```

Wait for 5 new numbered papers under "From paper 3". Then:

```
@scout summary 3
```

## 4. Methodology

Wait for the coordinator's Methodology draft (hypothesis, data and noise, model, metric, baseline, comparison, seeds, claim rule "not set", compute budget). Before the PI locks it, as the **Student**:

```
@coordinator 20% noise and 3 seeds cannot carry a workshop claim. Add a claim rule: we claim an effect only if label smoothing beats hard labels by more than the larger of the two standard deviations. Then ask the PI again.
```

Wait for the revised Methodology with the claim rule, still unlocked, asking the PI again. Then as the **PI**:

```
@coordinator Approved.
```

Wait for: "recorded in the Decisions log".

## 5. Baseline

As the **Student**:

```
@experimenter Can you set up a baseline following the Methodology?
```


Wait for: a first line with a time estimate, one-line progress updates as it works, then baseline.py written, run and debugged, the test accuracy, and a proposal asking the PI to approve.

## 6. The gate

As the **Student**:

```
@experimenter Approved.
```

Wait for the refusal naming the student's username, and the coordinator logging the refused attempt in the Decisions log. Then as the **PI**:

```
@experimenter Approved.
```

## 7. Results

No message. Wait for the 3-seed table (setting | mean accuracy | std), the line confirming it matched the Methodology, the claim rule verdict with its numbers, and "@coordinator".

## 8. Record

No message. Wait for the coordinator to update the Decisions log, mark tasks done in the Timeline, add a Lab notebook entry ending in "Claim" or "No claim" with the numbers, and name the next milestone. Done.

## Timing for the video

| Step | Typical wait | Speed up in edit? |
| --- | --- | --- |
| 1 to 2 | longest (scout reads ~10 records) | yes |
| 3 | medium | yes |
| 4 | short | no, the student's claim rule is a highlight |
| 5 | medium (writes and runs code) | yes |
| 6 | short | no, the refusal is the highlight |
| 7 to 8 | medium | yes |
