# Beacon: Typed Publish-Subscribe Messaging in Ada
## Capstone Design Concepts & Architectural Trade Study Presentation

**Course:** STG-455: Capstone Project I  
**Institution:** Grand Canyon University (GCU), College of Science, Engineering and Technology  
**Faculty Advisor / Instructor:** Professor Dwight Farris  
**BEACON Team Mentor:** Steven Faulkner (steven.faulkner@gcu.edu)  
**Industry Partner & GAP Coordinator:** Olivier Henley, AdaCore (henley@adacore.com)  
**Target Presentation Duration:** 13–14 Minutes (Allocated for 10–15 Minute Session)  
**Document Classification:** Software Architecture, Requirements Traceability & Concept Development Specification  
**Authors / Engineering Team:**  
* **Hovan Hodges:** Core Engineer  
* **Ryan Tomasko:** Security & Validation Engineer  
* **Praise Jibunor:** Network Engineer  

---

## Executive Presentation Overview & Timetable

| Slide # | Slide Title | Core Topic / Content | Target Timing | Primary Presenter |
| :---: | :--- | :--- | :---: | :--- |
| **1** | Title & Project Organization | Project identity, GCU course, AdaCore GAP sponsorship & team roster | 0:45 | Hovan Hodges (Core) |
| **2** | Sponsor & Target Users: AdaCore & Community | Overview of AdaCore, GAP sponsorship, and the two-phased user adoption model | 1:15 | Praise Jibunor (Network) |
| **3** | Project Context & Purpose | Problem statement, ROS 2/DDS dynamic limits, safety-critical rationale | 1:15 | Hovan Hodges (Core) |
| **4** | Team Structure & Engineering Ownership | Division of responsibilities across Core, Security, Validation & Network | 1:00 | Ryan Tomasko (Security & Validation) |
| **5** | Stakeholder Feedback Integration | Interviews with Olivier Henley (AdaCore) and Steven Faulkner (GCU) | 1:30 | Ryan Tomasko (Security & Validation) |
| **6** | Functional Requirements & Measurement | 10 requirements mapped to customer feedback, standards & test metrics | 1:30 | Ryan Tomasko (Security & Validation) |
| **7** | Concept 1 Overview: Static Generic Protected Queues | Current baseline: Compile-time types, bounded ring, Ada protected objects | 1:30 | Hovan Hodges (Core) |
| **8** | Concept 1 Deep Dive: Schematics & Sketches | Assumptions, narrative description of sketch, ASCII memory & concurrency | 1:45 | Hovan Hodges & Ryan Tomasko |
| **9** | Concept 2 Overview: Centralized Dynamic Broker | Industry alternative: Dynamic heap mailboxes, string topics, broker task | 1:15 | Praise Jibunor (Network) |
| **10** | Concept 2 Deep Dive: Schematics & Sketches | Assumptions, narrative description of sketch, ASCII pipeline & jitter risks | 1:30 | Praise Jibunor & Ryan Tomasko |
| **11** | Comparative Concept Assessment & Decision Matrix | Quantitative Pugh trade matrix scoring against requirements & safety | 1:30 | Praise Jibunor (Network) |
| **12** | Application of Appropriate Industry Standards | ISO 8652 (Jorvik), IEEE 802.3, UDP/Multicast, FACE TSS, NASA cFE, OMG DDS | 1:15 | Praise Jibunor (Network) |
| **13** | Concept Development Next Steps & Gantt Gates | Upcoming sprint tasks (Timed Receive, soak tests, wire bridge, serial) | 1:00 | Hovan Hodges (Core) |
| **14** | Conclusion & Technical Q&A | Summary of baseline selection, security signoff, and defense interrogation | 0:45 | All Team Members |
| **15** | References | Academic, governmental, and industry standard citations in APA 7th Edition | — | Reference Record |

---

<!-- SLIDE 1 -->
# Slide 1: Title & Presentation Header
**Duration:** 0:45 | **Presenter:** Hovan Hodges (Core Engineer)

```
========================================================================================
                                     BEACON
                      Typed Publish-Subscribe Messaging in Ada
                Design Concepts, Architectural Trade Study & Next Steps
========================================================================================

             Grand Canyon University - College of Engineering and Technology
                                Course: STG-455
                        Instructor: Professor Dwight Farris

                     BEACON Team Mentor: Steven Faulkner (GCU)
            Industry Partner: AdaCore (GNAT Academic Program - GAP Coordinator)
                       Industry Mentor: Olivier Henley (AdaCore)

                                   TEAM ROSTER:
        * Hovan Hodges:      Core Engineer                  (Architecture & Formal Proofs)
        * Ryan Tomasko:      Security & Validation Engineer (Hardening, Harness & Metrics)
        * Praise Jibunor:    Network Engineer               (Framing, Multicast & Transports)
========================================================================================
```

### Speaker Notes
> "Good morning, Professor Farris, Steven Faulkner, and fellow engineering students. Today, our capstone team—Hovan Hodges, Ryan Tomasko, and Praise Jibunor—presents the Initial Design Concepts, Requirements Traceability, and Architectural Trade Study for Project **Beacon: Typed Publish-Subscribe Messaging in Ada**.
>
> Conducted in partnership with AdaCore’s GNAT Academic Program under our mentor Olivier Henley, Project Beacon provides a type-safe, deterministic publish-subscribe communications library engineered for safety-critical aerospace and embedded computing. 
>
> Over the next thirteen minutes, we will walk you through who our sponsor AdaCore is and who will use this project, our stakeholder feedback, our quantifiable requirements, two contrasting design concepts with detailed schematics and sketches, our formal trade study evaluation, and our verified roadmap to completion. Praise will now introduce our industry sponsor and target user community."

---

<!-- SLIDE 2 -->
# Slide 2: Industry Sponsorship & Target Users — Who is AdaCore & Who Will Use Beacon?
**Duration:** 1:15 | **Presenter:** Praise Jibunor (Network Engineer)

### Who is AdaCore?
* **Pioneer in High-Integrity Software (Est. 1994):** Founded by the original designers of the GNAT compiler at New York University; global leader in commercial development tools and formal verification solutions for Ada and SPARK.
* **Mission-Critical Industry Presence:**
  * **Aerospace & Defense:** Powering flight-control computers, avionics, and radar systems for Airbus, Boeing, Lockheed Martin, and Collins Aerospace.
  * **Spaceflight:** Supporting mission-critical flight software for NASA Artemis, the James Webb Space Telescope, and European Space Agency (ESA) deep-space missions.
  * **High-Assurance Infrastructure:** Deployed in high-speed rail signaling (Alstom, Siemens) and nuclear reactor control systems.
* **The GNAT Academic Program (GAP):** Sponsoring universities worldwide to cultivate software engineering excellence in safety-critical domains. Olivier Henley coordinates GAP and mentors our capstone team.

### Who Will Use Project Beacon? (Two-Phased Adoption Roadmap)
```
+---------------------------------------------------------------------------------------+
| PHASE 1: EMBEDDED IOT & ROBOTICS ENTHUSIASTS       PHASE 2: MISSION-CRITICAL AEROSPACE|
| (Grassroots Adoption - Near Term)                 (Enterprise Adoption - Long Term)  |
+--------------------------------------------------+------------------------------------+
| * Hobbyists & makers running microcontrollers    | * Avionics & flight control units  |
|   (ARM Cortex-M, STM32, RISC-V).                 |   complying with DO-178C Level A/B.|
| * Drone & autonomous mobile robot (AMR) builders | * CubeSat & small-satellite teams  |
|   seeking a zero-heap pub-sub alternative to C++.|   adopting NASA cFE software bus.  |
| * Simple package installation via Alire crate    | * Defense & aerospace programs     |
|   index: 'alr get adacore_beacon'.               |   mandating The Open Group FACE TSS|
+--------------------------------------------------+------------------------------------+
```

### Speaker Notes
> "On Slide 2, we answer two foundational questions: Who is our sponsor AdaCore, and who is the intended audience for Project Beacon?
>
> AdaCore was founded in 1994 by the original creators of the GNAT Ada compiler. Today, they are the world's preeminent provider of safety-critical software tools for Ada and SPARK. If you board an Airbus A350 or Boeing 787, or look at NASA's Artemis lunar spacecraft and ESA missions, the flight-critical software is built and verified with AdaCore tools. Through the GNAT Academic Program, coordinated by our mentor Olivier Henley, AdaCore partners with universities like GCU to drive innovation in high-assurance computing.
>
> As Olivier advised in our stakeholder interview, Beacon follows a two-phased adoption curve. Initially, our primary users are **embedded IoT developers and robotics enthusiasts**. These developers need a modern, lightweight publish-subscribe library that doesn't consume megabytes of RAM or crash from dynamic heap fragmentation like ROS 2 or C++ DDS. They can install Beacon with one command through Alire. 
>
> In the long term, because we design with complete architectural rigor, Beacon scales to **aerospace and defense enterprises** building satellites, avionics, and flight controllers that require mathematical proof of safety under DO-178C and NASA spaceflight standards. Now, Hovan will explain the core engineering problem Beacon solves."

---

<!-- SLIDE 3 -->
# Slide 3: Project Context, Purpose & Justification
**Duration:** 1:15 | **Presenter:** Hovan Hodges (Core Engineer)

### The Core Problem in Modern Robotics & Avionics Middleware
Modern distributed systems rely on the **Data-Centric Publish-Subscribe (DCPS)** model (standardized by OMG DDS and utilized in ROS 2). However, commercial and C/C++ implementations exhibit critical vulnerabilities when deployed in mission-critical environments:
* **Silent Runtime Type-Casting Errors:** Traditional frameworks cross the public API boundary using untyped memory buffers (`void*`, serialized byte arrays). A mismatched header or schema version causes silent memory corruption or runtime exceptions in flight.
* **Non-Deterministic Dynamic Heap Allocations:** Standard DDS and ROS 2 daemons rely heavily on runtime `malloc` and dynamic linked lists. This introduces unbounded latency spikes and long-term heap fragmentation—violating hard real-time constraints.
* **Unbounded Buffer Overflows:** When a subscriber cannot keep pace with high-rate publishers, memory growth or arbitrary packet dropping threatens system stability.

### The Beacon Innovation
Project Beacon leverages **Ada 2022** and **SPARK** to enforce safety at compile time:
* **"The Type IS the Topic":** Topics are generic package instantiations (`Beacon.Topic`). Publishers and subscribers agree on strongly typed Ada record types at compile time. Untyped byte buffers are strictly banned from the public API.
* **Zero Dynamic Heap in Core:** Fixed, bounded ring buffers (`Beacon.Queue`) pre-allocated at startup; zero heap allocations occur in `src/`.
* **Explicit Delivery Discriminants:** Delivery modes (`Reliable` vs. `Best_Effort`) are static type discriminants that directly select the concurrency barrier of Ada Protected Objects.

```
+---------------------------------------------------------------------------------------+
|  Traditional Middleware (DDS / ROS 2)  |  Project Beacon (Ada 2022 / SPARK Core)     |
|----------------------------------------+----------------------------------------------|
|  - Untyped byte buffers / void* APIs   |  - Generic Topic(Type): 100% compile-checked |
|  - Dynamic heap allocation (malloc)    |  - 0 bytes heap in core (Bounded ring buffer)|
|  - Silent drops or heap exhaustion     |  - Explicit Mode discriminant (Reliable/Best)|
|  - Complex C runtime vulnerabilities   |  - SPARK Silver formal proof of index safety |
+---------------------------------------------------------------------------------------+
```

### Speaker Notes
> "In modern autonomous robotics, avionics, and spacecraft, real-time publish-subscribe architectures are essential for decoupling sensors, controllers, and actuators. However, as documented in our Project Charter, conventional C++ runtimes such as ROS 2 and DDS pose serious safety risks. They pass untyped byte buffers across public interfaces, leading to silent type-casting errors. Furthermore, their reliance on dynamic heap allocation can trigger memory fragmentation and non-deterministic pauses.
>
> Beacon resolves these challenges at the language level. By instantiating generic packages in Ada 2022, every publish and receive call is verified by the compiler. Untyped byte arrays and `void*` casts are strictly prohibited. In addition, our core ring buffers operate with zero dynamic heap allocation, making the system predictable, memory-safe, and eligible for formal verification under SPARK."

---

<!-- SLIDE 4 -->
# Slide 4: Team Structure & Engineering Ownership
**Duration:** 1:00 | **Presenter:** Ryan Tomasko (Security & Validation Engineer)

### Organizational Structure & Division of Responsibilities

```
                               +-----------------------------------+
                               |     Faculty & Sponsor Board       |
                               | Prof. Dwight Farris (GCU)         |
                               | Steven Faulkner (Team Mentor)     |
                               | Olivier Henley (AdaCore Mentor)   |
                               +-----------------+-----------------+
                                                 |
                               +-----------------+-----------------+
                               |    Hovan Hodges (Core Engineer)   |
                               | Generic Topics & Bounded Queues   |
                               | SPARK Formally Verified Ring      |
                               +--------+-----------------+--------+
                                        |                 |
         +------------------------------+                 +-------------------------------+
         |                                                                                |
+--------+------------------------+                              +------------------------+--------+
|   Ryan Tomasko                  |                              |  Praise Jibunor                 |
|   Security & Validation Engineer|                              |  Network Systems Engineer       |
|   Publisher Registry Lockdown   |                              |  14-Byte Wire Framing (Rep Cls) |
|   AUnit Harness & Soak Testing  |                              |  IEEE 802.3 CRC-32 Validation   |
|   Injection & Memory Defense    |                              |  UDP Multicast & Serial Bridge  |
+---------------------------------+                              +---------------------------------+
```

### Role-Specific Mandates
1. **Core Engineer (Hovan Hodges):** Governs `Beacon.Topic`, `Beacon.Queue`, and `Beacon`. Implements bounded ring buffer arithmetic, Ada protected entries, and SPARK Silver contracts.
2. **Security & Validation Engineer (Ryan Tomasko):** Audits code to prevent malicious data injection and backdoor exploits; implements post-initialization publisher lockdown; leads unit, property, and sustained multi-task concurrency stress testing suites.
3. **Network Engineer (Praise Jibunor):** Architects `Beacon.Wire`, `Beacon.Transport`, and `Beacon.Bridge`; oversees IEEE 802.3 CRC-32 integrity checking and GNAT.Sockets UDP multicast communication.

### Speaker Notes
> "Slide 4 presents our consolidated engineering team structure. Our three-person team divides technical ownership into three distinct engineering disciplines to ensure complete coverage of the software lifecycle.
>
> Hovan Hodges, our Core Engineer, oversees the Ada generic specifications and SPARK proof contracts. Praise Jibunor, our Network Engineer, handles representation clauses for 14-byte wire framing, UDP multicast transport, and physical serial bridges.
>
> As Security & Validation Engineer, my responsibility is twofold: I lead our automated AUnit test harnesses and sustained concurrency stress testing, while ensuring our architecture eliminates unauthorized publisher registration, prevents payload tampering via CRC-32 checks, and guarantees memory boundary integrity. Together, we conduct weekly design reviews with Steven Faulkner and Olivier Henley."

---

<!-- SLIDE 5 -->
# Slide 5: Stakeholder Feedback Integration
**Duration:** 1:30 | **Presenter:** Ryan Tomasko (Security & Validation Engineer)

### Stakeholder Consultations & Translation to Architectural Requirements

```
   STAKEHOLDER INTERVIEW                            ENGINEERING DIRECTIVE TRANSLATION
+------------------------------------+   +-------------------------------------------------------+
| Olivier Henley (10/14)             |   | 1. System Completeness Over Good Features:            |
| UX Engineer & GAP Coordinator,     |   |    Design for overall completeness and architectural   |
| AdaCore                            |   |    rigor so that IoT adoption naturally leads to       |
| (henley@adacore.com)               |   |    adoption in mission-critical aerospace applications|
+------------------------------------+   +-------------------------------------------------------+
| Steven Faulkner (10/15)            |   | 2. Dual Subscriber Receive Procedures:                |
| BEACON Team Mentor, GCU            |   |    Maintain indefinite blocking Receive alongside a   |
| (steven.faulkner@gcu.edu)          |   |    new Timed Receive procedure with timeout parameter. |
|                                    |   | 3. Publisher Registration Lockdown:                   |
|                                    |   |    Lock down publisher registry after proper system   |
|                                    |   |    initialization so unauthorized tasks cannot publish|
|                                    |   | 4. Configurable Try_Publish Delivery Modes:           |
|                                    |   |    Introduce mode parameter for Partial Delivery vs.   |
|                                    |   |    All-or-Nothing delivery to maintain equilibrium.   |
+------------------------------------+   +-------------------------------------------------------+
```

### Detailed Design Solutions from Stakeholder Decisions
* **Directive 1 (Dual Receive Procedures):** In [`src/beacon-topic.ads`](../src/beacon-topic.ads), the existing `procedure Receive (S, Msg)` blocks indefinitely. In response to Steven Faulkner's feedback, we are introducing `procedure Receive (S, Msg, Timeout, Success)` using `Ada.Real_Time.Time_Span`, preventing consumer thread starvation.
* **Directive 2 (Publisher Registry Lockdown):** Rather than adding runtime overhead with a dynamic protected registry, we enforce that publisher registration is strictly executed during pre-flight elaboration. Once `Publish` is initiated, the registry enters a permanent locked state—mitigating third-party injection attacks.
* **Directive 3 (Configurable `Try_Publish` Modes):** Certain aerospace subsystems require strict equilibrium across all control surfaces (if one fails to receive, none should process), whereas telemetry fan-outs tolerate partial drops. We are implementing an enumerated parameter:
  ```ada
  type Try_Publish_Policy is (Partial_Delivery, All_Or_Nothing);
  ```

### Speaker Notes
> "On Slide 5, we detail how direct stakeholder feedback shaped our design. In our October 14th interview with Olivier Henley of AdaCore, we discussed our target user base. Olivier advised us not to compromise the architecture for casual users: although IoT enthusiasts will be the first to experiment with Beacon, designing with total completeness and rigor will position it for mission-critical adoption by aerospace companies.
>
> On October 15th, our team consulted with Steven Faulkner, our project mentor. This meeting resolved three open architectural decisions: First, we agreed to maintain two `Receive` procedures—the original blocking entry and a new timed `Receive` accepting a timeout parameter. Second, regarding publisher registration, we decided to lock down the publisher registry after initialization rather than implementing a dynamic protected object, preventing malicious third parties from declaring rogue publishers. Third, we agreed to enhance `Try_Publish` with an explicit delivery policy, allowing developers to choose between partial delivery and all-or-nothing delivery to safeguard system equilibrium."

---

<!-- SLIDE 6 -->
# Slide 6: Functional Requirements & Target Metric Values
**Duration:** 1:30 | **Presenter:** Ryan Tomasko (Security & Validation Engineer)

### Requirements Traceability Matrix

| Req ID | Functional Requirement Description | Target Engineering Metric / Value | Customer & Stakeholder Trace | Relationship to Industry Standard | Verification & Measurement Method |
| :---: | :--- | :--- | :---: | :---: | :--- |
| **FR-01** | **Frame Integrity Validation** | 100% of corrupt frames detected; 0 payload tamper acceptance | Faulkner & Henley Feedback | IEEE 802.3-2022 (CRC-32 Clause 3.2.9) | False bit-flipping fault injection in `wire_tests` |
| **FR-02** | **Type Safety at Public API** | 0 untyped byte buffers or `void*` casts across public API | Henley (Completeness Directive) | OMG DDS v1.4 §7.1.3 & NASA cFE Bus | Compiler rejection when passing untyped memory buffers |
| **FR-03** | **Single Publisher Enforcement** | Exactly 1 publisher permitted per topic instantiation | Project Charter / Faulkner Feedback | OMG DDS QoS Ownership Policy | Attempting to declare multiple publishers on same topic |
| **FR-04** | **Guaranteed Reliable Delivery** | Exactly 0 dropped messages (`Dropped = 0`); publisher blocks | Charter Requirement / Faulkner | OMG DDS v1.4 Reliability QoS Policy | Saturating queue and asserting `Dropped = 0` |
| **FR-05** | **Bounded FIFO Ring Queues** | Queue depth $N \in [1, 65535]$; 0 heap allocation in `src/` | Charter Constraint / Henley | ISO/IEC 8652:2023 Annex D.13 (Jorvik) | GNATprove SPARK Silver formal mathematical proof |
| **FR-06** | **Timed Receive Operation** | Timeout parameter $\ge 1\ \mu\text{s}$; unblocks on expiration | Faulkner Stakeholder Feedback | POSIX 1003.13 PSE51 & Ada Real-Time | Simulated delayed publisher asserting timeout return |
| **FR-07** | **Publisher Registry Lockdown** | 0 publishers registered post-initialization; tamper immune | Faulkner & Security Audit | The Open Group FACE TSS Architecture | Attempting post-elaboration publisher creation |
| **FR-08** | **Configurable Try_Publish** | Selectable `Partial_Delivery` vs. `All_Or_Nothing` mode | Faulkner Stakeholder Feedback | OMG DDS v1.4 Coherent Set QoS | Simulating 1 full subscriber among $N$ recipients |
| **FR-09** | **In-Process Throughput & Jitter** | Sensor rate $\ge 1{,}000\text{ Hz}$; Controller $\ge 10\text{ Hz}$; Latency $< 50\ \mu\text{s}$ | Systems Lead & Inproc Demo | NASA cFE & CCSDS SOIS Spaceflight | High-rate multi-task load test in `inproc_demo` |
| **FR-10** | **Cross-Process Network Bridge** | Forwarding $\ge 200\text{ msg/s}$ over UDP multicast | Charter Deliverable / Praise | RFC 768 (UDP) & RFC 1112 (Multicast) | Dual-process loopback test measuring sequence gaps |

### Speaker Notes
> "Slide 6 presents our comprehensive Functional Requirements Matrix, directly incorporating our coursework submissions. Every requirement is tied to stakeholder feedback, an industry standard, and a concrete measurement method.
>
> FR-01 mandates IEEE 802.3 CRC-32 frame integrity, measured by automated bit-flipping test vectors in `wire_tests`. FR-02 enforces strict compile-time type safety with zero untyped buffers. FR-03 and FR-04 reflect our single-publisher and reliable zero-drop requirements, aligned with OMG DDS QoS policies. FR-05 mandates bounded FIFO queues, measured by a SPARK Silver formal proof under the Ada Jorvik profile. Finally, requirements FR-06, FR-07, and FR-08 directly implement the timed receive, publisher lockdown, and configurable try-publish directives established during our mentor meetings."

---

<!-- SLIDE 7 -->
# Slide 7: Concept 1 Overview — Compile-Time Generic Protected Queues (Selected Baseline)
**Duration:** 1:30 | **Presenter:** Hovan Hodges (Core Engineer)

### Architectural Foundation
* **Type-Centric Decentralization:** Pub-sub channels exist as compile-time generic instantiations (`Beacon.Topic`). The message type defines the channel:
  ```ada
  package Temperature_Topic is new Beacon.Topic
    (Message_Type => Telemetry.Reading, Queue_Depth => 32, Max_Subscribers => 8);
  ```
* **Direct Protected Object Fan-Out:** Publishing is executed directly within the publisher's task context by iterating through registered subscriber protected queues. No central daemon, broker task, or OS mailbox exists.
* **Separation of Proof and Concurrency:**
  * [`src/beacon-queue.ads`](../src/beacon-queue.ads): Pure bounded ring buffer data structure (`Buffer`, `Head`, `Tail`, `Fill`). Zero tasking dependencies; target of **SPARK Silver** proof.
  * [`src/beacon-topic.ads`](../src/beacon-topic.ads): Concurrency wrapper enclosing `Beacon.Queue` inside an Ada protected type `Bounded_Queue` with Ceiling Priority Protocol.

```
+---------------------------------------------------------------------------------------+
|                  CONCEPT 1: COMPILE-TIME GENERIC PROTECTED QUEUES                    |
+---------------------------------------------------------------------------------------+
|  +---------------------------------------------------------------------------------+  |
|  | User Application (Telemetry Specification)                                      |  |
|  | package Temperature_Topic is new Beacon.Topic (Reading, Queue_Depth => 32);     |  |
|  +---------------------------------------------------------------------------------+  |
|                                          |                                            |
|                                          v                                            |
|  +---------------------------------------------------------------------------------+  |
|  | Beacon.Topic Instantiation (Static Memory Partition)                           |  |
|  |  +---------------------------------------------------------------------------+  |  |
|  |  | Publisher Object (P : Publisher) [Single Publisher Enforced]              |  |  |
|  |  | Fan-Out Dispatch: Direct Protected Entry Calls (Zero Intermediate Tasks)    |  |  |
|  |  +---------------------------------------------------------------------------+  |  |
|  |                                  |                        |                        |
|  |            +---------------------+                        +---------------------+  |
|  |            v                                                                    v  |
|  |  +----------------------------------+          +--------------------------------+  |
|  |  | Subscriber 1 (Mode: Reliable)    |          | Subscriber 2 (Mode: Best_Effrt)|  |
|  |  | Protected Bounded_Queue          |          | Protected Bounded_Queue        |  |
|  |  | Entry Barrier: [ Fill < Depth ]  |          | Entry Barrier: [ Always True ] |  |
|  |  | Publisher Blocks on Saturation   |          | Overwrites Oldest Sample       |  |
|  |  | Dropped = 0 (Checkable Promise)  |          | Drop Counter Incremented       |  |
|  |  | +------------------------------+ |          | +----------------------------+ |  |
|  |  | | Bounded Ring (SPARK Silver)  | |          | | Bounded Ring (SPARK Silver)| |  |
|  |  | +------------------------------+ |          | +----------------------------+ |  |
|  |  +----------------------------------+          +--------------------------------+  |
|  +---------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------+
```

### Speaker Notes
> "Slide 7 illustrates Concept 1, our baseline architecture. In Concept 1, topics are not runtime string lookup tables. Instead, each topic is an instantiation of the generic package `Beacon.Topic`. When an application instantiates `Temperature_Topic` with `Telemetry.Reading`, the compiler generates dedicated code where all message exchanges are checked at compile time.
>
> In this design, the publisher task iterates directly through the subscriber registry, dispatching items into each subscriber's protected queue. A key innovation of our design is the clean separation of proof and concurrency: `Beacon.Queue` is a pure ring buffer with no tasking dependencies, allowing us to formally verify its index arithmetic using SPARK. `Beacon.Topic` then wraps this queue in an Ada protected object to enforce thread synchronization under the Jorvik profile."

---

<!-- SLIDE 8 -->
# Slide 8: Concept 1 Deep Dive — Assumptions, Schematics & Sketches
**Duration:** 1:45 | **Presenters:** Hovan Hodges & Ryan Tomasko

### 1. Underlying Assumptions
1. **Assumption C1-A1 (Static Participant Bounds):** Maximum subscriber count (`Max_Subscribers`) and queue depth (`Queue_Depth`) are statically known at compile time, precluding runtime heap allocation.
2. **Assumption C1-A2 (Initialization Precedence & Lockdown):** All subscribers register during startup elaboration. The registry locks down before publishing begins, mitigating unauthorized third-party publisher creation.
3. **Assumption C1-A3 (Jorvik Profile Real-Time Tasking):** The underlying runtime supports Ada 2022 Protected Objects with entry queues and Ceiling Priority Protocol (ISO/IEC 8652:2023 Annex D.13).
4. **Assumption C1-A4 (Relaxed Buffer Initialization):** Memory slots in the generic ring are uninitialized until populated; GNATprove flow analysis verifies that only slots between `Head` and `Tail` are read.

### 2. Narrative Description of the Sketch
> *The sketch illustrates the physical memory topology and execution flow of Concept 1. At the top, the Sensor Task (producer) invokes `Publish(P, Msg)`. The call executes synchronously within the publisher's thread, executing direct fan-out calls to pre-registered subscribers without any intermediate broker task. The dispatch branches into two distinct protected queues. On the left, Subscriber 1 is configured with the `Reliable` discriminant: its entry barrier evaluates `Fill < Depth`. If the queue is saturated, the entry barrier remains closed, forcing the publisher task to wait and mathematically preserving the invariant `Dropped = 0`. On the right, Subscriber 2 is configured as `Best_Effort`: its entry barrier is unconditional (`True`). When full, the queue pushes out its oldest element, advancing the head pointer and incrementing the atomic drop counter. At the base, the Controller Task and Telemetry Logger independently drain messages via protected `Pop` operations or timed `Receive`.*

### 3. Rough Markdown & ASCII Visual Sketch
```
+=======================================================================================+
|                SKETCH: CONCEPT 1 CONCURRENCY & MEMORY TOPOLOGY                        |
+=======================================================================================+
|                                                                                       |
|   [ Sensor Task / Producer ] (Rate: ~1 kHz)                                           |
|               |                                                                       |
|               | 1. Compile-Time Type Check (Message_Type = Telemetry.Reading)         |
|               | 2. Direct Call: Publish (Pub, Msg)                                    |
|               v                                                                       |
|   +-------------------------------------------------------------------------------+   |
|   | IN-PROCESS DIRECT FAN-OUT (Executed within Publisher Thread Context)          |   |
|   | Publisher Registry: LOCKED (Zero third-party dynamic registrations allowed)   |   |
|   +-------------------------------------------------------------------------------+   |
|            |                                                         |                |
|            | Protected Entry Call 1                                  | Entry Call 2   |
|            v                                                         v                |
|   +------------------------------------+    +-------------------------------------+   |
|   | SUBSCRIBER 1: RELIABLE             |    | SUBSCRIBER 2: BEST_EFFORT           |   |
|   | Protected Bounded_Queue (Reliable) |    | Protected Bounded_Queue (Best_Eff)  |   |
|   |------------------------------------|    |-------------------------------------|   |
|   | Entry Barrier: [ Fill < Depth ]    |    | Entry Barrier: [ True (Unblocked) ] |   |
|   |                                    |    |                                     |   |
|   | * If Full: Publisher BLOCKS        |    | * If Full: Overwrites Oldest Sample |   |
|   |                                    |    |                                     |   |
|   |   Buffer Layout: Depth = 4         |    |   Buffer Layout: Depth = 4          |   |
|   |   +----+----+----+----+            |    |   +----+----+----+----+             |   |
|   |   | S1 | S2 | S3 |    |            |    |   | S5 | S2 | S3 | S4 |             |   |
|   |   +----+----+----+----+            |    |   +----+----+----+----+             |   |
|   |   Head=0, Tail=3, Fill=3           |    |   Head=1, Tail=1, Fill=4 (Wrapped)  |   |
|   |                                    |    |                                     |   |
|   |   INVARIANT: Dropped = 0 ALWAYS    |    |   METRIC: Drops_Count := Drops + 1  |   |
|   +------------------------------------+    +-------------------------------------+   |
|            |                                                         |                |
|            | Protected Pop / Timed Receive                           | Protected Pop  |
|            v                                                         v                |
|   [ Controller Task (10 Hz) ]                [ Telemetry Logger Task (100 Hz) ]       |
|                                                                                       |
+=======================================================================================+
```

### Speaker Notes
> "On Slide 8, Hovan and Ryan present the physical assumptions and concurrency sketch of Concept 1. Our design assumes fixed bounds at instantiation, completely eliminating dynamic heap allocation.
>
> In the sketch, observe the execution path: the Sensor Task invokes `Publish` directly within its own thread context, eliminating thread context-switch latency. For the Reliable subscriber on the left, if the buffer fills, the protected entry barrier closes, blocking the publisher and guaranteeing that drop counts remain zero. For the Best-Effort subscriber on the right, the barrier remains open: when full, pointer arithmetic overwrites the oldest sample and increments the drop counter. Notice also that following Steven Faulkner's feedback, the publisher registry is locked down, ensuring no unauthorized task can inject data into the topic."

---

<!-- SLIDE 9 -->
# Slide 9: Concept 2 Overview — Centralized Dynamic Broker with Heap Buffers
**Duration:** 1:15 | **Presenter:** Praise Jibunor (Network Engineer)

### Architectural Foundation
* **Centralized Dispatcher Daemon:** Emulates standard commercial middleware patterns (e.g., Micro-ROS, Eclipse Mosquitto, and dynamic DDS engines). Publishers and subscribers do not interact directly; instead, all traffic flows through an intermediary **Message Broker Task**.
* **Dynamic String-Based Topic Lookup:** Topics are identified at runtime via text strings (e.g., `"/telemetry/temperature"`). Dynamic hash tables route data based on string matching.
* **Heap-Allocated Mailboxes:** Messages are serialized into untyped byte arrays (`Stream_Element_Array`) and dynamically allocated on the OS heap via `malloc` or unbounded linked lists.

```
+---------------------------------------------------------------------------------------+
|                    CONCEPT 2: CENTRALIZED DYNAMIC BROKER WITH HEAP                   |
+---------------------------------------------------------------------------------------+
|  +-------------------------+                     +---------------------------------+  |
|  | Producer Task           |                     | Consumer Task                   |  |
|  | (Sensor Thread)         |                     | (Controller Thread)             |  |
|  +-------------------------+                     +---------------------------------+  |
|               |                                                   ^                   |
|               | Enqueue Raw Bytes                                 | Dequeue Bytes     |
|               v                                                   | & Cast Type       |
|  +---------------------------------------------------------------------------------+  |
|  |                     CENTRAL MESSAGE BROKER DAEMON (TASK)                        |  |
|  |  +---------------------------------------------------------------------------+  |  |
|  |  | Inbound Dynamic Mailbox: Linked List of malloc'd frames (Topic, Payload)   |  |  |
|  |  +---------------------------------------------------------------------------+  |  |
|  |  | String Routing Table: Dynamic Hash Map [ String Topic -> List(Subscribers) ]|  |
|  |  +---------------------------------------------------------------------------+  |  |
|  |  | Dispatch Engine: Walks Subscriber Lists, malloc's duplicate byte buffers,  |  |  |
|  |  | pushes into per-subscriber dynamic heap queues                            |  |  |
|  |  +---------------------------------------------------------------------------+  |  |
|  |  | Heap Memory Manager: Runtime 'malloc' and 'free' across shared heap pool   |  |  |
|  |  +---------------------------------------------------------------------------+  |  |
|  +---------------------------------------------------------------------------------+  |
+---------------------------------------------------------------------------------------+
```

### Speaker Notes
> "Slide 9 details Alternative Concept 2, representing the conventional broker-based pattern found in Micro-ROS, MQTT, and commercial DDS runtimes. In Concept 2, publishers and subscribers never communicate directly. Instead, all communication routes through an active Central Message Broker Task.
>
> Topics are identified at runtime via dynamic string names, and messages are serialized into generic byte buffers allocated on the dynamic heap. When a producer publishes, it posts an envelope to the broker's mailbox. The broker task wakes up, queries a dynamic hash table to match topic strings, clones the payload for each registered subscriber using `malloc`, and deposits the buffers into per-subscriber mailboxes. While this pattern offers dynamic discovery flexibility, it introduces severe vulnerabilities in safety-critical domains."

---

<!-- SLIDE 10 -->
# Slide 10: Concept 2 Deep Dive — Assumptions, Schematics & Sketches
**Duration:** 1:30 | **Presenters:** Praise Jibunor & Ryan Tomasko

### 1. Underlying Assumptions
1. **Assumption C2-A1 (Dynamic Heap Availability):** The target system provides a general-purpose dynamic memory allocator (`malloc`, `free`) with sufficient heap capacity.
2. **Assumption C2-A2 (Tolerable Latency Jitter):** Non-deterministic delays caused by heap allocation pauses, memory compaction, or page faults are acceptable to the real-time application.
3. **Assumption C2-A3 (Runtime Dynamic Topology):** Publishers and subscribers can be declared, discovered, and terminated dynamically at any point during system execution.
4. **Assumption C2-A4 (Marshaled Byte Stream Payloads):** All message types are serialized into untyped byte vectors and deserialized via runtime type casting at the subscriber.

### 2. Narrative Description of the Sketch
> *The sketch illustrates the multi-hop data pipeline and memory hazards of Concept 2. On the upper left, the Producer Task must serialize its typed data into an untyped byte array and execute a dynamic `malloc` call to allocate an envelope on the system heap. This pointer is posted to the Central Inbound Mailbox. In the center, the Broker Dispatcher Task consumes CPU cycles to perform string matching and walks linked lists. To fan out the message, the broker invokes `malloc` multiple times to clone the payload for each subscriber. Saturated queues trigger dynamic buffer resizing or unbounded heap growth until the OS heap allocator is exhausted. Finally, on the bottom right, consumer tasks retrieve raw byte streams, execute dynamic `free` calls, and perform unchecked type casts, creating severe memory leak, double-free, and dangling pointer risks.*

### 3. Rough Markdown & ASCII Visual Sketch
```
+=======================================================================================+
|                SKETCH: CONCEPT 2 DYNAMIC HEAP BROKER PIPELINE                         |
+=======================================================================================+
|                                                                                       |
|   [ Sensor Task / Producer ]                                                          |
|        |                                                                              |
|        | 1. Serialize Record -> Untyped Byte_Array                                    |
|        | 2. Heap Allocation: Ptr := malloc(Size)  <-- NON-DETERMINISTIC JITTER        |
|        v                                                                              |
|   +-------------------------------------------------------------------------------+   |
|   | CENTRAL INBOUND MAILBOX (Dynamic Linked List on System Heap)                   |   |
|   | [ Node 1: "/telemetry/temp" | Ptr ] -> [ Node 2: "/cmd/abort" | Ptr ] -> Null |   |
|   +-------------------------------------------------------------------------------+   |
|        |                                                                              |
|        v Context Switch (Task Scheduling Delay)                                       |
|   +-------------------------------------------------------------------------------+   |
|   | CENTRAL BROKER DISPATCHER TASK                                                |   |
|   |  - Dequeues inbound message envelope                                          |   |
|   |  - Evaluates String Match: Hash("/telemetry/temp") -> [Sub_A, Sub_B]          |   |
|   |  - Clones Payloads: Ptr_A := malloc(Size); Ptr_B := malloc(Size)              |   |
|   |  - SECURITY HAZARD: Buffer overflows, rogue publishers inject unverified bytes|   |
|   +-------------------------------------------------------------------------------+   |
|            |                                                         |                |
|            | Pushes Ptr_A                                            | Pushes Ptr_B   |
|            v                                                         v                |
|   +------------------------------------+    +-------------------------------------+   |
|   | SUBSCRIBER A HEAP QUEUE            |    | SUBSCRIBER B HEAP QUEUE             |   |
|   | Dynamic FIFO (std::vector / list)  |    | Dynamic FIFO (std::vector / list)   |   |
|   |------------------------------------|    |-------------------------------------|   |
|   | Overflows trigger heap realloc     |    | Unbounded heap growth under load    |   |
|   | Silent drops under OOM pressure    |    | Memory fragmentation over 24h run   |   |
|   +------------------------------------+    +-------------------------------------+   |
|            |                                                         |                |
|            v Context Switch                                          v Context Switch |
|   [ Controller Task ]                       [ Telemetry Logger Task ]                 |
|   - Casts void* / Deserializes raw bytes    - Casts void* / Deserializes raw bytes    |
|   - Calls free(Ptr_A) (Double-free risk)    - Calls free(Ptr_B) (Memory leak risk)    |
|                                                                                       |
+=======================================================================================+
```

### Speaker Notes
> "On Slide 10, Praise and Ryan highlight the operational vulnerabilities of Concept 2. Notice the numerous failure modes introduced by this architecture.
>
> First, messages must be converted into untyped byte buffers, stripping away compile-time type safety. Second, every publish requires dynamic memory allocation (`malloc`), which introduces non-deterministic execution jitter and risks heap exhaustion during long-duration missions. Third, data must pass through an intermediary broker task, incurring two full thread context switches per publish and degrading our 1 kHz throughput target. Finally, from a security standpoint, accepting untyped bytes and dynamic string registrations allows rogue tasks to inject arbitrary payloads—directly violating our Project Charter's risk mitigation objectives."

---

<!-- SLIDE 11 -->
# Slide 11: Comparative Concept Assessment & Decision Matrix
**Duration:** 1:30 | **Presenter:** Praise Jibunor (Network Engineer)

### Quantitative Pugh Decision Matrix
*Scoring Scale: (+2) Exceptional, (+1) Compliant, (0) Neutral / Baseline, (-1) Sub-optimal, (-2) Unacceptable / Safety Violation*

| Evaluation Criteria | Weight | Concept 1 (Static) | Concept 2 (Broker) | Technical Justification |
| :--- | :---: | :---: | :---: | :--- |
| **Type Safety (FR-02)** | 15% | **+2** (+0.30) | **-2** (-0.30) | Compile-checked generics vs raw bytes |
| **Zero Heap Determinism (FR-05)** | 25% | **+2** (+0.50) | **-2** (-0.50) | 0 bytes core heap vs malloc jitter |
| **Reliable Delivery (FR-04)** | 20% | **+2** (+0.40) | **-1** (-0.20) | Protected entry barrier vs OOM drops |
| **SPARK Provability (FR-05)** | 15% | **+2** (+0.30) | **-2** (-0.30) | Silver ring proof vs unprovable pointers |
| **Publisher Security (FR-07)** | 15% | **+2** (+0.30) | **-2** (-0.30) | Post-init lockdown vs open string topics |
| **Runtime Topology Flexibility** | 10% | **-1** (-0.10) | **+2** (+0.20) | Compile-time static vs ad-hoc discovery |
| **TOTAL WEIGHTED SCORE** | **100%** | **+1.70 (SELECTED)** | **-1.40 (REJECTED)** | **Concept 1 selected as formal baseline** |

### Assessment Synthesis
* **Why Concept 1 Wins:** Concept 1 overwhelmingly outperforms Concept 2 across all safety-critical, real-time, and formal verification dimensions. By accepting a minor constraint on dynamic runtime discovery, Concept 1 guarantees zero heap allocation, bounded execution time, and mathematical absence of runtime errors.
* **Formal Decision:** The team formally selects **Concept 1 (Compile-Time Generic Protected Queues)** as the engineering baseline for Project Beacon.

### Speaker Notes
> "Slide 11 presents our formal Systems Engineering Pugh Decision Matrix. Following our project charter and stakeholder priorities, safety-critical determinism, zero-heap predictability, and formal provability account for 75% of the total decision weight.
>
> Concept 1 scores +1.70 out of a maximum +2.00. It achieves top scores for compile-time type safety, zero-heap determinism, and SPARK provability. Concept 2 receives a net negative score of -1.40. While Concept 2 offers dynamic discovery flexibility—scoring +2 in that category—it completely fails our core requirements: its dynamic heap makes formal verification impossible under DO-333, introduces unbounded latency jitter, and creates severe heap exhaustion risks. Therefore, our team has unanimously selected Concept 1 as our capstone design baseline."

---

<!-- SLIDE 12 -->
# Slide 12: Application of Appropriate Industry Standards
**Duration:** 1:15 | **Presenter:** Praise Jibunor (Network Engineer)

### Standards Alignment Matrix (From Submitted Assignment)

```
+---------------------------------------------------------------------------------------+
|                      INDUSTRY STANDARDS EMBEDDED IN BEACON DESIGN                     |
+---------------------------------------------------------------------------------------+
|  ISO/IEC 8652:2023 & Annex D.13 (Ada 2022 / The Jorvik Profile)                       |
|  - Core Language: Beacon uses Ada 2022 as its core implementation language.          |
|  - Concurrency Determinism: Ceiling Priority Protocol eliminates priority inversion;  |
|    restricted tasking with single-entry protected objects ensures bounded WCET.       |
+---------------------------------------------------------------------------------------+
|  IEEE 802.3-2022 Clause 3.2.9 (Ethernet Frame Check Sequence / CRC-32)                |
|  - Wire Integrity: 32-bit CRC polynomial (0xEDB88320) validates wire payload integrity|
|    and detects bit-level corruption in transit.                                       |
+---------------------------------------------------------------------------------------+
|  UDP (RFC 768) & IP Multicast (RFC 1112) (Network Transport)                          |
|  - Isolated Bridge: Beacon uses UDP datagrams to carry messages between separate       |
|    programs on a LAN; Multicast enables one publisher to reach multiple subscribers.  |
+---------------------------------------------------------------------------------------+
|  The Open Group FACE Technical Standard (Transport Services Segment - TSS)           |
|  - DoD Architecture Alignment: Components exchange strongly typed messages locally or|
|    across a bridge without transport coupling; mirrors FACE TSS via Ada generics.     |
+---------------------------------------------------------------------------------------+
|  Spaceflight Standards (CCSDS SOIS & NASA cFE Software Bus)                           |
|  - Telemetry Routing: Replaces untyped C-based flight software buses with compile-time|
|    Ada generic topics (Telemetry.Reading) while preserving spaceflight-grade bounded  |
|    protected queues and explicit overwrite/FIFO delivery modes.                       |
+---------------------------------------------------------------------------------------+
|  OMG DDS v1.4 & Clause 2.2.3 Quality of Service (QoS) Policies                        |
|  - Pub-Sub Semantics: Maps directly to DDS RELIABLE (0 drops) and BEST_EFFORT         |
|    (KEEP_LAST depth N, drop-oldest replacement) delivery policies.                    |
+---------------------------------------------------------------------------------------+
```

### Direct Codebase Manifestation
* **Jorvik Profile:** [`src/beacon-topic.ads`](../src/beacon-topic.ads#L95-L106) implements `Bounded_Queue` as a single-entry protected object.
* **IEEE 802.3 CRC-32:** [`src/net/beacon-wire.ads`](../src/net/beacon-wire.ads#L66-L69) computes 32-bit checksums over packed 14-byte frames.
* **NASA cFE / CCSDS SOIS:** [`demo/src/telemetry.ads`](../demo/src/telemetry.ads#L14-L42) models aerospace spacecraft bus telemetry.

### Speaker Notes
> "On Slide 12, Praise presents our comprehensive Industry Standards Alignment Matrix, directly reflecting our submitted STG-455 coursework.
>
> In accordance with **ISO/IEC 8652:2023** and the **Jorvik Profile**, Beacon uses Ada 2022 to provide deterministic concurrency via the Ceiling Priority Protocol. On the network wire, we enforce **IEEE 802.3** CRC-32 error detection and leverage **RFC 768** UDP and **RFC 1112** IP Multicast. Crucially, our architecture aligns with two premier aerospace standards: **The Open Group FACE Technical Standard**, where our generic topics mirror the Transport Services Segment, and **NASA's Core Flight Executive (cFE) Software Bus**, where we upgrade traditional untyped C telemetry packets into compile-time verified Ada records. Finally, our delivery discriminants map directly to **OMG DDS v1.4** Quality of Service policies."

---

<!-- SLIDE 13 -->
# Slide 13: Concept Development Next Steps & Gantt Schedule
**Duration:** 1:00 | **Presenter:** Hovan Hodges (Core Engineer)

### Project Roadmap & Phase Milestones (From Project Charter)

```
OCTOBER 2026                 NOVEMBER 2026                DECEMBER 2026               SPRING 2027
+---------------------+      +---------------------+      +---------------------+     +--------------------+
| PHASE 2 (W07-W08)   | ===> | PHASE 3 (W09-W11)   | ===> | PHASE 4-5 (W12-W15) | ==> | PHASE 6-9 (W16-W32)|
| Timed Receive &     |      | In-Process Soak &   |      | Wire Protocol, UDP  |     | SPARK Silver Proof,|
| Design Review 1     |      | v0.1.0-inproc Tag   |      | & Serial Transport  |     | Alire Packaging    |
+---------------------+      +---------------------+      +---------------------+     +--------------------+
```

### Immediate Sprint Tasks & Upcoming Deliverables
1. **Phase 2 (Weeks 7–8: Oct 19 – Nov 01, 2026) — Timed Receive & Design Review 1:**
   * **Task 2.1:** Implement Timed `Receive (S, Msg, Timeout, Success)` in [`src/beacon-topic.ads`](../src/beacon-topic.ads) using `Ada.Real_Time`.
   * **Task 2.2:** Author unit test suite in [`tests/src/topic_tests.adb`](../tests/src/topic_tests.adb) verifying timeout unblocking.
   * **Task 2.3 & 2.4:** Harden protected queue entry barriers and implement multi-task blocking publish tests.
   * **Milestone Gate 1 (Oct 22):** Formal Design Review 1 presentation delivery.
2. **Phase 3 (Weeks 9–11: Nov 02 – Nov 22, 2026) — In-Process Soak & Demo Release:**
   * Execute multi-task sustained soak stress test asserting `Dropped(Reliable) = 0` invariant.
   * Audit zero-heap footprint with `gnatmem` and verify Jorvik compliance.
   * **Milestone Gate 2 (Nov 22):** Tag and release `v0.1.0-inproc`.
3. **Phase 4 & 5 (Weeks 12–15: Nov 23 – Dec 20, 2026) — Network & Serial Transports:**
   * Lay out wire header representation clauses and tune UDP multicast socket bridge.
   * Architect point-to-point Serial UART transport with COBS stream framing.
   * **Milestone Gate 3 & 4 (Dec 20):** Cross-process UDP demo and Fall Semester Transport Review.
4. **Spring Semester (Weeks 16–32: Jan – Apr 2027) — SPARK Proof & Alire Packaging:**
   * Discharge 100% of GNATprove Silver verification conditions on [`src/beacon-queue.ads`](../src/beacon-queue.ads).
   * Package `adacore_beacon` for the Alire Community Index; conduct final Capstone Defense.

### Speaker Notes
> "On Slide 13, Hovan outlines our concrete roadmap to complete the concept development and verification process, directly tracking our Project Charter and Gantt schedule.
>
> In our current sprint, Weeks 7 and 8, we are implementing our stakeholder directive: timed `Receive` with timeout parameters, and executing our multi-task blocking-publish tests. In Weeks 9 through 11, we will subject the in-process core to sustained soak testing to verify that reliable queues never drop data, culminating in Milestone 2—our `v0.1.0-inproc` release on November 22. 
>
> In late fall, we integrate our cross-process UDP bridge and develop our serial UART transport. In the spring semester, we will discharge 100% of our SPARK Silver proof obligations, publish `adacore_beacon` to the official Alire repository, and defend our final senior capstone."

---

<!-- SLIDE 14 -->
# Slide 14: Summary & Technical Interrogation (Q&A)
**Duration:** 0:45 | **Presenter:** All Team Members

```
========================================================================================
                                  PROJECT BEACON
                 High-Integrity Publish-Subscribe Messaging in Ada
========================================================================================

   [x] Industry-Backed Initiative: Sponsored by AdaCore GAP under Olivier Henley.
   [x] Targeted Two-Tier Community: Embedded IoT makers today, mission-critical aerospace tomorrow.
   [x] Type-Safe Compile-Time Topics: "The type is the topic" (Zero untyped byte buffers).
   [x] Zero Dynamic Heap in Core: Predictable embedded footprint under Jorvik Profile.
   [x] Explicit Delivery Discriminants: Reliable (0 drops) vs. Best_Effort (drop-oldest).
   [x] Verified Industry Alignment: ISO 8652 (Jorvik), IEEE 802.3, FACE TSS, NASA cFE, DDS.
   [x] Security-Hardened Architecture: Publisher lockdown blocks rogue third-party writers.
   [x] Proven Concept Superiority: Concept 1 scored +1.70 vs. Concept 2 (-1.40).
   [x] Open-Source Repository: https://github.com/H000V/GCU-beacon

========================================================================================
                      FLOOR OPEN FOR TECHNICAL QUESTIONS & REVIEW
========================================================================================
```

### Anticipated Defense Inquiries & Prepared Responses
* **Q1: "Why choose compile-time static generic topics over runtime dynamic discovery?"**  
  * *Response (Hovan Hodges):* Dynamic discovery requires runtime string parsing, hash maps, and heap allocation, which introduce non-deterministic jitter and prevent DO-178C Level A certification. In safety-critical aerospace and spaceflight systems (such as NASA cFE architectures), communications topology is known at design time; compile-time static generic instantiation eliminates discovery overhead and guarantees complete predictability.
* **Q2: "How does the system prevent third-party rogue tasks from publishing on sensitive topics?"**  
  * *Response (Ryan Tomasko):* Following our stakeholder meeting with Steven Faulkner, we rejected dynamic protected registries in favor of an initialization lockdown rule. All publishers and subscribers must be instantiated during pre-flight elaboration. Once publishing begins, the registry is locked, preventing unauthorized third-party tasks from creating rogue publishers.
* **Q3: "How do you verify that the uninitialized queue buffer does not leak garbage data?"**  
  * *Response (Hovan Hodges):* Because generic message types in Ada may lack default initialization, `Beacon.Queue` leaves unpopulated slots uninitialized. We apply SPARK's `Relaxed_Initialization` aspect and prove invariants `Tail = (Head + Fill) mod Depth`, mathematically guaranteeing through GNATprove that the system only reads valid slots between `Head` and `Tail`.
* **Q4: "Who is the primary commercial sponsor, and what is AdaCore's stake in this capstone?"**  
  * *Response (Praise Jibunor):* AdaCore is the primary commercial provider of Ada and SPARK compilers and verification tools for aerospace (Airbus, Boeing, NASA). Through their GNAT Academic Program (GAP) coordinated by Olivier Henley, AdaCore sponsors this project to expand their open-source ecosystem by supplying verified, load-bearing pub-sub middleware on Alire for the next generation of embedded engineers.

### Speaker Notes
> "In summary, Project Beacon delivers a high-integrity publish-subscribe architecture tailored for real-time, safety-critical aerospace applications. By enforcing static generic typing, bounded memory, and Ada protected object concurrency, we achieve mathematical guarantees of safety that traditional broker-based systems cannot match. 
> 
> Thank you, Professor Farris, Steven Faulkner, and peers. Our team is now prepared to take your questions."

---

<!-- SLIDE 15 -->
# Slide 15: Academic, Industry & Government Citations (APA 7th Edition)
**Presenter:** Reference Record

### Formal References
* AdaCore. (2022). *SPARK 2022 reference manual: Formally proving safety and security*. AdaCore Documentation. https://docs.adacore.com/spark2022-docs/html/ug/
* Barnes, J. (2014). *Programming in Ada 2012*. Cambridge University Press.
* Burns, A., & Wellings, A. (2009). *Real-time systems and programming languages: Ada, Real-Time Java and C/Real-Time POSIX* (4th ed.). Addison-Wesley.
* Consultative Committee for Space Data Systems. (2014). *Spacecraft onboard interface services — Subnetwork packet service* (CCSDS Standard No. 851.0-M-1). CCSDS. https://public.ccsds.org/Pubs/851x0m1.pdf
* Institute of Electrical and Electronics Engineers. (2022). *IEEE standard for Ethernet: Clause 3.2.9 Frame check sequence (FCS) field* (IEEE Std 802.3-2022). IEEE. https://doi.org/10.1109/IEEESTD.2022.9844436
* International Organization for Standardization, & International Electrotechnical Commission. (2023). *Information technology — Programming languages — Ada: Annex D.13 The Jorvik profile* (ISO/IEC Standard No. 8652:2023). ISO. https://www.iso.org/standard/83621.html
* National Aeronautics and Space Administration. (2020). *Core Flight Executive (cFE) application programmer’s interface* (Version 6.7). Goddard Space Flight Center. https://github.com/nasa/cFE
* Object Management Group. (2015a). *Data Distribution Service (DDS) specification* (Version 1.4, OMG Document No. formal/2015-04-10). OMG. https://www.omg.org/spec/DDS/1.4/
* Object Management Group. (2015b). *Data Distribution Service (DDS) specification: Clause 2.2.3 Quality of Service (QoS) policies* (Version 1.4, OMG Document No. formal/2015-04-10). OMG. https://www.omg.org/spec/DDS/1.4/
* Pinho, L. M., & Wellings, A. (2021). The Jorvik profile: Real-time concurrency for embedded systems in Ada. *Ada User Journal*, 42(1), 35–42.
* Postel, J. (1980). *User Datagram Protocol* (RFC No. 768). Internet Engineering Task Force. https://doi.org/10.17487/RFC0768
* RTCA & EUROCAE. (2011a). *DO-178C / ED-12C: Software considerations in airborne systems and equipment certification*. RTCA, Inc.
* RTCA & EUROCAE. (2011b). *DO-333 / ED-216: Formal methods supplement to DO-178C and ED-12C*. RTCA, Inc.
* Taft, S. T., Duff, R. A., Brukardt, R. L., Pinho, L. M., & Henley, O. (2023). *Ada 2022 reference manual: Language and standard libraries*. Springer Nature. https://doi.org/10.1007/978-3-031-29704-5
* The Open Group. (2020). *Future Airborne Capability Environment (FACE™) technical standard, edition 3.1*. The Open Group. https://www.opengroup.org/face

---
*End of Design Concepts Presentation Document (GCU Senior Capstone Project Beacon)*
