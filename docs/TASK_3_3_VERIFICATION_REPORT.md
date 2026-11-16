# Task 3.3 Verification Report: Multi-Task Sustained Soak Stress Test

**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Task Identifier:** Task 3.3 (Phase 3: In-Process Soak & Demo Release)  
**Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)  
**Reporting Date:** Week 10 (November 15, 2026)  
**Status:** **Completed** (correctness criteria). Timing criteria are measured and reported but not gated; see §6.

---

## 1. Summary

Task 3.2 covered `Beacon.Queue` in a single task. Task 3.3 puts the protected wrapper in `Beacon.Topic` under real contention, at 1 kHz and unpaced, for minutes at a time, and checks that no message is lost, duplicated, reordered or corrupted.

The new suite, [`tests/src/topic_soak_tests.adb`](../tests/src/topic_soak_tests.adb), runs in CI on every push (10 s paced + 1,000,000-message floods, about 16 s).

| Item | Value |
| :--- | :--- |
| Queue depth | 8 |
| Tasks per scenario | 1 publisher, up to 4 subscribers, 1 monitor (plus a global watchdog) |
| Concurrency | Phase 1: paced alone. Phase 2: `flood` and `try_flood` at the same time (two publisher tasks, six subscriber tasks) |
| Long run (Windows 11 laptop) | 600 s at 1 kHz (600,000 messages) + 5,000,000 `Publish` + 5,000,000 `Try_Publish` |
| `Dropped (Reliable)` | **0** in every scenario and every run |
| Lost / reordered / corrupted messages | **0** |
| Memory during the 600 s soak | Working set 5,424 – 5,528 KiB, private bytes 1,096 – 1,164 KiB (no growth trend) |
| Seeded bugs caught | 4 of 4 (§5) |
| Result | `all passed` |

## 2. Scenarios

Each scenario is a fresh instantiation of `Beacon.Topic` (the procedure that runs it instantiates the generic locally), so each has its own registry and publisher.

| Scenario | Publisher | Subscribers |
| :--- | :--- | :--- |
| `paced` | `Publish` on a `delay until` schedule at 1 kHz for *N* s (default 10) | Reliable fast, Reliable stalling (5 ms every 100 msgs), Best_Effort fast, Best_Effort stalling (20 ms every 100 msgs) |
| `flood` | `Publish` as fast as possible, *M* messages (default 1,000,000) | Same four; both stalling consumers pause 1 ms every 5,000 msgs |
| `try_flood` | `Try_Publish` as fast as possible, *M* messages | Reliable stalling, Best_Effort fast |

At 1 kHz a depth-8 queue absorbs an 8 ms stall. The paced Reliable stall (5 ms) is meant to fit inside that and the Best_Effort stall (20 ms) is not, so Best_Effort must drop. In `flood` the stalling Reliable subscriber fills its queue, so `Publish` must block and then resume (the Task 2.4 behaviour, here under sustained load).

Each message carries its sequence number, a checksum of that number, and its send time. The publisher ends every scenario with an end marker sent by blocking `Publish`. It is the newest message, so a Best_Effort queue never drops it.

## 3. Properties Checked

| # | Property | How it is checked |
| :-: | :--- | :--- |
| S1 | `Dropped (Reliable) = 0` | `T.Dropped` read by each Reliable subscriber after the end marker. |
| S2 | Reliable: every message arrives, once, in order | Sequence gaps are summed. The total must be 0, or, in `try_flood`, exactly the number of refusals `Try_Publish` reported. `Received = Published + 1 − gaps`. |
| S3 | Best_Effort accounting | Arrivals strictly increase, the gap total equals `Dropped`, and `Received + Dropped = Published + 1`. |
| S4 | No corruption | Every message's checksum must match its sequence number. |
| S5 | Liveness and clean end | Every subscriber gets the end marker and finishes with an empty queue. A watchdog task exits with status 1 if the run takes far longer than expected (deadlock or livelock). |
| S6 | Coverage | `paced` published exactly Rate × Seconds; the stalling Best_Effort subscriber dropped; in `flood` the Reliable queue was seen full; in `try_flood` `Try_Publish` was refused at least once. |
| S7 | Memory stability | Linux: resident set size read from `/proc/self/statm` once a second after a 1 s warm-up must not grow by more than 1 MiB. Other OSes print "n/a". |

S2 is stronger than S1. Mutant M1 (§5) overwrites messages in a Reliable queue without counting them, so `Dropped (Reliable)` still reads 0. Only the end-to-end sequence check catches it.

## 4. Results

### 4.1 Long run: `topic_soak_tests 600 5000000` (Windows 11, GNAT via Alire, `-O1 -gnata -gnatVa`)

| Scenario | Published | Subscriber | Received | Dropped | Missing | Latency mean / p99 / max |
| :--- | --: | :--- | --: | --: | --: | :--- |
| paced (600 s) | 600,000 | Reliable fast | 600,001 | **0** | 0 | 42 µs / <256 µs / 25.4 ms |
| | | Reliable stall | 600,001 | **0** | 0 | 967 µs / <16.4 ms / 43.7 ms |
| | | Best_Effort fast | 598,293 | 1,708 | 1,708 | 144 µs / <1 ms / 30.3 ms |
| | | Best_Effort stall | 535,251 | 64,750 | 64,750 | 1.3 ms / <16.4 ms / 35.2 ms |
| flood | 5,000,000 | Reliable fast | 5,000,001 | **0** | 0 | 18 µs / <128 µs / 10.2 ms |
| | | Reliable stall | 5,000,001 | **0** | 0 | 39 µs / <256 µs / 19.2 ms |
| | | Best_Effort fast | 4,688,088 | 311,913 | 311,913 | 28 µs / <256 µs / 21.0 ms |
| | | Best_Effort stall | 4,003,124 | 996,877 | 996,877 | 37 µs / <256 µs / 24.8 ms |
| try_flood | 5,000,000 (3,312,082 refused) | Reliable stall | 1,687,919 | **0** | 3,312,082 = refusals | 26 µs / <128 µs / 16.7 ms |
| | | Best_Effort fast | 3,558,749 | 1,441,252 | 1,441,252 | 10 µs / <64 µs / 4.0 ms |

Received counts include the end marker. Wall time 11 min 39 s. CPU: about 10 % of one core at 1 kHz, about 150 % during the floods.

### 4.2 CI defaults: `topic_soak_tests` (10 s paced, 1,000,000-message floods)

`all passed` in 16 s on the same laptop. The figures follow the same pattern as §4.1.

### 4.3 Memory

The Windows build cannot read `/proc`, so the 600 s run was sampled from outside every 15 s (`Get-Process`: working set and private bytes):

| Window | Working set | Private bytes |
| :--- | :--- | :--- |
| Paced soak, 39 samples from 15 s to 600 s | 5,424 – 5,528 KiB | 1,096 – 1,164 KiB |
| Whole run, including both floods | max 5,568 KiB | max 1,200 KiB |

The values move within about 100 KiB and do not trend upward. That is consistent with Beacon's no-heap design. The in-process S7 check runs on Linux CI. The full zero-heap audit (`gnatmem`, Jorvik) remains Task 3.4.

### 4.4 Timing on Windows (finding)

The 1 kHz publisher was more than one period late on 540,492 of 600,000 releases (mean lateness 6.9 ms, p99 under 16.4 ms, max 58.7 ms). The 16 ms bucket matches the default Windows timer tick (15.6 ms): `delay until` cannot wake more often than that unless the process raises the timer resolution, and the GNAT runtime does not do this here. The publisher still made up the lost releases, because it schedules against absolute times, so exactly 600,000 messages went out.

A side effect is that the paced Reliable stall, a 5 ms `delay`, actually lasts about 15 ms on Windows, longer than the 8 ms the queue absorbs. So on Windows the paced Reliable queue fills too (seen full 3,013 times) and `Publish` blocks. Correctness is unaffected (S1–S5 pass), but **Windows desktop timing figures say nothing about Beacon's own latency.** Use the Linux CI log for timing. This is risk R-05 as logged in Week 9.

## 5. Does the Suite Catch Bugs? (Mutation Check)

Four bugs were seeded one at a time into a scratch copy of [`src/beacon-topic.adb`](../src/beacon-topic.adb), each run with `topic_soak_tests 2 100000`. The unmutated control passed.

| Mutant | Seeded bug | Caught by |
| :-: | :--- | :--- |
| M1 | Reliable `Push` barrier always open; a full Reliable queue overwrites its oldest without counting it | S2 (missing messages), 10 failures. `Dropped (Reliable) = 0` still passed |
| M2 | Reliable `Try_Push` on a full queue reports Accepted but does not store the message | S2 (gaps ≠ refusals) and S6, 3 failures |
| M3 | Best_Effort `Push` does not count its drops | S3 (gaps ≠ Dropped) and S6, 10 failures |
| M4 | `Publish` uses `Try_Push`, so it skips a full Reliable queue instead of blocking | S2 (missing messages), 9 failures |

## 6. Limits and Decisions

* **Timing is reported, not gated.** The WBS description asks for "zero latency spikes". A desktop OS gives no scheduling guarantee, and §4.4 shows a 16 ms timer tick on Windows. A timing gate would make CI flaky. The suite reports lateness and latency (mean, p99 bucket, max) and the count of overrun periods. *Decision (11/15/2026):* timing stays reported, not gated, and the WBS wording is left unchanged.
* **Windows timer resolution not raised.** The test could call `timeBeginPeriod(1)` so that Windows timing figures mean something. *Decision (11/15/2026):* not for now. It would be a test-only, OS-specific workaround. Tracked under risk R-05.
* **One publisher per topic.** `Beacon.Topic` allows one `Publisher` per instantiation (single-writer rule), so "multi-task" here means one publisher with several subscribers per topic, and two topics publishing at the same time in phase 2. Several tasks sharing one `Publisher` are not tested, because the design rules that out (confirmed 11/15/2026).
* **CI cost.** The defaults add about 16 s per push (confirmed 11/15/2026). A weekly scheduled Linux run of `topic_soak_tests 600 5000000` is an optional follow-up. It would also give Linux timing figures.
* **Default priorities.** All tasks run at the default priority under `Ceiling_Locking`. Real-time priorities need elevated rights on Linux and are not available on hosted CI.
* **RSS page size.** S7 assumes 4 KiB pages (x86-64 Linux, which is what CI uses).
* **The watchdog limit** is about 20× the expected run time: 120 s + 2 × paced seconds + flood messages / 10,000.

## 7. Reproducing

```
cd tests
alr -n build
./bin/topic_soak_tests                 # CI defaults: 10 s at 1 kHz, 1,000,000-message floods
./bin/topic_soak_tests 600 5000000     # the long run in §4.1
```

A failing check prints `FAIL` with the subscriber and property. The process exits non-zero, which fails CI.

## 8. Successor Hand-off

* **Task 3.4 (Zero-Heap & Jorvik Audit):** no memory growth was seen under sustained load (§4.3). Task 3.4 landed first (commit `c0e0ad7`: pure entry barriers, timed `Receive` moved to `Beacon.Topic.Timed`). This suite was re-run against it on 11/15/2026 at CI defaults and passed with the same pattern as §4.2. Mutants M1–M4 show it catches the kind of mistake those edits could introduce. The result is recorded in the Task 3.4 entry of the WBS and `beacon.md`.
* **Task 3.5 (Flight Telemetry Demo):** the demo can quote the §4.1 figures. Timing figures should come from Linux.
