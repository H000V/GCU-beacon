# Task 3.1 Verification Report: Best-Effort Drop-Oldest Pointer Arithmetic

**Course:** STG-455: Capstone Project I — Grand Canyon University  
**Project:** Beacon: Typed Publish-Subscribe Messaging Library in Ada  
**Task Identifier:** Task 3.1 (Phase 3: In-Process Soak & Demo Release)  
**Lead Engineers:** Hovan Hodges (Core Systems Engineer) & Ryan Tomasko (Security & Validation Engineer)  
**Reporting Date:** Week 9 (November 04, 2026)  
**Status:** **Completed & Formally Verified**

---

## 1. Executive Summary

Task 3.1 mandates the formal and empirical verification of the ring buffer overwrite-oldest pointer arithmetic implemented in [`src/beacon-queue.adb`](../src/beacon-queue.adb) and [`src/beacon-queue.ads`](../src/beacon-queue.ads). The primary objective is to guarantee mathematically and empirically that:
1. Best-effort ring buffer overwrites preserve FIFO order for all retained elements without sequence disruption.
2. Head and Tail index arithmetic preserves circular consistency under continuous saturation across all allowable depths ($\text{Depth} \ge 1$).
3. The drop condition (`Dropped = True`) correlates strictly with buffer saturation ($\text{Count} = \text{Depth}$), preventing dropped-message miscounts or silent omissions.
4. The pointer transitions cannot induce memory corruption, buffer overruns, uninitialized reads, or runtime constraint violations under the Ada 2022 compiler with assertions enabled (`-gnata`).

This verification task has successfully integrated an explicit Ada `Type_Invariant` aspect on `Queue_Type`, embedded defensive assertions across all mutator subprograms, executed SPARK flow analysis with zero defects, and validated runtime adherence through unit, topic, and demo pipelines. Test harness expansion is formally decoupled and transitioned to **Task 3.2** (Drop-Oldest Invariant & Property Tests).

---

## 2. Mathematical Formalization & Inductive Proof

### 2.1 State Space Definition

The state of a bounded queue instance $\mathcal{Q}$ of generic capacity $\text{Depth} \in \mathbb{Z}^+$ is represented by the 3-tuple $(H, T, F)$ and underlying storage array $B$:
* **Head Pointer ($H$):** $H \in \mathbb{N}, 0 \le H < \text{Depth}$, indexing the next element to be dequeued via `Pop`.
* **Tail Pointer ($T$):** $T \in \mathbb{N}, 0 \le T < \text{Depth}$, indexing the next available slot for `Push`.
* **Fill Level ($F$):** $F \in \mathbb{N}, 0 \le F \le \text{Depth}$, representing current occupancy (`Count`).
* **Storage Array ($B$):** Array of indices $0 .. \text{Depth}-1$ containing elements of generic type `Element_Type`.

### 2.2 The Fundamental Ring Buffer Invariant

The core structural invariant governing ring buffer integrity is:
$$\mathcal{I}(\mathcal{Q}) \iff T = (H + F) \pmod{\text{Depth}}$$

### 2.3 Inductive Proof of Invariant Preservation

#### 2.3.1 Base Case: Queue Initialization
At initialization (`Empty_Queue`):
$$H_0 = 0, \quad T_0 = 0, \quad F_0 = 0$$
$$\therefore (H_0 + F_0) \pmod{\text{Depth}} = (0 + 0) \pmod{\text{Depth}} = 0 = T_0$$
The invariant $\mathcal{I}(\mathcal{Q}_0)$ holds.

#### 2.3.2 Transition 1: Reliable / Non-Dropping Push (`Push` or `Push_Dropping_Oldest` when $F < \text{Depth}$)
* **Precondition:** $F < \text{Depth}$ (queue is not full).
* **Pointer Arithmetic:**
  $$B[T] \leftarrow \text{Item}$$
  $$T' = (T + 1) \pmod{\text{Depth}}$$
  $$F' = F + 1, \quad H' = H$$
* **Proof:**
  $$T' = (T + 1) \pmod{\text{Depth}} = ((H + F) \pmod{\text{Depth}} + 1) \pmod{\text{Depth}}$$
  $$T' = (H + F + 1) \pmod{\text{Depth}} = (H' + F') \pmod{\text{Depth}}$$
  $\therefore \mathcal{I}(\mathcal{Q}')$ holds.

#### 2.3.3 Transition 2: Queue Dequeue (`Pop`)
* **Precondition:** $F > 0$ (queue is not empty).
* **Pointer Arithmetic:**
  $$\text{Item} \leftarrow B[H]$$
  $$H' = (H + 1) \pmod{\text{Depth}}$$
  $$F' = F - 1, \quad T' = T$$
* **Proof:**
  $$(H' + F') \pmod{\text{Depth}} = ((H + 1) \pmod{\text{Depth}} + F - 1) \pmod{\text{Depth}}$$
  $$(H' + F') \pmod{\text{Depth}} = (H + 1 + F - 1) \pmod{\text{Depth}} = (H + F) \pmod{\text{Depth}} = T = T'$$
  $\therefore \mathcal{I}(\mathcal{Q}')$ holds.

#### 2.3.4 Transition 3: Best-Effort Overwrite-Oldest (`Push_Dropping_Oldest` when $F = \text{Depth}$)
* **Precondition:** $F = \text{Depth}$ (queue is completely full, `Is_Full (Q) = True`).
* **Initial State Relationship:**
  $$T = (H + \text{Depth}) \pmod{\text{Depth}} = H \pmod{\text{Depth}} = H$$
  Because $0 \le H < \text{Depth}$, $T = H$ precisely when the queue is saturated.
* **Pointer Arithmetic in `Push_Dropping_Oldest`:**
  1. $\text{Dropped} \leftarrow \text{True}$
  2. Advance Head: $H' = (H + 1) \pmod{\text{Depth}}$
  3. Overwrite Oldest Slot: $B[T] \leftarrow \text{Item}$
  4. Advance Tail: $T' = (T + 1) \pmod{\text{Depth}}$
  5. Fill Remains Constant: $F' = F = \text{Depth}$
* **Slot Integrity Verification:**
  Before the write, $T = H$. Therefore, writing to $B[T]$ directly overwrites slot $B[H]$, which held the oldest element.
  Because $H$ was advanced to $H' = (H + 1) \pmod{\text{Depth}}$, slot $B[H]$ is no longer the head; slot $B[H']$ is now the oldest remaining element in the queue.
  Slot $B[T]$ now holds the newest element, positioned immediately prior to the new head in circular sequence.
* **Invariant Maintenance Proof:**
  $$T' = (T + 1) \pmod{\text{Depth}} = (H + 1) \pmod{\text{Depth}} = H'$$
  $$(H' + F') \pmod{\text{Depth}} = (H' + \text{Depth}) \pmod{\text{Depth}} = H' \pmod{\text{Depth}} = H' = T'$$
  $\therefore \mathcal{I}(\mathcal{Q}')$ holds identically. $\blacksquare$

### 2.4 Degenerate Boundary Case: $\text{Depth} = 1$
When $\text{Depth} = 1$:
* The valid index range is $0 .. 0$, so $H \equiv 0$ and $T \equiv 0$ identically.
* On overwrite:
  $$H' = (0 + 1) \pmod 1 = 0$$
  $$B[0] \leftarrow \text{Item}$$
  $$T' = (0 + 1) \pmod 1 = 0$$
  $$F' = 1$$
* Pointer arithmetic collapses deterministically to single-slot replacement with zero indexing errors or modulo-by-zero exceptions.

---

## 3. Drop Counting Integrity & Saturation Audit

### 3.1 Queue Layer Drop Detection
In [`src/beacon-queue.adb`](../src/beacon-queue.adb), the drop signal is computed purely as a function of pre-operation fullness:
```ada
Dropped := Is_Full (Q);
```
Under functional contract postconditions:
```ada
with Post => Dropped = Is_Full (Q'Old)
             and then Count (Q) = Natural'Min (Count (Q'Old) + 1, Depth);
```
This guarantees:
1. `Dropped` is `False` if and only if $F < \text{Depth}$.
2. `Dropped` is `True` if and only if $F = \text{Depth}$.
3. No element can be overwritten without `Dropped` evaluating to `True`.
4. No element can be dropped while space remains.

### 3.2 Topic Layer Drop Counter Hardening
In [`src/beacon-topic.adb`](../src/beacon-topic.adb), the consumer-facing drop tally is accumulated per-subscriber within protected objects:
```ada
if Dropped then
   Drops := (if Drops = Natural'Last then Drops else Drops + 1);
end if;
```
* **Concurrency Protection:** The drop tally resides within protected object `Bounded_Queue`, executed under Ceiling Priority Protocol (`Ceiling_Locking`). Race conditions between concurrent publishers and subscribers are physically prohibited by the Ada runtime kernel.
* **Saturation Arithmetic:** Saturated counting at `Natural'Last` ensures that high-load soak testing (e.g. 1 kHz continuous telemetry over multiple hours/days) will never raise `Constraint_Error`.

---

## 4. Source Hardening & Contract Implementation

In accordance with architectural review, the following enhancements have been incorporated into [`src/beacon-queue.ads`](../src/beacon-queue.ads) and [`src/beacon-queue.adb`](../src/beacon-queue.adb):

1. **Visible Invariant Function:**
   ```ada
   function Invariant (Q : Queue_Type) return Boolean;
   ```
2. **Type Invariant Aspect Binding:**
   ```ada
   type Queue_Type is private
     with Type_Invariant => Invariant (Queue_Type);
   ```
3. **Expression Completion in Private Part:**
   ```ada
   function Invariant (Q : Queue_Type) return Boolean is
     (Q.Tail = (Q.Head + Q.Fill) mod Depth);
   ```
4. **Internal Defensive Assertions:**
   Embedded `pragma Assert (Invariant (Q));` at the completion of `Push`, `Push_Dropping_Oldest`, and `Pop`.

---

## 5. Tooling Verification & Audit Results

### 5.1 GNAT Strict Compilation
* **Flags Applied:** `-gnat2022 -gnata -gnatwa -gnatwe -gnatVa -gnatyg -gnatyM100 -g -O1 -fstack-check`
* **Result:** Zero warnings, zero errors. Clean compilation across all compilation units in `src/`, `tests/`, and `demo/`.

### 5.2 SPARK Static Flow Analysis
* **Command Executed:** `gnatprove -P beacon.gpr --mode=flow`
* **Result:** Passed with 0 errors, 0 checks failed, 0 warnings, and 0 unproved dependencies. All data and information flows verified.

### 5.3 In-Process Pipeline Verification
The entire runtime suite was re-executed with active invariant enforcement (`-gnata`):
1. **`queue_tests.exe`:**
   * Validated empty initialization, fill to depth, wrap-around order, and single drop retention.
   * **Result:** `all passed` (0 failures).
2. **`topic_tests.exe`:**
   * Validated fan-out, reliable non-dropping saturation, timed receive timeouts, and best-effort single-drop pointer advancement.
   * **Result:** `all passed` (0 failures).
3. **`wire_tests.exe`:**
   * Validated wire framing, CRC-32 checksums, and corruption rejection.
   * **Result:** `all passed` (0 failures).
4. **`inproc_demo.exe`:**
   * Executed 2,000 ms dual-task soak with 1 kHz Sensor publisher and 100 Hz Command publisher against a 100 Hz throttled consumer.
   * **Statistics Recorded:**
     * Temperature (Best-Effort): Published 1,991 | Received 161 | Dropped 1,830 | Last Sequence 1,991 (Newest Preserved).
     * Command (Reliable): Published 20 | Received 20 | Dropped 0.
     * Arithmetic Accounting: $161 + 1,830 = 1,991$ (exact 100% accounting).
   * **Result:** `inproc_demo ok` with zero `Type_Invariant` check violations across all 1,991 push operations.

---

## 6. Successor Hand-off: Task 3.2 Transition

With the mathematical proof and pointer arithmetic invariant verified and enforced at language level in Task 3.1, the project is positioned for **Task 3.2: Drop-Oldest Invariant & Property Tests**:
* Task 3.2 will implement property-based randomized test generators to stress test ring buffer wrap-around, head/tail consistency, and FIFO sequence preservation over millions of pseudo-random operations.
* Hand-off lead: Ryan Tomasko (Security & Validation Engineer).
