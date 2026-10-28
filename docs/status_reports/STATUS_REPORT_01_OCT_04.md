# STG-455 Weekly Status Update: Beacon
## Week 4 Status Report: Project Initiation, Tooling & Initial Research

**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Reporting Period:** Week 4 (Ending October 04, 2026)  
**Overall Project Progress:** **1% Complete**  
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

**Percent Complete: 1%**  
The team has been made aware of the project goals and requirements broadly. The team is currently in the research and design phase of the project, where the scope of the objectives is being defined and the timeline is being measured out.

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

The team has been provided with a general architecture from AdaCore to follow and some sample code to build off of. The team was provided with this information on Tuesday, September 29th.

---

## Accomplishments & Learning

### Planned Items Accomplished:
* **Reach out to AdaCore contact** (Accomplished)
* **Schedule meeting with AdaCore contact** (Accomplished)

---

## Work Planned for Next Week

1. Meet to discuss specific roles and responsibilities according to the scope of the project as it relates to the structure provided by AdaCore.
2. Research DDS and ROS 2 design architectures.
3. Research Ada and SPARK programming languages.

---

## Risks

* **Technical Risk (Language Onboarding):** Coding in a new programming language (Ada 2022) may prove more difficult to pick up than anticipated and could cause the team to fall behind schedule.
  * *Mitigation:* Team members are studying the Ada 2022 Reference Manual and AdaCore university learning materials.

---

## Deliverables and Milestones

### Milestones
| Milestone | Planned | Forecasted | Actual | Status |
| :--- | :---: | :---: | :---: | :--- |
| Initial Research & Design | 10/04/2026 | 10/04/2026 | 10/04/2026 | **Completed** |

### Deliverables
| Deliverable | Planned | Forecasted | Actual | Status |
| :--- | :---: | :---: | :---: | :--- |
| Team Members Specific Roles & Responsibilities | 10/08/2026 | 10/08/2026 | — | **On Schedule** |

---

## Attachments
* N/A.

---

## Approvals

| Team Role | Print Name | Approval Status | Date |
| :--- | :--- | :---: | :---: |
| **Faculty Mentor** | Steven Faulkner | Approved | 10/04/2026 |
| **Core Systems Engineer** | Hovan Hodges | Approved | 10/04/2026 |
| **Security & Validation Engineer** | Ryan Tomasko | Approved | 10/04/2026 |
| **Network Systems Engineer** | Praise Jibunor | Approved | 10/04/2026 |
