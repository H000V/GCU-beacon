# Project Beacon: Capstone Presentation Speaker Script & Rehearsal Notes
## Complete Slide-by-Slide Script for 10–15 Minute Design Concepts Presentation

**Course:** STG-455: Capstone Project I  
**Institution:** Grand Canyon University (GCU)  
**Instructor:** Professor Dwight Farris  
**Team Mentor:** Steven Faulkner  
**AdaCore GAP Coordinator:** Olivier Henley  
**Target Duration:** 13 Minutes 45 Seconds (10–15 Minute Window)  

---

### Timetable & Role Breakdown (Consolidated 3-Person Team)

```
[00:00 - 00:45] Slide 1:  Title & Team Structure           --> Hovan Hodges (Core)
[00:45 - 02:00] Slide 2:  Who is AdaCore & Target Users    --> Praise Jibunor (Network)
[02:00 - 03:15] Slide 3:  Project Context & Justification  --> Hovan Hodges (Core)
[03:15 - 04:15] Slide 4:  Engineering Ownership            --> Ryan Tomasko (Security & Validation)
[04:15 - 05:45] Slide 5:  Stakeholder Feedback             --> Ryan Tomasko (Security & Validation)
[05:45 - 07:15] Slide 6:  Functional Requirements Table    --> Ryan Tomasko (Security & Validation)
[07:15 - 08:45] Slide 7:  Concept 1 Overview               --> Hovan Hodges (Core)
[08:45 - 10:30] Slide 8:  Concept 1 Deep Dive & Sketches   --> Hovan Hodges & Ryan Tomasko
[10:30 - 11:45] Slide 9:  Concept 2 Overview               --> Praise Jibunor (Network)
[11:45 - 13:15] Slide 10: Concept 2 Deep Dive & Sketches   --> Praise Jibunor & Ryan Tomasko
[13:15 - 14:45] Slide 11: Comparative Decision Matrix      --> Praise Jibunor (Network)
[14:45 - 16:00] Slide 12: Industry Standards Application   --> Praise Jibunor (Network)
[16:00 - 17:00] Slide 13: Next Steps & Gantt Gates         --> Hovan Hodges (Core)
[17:00 - 17:45] Slide 14: Conclusion & Q&A                 --> All Team Members
```

---

### Slide 1: Title & Presentation Header
* **Presenter:** Hovan Hodges (Core Engineer)
* **Target Time:** 0:45 (Running Total: 0:45)
* **Slide Visual:** Title header, institutional credits (GCU, Professor Farris, Steven Faulkner, Olivier Henley), and the three team roles.

> **Spoken Script:**  
> "Good morning, Professor Farris, Steven Faulkner, and fellow engineering students. Today, our capstone team—Hovan Hodges, Ryan Tomasko, and Praise Jibunor—presents the Initial Design Concepts, Requirements Traceability, and Architectural Trade Study for Project **Beacon: Typed Publish-Subscribe Messaging in Ada**.
>
> Conducted in partnership with AdaCore’s GNAT Academic Program under our mentor Olivier Henley, Project Beacon provides a type-safe, deterministic publish-subscribe communications library engineered for safety-critical aerospace and embedded computing. 
>
> Over the next thirteen minutes, we will walk you through who our sponsor AdaCore is and who will use this project, our stakeholder feedback, our quantifiable requirements, two contrasting design concepts with detailed schematics and sketches, our formal trade study evaluation, and our verified roadmap to completion. Praise will now introduce our industry sponsor and target user community."

---

### Slide 2: Industry Sponsorship & Target Users — Who is AdaCore & Who Will Use Beacon?
* **Presenter:** Praise Jibunor (Network Engineer)
* **Target Time:** 1:15 (Running Total: 2:00)
* **Slide Visual:** Company profile of AdaCore, GNAT Academic Program (GAP) mission, and the two-phased adoption diagram (IoT makers vs. aerospace enterprises).

> **Spoken Script:**  
> "Thank you, Hovan. On Slide 2, we address two foundational questions: Who is our industry sponsor AdaCore, and who is the intended audience for Project Beacon?
>
> AdaCore was founded in 1994 by the original designers of the GNAT Ada compiler at New York University. Today, they are the world's preeminent commercial provider of development tools and mathematical verification engines for the Ada and SPARK programming languages. If you look at high-assurance flight controls on the Airbus A350, Boeing commercial airliners, NASA’s Artemis lunar exploration spacecraft, or high-speed European rail signaling, that software is built and verified with AdaCore tools. Through the GNAT Academic Program, or GAP—coordinated by our mentor Olivier Henley—AdaCore sponsors capstone teams like ours to expand high-reliability software engineering.
>
> So who will use Beacon? As Olivier outlined during our stakeholder interview, Beacon follows a strategic, two-tiered adoption roadmap. In the near term, our primary users are **embedded IoT developers and robotics enthusiasts**. These makers are building autonomous drones, mobile rovers, and smart devices using microcontrollers like ARM Cortex-M and STM32. They need a lightweight, memory-efficient pub-sub library that doesn't drag in megabytes of C++ runtime or crash from dynamic heap fragmentation like ROS 2 and commercial DDS. They can install Beacon with a single command using the Alire package manager.
>
> In the long term, because we design Beacon with total architectural completeness and zero heap, our platform scales to **aerospace and defense enterprises** building satellites, avionics, and radar systems that require DO-178C Level A and NASA spaceflight compliance. Now, Hovan will explain the technical problem context."

---

### Slide 3: Project Context, Purpose & Justification
* **Presenter:** Hovan Hodges (Core Engineer)
* **Target Time:** 1:15 (Running Total: 3:15)
* **Slide Visual:** Comparison table showing Traditional Middleware vs. Project Beacon.

> **Spoken Script:**  
> "In modern autonomous robotics, avionics, and spacecraft, systems rely heavily on the Data-Centric Publish-Subscribe pattern—standardized by OMG DDS and popularized by ROS 2—to decouple publishers and subscribers. However, conventional C and C++ middleware implementations introduce severe vulnerabilities in safety-critical domains.
>
> First, standard middleware passes data across public APIs as untyped byte buffers or `void*` pointers. This means type checking is deferred to runtime deserialization; a corrupted header or schema drift causes silent failures or crashes during flight. Second, commercial DDS runtimes rely heavily on the dynamic heap via `malloc`, creating unpredictable execution jitter and memory fragmentation that makes DO-178C Level A avionics certification almost impossible. Third, buffer overflow policies are often vague flags rather than guaranteed behaviors.
>
> Project Beacon changes this paradigm by using Ada 2022 and SPARK. In Beacon, **the type IS the topic**—generic package instantiations eliminate byte buffers entirely from the public API. We enforce zero dynamic heap in our core library, and we express delivery modes as static type discriminants backed by Ada protected objects. Now, I'll pass it to Ryan to discuss how our team is structured to deliver this."

---

### Slide 4: Team Structure & Engineering Ownership
* **Presenter:** Ryan Tomasko (Security & Validation Engineer)
* **Target Time:** 1:00 (Running Total: 4:15)
* **Slide Visual:** Organizational hierarchy chart and role breakdown.

> **Spoken Script:**  
> "Thank you, Hovan. As detailed in our Project Charter, our three-person team divides technical ownership into three distinct engineering disciplines to ensure complete coverage of the software lifecycle.
>
> Hovan Hodges serves as our Core Engineer, governing generic package specifications, bounded ring buffer arithmetic, and formal SPARK verification contracts. Praise Jibunor serves as our Network Engineer, owning wire framing representation clauses, UDP multicast sockets, and upcoming physical serial transports.
>
> As Security & Validation Engineer, my responsibility is twofold: I lead our automated AUnit test harnesses and sustained concurrency stress testing, while ensuring our architecture eliminates unauthorized publisher registration, prevents payload tampering via CRC-32 checks, and guarantees memory boundary integrity. We hold weekly engineering standups and work closely with our faculty mentor, Steven Faulkner, and AdaCore’s Olivier Henley. Now, let's examine our stakeholder findings."

---

### Slide 5: Stakeholder Feedback Integration
* **Presenter:** Ryan Tomasko (Security & Validation Engineer)
* **Target Time:** 1:30 (Running Total: 5:45)
* **Slide Visual:** Stakeholder interview cards for Olivier Henley (AdaCore) and Steven Faulkner (GCU).

> **Spoken Script:**  
> "On Slide 5, we highlight how direct customer and mentor feedback actively shaped Beacon’s architectural directives.
>
> On October 14th, we interviewed Olivier Henley, UX Engineer and GAP Coordinator at AdaCore. We asked Olivier whether we should optimize for IoT hobbyists or mission-critical enterprise companies. His guidance was clear: design the system with **completeness and architectural rigor** first. While IoT enthusiasts will be our earliest adopters, building a complete, high-integrity architecture from day one is what will earn trust from aerospace and robotics enterprises.
>
> On October 15th, our team met with our GCU mentor, Steven Faulkner, to resolve three core architectural questions. First, regarding subscriber calls, Steven recommended implementing two distinct procedures: maintaining our indefinite blocking `Receive` for deterministic pipelines, while introducing a new timed `Receive` accepting a timeout parameter to prevent consumer deadlocks. 
>
> Second, regarding publisher registration, we decided against adding runtime overhead with a dynamic protected registry. Instead, we agreed to test locking down the publisher registry immediately after startup initialization, ensuring no unauthorized third party can declare rogue publishers. 
>
> Third, for `Try_Publish`, Steven advised providing a configurable mode parameter: allowing developers to choose between partial delivery for independent subscribers, or all-or-nothing delivery for control systems that require strict equilibrium. These directives form the foundation of our requirements."

---

### Slide 6: Functional Requirements & Target Metric Values
* **Presenter:** Ryan Tomasko (Security & Validation Engineer)
* **Target Time:** 1:30 (Running Total: 7:15)
* **Slide Visual:** 10-row Requirements Traceability Matrix with target values and measurement methods.

> **Spoken Script:**  
> "Slide 6 presents our comprehensive Functional Requirements Matrix, directly incorporating our coursework submissions. Each requirement is tied to stakeholder feedback, an industry standard, and a concrete verification method.
>
> Requirement FR-01 mandates 100% frame integrity validation via IEEE 802.3 CRC-32 checksums, measured in our test suite by injecting intentional bit-flipping faults. FR-02 enforces absolute compile-time type safety: the compiler must reject any attempt to pass untyped memory buffers. 
>
> FR-03 enforces single-publisher ownership per topic, matching OMG DDS QoS policies. FR-04 mandates guaranteed reliable delivery: when a reliable queue saturates, the publisher must block, and the drop count must remain mathematically zero—verified under sustained multi-task load. 
>
> FR-05 enforces bounded FIFO queues with zero heap in `src/`, verified by a SPARK Silver formal proof under the Ada Jorvik profile. FR-06 and FR-07 implement our stakeholder directives for microsecond-precision timed receives and publisher registry lockdown. Finally, FR-09 demands sensor streaming at over 1,000 Hertz with under 50 microseconds of dispatch latency, verified in our flight telemetry demonstrator. Now, Hovan will introduce our baseline design concept."

---

### Slide 7: Concept 1 Overview — Compile-Time Generic Protected Queues (Selected Baseline)
* **Presenter:** Hovan Hodges (Core Engineer)
* **Target Time:** 1:30 (Running Total: 8:45)
* **Slide Visual:** Component architecture diagram of Concept 1 showing generic topics and protected queues.

> **Spoken Script:**  
> "Thank you, Ryan. Slide 7 presents Concept 1: our selected baseline architecture, titled 'Compile-Time Generic Protected Queues'. 
>
> In Concept 1, there is no centralized message broker daemon. Instead, communication channels exist as compile-time generic package instantiations of `Beacon.Topic`. An engineer simply declares `package Temperature_Topic is new Beacon.Topic(Reading, Queue_Depth => 32)`. The Ada compiler instantiates a dedicated, statically typed pub-sub channel.
>
> Publication is decentralized: when a producer calls `Publish`, it executes a direct fan-out loop across registered subscriber protected queues within its own task context—without any intermediate daemon task or heap mailbox. 
>
> Crucially, we separate proof from concurrency: `Beacon.Queue` is a pure, generic ring buffer with zero tasking primitives, allowing us to mathematically prove its index safety in SPARK. `Beacon.Topic` then wraps this ring in an Ada protected object, using entry barriers to enforce our delivery modes under the Jorvik profile. Let's look at the detailed concurrency mechanics."

---

### Slide 8: Concept 1 Deep Dive — Assumptions, Schematics & Sketches
* **Presenters:** Hovan Hodges (Core) & Ryan Tomasko (Security & Validation)
* **Target Time:** 1:45 (Running Total: 10:30)
* **Slide Visual:** Physical memory layout and ASCII concurrency schematic of Concept 1.

> **Spoken Script (Hovan Hodges):**  
> "On Slide 8, we examine the physical assumptions and the architectural sketch of Concept 1. Our primary assumptions are that queue depths and subscriber counts are statically fixed at compile time, eliminating heap usage, and that element slots are read only between `Head` and `Tail` indexes using SPARK's `Relaxed_Initialization`.
>
> Looking at the sketch, trace the execution flow: when the Sensor Task calls `Publish`, it executes synchronously. In the left branch, Subscriber 1 is configured in `Reliable` mode: its entry barrier checks `Fill < Depth`. When full, the barrier closes, holding the calling task and guaranteeing that drop counts remain exactly zero. In the right branch, Subscriber 2 is `Best_Effort`: its entry barrier is unconditional. When full, pointer arithmetic pushes the head forward, overwriting the oldest sample to preserve the newest reading, while atomically incrementing the drop counter. Now, Ryan will speak to the security and boundary benefits."
>
> **Spoken Script (Ryan Tomasko):**  
> "From a security standpoint, observe that the publisher registry is locked down. All subscribers register during startup elaboration before any task calls `Publish`. Once publishing begins, the registry is locked, preventing unauthorized third-party tasks from creating rogue publishers or injecting unverified data. Memory isolation is absolute because every queue is a private protected record."

---

### Slide 9: Concept 2 Overview — Centralized Dynamic Broker with Heap Buffers
* **Presenter:** Praise Jibunor (Network Engineer)
* **Target Time:** 1:15 (Running Total: 11:45)
* **Slide Visual:** Architecture block diagram of Concept 2 showing central broker task, string tables, and heap mailboxes.

> **Spoken Script:**  
> "Thank you, Ryan. Slide 9 illustrates Alternative Concept 2, representing the industry-standard broker pattern found in Micro-ROS, MQTT, and commercial DDS runtimes. 
>
> In Concept 2, publishers and subscribers never communicate directly. Instead, all traffic routes through a centralized Message Broker Task. Topics are identified at runtime via text strings such as `'/telemetry/temperature'`. 
>
> When a producer publishes, it serializes its data into an untyped byte array allocated on the dynamic system heap. It posts this pointer to the broker's inbound mailbox. The broker task wakes up, queries a dynamic hash table to match topic strings, clones the payload for each subscriber using `malloc`, and deposits the buffers into per-subscriber heap mailboxes. 
>
> While this approach offers dynamic discovery flexibility, it introduces severe architectural and security hazards in safety-critical systems, as we detail on Slide 10."

---

### Slide 10: Concept 2 Deep Dive — Assumptions, Schematics & Sketches
* **Presenters:** Praise Jibunor (Network) & Ryan Tomasko (Security & Validation)
* **Target Time:** 1:30 (Running Total: 13:15)
* **Slide Visual:** Multi-hop heap pipeline sketch highlighting latency jitter, context switches, and memory hazards.

> **Spoken Script (Praise Jibunor):**  
> "Slide 10 illustrates the physical data pipeline and failure modes of Concept 2. Our sketch reveals four major bottlenecks. 
>
> First, every message must undergo serialization into an untyped byte array, adding CPU overhead. Second, publishing requires dynamic `malloc` calls, introducing non-deterministic execution jitter and memory fragmentation over long operational lifecycles. Third, because data must pass through the broker task, every publication requires two full task context switches, severely degrading our 1 kHz real-time streaming requirement. Fourth, subscriber queues rely on dynamic linked lists; when a subscriber lags, the heap grows uncontrollably until the operating system experiences an out-of-memory crash. Ryan will now address the security risks."
>
> **Spoken Script (Ryan Tomasko):**  
> "From a security perspective, Concept 2 violates our Project Charter's risk mitigations. Passing untyped byte buffers across public interfaces makes the system vulnerable to memory corruption, buffer overflows, and double-free bugs. Furthermore, allowing runtime string-based topic registration makes it trivial for rogue tasks to inject arbitrary payloads into sensitive topics without compile-time verification."

---

### Slide 11: Comparative Concept Assessment & Decision Matrix
* **Presenter:** Praise Jibunor (Network Engineer)
* **Target Time:** 1:30 (Running Total: 14:45)
* **Slide Visual:** Quantitative Pugh Decision Matrix with 7 weighted criteria and scoring breakdown.

> **Spoken Script:**  
> "Slide 11 presents our Systems Engineering Pugh Decision Matrix. In alignment with our Project Charter and stakeholder directives, safety-critical determinism, zero-heap bounds, and formal provability account for 75% of our total evaluation weight.
>
> Concept 1 scores a decisive **+1.75** out of a maximum +2.00. It receives top marks for compile-time type safety, zero dynamic heap allocation, guaranteed zero-drop reliability, and SPARK Silver provability.
>
> In contrast, Concept 2 receives a net negative score of **-1.50**. While Concept 2 scores high in runtime topology flexibility (+2)—since it supports dynamic topic creation—it fails completely in deterministic memory bounds, type safety, and DO-178C certifiability. Dynamic heap allocations cannot be formally proved under DO-333, and unpredictable heap exhaustion violates our core requirements. Therefore, our engineering team unanimously selects Concept 1 as our capstone baseline."

---

### Slide 12: Application of Appropriate Industry Standards
* **Presenter:** Praise Jibunor (Network Engineer)
* **Target Time:** 1:15 (Running Total: 16:00)
* **Slide Visual:** Industry Standards Matrix detailing ISO 8652 Jorvik, IEEE 802.3, FACE TSS, NASA cFE, and OMG DDS.

> **Spoken Script:**  
> "On Slide 12, we demonstrate how our current codebase directly implements established international industry standards.
>
> Under **ISO/IEC 8652:2023**, Beacon is built in Ada 2022 and strictly conforms to the **Jorvik Real-Time Profile** (Annex D.13), utilizing the Ceiling Priority Protocol to eliminate priority inversion and bound execution time. On the network wire, we enforce **IEEE 802.3** CRC-32 checksums and implement **RFC 768** UDP and **RFC 1112** IP Multicast inside an isolated bridge.
>
> Crucially, our architecture aligns with two premier defense and aerospace standards: **The Open Group FACE Technical Standard**, where our generic topics mirror the Transport Services Segment (TSS), and **NASA's Core Flight Executive (cFE) Software Bus**, where we upgrade traditional untyped C telemetry packets into compile-time verified Ada records. Finally, our delivery discriminants map directly to **OMG DDS v1.4** Quality of Service policies. Now, Hovan will walk through our roadmap."

---

### Slide 13: Concept Development Next Steps & Gantt Schedule
* **Presenter:** Hovan Hodges (Core Engineer)
* **Target Time:** 1:00 (Running Total: 17:00)
* **Slide Visual:** Gantt roadmap spanning Phase 2 through Phase 9 milestones.

> **Spoken Script:**  
> "On Slide 13, we outline our concrete development roadmap, directly tracking our Project Charter and Gantt schedule.
>
> We are currently in Phase 2, Weeks 7 and 8. Our immediate deliverable is implementing our stakeholder directive: timed `Receive` with timeout parameters, alongside hardening our protected entry barriers under multi-task contention. In Weeks 9 through 11, we will conduct sustained multi-task soak tests to verify that reliable queues never drop data, culminating in our Milestone 2 `v0.1.0-inproc` tagged release on November 22nd.
>
> In late fall, we integrate our cross-process UDP bridge and develop our serial UART transport with COBS framing. Next semester, we will discharge 100% of our SPARK Silver proof obligations using GNATprove, package `adacore_beacon` for the Alire Community Index, and present our final senior capstone defense."

---

### Slide 14: Summary & Technical Interrogation (Q&A)
* **Presenters:** All Team Members
* **Target Time:** 0:45 + Open Q&A (Running Total: 17:45)
* **Slide Visual:** Project summary checklist and open floor notice for questions.

> **Spoken Script (Hovan Hodges):**  
> "To summarize: Project Beacon delivers a high-integrity, compile-time verified publish-subscribe messaging architecture backed by AdaCore’s GNAT Academic Program. By enforcing that the type is the topic, eliminating dynamic heap allocations in our core library, and providing mathematically provable bounded queues, Beacon provides the safety and determinism that aerospace and robotics systems demand.
>
> Thank you, Professor Farris, Steven Faulkner, and fellow classmates. Our entire team—Hovan, Ryan, and Praise—is now ready to take your questions."

---

### Prepared Defense Q&A Cheat Sheet

* **Q1: "Why choose compile-time static generic topics over runtime dynamic discovery?"**
  * **Hovan Hodges:** *"Dynamic discovery requires runtime string parsing, dynamic memory allocation, and multicast discovery daemons, which violate DO-178C Level A determinism. In safety-critical aerospace and spaceflight systems—such as NASA cFE architectures—the communications topology is fully known at design time. Compile-time static generic instantiation eliminates discovery overhead, prevents schema mismatch bugs, and guarantees complete predictability."*

* **Q2: "How does the system prevent unauthorized third-party tasks from publishing on sensitive topics?"**
  * **Ryan Tomasko:** *"Following our consultation with Steven Faulkner, we rejected dynamic protected registries in favor of an initialization lockdown rule. All publishers and subscribers must be instantiated during pre-flight elaboration. Once publishing begins, the registry is locked, preventing unauthorized third-party tasks from declaring rogue publishers or injecting unverified data into the topic."*

* **Q3: "How do you verify that the uninitialized queue buffer does not leak garbage data?"**
  * **Hovan Hodges:** *"Because generic message types in Ada may lack default initialization, `Beacon.Queue` leaves unpopulated array slots uninitialized. We apply SPARK’s `Relaxed_Initialization` aspect and prove invariants `Tail = (Head + Fill) mod Depth`, mathematically guaranteeing through GNATprove that the system only reads valid slots between `Head` and `Tail`."*

* **Q4: "Who is the primary commercial sponsor, and what is AdaCore's stake in this capstone?"**
  * **Praise Jibunor:** *"AdaCore is the primary commercial provider of Ada and SPARK compilers and verification tools for aerospace (Airbus, Boeing, NASA). Through their GNAT Academic Program (GAP) coordinated by Olivier Henley, AdaCore sponsors this project to expand their open-source ecosystem by supplying verified, load-bearing pub-sub middleware on Alire for the next generation of embedded engineers."*

* **Q5: "What happens if a Reliable subscriber permanently stalls or crashes?"**
  * **Praise Jibunor:** *"In our baseline design, `Publish` blocks on a full Reliable queue to preserve the zero-drop invariant. However, for non-blocking publishers, we provide `Try_Publish(P, Msg, Delivered)` which reports refusal without blocking. Furthermore, as directed by Steven Faulkner, we are introducing timed `Receive` and queue timeouts in our current sprint to prevent unilateral task starvation."*

---
*End of Speaker Script (GCU Capstone Project Beacon)*
