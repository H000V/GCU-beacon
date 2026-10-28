# STG-455 Weekly Status Update: Beacon
## Week 6 Status Report: Stakeholder Consultations & Design Review Preparation

**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Reporting Period:** Week 6 (Ending October 18, 2026)  
**Overall Project Progress:** **5% Complete**  
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

**Percent Complete: 5%**  
The team explored and discussed the information provided by AdaCore in the GitHub repository. The team has tackled open design questions and has met with our AdaCore contact for design feedback.

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
* **Researched Industry Standards** (Accomplished)
* **Forked seed repository for our team** (Accomplished)
* **Each team member cloned seed repository on devices** (Accomplished)
* **Each team member set up tools for Beacon project** (Accomplished)
* **Reviewed `beacon-proposal.md`, [`README.md`](../../README.md), and [`ARCHITECTURE.md`](../../ARCHITECTURE.md) thoroughly** (Accomplished)
* **Discussed design decisions for Beacon** (Accomplished)
* **Met with Olivier Henley (AdaCore GAP)** (Accomplished on 10/14)

---

## Work Planned for Next Week

1. Test seed repository thoroughly across in-process demo and unit test suites.
2. Meet with Olivier Henley (AdaCore contact) to go over Ada specifics in the Beacon seed repository.
3. Prepare and deliver our formal **Design Review Presentation 1** (Milestone 1, scheduled for October 22).
4. Submit the technology purchasing request form with the team.
5. Kick off implementation of Timed `Receive` procedure in [`src/beacon-topic.ads`](../../src/beacon-topic.ads).

---

## Risks

* **Technical Verification Risk:** The team ramping up on Ada generic contracts and proofs. Learning process could take longer than scheduled.
* **Open Design Questions:** Open design questions about Beacon could delay implementation of architecture into repository.
  * *Resolution:* The consultations on 10/14 and 10/15 successfully resolved open questions, documented in [`docs/STAKEHOLDER_FEEDBACK_FORM.md`](../STAKEHOLDER_FEEDBACK_FORM.md).

---

## Deliverables and Milestones

### Milestones
| Milestone | Planned | Forecasted | Actual | Status |
| :--- | :---: | :---: | :---: | :--- |
| Initial Research & Design | 10/04/2026 | 10/04/2026 | 10/04/2026 | **Completed** |
| First meeting with AdaCore contact | 10/14/2026 | 10/14/2026 | 10/14/2026 | **Completed** |
| Design Review Presentation Meeting | 10/22/2026 | 10/22/2026 | — | **On Schedule** |

### Deliverables
| Deliverable | Planned | Forecasted | Actual | Status |
| :--- | :---: | :---: | :---: | :--- |
| Team Members Specific Roles & Responsibilities | 10/08/2026 | 10/08/2026 | 10/08/2026 | **Completed** |
| Research Industry Standards | 10/11/2026 | 10/11/2026 | 10/11/2026 | **Completed** |
| Gather Stakeholder Feedback | 10/15/2026 | 10/15/2026 | 10/15/2026 | **Completed** |
| Create Bill of Materials (BOM) for Software and Cloud Projects | 10/18/2026 | 10/18/2026 | — | **On Schedule** |
| Finalize Product Functional Requirements | 10/18/2026 | 10/18/2026 | — | **On Schedule** |
| Finalize Project Timeline and Work Breakdown Structure | 10/18/2026 | 10/18/2026 | — | **On Schedule** |
| Complete research on testing and validation for Beacon | 10/21/2026 | 10/21/2026 | — | **On Schedule** |

---

## Attachments
* N/A.

---

## Approvals

| Team Role | Print Name | Approval Status | Date |
| :--- | :--- | :---: | :---: |
| **Faculty Mentor** | Steven Faulkner | Approved | 10/18/2026 |
| **Core Systems Engineer** | Hovan Hodges | Approved | 10/18/2026 |
| **Security & Validation Engineer** | Ryan Tomasko | Approved | 10/18/2026 |
| **Network Systems Engineer** | Praise Jibunor | Approved | 10/18/2026 |
