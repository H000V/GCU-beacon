# Task 3.4 Verification Report: Zero-Heap & Embedded Jorvik Audit

* **Lead Engineer:** Hovan Hodges (Core Systems Engineer)
* **Date:** November 12, 2026
* **Scope:** the core, `src/` built with `BEACON_NETWORK=no` (`Beacon`, `Beacon.Queue`, `Beacon.Topic`). `src/net/` is desktop-only and out of scope.

## 1. Result

| Claim | Status | Evidence |
| :--- | :--- | :--- |
| The core compiles under `pragma Profile (Jorvik)` | Verified | `jorvik/jorvik.gpr` builds with GNAT 16.1.0 |
| An instance of `Beacon.Topic` runs under the profile | Verified on the native runtime | `jorvik_check`, 10 checks pass |
| The core uses no allocator and no implicit heap allocation | Verified at compile time | `No_Allocators`, `No_Implicit_Heap_Allocations` |
| The core uses no secondary stack | Verified at compile time | `No_Secondary_Stack` |
| The check fails when the rules are broken | Verified for barriers, `select` and allocators | Section 4 |
| The timed `Receive` still works | Verified | `topic_timed_tests`, 6 checks pass |

Not done: no run on an embedded Jorvik runtime or a target board, and no `gnatmem` run (Section 5).

## 2. Code changes

**Pure barriers.** Jorvik's `Pure_Barriers` forbids a function call in an entry barrier. The barriers of `Bounded_Queue` called `Ring.Is_Full` and `Ring.Is_Empty`. The protected type now holds two Boolean components, `Full` and `Empty`, and a local procedure, `Refresh_Flags`, sets them from the ring after every operation that changes the queue (`Push`, `Try_Push`, `Pop`, `Try_Pop`). The barriers are now:

```ada
entry Push (Msg : Message_Type) when Mode = Best_Effort or else not Full
entry Pop (Msg : out Message_Type) when not Empty
```

The flags are derived from the proved ring, not maintained by hand, so they cannot drift from `Count`.

**Timed `Receive`.** The `select ... or delay` violated `No_Select_Statements`. The procedure moved, unchanged, into a generic child package:

```ada
package T is new Beacon.Topic (...);
package T_Timed is new T.Timed;
T_Timed.Receive (Sub, Msg, Milliseconds (10), Got);
```

`Beacon.Topic` no longer depends on `Ada.Real_Time`. This is a breaking API change for callers of the four-parameter `Receive`. The only callers were the Task 2.2 timeout tests, which moved to `tests/src/topic_timed_tests.adb`. The demos and `Beacon.Bridge` use `Try_Receive` and did not change. The bridge egress will adopt `Beacon.Topic.Timed` in Task 4.4.

**Profile position.** Jorvik is the supported light-tasking profile. Ravenscar is out of reach by design: `Bounded_Queue` has two entries and Ravenscar sets `Max_Protected_Entries = 1`.

## 3. The check

`jorvik/jorvik.gpr` builds the core sources and a library-level instance (`jorvik/src/jorvik_topics.ads`) under `jorvik/jorvik.adc`:

```ada
pragma Profile (Jorvik);
pragma Restrictions (No_Allocators);
pragma Restrictions (No_Implicit_Heap_Allocations);
pragma Restrictions (No_Secondary_Stack);
```

It excludes `src/net/` and `Beacon.Topic.Timed`. An instance is needed because GNAT checks `Pure_Barriers` when it expands a protected body, which does not happen for a generic template on its own. The program `jorvik_check` then runs both entries, the overflow path of each delivery mode, and the reopening of each barrier.

CI runs it on every push (step "Jorvik profile and zero-heap check of the core"):

```
alr exec -- gprbuild -P jorvik/jorvik.gpr
./jorvik/bin/jorvik_check
```

## 4. Negative controls

Each control was run on a scratch copy of the sources on November 12, 2026.

| Change made to the copy | Result |
| :--- | :--- |
| `Beacon.Topic` as it was before this task | Rejected: `Pure_Barriers` at lines 12 and 43, `No_Select_Statements` at line 137 |
| An allocator (`new Subscriber (Reliable)`) added to the body of `Beacon.Topic` | Rejected: `No_Allocators` and `No_Protected_Type_Allocators` |

No control was run for `No_Secondary_Stack`. The restriction is active and the core compiles under it, but it was not shown to reject a violation.

## 5. Deviations from the plan

* **`gnatmem` was not used.** The work breakdown structure names `gnatmem` for the heap audit. It is not part of the Alire GNAT 16.1.0 toolchain used by the team and by CI. The compile-time restrictions replace it. They are stronger in one way: `gnatmem` reports the allocations of one run, while the restrictions reject every allocator and implicit heap allocation in the core on every build. They are weaker in another: they say nothing about the runtime library's own allocations (for example at task creation), which `gnatmem` would show.
* **No embedded runtime.** The check runs on the native runtime, as the task text allows. The restrictions are the same ones an embedded Jorvik runtime enforces, but timing, stack sizes and ceiling priorities on a real target are untested.
* **Stack use was not measured.** `-fstack-check` stays on for the library and the check. No worst-case stack figure was produced.
* **Task 3.3 had not landed.** The soak test is the listed predecessor and is not in the repository yet. It should be run against these barriers when it lands.

## 6. Test results (Windows 11, GNAT 16.1.0, November 12, 2026)

| Program | Result |
| :--- | :--- |
| `alr build` and `BEACON_NETWORK=no alr build` | Pass |
| `jorvik_check` | Pass, 10 checks |
| `queue_tests`, `queue_property_tests`, `wire_tests` | Pass |
| `topic_tests` | Pass |
| `topic_timed_tests` | Pass, 6 checks |
| `inproc_demo` | Pass (reliable: 20 published, 20 received, 0 dropped) |

Not run locally: the two-process UDP demo and the GNATprove step. `Beacon.Queue` was not changed, so its proof is unaffected. The new CI step has not run on GitHub yet.
