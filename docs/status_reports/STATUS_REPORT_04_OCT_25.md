# STG-455 Weekly Status Update: Beacon
## Week 7 Status Report: Design Review Delivery & Team Consolidation

**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Reporting Period:** Week 7 (Ending October 25, 2026)  
**Overall Project Progress:** **7% Complete**  
**Engineering Team:**  
* Hovan Hodges (Core Systems Engineer)  
* Ryan Tomasko (Security & Validation Engineer)  
* Praise Jibunor (Network Systems Engineer)  
**Mentor:** Steven Faulkner (GCU Mentor) | **Industry Partner:** Olivier Henley (AdaCore GAP)  
**Repository:** [`GCU-beacon`](../..)  

---

## Project Description

Beacon is a typed publish-subscribe messaging library: topics are Ada generic instantiations, so a subscriber to a `Telemetry_Topic` receives `Telemetry_Reading` values directly, never raw bytes to be cast and hoped about. It provides an in-process bounded-queue backend for single-application use and a network backend for cross-process communication on desktop.

---

## Project Status Summary

**Percent Complete: 7%**  
The team delivered our formal **Design Review Presentation 1** on October 22nd. The team has tackled open design questions, established our formal requirements traceability and trade study baseline, and has initiated in-process implementation for Timed `Receive` in [`src/beacon-topic.ads`](../../src/beacon-topic.ads).

---

## Timeline Snapshot

The team has been provided with a general project timeline for the Beacon project from the AdaCore contact (Olivier Henley). The following table outlines the full 32-week roadmap:

| Week Timeline | Goals & Target Deliverables |
| :--- | :--- |
| **Weeks 1–4: Architecture & Generic Design** | • Design the `Beacon.Topic` generic package: publisher, subscriber, delivery modes.<br>• Specify the protected queue type and its overflow behavior for both delivery modes.<br>• Mentor architecture review at Week 4: generic interface signoff. |
| **Weeks 5–8: In-Process Backend** | • Implement the bounded protected queue.<br>• Verify reliable and best-effort delivery modes operating concurrently.<br>• Single-process test: multiple publishers and subscribers on different topic instantiations. |
| **Weeks 9–12: Demonstration & Checkpoint** | • Small simulated application: two or three topics at different message rates, mixed delivery modes.<br>• Load test: verify reliable mode never drops, best-effort mode drops in the documented way under sustained overflow.<br>• Tagged release for the in-process backend (`v0.1.0-inproc`). |
| **Weeks 13–16: Network Backend Design & Prototype** | • UDP multicast transport design, message framing with representation clauses.<br>• First cross-process publish and receive between two processes on the same host. |
| **Weeks 17–22: Network Backend Completion** | • Full UDP multicast backend: multiple publishers and subscribers across processes.<br>• Static participant configuration.<br>• Cross-process demonstration application extended to use the network backend. |
| **Weeks 23–26: SPARK & Robustness** | • GNATprove on `Beacon.Queue` (Silver target).<br>• Stress testing: sustained high message rate, verify queue behavior matches specification under load.<br>• Latency measurement: in-process versus network backend. |
| **Weeks 27–29: Documentation & Alire Packaging** | • API reference and delivery guarantee documentation.<br>• Short comparison document: what Beacon provides relative to full DDS, and why each omission was made.<br>• Alire crate preparation (`adacore_beacon`). |
| **Weeks 30–32: Final Demonstration & Delivery** | • Live demo: multi-process simulated sensor network, reliable and best-effort topics running simultaneously.<br>• Final report defending the delivery guarantees and the generic design.<br>• Alire crate submitted to community index. |

---

## Current Concept

```
+---------------------------------------------------------------------------------------+
| application (demo/, or yours)                                                         |
|       |                                                                               |
| Beacon.Topic (generic)   Publisher, Subscriber (Mode), protected Bounded_Queue,       |
|       |                  static registry                                              |
| Beacon.Queue (generic)   pure bounded ring buffer, no tasking      SPARK proof target |
|       |                                                                               |
| Beacon                   Delivery_Mode                             Pure, SPARK        |
|                                                                                       |
| --- src/net/, desktop only, never referenced by the three above ---                   |
|                                                                                       |
| Beacon.Bridge (generic)  Egress task: local Subscriber -> frames -> Transport         |
|       |                  Ingress task: Transport -> frames -> local Publisher         |
|       |                                                                               |
| Beacon.Wire              Beacon.Transport       frame header by rep clause, CRC-32 /  |
|                               |                 Send, Receive interface               |
|                          Beacon.Transport.UDP   GNAT.Sockets multicast                |
+---------------------------------------------------------------------------------------+
```
*Figure 1. Current Design/Architecture Concept Layering.*  
*(Artifact image: [`docs/assets/beacon_architecture_layers.png`](../assets/beacon_architecture_layers.png))*

The team has been provided with a general architecture from AdaCore to follow and some sample code to build off of. The team was provided with this information on September 29th.

---

## Accomplishments & Learning

### Planned Items Accomplished:
* **Prepare and deliver our Design Review Presentation** (Accomplished on October 22, 2026; Milestone 1 complete)
* **Implement Timed Receive in Topic Body** (In Progress in [`src/beacon-topic.adb`](../../src/beacon-topic.adb)

---

## Work Planned for Next Week

1. Test seed repository thoroughly across all test executables.
2. Meet with Olivier Henley (AdaCore contact) to go over Ada specifics in the Beacon seed repository.
3. Resubmit the university order form correctly.
4. Implement Timed `Receive` Unit Tests & Timeout Checks in [`tests/src/topic_tests.adb`](../../tests/src/topic_tests.adb).
5. Implement Hardened Protected Queue Entry Barriers with Ceiling Priority Protocol in [`src/beacon-topic.adb`](../../src/beacon-topic.adb).

---

## Risks

* **Technical Verification Risk:** The team ramping up on Ada generic contracts and proofs. Learning process could take longer than scheduled.
* **Personnel / Roster Change:** One of the team members informed the team that they are withdrawing from Capstone. This could slow down completion of validation tasks.
  * *Mitigation:* The team reorganized into a consolidated 3-engineer structure; **Ryan Tomasko** assumed all Validation Engineer duties as **Security & Validation Engineer**, ensuring test plan authoring, soak test validation, and CI verification workflows remain on track.

---

## Deliverables and Milestones

### Milestones
| Milestone | Planned | Forecasted | Actual | Status |
| :--- | :---: | :---: | :---: | :--- |
| Initial Research & Design | 10/04/2026 | 10/04/2026 | 10/04/2026 | **Completed** |
| First meeting with AdaCore contact | 10/14/2026 | 10/14/2026 | 10/14/2026 | **Completed** |
| Design Review Presentation Meeting | 10/22/2026 | 10/22/2026 | 10/22/2026 | **Completed** |
| In-Process Backend Demo | 11/22/2026 | 11/22/2026 | — | **In Progress** |

### Deliverables
| Deliverable | Planned | Forecasted | Actual | Status |
| :--- | :---: | :---: | :---: | :--- |
| Team Members Specific Roles & Responsibilities | 10/08/2026 | 10/08/2026 | 10/08/2026 | **Completed** |
| Research Industry Standards | 10/11/2026 | 10/11/2026 | 10/11/2026 | **Completed** |
| Gather Stakeholder Feedback | 10/15/2026 | 10/15/2026 | 10/15/2026 | **Completed** |
| Create Bill of Materials (BOM) for Software and Cloud Projects | 10/18/2026 | 10/18/2026 | 10/18/2026 | **Completed** |
| Finalize Product Functional Requirements | 10/18/2026 | 10/18/2026 | 10/18/2026 | **Completed** |
| Finalize Project Timeline and Work Breakdown Structure | 10/18/2026 | 10/18/2026 | 10/18/2026 | **Completed** |
| Implement Timed Receive in Topic Body | 10/25/2026 | 10/25/2026 | — | **In Progress** |
| Implement Timed Receive Unit Tests & Timeout Checks | 10/25/2026 | 11/01/2026 | — | **In Progress** |
| Implement Hardened Protected Queue Entry Barriers | 11/01/2026 | 11/01/2026 | — | **In Progress** |
| Complete Project Portfolio | 11/01/2026 | 11/01/2026 | — | **In Progress** |

---

## Attachments
* N/A.

---

## Approvals

| Team Role | Print Name | Approval Status | Date |
| :--- | :--- | :---: | :---: |
| **Faculty Mentor** | Steven Faulkner | Approved | 10/25/2026 |
| **Core Systems Engineer** | Hovan Hodges | Approved | 10/25/2026 |
| **Security & Validation Engineer** | Ryan Tomasko | Approved | 10/25/2026 |
| **Network Systems Engineer** | Praise Jibunor | Approved | 10/25/2026 |
