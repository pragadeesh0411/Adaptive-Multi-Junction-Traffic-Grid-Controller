# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

## Task 1 – System Architecture Planning

The **Adaptive Multi-Junction Traffic Grid Controller (AMTGC)** is a coordinated traffic-control architecture for two 4-way traffic junctions, **Junction A** and **Junction B**.

The purpose of this stage is to define the complete system architecture before RTL implementation begins. The design includes coordinated traffic signal sequencing, green-wave coordination, a shared pedestrian arbiter, emergency override handling, a common clock domain, and a defined reset strategy.

Task 1 is limited to **system architecture planning and verification planning**. RTL implementation and simulation will be completed in the later tasks.

---

## 1. Project Objectives

The planned AMTGC system will:

* Control two 4-way traffic junctions.
* Provide North-South and East-West traffic signal sequencing.
* Maintain an all-red safety interval between conflicting traffic directions.
* Coordinate Junction A and Junction B using a green-wave mechanism.
* Use one shared pedestrian arbiter for both junctions.
* Handle simultaneous pedestrian requests fairly.
* Prevent starvation of either junction's pedestrian request.
* Provide a system-wide emergency override.
* Use a single clock domain.
* Provide a defined reset strategy.
* Support traffic-density information for adaptive timing in later tasks.
* Use a modular and reusable architecture.

---

## 2. System Architecture

The planned system contains the following major modules:

```text
AMTGC Top-Level Controller

        |
        +-----------------------------+
        |                             |
        v                             v
Shared Pedestrian              Green-Wave
Arbiter                        Coordinator
        |                             |
     Grant A/B                  Delayed Signal
        |                             |
   +----+----+                  +-----+-----+
   |         |                  |           |
   v         v                  v           v
Junction A  Junction B      Junction A   Junction B
Controller Controller       NS Green     Coordination
   |         |
   v         v
Timer A    Timer B
```

The complete graphical architecture is provided separately as:

```text
docs/amtgc_block_diagram.png
docs/amtgc_block_diagram.svg
```

---

## 3. Main Modules

### 3.1 AMTGC Top-Level Controller

The top-level controller connects all major modules.

Its responsibilities include:

* Distributing the common clock.
* Distributing reset.
* Distributing the emergency override.
* Connecting pedestrian requests.
* Connecting traffic-density inputs.
* Connecting Junction A and Junction B.
* Connecting the shared pedestrian arbiter.
* Connecting the green-wave coordinator.

The top-level module is intended mainly for integration and signal routing rather than implementing the detailed traffic FSM itself.

---

### 3.2 Junction Controller

Two junctions are controlled using the same basic controller architecture:

* Junction A
* Junction B

The controller is planned as a Moore FSM.

The normal traffic sequence is:

```text
NS_GREEN
    |
    v
NS_YELLOW
    |
    v
ALL_RED
    |
    v
EW_GREEN
    |
    v
EW_YELLOW
    |
    v
ALL_RED
    |
    v
NS_GREEN
```

A pedestrian phase may be inserted at a safe transition point.

The same controller architecture will later be reused for both junctions with configurable timing parameters.

---

### 3.3 Generic Timer

The generic timer is intended to provide the timing function for traffic phases.

Responsibilities:

* Start counting when enabled.
* Count clock cycles toward a target.
* Generate a completion indication.
* Reset when inactive or reset.
* Remain independent from traffic-specific FSM logic.

This separation allows the timer to be reused by both junction controllers.

---

### 3.4 Shared Pedestrian Arbiter

Instead of implementing separate pedestrian controllers for Junction A and Junction B, one shared pedestrian arbiter is used.

The arbiter receives:

```text
pedestrian_request_a
pedestrian_request_b
```

and produces:

```text
ped_grant_a
ped_grant_b
```

The selected arbitration method is **round-robin arbitration**.

The arbiter is responsible only for request and grant handling. It does not need to access the internal FSM state of either junction controller.

---

### 3.5 Green-Wave Coordinator

The green-wave coordinator establishes a timing relationship between Junction A and Junction B.

The intended relationship is:

```text
Junction A NS Green Start
           |
           | Defined Delay
           v
Junction B NS Green Start
```

The coordinator receives the North-South green indication from Junction A and produces a delayed coordination signal for Junction B.

The timing delay will be configurable and will later be measured during simulation.

---

## 4. Module Interfaces

### 4.1 AMTGC Top-Level

| Signal                 | Direction       | Purpose                              |
| ---------------------- | --------------- | ------------------------------------ |
| `clk`                  | Input           | Common system clock                  |
| `reset`                | Input           | System reset                         |
| `emergency_override`   | Input           | System-wide emergency signal         |
| `pedestrian_request_a` | Input           | Pedestrian request from Junction A   |
| `pedestrian_request_b` | Input           | Pedestrian request from Junction B   |
| `traffic_density_a`    | Input           | Traffic-density input for Junction A |
| `traffic_density_b`    | Input           | Traffic-density input for Junction B |
| `a_ns_green`           | Output          | Junction A North-South green         |
| `a_ns_yellow`          | Output          | Junction A North-South yellow        |
| `a_ns_red`             | Output          | Junction A North-South red           |
| `a_ew_green`           | Output          | Junction A East-West green           |
| `a_ew_yellow`          | Output          | Junction A East-West yellow          |
| `a_ew_red`             | Output          | Junction A East-West red             |
| `b_ns_green`           | Output          | Junction B North-South green         |
| `b_ns_yellow`          | Output          | Junction B North-South yellow        |
| `b_ns_red`             | Output          | Junction B North-South red           |
| `b_ew_green`           | Output          | Junction B East-West green           |
| `b_ew_yellow`          | Output          | Junction B East-West yellow          |
| `b_ew_red`             | Output          | Junction B East-West red             |
| `ped_grant_a`          | Internal/Output | Pedestrian grant for A               |
| `ped_grant_b`          | Internal/Output | Pedestrian grant for B               |
| `green_wave_signal`    | Internal        | Delayed coordination signal for B    |

---

### 4.2 Junction Controller

| Signal               | Direction | Purpose                                  |
| -------------------- | --------- | ---------------------------------------- |
| `clk`                | Input     | Common system clock                      |
| `reset`              | Input     | Controller reset                         |
| `emergency_override` | Input     | Emergency transition request             |
| `traffic_density`    | Input     | Traffic-density information              |
| `pedestrian_request` | Input     | Local pedestrian request                 |
| `pedestrian_grant`   | Input     | Grant from shared arbiter                |
| `green_wave_start`   | Input     | Green-wave coordination signal           |
| `ns_red`             | Output    | North-South red                          |
| `ns_yellow`          | Output    | North-South yellow                       |
| `ns_green`           | Output    | North-South green                        |
| `ew_red`             | Output    | East-West red                            |
| `ew_yellow`          | Output    | East-West yellow                         |
| `ew_green`           | Output    | East-West green                          |
| `pedestrian_active`  | Output    | Pedestrian phase indication              |
| `state_code`         | Output    | FSM state information                    |
| `timer_target`       | Output    | Current timing target                    |
| `ped_pending`        | Output    | Pending pedestrian request indication    |
| `ped_service_done`   | Output    | Pedestrian service completion indication |

---

### 4.3 Generic Timer

| Signal         | Direction | Purpose                  |
| -------------- | --------- | ------------------------ |
| `clk`          | Input     | Common system clock      |
| `reset`        | Input     | Timer reset              |
| `start`        | Input     | Starts timer operation   |
| `count_target` | Input     | Timer target value       |
| `done`         | Output    | Indicates target reached |
| `count`        | Output    | Current counter value    |

---

### 4.4 Pedestrian Arbiter

| Signal           | Direction | Purpose                        |
| ---------------- | --------- | ------------------------------ |
| `clk`            | Input     | Common system clock            |
| `reset`          | Input     | Arbiter reset                  |
| `req_a`          | Input     | Pedestrian request from A      |
| `req_b`          | Input     | Pedestrian request from B      |
| `service_done_a` | Input     | A pedestrian service completed |
| `service_done_b` | Input     | B pedestrian service completed |
| `grant_a`        | Output    | Pedestrian grant for A         |
| `grant_b`        | Output    | Pedestrian grant for B         |

---

### 4.5 Green-Wave Coordinator

| Signal            | Direction | Purpose                         |
| ----------------- | --------- | ------------------------------- |
| `clk`             | Input     | Common system clock             |
| `reset`           | Input     | Coordinator reset               |
| `source_ns_green` | Input     | Junction A NS green indication  |
| `wave_start`      | Output    | Delayed green-wave signal for B |

---

## 5. Pedestrian Arbitration and Starvation Prevention

A shared pedestrian arbiter is used instead of two duplicated controllers because pedestrian requests must be coordinated fairly at the system level.

For example, when both requests are active:

```text
Request A = 1
Request B = 1
```

and Junction A currently has priority:

```text
Grant A = 1
Grant B = 0
```

After Junction A's request is served, the priority changes to Junction B.

The next simultaneous request therefore becomes:

```text
Grant A = 0
Grant B = 1
```

The priority continues to rotate after successful service.

This round-robin approach prevents permanent priority from being assigned to one junction and is intended to prevent starvation.

---

## 6. Emergency Override

One common system input is used:

```text
emergency_override
```

When the signal is activated, both junction controllers must transition to the all-red safety condition within the defined response limit.

During emergency operation:

```text
Junction A:
NS = RED
EW = RED

Junction B:
NS = RED
EW = RED
```

The emergency override remains active until it is deasserted.

After emergency operation ends, the system should resume from a valid and known traffic state rather than an undefined state.

The final emergency response will be verified by simulation in later tasks.

---

## 7. Green-Wave Coordination

The green-wave mechanism is intended to coordinate traffic between Junction A and Junction B.

The planned relationship is:

```text
A NS GREEN START
       |
       | Configurable Delay
       v
B NS GREEN START
```

The green-wave coordinator remains separate from both junction FSMs.

This approach prevents Junction B from depending directly on the internal state implementation of Junction A.

The final timing offset will be measured from the simulation waveform and documented as part of later verification.

---

## 8. Clocking Strategy

The AMTGC system uses a:

```text
Single Clock Domain
```

All major modules operate from the same `clk`.

The common clock is used by:

* Junction A controller
* Junction B controller
* Generic Timer A
* Generic Timer B
* Pedestrian Arbiter
* Green-Wave Coordinator

A single clock domain simplifies synchronization and timing verification.

---

## 9. Reset Strategy

The planned reset strategy is:

```text
Synchronous Active-High Reset
```

The reset is intended to place the system into known safe states.

The intended reset condition is:

```text
Junction A = ALL_RED
Junction B = ALL_RED
Timer A = Reset
Timer B = Reset
Pedestrian Arbiter = Initial Priority
FSM State = Known State
```

The final RTL implementation will follow and verify this design decision in later tasks.

---

## 10. Verification Plan

The following verification scenarios are defined during Task 1:

| No. | Scenario                          | Expected Result                                 |
| --: | --------------------------------- | ----------------------------------------------- |
|   1 | Startup reset                     | Both junctions enter a known safe state         |
|   2 | Junction A NS green               | NS green, EW red                                |
|   3 | Junction A NS yellow              | Correct transition from NS green                |
|   4 | NS yellow to all-red              | Safe all-red interval                           |
|   5 | All-red to EW green               | EW green only after all-red                     |
|   6 | EW green to EW yellow             | Correct transition                              |
|   7 | EW yellow to all-red              | Safe all-red interval                           |
|   8 | Complete FSM sequence             | All phases occur in the expected order          |
|   9 | Pedestrian request A              | A request is eventually serviced                |
|  10 | Pedestrian request B              | B request is eventually serviced                |
|  11 | Simultaneous A/B request          | Fair arbiter decision                           |
|  12 | Repeated simultaneous requests    | No starvation                                   |
|  13 | Emergency during NS green         | Both junctions safely enter all-red             |
|  14 | Emergency during EW green         | Both junctions safely enter all-red             |
|  15 | Emergency during pedestrian phase | Both junctions safely enter all-red             |
|  16 | Emergency release                 | Valid safe traffic operation resumes            |
|  17 | Green-wave coordination           | B NS green starts after A by defined delay      |
|  18 | Reset during active operation     | System returns to known safe state              |
|  19 | Pedestrian request during yellow  | Request is retained and serviced safely         |
|  20 | Repeated pedestrian requests      | Requests are handled without starvation         |
|  21 | Conflicting green check           | Conflicting directions are never green together |
|  22 | All-red interval check            | Non-zero safety gap exists                      |

---

## 11. Design Assumptions

The Task 1 architecture assumes:

1. Junction A and Junction B use the same basic traffic-controller structure.
2. Timing parameters will be introduced during RTL development.
3. The pedestrian arbiter is shared by both junctions.
4. Round-robin arbitration is used for simultaneous requests.
5. Emergency override is common to the complete system.
6. Emergency override has the highest operational priority.
7. Both junctions enter all-red during emergency operation.
8. Green-wave timing is configurable.
9. Traffic-density-based adaptation will be implemented in a later task.
10. Final timing values will be validated through simulation.

---

## 12. Repository Structure

The planned repository is:

```text
AMTGC/
│
├── README.md
│
├── rtl/
│   └── RTL files added in later tasks
│
├── tb/
│   └── Testbenches added in later tasks
│
├── docs/
│   ├── task1_architecture.md
│   ├── amtgc_block_diagram.png
│   └── amtgc_block_diagram.svg
│
├── sim/
│   └── Simulation files added in later tasks
│
└── screenshots/
    └── Verification screenshots added later
```

---

## 13. Task 1 Completion Checklist

* [ ] System architecture defined
* [ ] Junction A defined
* [ ] Junction B defined
* [ ] Shared pedestrian arbiter defined
* [ ] Green-wave coordinator defined
* [ ] Generic timer defined conceptually
* [ ] Module interfaces documented
* [ ] Pedestrian fairness explained
* [ ] Starvation prevention explained
* [ ] Emergency strategy explained
* [ ] Single clock domain defined
* [ ] Reset strategy defined
* [ ] At least 15 verification scenarios defined
* [ ] Top-level block diagram included
* [ ] Architecture reviewed before RTL development

---

## 14. Status

**Project:** Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

**Task:** Task 1 – System Architecture Planning

**Status:** Planning-stage architecture and verification contract prepared.

RTL implementation and simulation are intentionally reserved for the subsequent tasks.
"""

readme_path.write_text(readme, encoding="utf-8")
print(readme_path)
print(readme_path.stat().st_size)
