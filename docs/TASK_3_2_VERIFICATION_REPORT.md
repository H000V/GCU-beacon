# Task 3.2 Verification Report: Drop-Oldest Invariant & Property Tests

**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Task Identifier:** Task 3.2 (Phase 3: In-Process Soak & Demo Release)  
**Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)  
**Reporting Date:** Week 9 (November 07, 2026)  
**Status:** **Completed.**

---

## 1. Summary

Task 3.1 proved with GNATprove that `Beacon.Queue` has no runtime errors, keeps its ring invariant and honours its `Count` contracts for every `Depth`. It did **not** prove that elements come out in FIFO order (see §7 of the [Task 3.1 report](TASK_3_1_VERIFICATION_REPORT.md)). Task 3.2 covers that gap, and the rest of the queue's observable behaviour, by testing.

The new suite, [`tests/src/queue_property_tests.adb`](../tests/src/queue_property_tests.adb), runs long pseudo-random operation sequences against `Beacon.Queue` and checks every step against a reference model. CI runs it on every push.

| Item | Value |
| :--- | :--- |
| Depths tested | 1, 2, 3, 4, 5, 7, 8, 9, 16, 31, 64, 100 |
| Operations per depth | 1,000,000 (12,000,000 total) |
| Run time | about 6 s on a laptop (`-O1 -gnata -gnatVa`) |
| Seed | 20261108 (fixed in CI). Depth *i* uses seed + *i* |
| Result | `all passed` |
| Seeded bugs caught | 4 of 4 (§5) |

## 2. Properties Checked

Every property is checked after **every** operation, not only at the end of a run.

| # | Property | How it is checked |
| :-: | :--- | :--- |
| P1 | **FIFO order.** Each `Pop` returns the oldest element still held. | The popped element (sequence number *and* random payload) must equal the model's front, and sequence numbers must strictly increase. |
| P2 | **Drop-oldest.** `Dropped` is True exactly when the queue was full, and the element lost is the oldest. | `Dropped` is compared with the model's fill level before the push. The model removes its front element, and later pops confirm the ring removed the same one. |
| P3 | **Head/tail consistency.** `Tail = (Head + Fill) mod Depth`. | Calls the visible `Invariant` function. The `Type_Invariant` on the full view (which also covers slot initialization) is checked at each call boundary because the suite is built with `-gnata`. |
| P4 | **Fill level.** | `Count`, `Is_Empty` and `Is_Full` must match the model. |
| P5 | **Accounting.** No message is lost without being counted. | `Pushed = Popped + Dropped + Count`. After the final drain, `Pushed = Popped + Dropped`. |
| P6 | **Contracts.** | `Push` on a full queue and `Pop` on an empty one must raise `Assertion_Error`, and the next step's checks confirm the queue is unchanged. |

## 3. Method

**Reference model.** The model is a plain array whose front is always element 1. `Pop` shifts the remaining elements down. It has no head, tail or modular arithmetic, so a wrap-around bug in the ring cannot be copied into the model.

**Operation generator.** Each step picks one of `Push`, `Push_Dropping_Oldest`, `Pop`, or a contract guard (P6). To make sure runs spend time at both boundaries and wrap many times, the generator switches between three randomly chosen *phases* (filling 80 % push, draining 20 % push, balanced 50 %), each lasting 1 to 4 × Depth + 4 steps. At Depth 100 a typical run was full about 169,000 times and empty about 102,000 times.

**Elements.** Each pushed element carries a sequence number and a random payload. If a stale slot were returned, its payload would not match, even when the sequence number happened to be plausible.

**Coverage gate.** A run of 1,000 or more operations fails if it never reached a full queue, never reached an empty queue, never took the drop path, or pushed fewer than 2 × Depth elements (no wrap). This stops a generator change from silently weakening the suite.

**Instantiation.** The generic is instantiated inside a loop, once per depth, so the same code tests every depth. `Depth` is not a static constant here, as in the Task 3.1 proof harness.

## 4. Reproducing a Failure

```
cd tests
alr -n build
./bin/queue_property_tests                 # default: seed 20261108, 1,000,000 ops per depth
./bin/queue_property_tests 42 5000         # another seed, shorter run
```

A failure prints the depth, seed and step, the property that broke, and the last 12 operations with the fill level before each. Running again with the same arguments reproduces it exactly. An unexpected exception (for example a failed `Type_Invariant` or postcondition) is reported the same way instead of aborting the suite. The process exits non-zero, which fails CI.

## 5. Does the Suite Catch Bugs? (Mutation Check)

Four bugs were seeded one at a time into a scratch copy of [`src/beacon-queue.adb`](../src/beacon-queue.adb). Every one was caught within the first few steps of a 20,000-op run:

| Mutant | Seeded bug | Caught by |
| :-: | :--- | :--- |
| M1 | On a drop, the new item overwrites the slot at the *new* Head (the second-oldest) instead of the old one | P1, depth 2, step 5 |
| M2 | `Dropped` is wrong when `Head = 0` | `Push` precondition, depth 1, step 2 |
| M3 | A drop does not advance Head (it loses the newest message instead) | `Type_Invariant` / ghost assertion, depth 2, step 4 |
| M4 | `Pop` reads the slot after Head | P1, depth 2, step 5 |

M1 and M4 keep the ring invariant and every count correct, so neither the proof nor the counters would notice them. Only the FIFO check (P1) catches them. That gap is what this task was meant to fill.

## 6. Limits and Decisions

* **Hand-rolled generator.** No mature property-based testing library exists in Alire, so the generator uses `Ada.Numerics.Discrete_Random`. It has no automatic shrinking. Instead the fixed seed, step number and operation trace make a failure easy to replay and cut down by hand.
* **Fixed seed in CI.** A red build always reproduces. A scheduled CI job with a random seed (printed in the log) would explore more inputs and is left as future work.
* **Single task.** The suite tests the data structure, which has no tasking of its own. Contention, the protected-object wrapper and `Dropped (Reliable) = 0` under load are Task 3.3. The "multi-core test host" resource was dropped from this task for that reason.
* **Element type.** Only a small non-limited record is tested. The generic formal is `private`, so limited types cannot be used anyway.
* **Testing, not proof.** FIFO order is now tested over 12 million operations, not proven. A Gold-level SPARK proof (a functional model in the contracts) is still a candidate for the spring phase.

## 7. Successor Hand-off: Task 3.3

Task 3.3 (Multi-Task Sustained Soak Stress Test) can rely on the queue's single-task behaviour being covered by P1–P6. Any failure under load can then be attributed to `Beacon.Topic`'s protected wrapper or to scheduling, not to the ring arithmetic.
