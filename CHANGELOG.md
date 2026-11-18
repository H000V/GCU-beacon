# Changelog

All notable changes to beacon are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0-inproc] - 2026-11-18

First tagged release: the in-process core, verified. It covers
everything since the GAP seed (commit `c7e44fd`). The in-process
library (`src/`) is what this release claims. The network code
(`src/net/`: wire framing, UDP transport, bridge) ships as an
experimental preview; Phase 4 has not started on it.

### Added

- Timed receive: `Receive (S, Msg, Timeout, Success)` returns after
  `Timeout` if no message arrives. It lives in the child package
  `Beacon.Topic.Timed` (see Changed).
- Ceiling priority on the protected queue. `Beacon.Topic` takes a
  `Ceiling_Priority` generic parameter (default `System.Priority'Last`),
  and `gnat.adc` sets `Ceiling_Locking` and `Priority_Queuing`.
- Registry lockdown (FR-07). The first `Publish` or `Try_Publish` locks
  the subscriber registry for the rest of the program. `Is_Locked`
  reports it, and `Create_Subscriber` after the lock fails its
  precondition.
- `Delete_Subscriber` removes a subscriber before the first `Publish`
  and frees its slot.
- `Beacon.Queue` is proved with GNATprove for every `Depth`: all 71
  checks, through the harness in `prove/prove.gpr`. This covers absence
  of runtime errors and the ring type invariant. FIFO order is tested,
  not proved.
- `jorvik/`: builds and runs an instance of `Beacon.Topic` under
  `pragma Profile (Jorvik)` with `No_Allocators`,
  `No_Implicit_Heap_Allocations` and `No_Secondary_Stack`.
- Test suites, all run in CI:
  - `queue_property_tests`: 1,000,000 random operations at each of 12
    depths, checked against a reference model.
  - `topic_soak_tests`: a 1 kHz soak, then concurrent `Publish` and
    `Try_Publish` floods. Checks `Dropped (Reliable) = 0` and in-order,
    exactly-once Reliable delivery.
  - `topic_timed_tests`: the timed receive.
  - `topic_tests`: a publisher task blocks on a full Reliable subscriber
    and resumes when it drains; registry lockdown and
    `Delete_Subscriber`.
- `inproc_demo` is now a flight telemetry scenario: attitude at 1 kHz,
  a 100 Hz control loop, power at 5 Hz and ground commands at 10 Hz,
  with ten checks and a non-zero exit status on failure.
- `.gitattributes` forces LF line endings, so Windows checkouts build.

### Changed

- **Breaking:** the four-parameter `Receive` moved from `Beacon.Topic`
  to the generic child `Beacon.Topic.Timed`, because its `select` is
  not allowed under Jorvik. Instantiate it next to the topic:

  ```ada
  package T is new Beacon.Topic (Reading, 32);
  package T_Timed is new T.Timed;
  T_Timed.Receive (Sub, Msg, Milliseconds (10), Got);
  ```

- **Breaking:** the preconditions of `Beacon.Topic` are checked in
  every build, even without `-gnata`. Code that registered a subscriber
  after publishing used to run; it now raises
  `Ada.Assertions.Assertion_Error`.
- The entry barriers of the protected queue read Boolean components
  instead of calling functions, as `Pure_Barriers` requires.
- Best_Effort drop counters saturate at `Natural'Last` instead of
  raising `Constraint_Error`.
- `Beacon.Bridge`: the bridge tasks register their subscriber inside
  the accept body, and `Start_Egress` requires `not Is_Locked`. This
  closes a race with the registry lock.
- `LICENSE` is the official Apache-2.0 text, and `NOTICE` was added.

### Known limitations

- `Try_Publish` on a full Reliable subscriber still delivers to the
  others and returns `Delivered = False`. The configurable policy
  (FR-08) is deferred to Spring 2027.
- Jorvik is checked on the native runtime only. Nothing has run on an
  embedded runtime or a board, and `gnatmem` was not available.
  Ravenscar is not supported: the protected queue has two entries.
- Registration is not task-safe. Register every subscriber from one
  task before the first `Publish`. Once the registry is locked, a
  subscriber must outlive every `Publish`.
- Latency is measured in the soak test, not gated. On Windows the
  timer tick (about 16 ms) dominates timing, and the UDP demo needs a
  longer subscriber window there than on Linux.
- `src/net/` is a preview: the UDP bridge has no retransmission, and
  the wire header still reports `Alignment = 4` (Task 4.1).

[Unreleased]: https://github.com/H000V/GCU-beacon/compare/v0.1.0-inproc...HEAD
[0.1.0-inproc]: https://github.com/H000V/GCU-beacon/releases/tag/v0.1.0-inproc
