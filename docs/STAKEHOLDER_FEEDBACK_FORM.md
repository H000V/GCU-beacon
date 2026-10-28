# STG-455: CLC – Stakeholder Feedback Form
## Capstone Project I — Grand Canyon University
### Project Beacon: Typed Publish-Subscribe Messaging Library in Ada

**Course:** STG-455: Capstone Project I
**Institution:** Grand Canyon University (GCU)
**Instructor:** Professor Dwight Farris
**Engineering Team:** Hovan Hodges (Core Systems Engineer), Ryan Tomasko (Security & Validation Engineer), Praise Jibunor (Network Systems Engineer)
**Industry Partner:** AdaCore (GNAT Academic Program - GAP)
**Repository:** [`GCU-beacon`](..)

---

## Instructions

> Document important design feedback from the customer in the appropriate space below. After all feedback has been collected, translate the customer feedback into functional design requirements in the space provided. Add additional rows as necessary.

---

## Stakeholder Consultations

### Stakeholder 1: Olivier Henley (AdaCore)

| Field | Detail |
| :--- | :--- |
| **Stakeholder Name** | Olivier Henley |
| **Date** | October 14, 2026 |
| **Contact Information** | 514-922-6722 \| henley@adacore.com |
| **Relevance** | UX Engineer and GAP Coordinator, AdaCore |
| **Conversation Notes** | **Question:** Whenever we are designing the Beacon project, what customer base should we have in mind? Companies with mission critical goals or IoT enthusiasts?<br><br>**Answer:** Don’t imagine the customer base when designing the project, the project will need to feel complete and good, and the word will spread. At first, you will not have companies implementing your project because it is new and it has not been around enough to prove itself. First, you will have the IoT enthusiasts play with it, build projects with it, interact with it. If they like the project and it is good and it does what it is supposed to, then big companies may start implementing it. |
| **Design Requirements** | While at first it may be used by IoT enthusiasts, it could eventually be used for mission-critical goals. Meaning we need to design it with completeness and not just with good features. |

---

### Stakeholder 2: Steven Faulkner (GCU Mentor)

| Field | Detail |
| :--- | :--- |
| **Stakeholder Name** | Steven Faulkner |
| **Date** | October 15, 2026 |
| **Contact Information** | steven.faulkner@gcu.edu |
| **Relevance** | BEACON Team Mentor, Grand Canyon University |
| **Conversation Notes** | **Question 1:** Currently, the Receive procedure for Subscribers has no time out, leaving the procedure pending until it has received data. Should we keep it the way it is or change the Receive procedure to accept timeout as a parameter?<br>*Discussion:* We discussed for a little bit until we decided that we should have two procedures, one without a timeout and one with a timeout.<br><br>**Question 2:** Currently, Publisher Registration is not task-safe and must precede any Publish. Should we keep this as a documented rule of the library or make the registry a protected object (allowing dynamic publisher registration)?<br>*Discussion:* We discussed for a little bit until we decided that we should further test the current implementation of the non-task safe Publisher Registration because we had the idea that the Publisher Registration should be locked down after proper initialization, so no Publisher can be made by a third-party.<br><br>**Question 3:** Currently, the Try_Publish procedure provides partial delivery to Subscribers. Should we keep it like it is or implement an all-or-nothing method?<br>*Discussion:* We discussed for a little bit before deciding that we should allow the developer using the library to pick between a partial delivery mode or all-or-nothing mode. We chose this because some systems could be in an equilibrium that could fail if partial delivery was implemented but some systems have Publishers that have many Subscribers that are not related to each other, where partial delivery is okay. |
| **Design Requirements** | 1. Create a `Receive` procedure for Subscribers that has a timeout parameter.<br>2. Test if locking down the publishers list before any data is published will work properly.<br>3. Implement a mode parameter into the `Try_Publish` procedure to determine how the `Try_Publish` procedure should work. |

---

## Synthesis & Planned Implementation

Based on the stakeholder feedback gathered from Olivier Henley and Steven Faulkner, the identified design requirements and their planned implementation for Project Beacon are as follows:

1. **System Completeness and Reliability:**
   Because the project will initially be tested by IoT enthusiasts before potentially being adopted by companies for mission-critical goals, the library will be designed and implemented with a focus on overall architectural completeness rather than just individual ad-hoc features.

2. **Subscriber Receive Procedure with Timeout:**
   Currently, the `Receive` procedure for Subscribers has no timeout and remains pending until data is received. This requirement will be implemented by maintaining two `Receive` procedures:
   - The existing blocking procedure without a timeout: `procedure Receive (S : in out Subscriber; Item : out Element_Type);`
   - A new timed procedure that accepts a timeout parameter: `procedure Receive (S : in out Subscriber; Item : out Element_Type; Timeout : Ada.Real_Time.Time_Span; Success : out Boolean);`

3. **Publisher Registration Lockdown:**
   Currently, Publisher Registration is not task-safe and must occur before any `Publish` action. Rather than converting the registry into a protected object for dynamic runtime registration, the team will test locking down the publishers list after proper system initialization (during pre-flight elaboration and before any data is published), ensuring that no unauthorized third-party Publishers can be created.

4. **Configurable Try_Publish Delivery Modes:**
   Currently, the `Try_Publish` procedure only provides partial delivery to Subscribers. This will be updated by implementing a mode parameter within the `Try_Publish` procedure that allows the developer using the library to choose between:
   - `Partial_Delivery`: Best-effort fan-out to all unblocked subscribers (suitable for decoupled telemetry streams).
   - `All_Or_Nothing`: Atomically checks whether all registered subscribers have space before delivering; if any subscriber is full, delivery is aborted (suitable for control surfaces requiring strict equilibrium).

---

## Team Approvals & Sign-Offs

> This is an official document recording team sign-off on the validity of the customer feedback and derived design requirements. Following team consolidation, Ryan Tomasko serves as Security & Validation Engineer.

| Team Role | Member Name | Approval Status | Sign-Off Date |
| :--- | :--- | :---: | :---: |
| **Core Systems Engineer** | Hovan Hodges | Approved | 10/15/2026 |
| **Security & Validation Engineer** | Ryan Tomasko | Approved | 10/15/2026 |
| **Network Systems Engineer** | Praise Jibunor | Approved | 10/15/2026 |

---

### Referenced Artifacts
* Stakeholder Integration in Architecture Presentation: [`PRESENTATION_SLIDES.md#slide-5-03--mentor-consultations-oct-1415`](PRESENTATION_SLIDES.md#slide-5-03--mentor-consultations-oct-1415)
