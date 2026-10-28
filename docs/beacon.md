# Project Beacon: Work Breakdown Structure & Schedule
## Fall 2026 Sprint Task Catalog (Weeks 1–15: Sep 07 – Dec 20, 2026)

**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Sponsor:** AdaCore (GNAT Academic Program - GAP)  
**Engineering Team:**  
* **Hovan Hodges:** Core Systems Engineer  
* **Ryan Tomasko:** Security & Validation Engineer  
* **Praise Jibunor:** Network Systems Engineer  
**Repository:** [`GCU-beacon`](..)  

---

### Phase 1: Environment Setup & Design Decisions (Weeks 1–6: Sep 07 – Oct 18, 2026)

* **Task 1.1: Toolchain Setup & Build Verification**
  * **Lead Engineer:** Hovan Hodges (Core Systems Engineer) with Full Team
  * **Resources Required:** Alire 2.1+ package manager; native GNAT 2022 compiler toolchain (`gnat_native 14+`); GitHub repository ([`GCU-beacon`](..).
  * **Time Needed:** 6 hours (2 hrs/member across 3 team members) | **Duration:** 1 week (Sep 28 – Oct 04, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* None (Project Initiation).
    * *Successors:* Task 1.2, Task 1.3.

* **Task 1.2: Audit Seed Repository**
  * **Lead Engineer:** Hovan Hodges (Core Systems Engineer)
  * **Resources Required:** Native GNAT 2022 compiler toolchain (`gnat_native 14+`); GitHub repository ([`GCU-beacon`](..); Visual Studio Code.
  * **Time Needed:** 20 hours | **Duration:** 2 weeks (Sep 28 – Oct 11, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 1.1.
    * *Successors:* Task 1.3.

* **Task 1.3: Resolve Open Design Decisions**
  * **Lead Engineer:** Full Team (Hovan Hodges, Ryan Tomasko, Praise Jibunor)
  * **Resources Required:** Ada 2022 Reference Manual; OMG DDS v1.4 Specification; [`ARCHITECTURE.md`](../ARCHITECTURE.md).
  * **Time Needed:** 12 hours (4 hrs/member across 3 team members) | **Duration:** 2 weeks (Oct 05 – Oct 18, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 1.1, Task 1.2.
    * *Successors:* Task 2.1, Task 2.2.

---

### Phase 2: Timed Receive & Design Review Presentation (Weeks 7–8: Oct 19 – Nov 01, 2026)

* **Task 2.1: Implement Timed Receive in Topic Body**
  * **Lead Engineer:** Hovan Hodges (Core Systems Engineer)
  * **Resources Required:** GNAT 2022 compiler; Ada tasking runtime; [`src/beacon-topic.ads`](../src/beacon-topic.ads) and [`src/beacon-topic.adb`](../src/beacon-topic.adb); Visual Studio Code.
  * **Time Needed:** 12 hours | **Duration:** 1 week (Oct 19 – Oct 25, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 1.3.
    * *Successors:* Task 2.2, Milestone 1.

* **Task 2.2: Timed Receive Unit Tests & Timeout Checks**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** Unit test framework; [`tests/src/topic_tests.adb`](../tests/src/topic_tests.adb); Visual Studio Code.
  * **Time Needed:** 12 hours | **Duration:** 1 week (Oct 19 – Oct 25, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 1.3, Task 2.1.
    * *Successors:* Task 2.3, Milestone 1.

* **Milestone 1: Design Review Presentation 1**
  * **Lead Engineer:** Full Team
  * **Resources Required:** Microsoft PowerPoint; Presentation Slides ([`docs/PRESENTATION_SLIDES.md`](PRESENTATION_SLIDES.md).
  * **Time Needed:** 8 hours | **Duration:** 4 days (Oct 19 – Oct 22, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 2.1, Task 2.2.
    * *Successors:* Task 2.3.

* **Task 2.3: Harden Protected Queue Entry Barriers**
  * **Lead Engineer:** Hovan Hodges (Core Systems Engineer) & Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** GNAT tasking runtime with Ceiling Priority Protocol; GDB debugger; [`src/beacon-topic.adb`](../src/beacon-topic.adb); Visual Studio Code.
  * **Time Needed:** 10 hours | **Duration:** 1 week (Oct 26 – Nov 01, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 2.1, Milestone 1.
    * *Successors:* Task 2.4, Task 3.1.

* **Task 2.4: Implement Multi-Task Blocking-Publish Test**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** Multi-threaded test runner; [`tests/src/topic_tests.adb`](../tests/src/topic_tests.adb); atomic synchronization primitives; Visual Studio Code.
  * **Time Needed:** 16 hours | **Duration:** 1 week (Oct 26 – Nov 01, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 2.3.
    * *Successors:* Task 3.1.

---

### Phase 3: In-Process Soak & Demo Release (Weeks 9–11: Nov 02 – Nov 22, 2026)

* **Task 3.1: Verify Best-Effort Drop-Oldest**
  * **Lead Engineer:** Hovan Hodges (Core Systems Engineer) & Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** GNAT tracing utilities; [`src/beacon-queue.adb`](../src/beacon-queue.adb); Visual Studio Code.
  * **Time Needed:** 12 hours | **Duration:** 1 week (Nov 02 – Nov 08, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 2.3, Task 2.4.
    * *Successors:* Task 3.2.

* **Task 3.2: Drop-Oldest Invariant & Property Tests**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** Property-based randomized test generator; multi-core test host; [`tests/src/`](../tests/src); Visual Studio Code.
  * **Time Needed:** 16 hours | **Duration:** 1 week (Nov 02 – Nov 08, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.1.
    * *Successors:* Task 3.3.

* **Task 3.3: Multi-Task Sustained Soak Stress Test**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** High-load multi-threaded test environment; CPU utilization monitor; [`tests/src/topic_tests.adb`](../tests/src/topic_tests.adb); Visual Studio Code.
  * **Time Needed:** 20 hours | **Duration:** 1 week (Nov 09 – Nov 15, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.2.
    * *Successors:* Task 3.4, Task 3.5.

* **Task 3.4: Zero-Heap & Embedded Jorvik Audit**
  * **Lead Engineer:** Hovan Hodges (Core Systems Engineer) & Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** GNAT Jorvik embedded runtime; `gnatmem` heap profiling utility; `-fstack-check` compiler diagnostics; [`beacon.gpr`](../beacon.gpr); Visual Studio Code.
  * **Time Needed:** 16 hours | **Duration:** 1 week (Nov 09 – Nov 15, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.3.
    * *Successors:* Task 3.5.

* **Task 3.5: Expand Flight Telemetry Demo**
  * **Lead Engineer:** Praise Jibunor (Network Systems Engineer) & Hovan Hodges (Core Systems Engineer)
  * **Resources Required:** Flight simulation models; [`demo/src/inproc_demo.adb`](../demo/src/inproc_demo.adb) and [`demo/src/telemetry.ads`](../demo/src/telemetry.ads); Visual Studio Code.
  * **Time Needed:** 20 hours | **Duration:** 1 week (Nov 16 – Nov 22, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.3, Task 3.4.
    * *Successors:* Task 3.6, Milestone 2.

* **Task 3.6: Tag In-Process Release v0.1.0-inproc**
  * **Lead Engineer:** Full Team (Lead: Hovan Hodges)
  * **Resources Required:** Git version control.
  * **Time Needed:** 14 hours | **Duration:** 1 week (Nov 16 – Nov 22, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.5.
    * *Successors:* Task 4.1, Milestone 2.

* **Milestone 2: In-Process Backend Demo**
  * **Lead Engineer:** Full Team
  * **Resources Required:** Visual Studio Code; Google Meet.
  * **Time Needed:** 4 hours | **Duration:** 1 week (Nov 16 – Nov 22, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.5, Task 3.6.
    * *Successors:* Task 4.1.

---

### Phase 4: Wire Protocol & UDP Prototype (Weeks 12–14: Nov 23 – Dec 13, 2026)

* **Task 4.1: Wire Header Representation Clauses Layout**
  * **Lead Engineer:** Praise Jibunor (Network Systems Engineer)
  * **Resources Required:** System package endianness constants; IEEE 802.3 CRC-32 specification; [`src/net/beacon-wire.ads`](../src/net/beacon-wire.ads); Visual Studio Code.
  * **Time Needed:** 18 hours | **Duration:** 1 week (Nov 23 – Nov 29, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 3.6, Milestone 2.
    * *Successors:* Task 4.2, Task 4.3.

* **Task 4.2: Wire Framing & CRC-32 Unit Test Suite**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** Automated test runner; CRC test vectors; [`tests/src/wire_tests.adb`](../tests/src/wire_tests.adb); Visual Studio Code.
  * **Time Needed:** 16 hours | **Duration:** 1 week (Nov 23 – Nov 29, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.1.
    * *Successors:* Task 4.3.

* **Task 4.3: GNAT.Sockets UDP Multicast Transport Tuning**
  * **Lead Engineer:** Praise Jibunor (Network Systems Engineer)
  * **Resources Required:** `GNAT.Sockets` package; local loopback multicast routing; [`src/net/beacon-transport-udp.adb`](../src/net/beacon-transport-udp.adb); Visual Studio Code.
  * **Time Needed:** 16 hours | **Duration:** 1 week (Nov 30 – Dec 06, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.1, Task 4.2.
    * *Successors:* Task 4.4.

* **Task 4.4: Bridge Egress & Ingress Task Integration**
  * **Lead Engineer:** Praise Jibunor (Network Systems Engineer) & Hovan Hodges (Core Systems Engineer)
  * **Resources Required:** Ada tasking runtime; [`src/net/beacon-bridge.ads`](../src/net/beacon-bridge.ads) and [`src/net/beacon-bridge.adb`](../src/net/beacon-bridge.adb); Visual Studio Code.
  * **Time Needed:** 18 hours | **Duration:** 1 week (Nov 30 – Dec 06, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.3.
    * *Successors:* Task 4.5.

* **Task 4.5: Implement Cross-Process UDP Publish-Receive**
  * **Lead Engineer:** Praise Jibunor (Network Systems Engineer)
  * **Resources Required:** 2 terminal processes on host; [`demo/src/net_publisher.adb`](../demo/src/net_publisher.adb) and [`demo/src/net_subscriber.adb`](../demo/src/net_subscriber.adb); Visual Studio Code.
  * **Time Needed:** 18 hours | **Duration:** 1 week (Dec 07 – Dec 13, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.4.
    * *Successors:* Task 4.6, Milestone 3.

* **Task 4.6: Headless Cross-Process CI Verification Test**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer)
  * **Resources Required:** GitHub Actions Ubuntu/Windows runners; bash/PowerShell automation scripts; [`.github/workflows/ci.yml`](../.github/workflows/ci.yml); Visual Studio Code.
  * **Time Needed:** 16 hours | **Duration:** 1 week (Dec 07 – Dec 13, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.5.
    * *Successors:* Task 5.1, Milestone 3.

* **Milestone 3: Cross-Process UDP Demo**
  * **Lead Engineer:** Full Team
  * **Resources Required:** Visual Studio Code; Google Meet.
  * **Time Needed:** 6 hours | **Duration:** 1 week (Dec 07 – Dec 13, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.5, Task 4.6.
    * *Successors:* Task 5.1.

---

### Phase 5: Serial Transport & Fall Finish (Week 15: Dec 14 – Dec 20, 2026)

* **Task 5.1: Serial Transport Architecture & Stream Framing**
  * **Lead Engineer:** Praise Jibunor (Network Systems Engineer)
  * **Resources Required:** COBS/SLIP framing algorithms; serial interface specifications; [`src/net/`](../src/net); Visual Studio Code.
  * **Time Needed:** 22 hours | **Duration:** 1 week (Dec 14 – Dec 20, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 4.6, Milestone 3.
    * *Successors:* Task 5.2.

* **Task 5.2: Serial Virtual Port Loopback & Recovery Tests**
  * **Lead Engineer:** Ryan Tomasko (Security & Validation Engineer) & Praise Jibunor (Network Systems Engineer)
  * **Resources Required:** Virtual serial port emulator (`socat` / `com0com`); noise injection harness.
  * **Time Needed:** 18 hours | **Duration:** 1 week (Dec 14 – Dec 20, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 5.1.
    * *Successors:* Milestone 4.

* **Milestone 4: Design Review Presentation 2**
  * **Lead Engineer:** Full Team
  * **Resources Required:** Microsoft PowerPoint.
  * **Time Needed:** 8 hours | **Duration:** 4 days (Dec 14 – Dec 18, 2026).
  * **Costs Associated:** \$0.
  * **Predecessors & Successors:**
    * *Predecessors:* Task 5.2.
    * *Successors:* Spring Semester (Phase 6: SPARK Silver Proof & Alire Distribution).

---

### Complete Work Breakdown Structure Matrix

| Phase | Task ID | Task / Milestone Title | Lead Engineer | Time Needed | Duration | Predecessors | Successors |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Phase 1** | Task 1.1 | Toolchain Setup & Build Verification | Hovan Hodges / Team | 6 hrs | Sep 28 – Oct 04 | None | Task 1.2, 1.3 |
| | Task 1.2 | Audit Seed Repository | Hovan Hodges | 20 hrs | Sep 28 – Oct 11 | Task 1.1 | Task 1.3 |
| | Task 1.3 | Resolve Open Design Decisions | Full Team | 12 hrs | Oct 05 – Oct 18 | Task 1.1, 1.2 | Task 2.1, 2.2 |
| **Phase 2** | Task 2.1 | Implement Timed Receive in Topic Body | Hovan Hodges | 12 hrs | Oct 19 – Oct 25 | Task 1.3 | Task 2.2, M1 |
| | Task 2.2 | Timed Receive Unit Tests & Timeout Checks | Ryan Tomasko | 12 hrs | Oct 19 – Oct 25 | Task 1.3, 2.1 | Task 2.3, M1 |
| | **Milestone 1** | **Design Review Presentation 1** | **Full Team** | **8 hrs** | **Oct 19 – Oct 22** | **Task 2.1, 2.2** | **Task 2.3** |
| | Task 2.3 | Harden Protected Queue Entry Barriers | Hovan Hodges & Ryan Tomasko | 10 hrs | Oct 26 – Nov 01 | Task 2.1, M1 | Task 2.4, 3.1 |
| | Task 2.4 | Implement Multi-Task Blocking-Publish Test | Ryan Tomasko | 16 hrs | Oct 26 – Nov 01 | Task 2.3 | Task 3.1 |
| **Phase 3** | Task 3.1 | Verify Best-Effort Drop-Oldest | Hovan Hodges & Ryan Tomasko | 12 hrs | Nov 02 – Nov 08 | Task 2.3, 2.4 | Task 3.2 |
| | Task 3.2 | Drop-Oldest Invariant & Property Tests | Ryan Tomasko | 16 hrs | Nov 02 – Nov 08 | Task 3.1 | Task 3.3 |
| | Task 3.3 | Multi-Task Sustained Soak Stress Test | Ryan Tomasko | 20 hrs | Nov 09 – Nov 15 | Task 3.2 | Task 3.4, 3.5 |
| | Task 3.4 | Zero-Heap & Embedded Jorvik Audit | Hovan Hodges & Ryan Tomasko | 16 hrs | Nov 09 – Nov 15 | Task 3.3 | Task 3.5 |
| | Task 3.5 | Expand Flight Telemetry Demo | Praise Jibunor & Hovan Hodges | 20 hrs | Nov 16 – Nov 22 | Task 3.3, 3.4 | Task 3.6, M2 |
| | Task 3.6 | Tag In-Process Release v0.1.0-inproc | Hovan Hodges / Team | 14 hrs | Nov 16 – Nov 22 | Task 3.5 | Task 4.1, M2 |
| | **Milestone 2** | **In-Process Backend Demo** | **Full Team** | **4 hrs** | **Nov 16 – Nov 22** | **Task 3.5, 3.6** | **Task 4.1** |
| **Phase 4** | Task 4.1 | Wire Header Representation Clauses Layout | Praise Jibunor | 18 hrs | Nov 23 – Nov 29 | Task 3.6, M2 | Task 4.2, 4.3 |
| | Task 4.2 | Wire Framing & CRC-32 Unit Test Suite | Ryan Tomasko | 16 hrs | Nov 23 – Nov 29 | Task 4.1 | Task 4.3 |
| | Task 4.3 | GNAT.Sockets UDP Multicast Transport Tuning | Praise Jibunor | 16 hrs | Nov 30 – Dec 06 | Task 4.1, 4.2 | Task 4.4 |
| | Task 4.4 | Bridge Egress & Ingress Task Integration | Praise Jibunor & Hovan Hodges | 18 hrs | Nov 30 – Dec 06 | Task 4.3 | Task 4.5 |
| | Task 4.5 | Implement Cross-Process UDP Publish-Receive | Praise Jibunor | 18 hrs | Dec 07 – Dec 13 | Task 4.4 | Task 4.6, M3 |
| | Task 4.6 | Headless Cross-Process CI Verification Test | Ryan Tomasko | 16 hrs | Dec 07 – Dec 13 | Task 4.5 | Task 5.1, M3 |
| | **Milestone 3** | **Cross-Process UDP Demo** | **Full Team** | **6 hrs** | **Dec 07 – Dec 13** | **Task 4.5, Task 4.6** | **Task 5.1** |
| **Phase 5** | Task 5.1 | Serial Transport Architecture & Stream Framing | Praise Jibunor | 22 hrs | Dec 14 – Dec 20 | Task 4.6, M3 | Task 5.2 |
| | Task 5.2 | Serial Virtual Port Loopback & Recovery Tests | Ryan Tomasko & Praise Jibunor | 18 hrs | Dec 14 – Dec 20 | Task 5.1 | Milestone 4 |
| | **Milestone 4** | **Design Review Presentation 2** | **Full Team** | **8 hrs** | **Dec 14 – Dec 18** | **Task 5.2** | **Spring 2027** |
