# Code Review Follow-Up: Coverage of Required Changes

**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada
**Prepared:** 11/06/2026 (Week 9)
**Status:** Decisions recorded 11/06/2026 (Part 3). Applied to `beacon.md`, the WBS, `beacon.gantt`, the schedule matrix and the charter (v1.11).

The 11/06 repository review produced a list of code and Jorvik-compliance changes. This report checks each change against the future tasks in [`beacon.md`](beacon.md):

- Changes that fit an existing task were added to that task in `beacon.md`, under **⚠ Code Review Changes Required (11/06/2026)**.
- Changes with **no task** are in Part 2. Each one needs a decision: add a task, fold it into an existing one, or accept the risk and document it.

---

## Part 1: Changes Already Covered by a Task

| # | Change | Kind | Covered by | Lead |
| :-: | :--- | :--- | :--- | :--- |
| 1 | Multi-task test showing `Publish` blocks on a full `Reliable` queue and resumes when drained | Missing test | **Task 2.4** (in progress, past its 11/01 date) | Praise Jibunor |
| 2 | `Beacon.Topic` fails Jorvik: function calls in entry barriers (`Pure_Barriers`) | Compliance | **Task 3.4** | Hovan Hodges |
| 3 | Timed `Receive` uses `select ... or delay`, which Jorvik forbids (`No_Select_Statements`) | Compliance / design | **Task 3.4** (moves to a `Beacon.Topic.Timed` child package) | Hovan Hodges |
| 4 | CI step that compiles the core under `pragma Profile (Jorvik)` | Regression guard | **Task 3.4** | Hovan Hodges |
| 5 | Sustained multi-task load, `Dropped (Reliable) = 0` | Missing test | **Task 3.3** (no change; its scope already matches) | Ryan Tomasko |
| 6 | `Wire.Header` alignment is 4 but overlaid at any byte offset | Portability | **Task 4.1** | Praise Jibunor |
| 7 | Missing wire tests: `Bad_Magic`, trailing bytes, maximum payload, odd-offset frame, codec round trip | Missing tests | **Task 4.2** | Ryan Tomasko |
| 8 | UDP: a selector created on every `Receive`, a socket leaked if `Open` fails, `Socket_Error` after `Check_Selector`, a double copy in `Send` | Robustness | **Task 4.3** | Praise Jibunor |
| 9 | Bridge registration race: `Create_Subscriber` / `Create_Publisher` run after the `accept` | **Bug** | **Task 4.4** | Praise Jibunor & Hovan Hodges |
| 10 | Bridge tasks die silently (no exception handlers) | **Bug** | **Task 4.4** | Praise Jibunor & Hovan Hodges |
| 11 | Ingress ignores the `Try_Publish` result, so messages it drops are not counted | Observability | **Task 4.4** | Praise Jibunor & Hovan Hodges |
| 12 | A second `Start_*` replaces the first task; `Rejected` and `Gaps` can overflow; egress busy-polls | Robustness | **Task 4.4** | Praise Jibunor & Hovan Hodges |
| 13 | CI UDP step can fail intermittently (caused by #9, not by UDP loss) | CI reliability | **Task 4.6** (after #9 lands) | Ryan Tomasko |

The use-after-free after `Bridge.Stop` is listed under Task 4.4. With the decisions in Part 3, Task 4.4 fixes it inside the bridge: the egress subscriber moves to library level and keeps draining after `Stop`.

Leads in this table follow the task owners named in the status reports (decision 9 in Part 3).

---

## Part 2: Changes With No Task (Need a Decision)

### U-1. A way to unregister a subscriber (Open Decision #4)

**Problem.** `Create_Subscriber` stores `S'Unchecked_Access` in a fixed registry ([`src/beacon-topic.adb`](../src/beacon-topic.adb) line 119), and nothing can remove it. If a subscriber goes out of scope, the next `Publish` uses freed memory.

The bridge already does this. The egress subscriber is a local variable of a task ([`src/net/beacon-bridge.adb`](../src/net/beacon-bridge.adb) line 20). After `Bridge.Stop` the task ends and its entry in the registry points at freed memory. With a `Reliable` egress, the publisher can also block forever on a queue nobody drains.

**Why no task covers it.** Task 1.3 discussed it, but no implementation task was created. Task 4.4 only touches `src/net/`, and the fix belongs to the core API in `src/beacon-topic.*`.

**Proposed change.**
- Add `procedure Delete_Subscriber (S : in out Subscriber)` with `Pre => Is_Registered (S)`. It removes `S` from the registry and closes the gap.
- Under the current "registration happens at startup" rule, it must not run while a `Publish` is in progress. Decide that together with U-2.
- An alternative is to make the bridge declare its egress subscriber at library level, inside the generic body, so it lives as long as the program. That avoids the dangling access, but `Stop` still leaves a `Reliable` egress that nobody drains.

**Risk if deferred.** Milestone 3's cross-process demo calls `Stop`. Any code that publishes after it stops relies on erroneous behavior.

**Suggested home.** A new **Task 3.7: Subscriber Lifecycle (Unregister)**, Hovan Hodges, about 8 hours, before Task 4.4. Or extend Task 4.4 to cover `src/beacon-topic.*` and add about 8 hours to it.

**Decision (11/06/2026).** New **Task 3.7: Subscriber Lifecycle & Registry Lockdown** (with U-2). `Delete_Subscriber` is for startup and shutdown only, because it must not run once the registry is locked. The bridge therefore uses the library-level alternative above, and its egress keeps draining after `Stop`.

---

### U-2. Registry protection, or lockdown after the first `Publish` (Open Decision #2, FR-07)

**Problem.** The registry is an unprotected array. Correctness depends on a documented rule ("register before any `Publish`, from one task") that nothing enforces. The stakeholder directive behind FR-07 asks for "publisher registry lockdown". Only the publisher half exists: a second `Create_Publisher` is refused. Nothing stops a subscriber registering in the middle of a run.

**Why no task covers it.** Task 1.3 marked it as resolved, but no implementation task exists. The slides and speaker notes were corrected on 11/06 to call it "planned".

**Proposed change.** Pick one:
1. **Lockdown.** A package-level `Locked` flag, set by the first `Publish` or `Try_Publish`. `Create_Subscriber` (and `Delete_Subscriber` from U-1) get `Pre => not Locked`. This is cheap, and the contracts make it checkable.
2. **Protected registry.** Move `Registry` and `Registered` into a protected object, so registering at any time is safe. This costs a protected call on every `Publish`, and Jorvik limits must be respected (see Task 3.4).

Option 1 matches the static-configuration design (design rule 4) and the FR-07 wording.

**Risk if deferred.** The Task 4.4 registration race is one instance of this class of bug, and the next one won't be caught at compile time or by a contract.

**Suggested home.** Fold it into U-1's new task (same files, same owner), about 4 more hours. Add a test to `topic_tests` that shows the precondition fails after the first `Publish`.

**Decision (11/06/2026).** Option 1, the lockdown flag, in Task 3.7.

---

### U-3. Configurable `Try_Publish` delivery policy (Open Decision #1, FR-08)

**Problem.** FR-08 and the stakeholder feedback form describe a configurable `Try_Publish`, either partial delivery or all-or-nothing. The code only does partial delivery. The 11/06 doc fix marked FR-08 as "(Planned)", but no task delivers it.

**Proposed change.** Add a generic formal `Try_Publish_Policy : Delivery_Policy := Partial` to `Beacon.Topic`. An all-or-nothing `Try_Publish` must check that every `Reliable` queue has room before pushing to any of them. With one queue per subscriber, those checks happen one protected call at a time, so they can't be done in a single step. The design has to accept a narrow window where a queue fills between the check and the push, or use a single publisher-side lock. That needs a short design note first.

**Risk if deferred.** A requirement listed in the charter and presented at Design Review 1 is missing, and someone will notice at Design Review 2.

**Suggested home.** Either a spring task, or formally drop or defer FR-08 with a documented rationale. Cheapest path: record the deferral in the charter's requirements matrix now.

**Decision (11/06/2026).** Formally deferred to Spring 2027. The deferral and its rationale are recorded under Appendix A of the charter (v1.11). It will be scheduled in the Phase 6 re-plan.

---

### U-4. An in-memory loopback transport for bridge tests

**Problem.** Every Task 4.4 fix (registration race, exception handling, ingress drop counter, restart guard) can only be tested today through real UDP multicast. That is timing-dependent, and some CI runners don't support it. [`ARCHITECTURE.md`](../ARCHITECTURE.md) and [`src/net/beacon-transport.ads`](../src/net/beacon-transport.ads) both suggest a loopback transport as "a good first thing to write for tests", but no task does it.

**Proposed change.** Add `Beacon.Transport.Loopback`: a bounded in-memory frame queue that implements `Send` and `Receive (Timeout)`. Then add `tests/src/bridge_tests.adb`, which runs egress and ingress in one process and checks the counters exactly, including a fault-injection transport that raises on `Receive`.

**Suggested home.** Add it to Task 4.2 (test suite) or as a new **Task 4.2b**, Ryan Tomasko, about 10 hours, before Task 4.4 so the bridge fixes can be tested as they land.

**Decision (11/06/2026).** New **Task 4.2b: In-Memory Loopback Transport & Bridge Tests**, Ryan Tomasko, 10 hours, Nov 23 – Nov 29, before Task 4.4.

---

### U-5. Spring schedule re-plan after the early SPARK proof (schedule only, no code)

**Problem.** As of 11/06, `Beacon.Queue` is fully proved: 71 of 71 checks, `Relaxed_Initialization` applied, and the proof running in CI through [`prove/prove.gpr`](../prove/prove.gpr). The spring Phase 6.2 tasks in [`beacon.gantt`](beacon.gantt) still schedule this work for February 2027:
- W20 "SPARK Annotations & Relaxed_Initialization"
- W20 "Formal Contracts on Push, Pop, and Ring Index"
- W21 "GNATprove Silver Proof Index & Bounds Safety"
- W21 "Automated SPARK Proof CI Workflow Setup"
- W22 "Discharge 100% Silver Verification Conditions"

**Still open in that phase:** W22 "GNATprove Proof of Drop-Oldest Preservation". The proof does not yet show that elements come out in FIFO order, or that drop-oldest removes exactly the oldest element (Gold level).

**Proposed change.** Re-scope P6.2 to:
1. a functional (Gold) proof of FIFO order and drop-oldest, using a ghost model of the queue's contents;
2. extending SPARK to the parts of `Beacon.Topic` outside its protected bodies, if desired.

This frees roughly 3 weeks of spring capacity, which could go to U-1 through U-3 if they are deferred.

**Decision (11/06/2026).** Re-plan at the end of the fall semester, together with scheduling the deferred FR-08 (U-3). `beacon.gantt` keeps the current P6.2 entries until then; the charter notes that Silver was completed early.

---

## Part 3: Decisions (11/06/2026)

| # | Question | Decision | Where it was applied |
| :-: | :--- | :--- | :--- |
| 1 | Home for U-1 and U-2 | New **Task 3.7: Subscriber Lifecycle & Registry Lockdown**, Hovan Hodges, 12 hours, Nov 16 – Nov 22. Predecessor Task 3.4; successors Task 3.6 and Task 4.4. | `beacon.md`, WBS, gantt, matrix |
| 2 | Registry protection (U-2) | **Lockdown flag.** The first `Publish` or `Try_Publish` locks the registry; `Create_Subscriber` and `Delete_Subscriber` require `not Is_Locked`. | Task 3.7 |
| 3 | Timed `Receive` under Jorvik | **Move it to a full-tasking child package, `Beacon.Topic.Timed`.** The core compiles under Jorvik; desktop builds keep the feature. The Jorvik CI step excludes the child package. | Task 3.4 |
| 4 | Configurable `Try_Publish` (U-3, FR-08) | **Formally deferred** to Spring 2027, with the rationale recorded in the charter. | Charter v1.11, Appendix A |
| 5 | Bridge egress after `Stop` (follows from 2) | **Library-level egress subscriber that keeps draining after `Stop`.** The egress `Mode` becomes a generic formal of `Beacon.Bridge`. | Task 4.4 |
| 6 | Home for U-4 | New **Task 4.2b: In-Memory Loopback Transport & Bridge Tests**, Ryan Tomasko, 10 hours, Nov 23 – Nov 29. Predecessor Task 4.1; successor Task 4.4. | `beacon.md`, WBS, gantt, matrix |
| 7 | Spring P6.2 re-plan (U-5) | **At the end of the fall semester**, together with FR-08. | Charter schedule note |
| 8 | Task 3.4 estimate | **24 hours** (from 16). | `beacon.md`, WBS |
| 9 | Task owners | **The status reports are the source of truth.** Task 2.2 and Task 2.4 → Praise Jibunor; Task 2.3, Task 3.1 and Task 3.4 → Hovan Hodges; Task 3.5 → Praise Jibunor. | `beacon.md`, WBS |
| 10 | Charter vs. WBS schedule | **The WBS wins.** The charter's 32-week table was replaced with the WBS phases (28 weeks, Milestones 1–8). Milestone 1 now follows Task 1.3, and Milestone 4 follows Milestone 3, because each presentation date falls before the tasks that used to be listed as its predecessors finished. | Charter v1.11, `beacon.md`, WBS |
| 11 | WBS sync | **Mirror everywhere:** the notes and new tasks are in `beacon.md`, the WBS, `beacon.gantt` and the schedule matrix. | All four |
| 12 | Presentation length | **15 minutes.** The speaker notes were re-timed from 17:45. Slide order differences across the three presentation documents are left for the team. | `SPEAKER_NOTES.md` |

The hour figures are rough and come from the size of each change.
