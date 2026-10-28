# Project Beacon Documentation Index

This directory contains the systems engineering documentation, project charter, schedule, architecture presentations, stakeholder consultations, and compliance specifications for **Project Beacon: Typed Publish-Subscribe Messaging Library in Ada**.

---

## Document Catalog

| Document | Description | Format / Status |
| :--- | :--- | :--- |
| [`PROJECT_CHARTER.md`](PROJECT_CHARTER.md) | **Official Project Charter (v1.10)**<br>Contains the project purpose justification, strategic objectives, requirements, assumptions/constraints, preliminary risk statement, summary milestone schedule, ROM estimated budget, consolidated 3-engineer organization chart, functional requirements matrix, APA references, and CLC industry standards alignment. | Markdown (`.md`) |
| [`STAKEHOLDER_FEEDBACK_FORM.md`](STAKEHOLDER_FEEDBACK_FORM.md) | **Stakeholder Feedback Form & Approvals**<br>Interviews and architectural directives from Olivier Henley (AdaCore GAP) and Steven Faulkner (GCU Mentor), translating feedback into concrete design requirements (timed receive, publisher lockdown, configurable try-publish) with team approvals. | Markdown (`.md`) |
| [`GANTT_SCHEDULE_MATRIX.md`](GANTT_SCHEDULE_MATRIX.md) | **15-Week Gantt Schedule Grid & Matrix**<br>Full semester timeline mapping all 22 tasks and 4 milestones across Weeks 1 to 15, matching the official project spreadsheet matrix, color codes, calendar dates, and Mermaid Gantt visualization. | Markdown (`.md`) |
| [`WORK_BREAKDOWN_STRUCTURE.md`](WORK_BREAKDOWN_STRUCTURE.md) | **Work Breakdown Structure & Fall 2026 Schedule**<br>Comprehensive task catalog covering Phase 1 through Phase 5 (Tasks 1.1 to 5.2, Milestones 1 to 4) with person-hour estimates, durations, resource requirements, explicit engineer assignments, and predecessor/successor dependency chains. | Markdown (`.md`) |
| [`beacon.md`](beacon.md) | **Sprint Tasks & Deliverables Reference**<br>Synchronized sprint task listing matching the approved Work Breakdown Structure for immediate developer lookup. | Markdown (`.md`) |
| [`PRESENTATION_SLIDES.md`](PRESENTATION_SLIDES.md) | **Design Review Presentation 1: Slide Deck**<br>Direct Markdown transcription of the 16 slides for the Capstone Design Concepts, Requirements Traceability, and Architectural Trade Study presentation. Includes Mermaid organization charts, Concept 1 & 2 schematics, and the Pugh decision matrix. | Markdown (`.md`) |
| [`DESIGN_CONCEPTS_PRESENTATION.md`](DESIGN_CONCEPTS_PRESENTATION.md) | **Capstone Design Concepts & Architectural Trade Study Document**<br>In-depth architectural specification and complete presentation transcript with embedded speaker notes, requirements traceability matrix, and technical interrogation answers. | Markdown (`.md`) |
| [`SPEAKER_NOTES.md`](SPEAKER_NOTES.md) | **Presentation Speaker Script & Rehearsal Notes**<br>Slide-by-slide verbal script with timed rehearsal windows (13m 45s target) and consolidated 3-person team role allocations across Hovan, Praise, and Ryan. | Markdown (`.md`) |
| [`beacon.gantt`](beacon.gantt) | **Mermaid Gantt Chart**<br>Visual schedule tracking weekly sprint tasks and milestones across Fall 2026 and Spring 2027. | Mermaid Gantt (`.gantt`) |
| [`status_reports/`](status_reports/README.md) | **Weekly Status Reports Directory & Catalog**<br>Chronological catalog containing Weekly Status Updates (SR-01 to SR-04, Weeks 4–7) covering project progress, milestones, risk monitoring, and team transition updates. | Directory / Reports |

---

## Architecture Visuals

- System Layering Diagram: [`assets/beacon_architecture_layers.png`](assets/beacon_architecture_layers.png)

---

## Core Repository References

- Architectural Design: [`ARCHITECTURE.md`](../ARCHITECTURE.md)
- Project Readme & Quickstart: [`README.md`](../README.md)
- Alire Crate Specification: [`alire.toml`](../alire.toml)
- GNAT Project File: [`beacon.gpr`](../beacon.gpr)
