# Task 1 – System Architecture Planning

## Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

### 1. Project Overview

The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) is designed to coordinate two 4-way traffic junctions, Junction A and Junction B, as a single traffic control system.

Each junction controls traffic in two directions:

* North-South (NS)
* East-West (EW)

The system supports normal traffic signal sequencing, green-wave coordination, shared pedestrian request handling, and a system-wide emergency override.

Junction A and Junction B do not operate completely independently. A green-wave coordination mechanism is used so that Junction B's North-South green phase starts after a defined delay from Junction A's North-South green phase.

A shared pedestrian arbiter is used instead of implementing separate pedestrian controllers for both junctions. The arbiter receives pedestrian requests from both junctions and provides a fair grant decision.

A single emergency override input is provided for the complete system. When emergency override is activated, both junctions safely transition to an all-red condition within the defined response limit.

The architecture is designed as a modular and reusable RTL system so that the same junction controller can later be instantiated for both Junction A and Junction B with different timing parameters.

---

## 2. High-Level Architecture

The proposed AMTGC architecture contains the following major modules:

1. Junction A Controller
2. Junction B Controller
3. Shared Pedestrian Arbiter
4. Green-Wave Coordinator
5. Generic Timer
6. AMTGC Top-Level Controller

The top-level controller connects these modules and provides the common clock, reset, pedestrian requests, traffic information, and emergency override.

### Top-Level Block Diagram

```text
                         +----------------------------------+
                         |        AMTGC TOP LEVEL           |
                         |                                  |
Clock -----------------> |                                  |
Reset -----------------> |                                  |
Emergency Override ----> |                                  |
                         |                                  |
                         |   +--------------------------+   |
                         |   | Shared Pedestrian        |   |
Pedestrian Request A --> |   | Arbiter                  |   |
Pedestrian Request B --> |   |                          |   |
                         |   | Fair Grant A / Grant B    |   |
                         |   +------------+-------------+   |
                         |                |                 |
                         |                |                 |
                         |      +---------+---------+       |
                         |      |                   |       |
                         |      v                   v       |
                         | +------------+     +------------+|
Traffic Density A -----> | | Junction A |     | Junction B || <----- Traffic Density B
                         | | Controller |     | Controller ||
                         | +-----+------+     +------+-----+|
                         |       |                   |      |
                         |       |                   |      |
                         |       v                   v      |
                         | +-----------+         +-----------+
                         | | Timer A   |         | Timer B   |
                         | +-----------+         +-----------+
                         |                                  |
                         |      Green-Wave Coordinator      |
                         |   A NS Green --> Delay --> B NS  |
                         |                         Green     |
                         +----------------------------------+

              Junction A Traffic Signals       Junction B Traffic Signals
                    NS / EW / Pedestrian             NS / EW / Pedestrian
```

### Green-Wave Signal Path

```text
Junction A NS Green
        |
        v
Green-Wave Coordinator
        |
        | Defined delay
        v
Junction B NS Green Start
```

The green-wave coordinator provides the timing relationship between the two junctions without requiring Junction B to directly access the internal FSM state of Junction A.

---

## 3. Module Description

### 3.1 AMTGC Top-Level Controller

The top-level module connects all system modules.

Responsibilities:

* Distribute the common clock and reset.
* Connect Junction A and Junction B.
* Connect the shared pedestrian arbiter.
* Connect the green-wave coordination path.
* Distribute the emergency override signal.
* Provide the external system interface.

The top-level module does not implement detailed traffic FSM logic itself. Its main purpose is system integration and signal routing.

---

### 3.2 Junction Controller

There are two instances of the same junction controller module:

* Junction A Controller
* Junction B Controller

Both controllers implement the normal traffic signal sequence using a Moore FSM.

The main traffic states are:

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
     +----> NS_GREEN
```

A pedestrian phase may be inserted when a valid pedestrian request is granted.

The same RTL module is intended to be reused for both junctions. Timing parameters can be different without creating a completely new controller design.

---

### 3.3 Generic Timer

The generic timer provides the timing function required by the junction controllers.

Responsibilities:

* Start counting when requested.
* Count clock cycles up to a configurable target.
* Produce a completion signal when the target is reached.
* Reset the count when the timer is not active.
* Operate independently from the traffic FSM.

Keeping the timer separate prevents timing/counting logic from being duplicated inside the FSM.

---

### 3.4 Shared Pedestrian Arbiter

The pedestrian arbiter receives requests from both Junction A and Junction B.

```text
Request A ----\
               \
                > Shared Pedestrian Arbiter
               /
Request B ----/

                 |
          +------+------+
          |             |
       Grant A       Grant B
```

The arbiter is shared rather than duplicated because pedestrian requests are a system-level resource that should be coordinated between the two junctions.

A round-robin arbitration policy is selected.

When both requests are active simultaneously:

* If Junction A has the current priority, Junction A is granted.
* After Junction A is served, the priority changes to Junction B.
* If both request again, Junction B is granted.
* After Junction B is served, priority returns to Junction A.

This prevents one junction from continuously receiving priority and provides starvation prevention.

---

### 3.5 Green-Wave Coordinator

The green-wave coordinator manages the timing relationship between Junction A and Junction B.

The main requirement is:

```text
Junction A NS Green Start
              |
              | Defined delay
              v
Junction B NS Green Start
```

The coordinator receives an indication that Junction A has entered its North-South green phase.

It then generates a delayed coordination signal for Junction B.

The delay is treated as a configurable design parameter rather than a fixed value hidden inside the FSM logic.

The green-wave coordinator does not directly control all traffic states. It only provides the timing coordination signal required by Junction B.

---

## 4. Module Interfaces

### 4.1 AMTGC Top-Level Interface

| Signal                 | Direction       | Purpose                               |
| ---------------------- | --------------- | ------------------------------------- |
| `clk`                  | Input           | Common system clock                   |
| `reset`                | Input           | System reset                          |
| `emergency_override`   | Input           | Forces both junctions toward all-red  |
| `pedestrian_request_a` | Input           | Pedestrian request from Junction A    |
| `pedestrian_request_b` | Input           | Pedestrian request from Junction B    |
| `traffic_density_a`    | Input           | Traffic information for Junction A    |
| `traffic_density_b`    | Input           | Traffic information for Junction B    |
| `a_ns_green`           | Output          | Junction A NS green indication        |
| `a_ns_yellow`          | Output          | Junction A NS yellow indication       |
| `a_ns_red`             | Output          | Junction A NS red indication          |
| `a_ew_green`           | Output          | Junction A EW green indication        |
| `a_ew_yellow`          | Output          | Junction A EW yellow indication       |
| `a_ew_red`             | Output          | Junction A EW red indication          |
| `b_ns_green`           | Output          | Junction B NS green indication        |
| `b_ns_yellow`          | Output          | Junction B NS yellow indication       |
| `b_ns_red`             | Output          | Junction B NS red indication          |
| `b_ew_green`           | Output          | Junction B EW green indication        |
| `b_ew_yellow`          | Output          | Junction B EW yellow indication       |
| `b_ew_red`             | Output          | Junction B EW red indication          |
| `ped_grant_a`          | Output/Internal | Pedestrian grant for Junction A       |
| `ped_grant_b`          | Output/Internal | Pedestrian grant for Junction B       |
| `green_wave_signal`    | Internal        | Coordination signal toward Junction B |

---

### 4.2 Junction Controller Interface

| Signal               | Direction | Purpose                                |
| -------------------- | --------- | -------------------------------------- |
| `clk`                | Input     | Common system clock                    |
| `reset`              | Input     | Controller reset                       |
| `emergency_override` | Input     | Emergency transition request           |
| `traffic_density`    | Input     | Traffic-density information            |
| `pedestrian_request` | Input     | Local pedestrian request               |
| `pedestrian_grant`   | Input     | Grant from shared arbiter              |
| `green_wave_start`   | Input     | Delayed green-wave command             |
| `ns_red`             | Output    | North-South red                        |
| `ns_yellow`          | Output    | North-South yellow                     |
| `ns_green`           | Output    | North-South green                      |
| `ew_red`             | Output    | East-West red                          |
| `ew_yellow`          | Output    | East-West yellow                       |
| `ew_green`           | Output    | East-West green                        |
| `pedestrian_active`  | Output    | Indicates pedestrian phase             |
| `state_code`         | Output    | Current FSM state for verification     |
| `timer_target`       | Output    | Current timing target for verification |
| `ped_pending`        | Output    | Indicates pending pedestrian request   |
| `ped_service_done`   | Output    | Indicates completed pedestrian service |

---

### 4.3 Generic Timer Interface

| Signal         | Direction | Purpose                         |
| -------------- | --------- | ------------------------------- |
| `clk`          | Input     | Common system clock             |
| `reset`        | Input     | Timer reset                     |
| `start`        | Input     | Enables timer counting          |
| `count_target` | Input     | Number of clock cycles to count |
| `done`         | Output    | Indicates target reached        |
| `count`        | Output    | Current counter value           |

The timer is intentionally kept independent from traffic-specific information.

---

### 4.4 Pedestrian Arbiter Interface

| Signal           | Direction | Purpose                            |
| ---------------- | --------- | ---------------------------------- |
| `clk`            | Input     | Common system clock                |
| `reset`          | Input     | Arbiter reset                      |
| `req_a`          | Input     | Pedestrian request from Junction A |
| `req_b`          | Input     | Pedestrian request from Junction B |
| `service_done_a` | Input     | A pedestrian service completed     |
| `service_done_b` | Input     | B pedestrian service completed     |
| `grant_a`        | Output    | Grant for Junction A               |
| `grant_b`        | Output    | Grant for Junction B               |

The arbiter uses only request and grant/service information. It does not access the internal FSM states of either junction.

---

### 4.5 Green-Wave Coordinator Interface

| Signal            | Direction | Purpose                                    |
| ----------------- | --------- | ------------------------------------------ |
| `clk`             | Input     | Common system clock                        |
| `reset`           | Input     | Coordinator reset                          |
| `source_ns_green` | Input     | Junction A NS green indication             |
| `wave_start`      | Output    | Delayed coordination signal for Junction B |

---

## 5. Traffic Signal Operation

The normal traffic operation of each junction follows the sequence:

### Phase 1 – North-South Green

```text
NS = GREEN
EW = RED
```

North-South traffic is allowed to move.

### Phase 2 – North-South Yellow

```text
NS = YELLOW
EW = RED
```

North-South traffic receives a transition warning.

### Phase 3 – All Red

```text
NS = RED
EW = RED
```

A safety interval is provided before the conflicting direction receives green.

### Phase 4 – East-West Green

```text
NS = RED
EW = GREEN
```

East-West traffic is allowed to move.

### Phase 5 – East-West Yellow

```text
NS = RED
EW = YELLOW
```

East-West traffic receives a transition warning.

### Phase 6 – All Red

```text
NS = RED
EW = RED
```

Another safety interval is provided before returning to North-South operation.

### Optional Pedestrian Phase

When a pedestrian request is granted, the junction enters a pedestrian phase while vehicle signals remain all-red.

```text
NS = RED
EW = RED
Pedestrian = ACTIVE
```

---

## 6. Pedestrian Arbitration Strategy

A single shared pedestrian arbiter is used instead of two separate pedestrian controllers.

The main reasons are:

1. Both junctions share the same system-level pedestrian service resource.
2. Centralized arbitration provides consistent priority handling.
3. It prevents duplicated arbitration logic.
4. It makes simultaneous requests easier to manage.
5. A round-robin policy provides fairness.

### Simultaneous Request Example

Suppose:

```text
Request A = 1
Request B = 1
```

and the current priority is Junction A.

The arbiter produces:

```text
Grant A = 1
Grant B = 0
```

After Junction A's pedestrian service completes, the next priority becomes Junction B.

If both requests are again active:

```text
Grant A = 0
Grant B = 1
```

Therefore neither junction can permanently dominate the other.

---

## 7. Starvation Prevention

Starvation is prevented using a round-robin priority pointer.

The priority rotates after a successful pedestrian service.

```text
Initial priority
       |
       v
       A
       |
   A served
       |
       v
       B
       |
   B served
       |
       v
       A
```

If only one junction requests service, that request is served directly.

If both request simultaneously, the rotating priority determines the first grant.

This provides a simple and deterministic fairness mechanism.

---

## 8. Emergency Override Strategy

A single system-level signal is used:

```text
emergency_override
```

When this input is asserted:

```text
emergency_override = 1
```

both junction controllers must leave their current traffic phase and transition safely toward an all-red condition.

The planned emergency response bound is:

```text
Maximum emergency transition time = 1 clock cycle
```

This means that after the emergency condition is sampled by the synchronous system, both junctions are required to be in the all-red safety condition by the next active clock edge.

During emergency operation:

```text
Junction A:
NS = RED
EW = RED

Junction B:
NS = RED
EW = RED
```

The system remains in the safe condition while emergency override remains active.

After the emergency signal is removed, the controllers restart from a valid safe traffic state rather than continuing from an undefined state.

---

## 9. Clocking Strategy

The complete AMTGC design uses a:

```text
Single synchronous clock domain
```

All major modules use the same `clk` input:

```text
AMTGC Top
    |
    +--> Junction A Controller
    |
    +--> Junction B Controller
    |
    +--> Pedestrian Arbiter
    |
    +--> Green-Wave Coordinator
    |
    +--> Generic Timers
```

### Reason for Single Clock Domain

A single clock domain simplifies:

* FSM synchronization
* timer operation
* pedestrian arbitration
* green-wave timing
* emergency response
* simulation and verification

No clock-domain crossing logic is required between the modules.

This also makes the timing relationship between Junction A and Junction B easier to measure during simulation.

---

## 10. Reset Strategy

The planned reset strategy is:

```text
Synchronous active-high reset
```

### Reason

A synchronous reset is selected so that state changes occur only on the common system clock. This keeps all major state elements aligned within the single clock domain.

When reset is asserted, the system returns to a known safe state.

The initial safe state for both traffic controllers is:

```text
ALL_RED
```

The pedestrian arbiter priority is reset to its initial priority.

The timer counter is reset to zero.

All FSM registers therefore start from known values.

---

## 11. Green-Wave Coordination

The green-wave mechanism is intended to reduce unnecessary stopping between the two junctions.

The relationship is:

```text
A NS GREEN START
       |
       | configurable delay
       v
B NS GREEN START
```

The green-wave delay is treated as a configurable architectural parameter.

Junction B receives a coordination signal generated from Junction A's North-South green indication.

The green-wave coordinator does not directly control Junction A or read the internal FSM state of Junction A.

It only observes the defined external NS-green signal and produces the delayed coordination event.

The final delay must be measured in simulation and recorded in the verification results.

---

# 12. Separation of Modules

The system is intentionally divided into independent modules.

### Junction Controller

Responsible for traffic FSM sequencing and signal generation.

### Generic Timer

Responsible only for timing/counting.

### Pedestrian Arbiter

Responsible only for fair pedestrian request arbitration.

### Green-Wave Coordinator

Responsible only for the timing relationship between Junction A and Junction B.

### AMTGC Top Level

Responsible for connecting the modules.

This separation improves:

* reusability
* readability
* debugging
* verification
* parameterization
* future modification

It also prevents one module from depending unnecessarily on the internal implementation of another module.

---

# 13. Planned FSM States

The junction controller will use the following Moore FSM states:

```text
+----------------+
|   NS_GREEN     |
+-------+--------+
        |
        v
+----------------+
|   NS_YELLOW    |
+-------+--------+
        |
        v
+----------------+
|   ALL_RED      |
+-------+--------+
        |
        v
+----------------+
|   EW_GREEN     |
+-------+--------+
        |
        v
+----------------+
|   EW_YELLOW    |
+-------+--------+
        |
        v
+----------------+
|   ALL_RED      |
+-------+--------+
        |
        v
+----------------+
|   NS_GREEN     |
+----------------+
```

Pedestrian service may be inserted at a safe all-red boundary.

Emergency override takes precedence and moves the controller to the all-red safety condition.

---

# 14. Verification Plan

The following test scenarios will be used later during RTL and system-level verification.

| No. | Test Scenario                                      | Expected Result                                                               |
| --: | -------------------------------------------------- | ----------------------------------------------------------------------------- |
|   1 | Apply reset at startup                             | Both junctions enter a known safe all-red state                               |
|   2 | Normal NS operation at Junction A                  | NS becomes green and EW remains red                                           |
|   3 | NS green to NS yellow                              | Correct transition occurs                                                     |
|   4 | NS yellow to all-red                               | All-red safety gap is present                                                 |
|   5 | All-red to EW green                                | EW becomes green only after all-red                                           |
|   6 | EW green to EW yellow                              | Correct transition occurs                                                     |
|   7 | EW yellow to all-red                               | Second all-red safety gap is present                                          |
|   8 | Complete normal FSM cycle                          | All required traffic phases occur in order                                    |
|   9 | Pedestrian request from Junction A                 | A request is stored and later serviced                                        |
|  10 | Pedestrian request from Junction B                 | B request is stored and later serviced                                        |
|  11 | Simultaneous A and B pedestrian requests           | Arbiter grants only one request according to round-robin priority             |
|  12 | Repeated simultaneous pedestrian requests          | Priority alternates and neither junction starves                              |
|  13 | Assert emergency during NS green                   | Both junctions transition to all-red within the defined limit                 |
|  14 | Assert emergency during EW green                   | Both junctions transition to all-red safely                                   |
|  15 | Assert emergency during pedestrian phase           | Both junctions return to all-red safely                                       |
|  16 | Release emergency override                         | System resumes from a valid safe traffic state                                |
|  17 | Green-wave coordination                            | Junction B NS green begins within the defined delay after Junction A NS green |
|  18 | Reset during active traffic operation              | System returns to the defined safe reset state                                |
|  19 | Pedestrian request during yellow                   | Request is retained and serviced once at a safe boundary                      |
|  20 | Pedestrian requests from both junctions repeatedly | No request is permanently starved                                             |
|  21 | Check opposing traffic signals                     | Conflicting directions are never green simultaneously                         |
|  22 | Check all-red safety interval                      | Non-zero all-red interval exists between conflicting traffic directions       |

The first 15 scenarios form the minimum verification plan required by Task 1. Additional scenarios are included to cover important corner cases that will be useful during later RTL verification.

---

# 15. Expected Verification Evidence

The later simulation stage should produce evidence for:

```text
1. Normal Junction A traffic sequence
2. Normal Junction B traffic sequence
3. Complete FSM state transitions
4. Pedestrian request from A
5. Pedestrian request from B
6. Simultaneous pedestrian requests
7. Fair arbitration
8. Emergency override
9. Green-wave timing
10. Reset during operation
11. All-red safety interval
12. Pedestrian request during yellow
```

Waveforms should be captured from ModelSim and included in the later project submission.

---

# 16. Design Assumptions

The following assumptions are made for Task 1:

1. Both junctions operate from the same system clock.
2. Junction A and Junction B use the same basic traffic-control FSM structure.
3. Junction timing values will be parameterized in the RTL stage.
4. Pedestrian requests are handled by one shared arbiter.
5. Round-robin arbitration is used for simultaneous pedestrian requests.
6. Emergency override is common to both junctions.
7. Emergency override has the highest operational priority.
8. Both junctions enter an all-red safety state during emergency operation.
9. Green-wave timing is configurable.
10. Traffic-density-based adaptive timing will be implemented in a later task.
11. Detailed timing values will be finalized during RTL development and verification.

---

# 17. Task 1 Completion Criteria

Task 1 will be considered complete when the following items are available:

[ ] Complete system architecture

[ ] Top-level block diagram

[ ] Module descriptions

[ ] Input/output interface definitions

[ ] Reason for modular separation

[ ] Reason for shared pedestrian arbiter

[ ] Starvation-prevention method

[ ] Green-wave coordination description

[ ] Emergency override strategy

[ ] Single-clock-domain strategy

[ ] Reset strategy and justification

[ ] At least 15 verification scenarios

[ ] Document reviewed before beginning RTL implementation

---

# 18. Conclusion

The proposed AMTGC architecture provides a modular foundation for controlling two coordinated 4-way traffic junctions.

The architecture separates traffic FSM control, timing, pedestrian arbitration, green-wave coordination, and system integration into independent modules.

A shared round-robin pedestrian arbiter provides fair handling of simultaneous pedestrian requests, while the green-wave coordinator establishes a defined timing relationship between the North-South green phases of Junction A and Junction B.

A common clock domain and defined reset strategy provide a predictable control environment, while the emergency override provides a system-wide path to the all-red safety state.

This architecture will serve as the design contract for the subsequent RTL implementation and verification tasks.
