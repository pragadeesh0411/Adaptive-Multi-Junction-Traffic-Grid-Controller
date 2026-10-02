# AMTGC Technical Report

## 1. Introduction

The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) was developed as a modular RTL traffic-control system for two coordinated 4-way junctions.

The design combines fixed traffic sequencing with adaptive green-time control, pedestrian management, emergency handling, and green-wave coordination.

Task 6 focuses on the engineering delivery of the completed design.

---

## 2. Architecture

The design is divided into reusable modules:

```text
generic_timer
junction_controller
ped_arbiter
green_wave_coordinator
amtgc_top
```

The top-level integration module connects two junction controllers with shared coordination logic.

---

## 3. Architectural Decisions

### 3.1 Moore FSM

A Moore FSM was selected for traffic control because the traffic outputs are determined by the current traffic phase.

This makes the traffic-light behavior easier to inspect and verify.

### 3.2 Separate Generic Timer

The timing function was separated from traffic-state logic.

Advantages:

- Reusability
- Parameterization
- Cleaner controller structure
- Easier verification

### 3.3 Adaptive Timing Inside the Controller

Traffic-density processing is located inside the junction controller rather than inside the generic timer.

The controller knows the current phase and therefore can determine when density should be sampled and how the timing target should be calculated.

### 3.4 Density Sampling

Traffic density is sampled at the beginning of a green phase.

This avoids continuously changing the active green phase while it is already running.

### 3.5 Shared Pedestrian Arbiter

A common pedestrian arbiter is used rather than independent arbitration logic.

The purpose is to provide centralized and fair request handling.

### 3.6 Emergency Override

Emergency operation has priority over normal traffic operation and is intended to place the junctions into a safe all-red condition within the documented response bound.

### 3.7 Green-Wave Coordination

A dedicated coordinator separates synchronization timing from the junction FSM.

This allows the coordination mechanism to remain independently configurable.

---

## 4. Verification Strategy

Verification was performed using a unified top-level self-checking testbench.

The testbench included both directed and randomized testing.

Major tests included:

```text
Normal traffic sequence
Pedestrian operation
Pedestrian arbitration
Emergency operation
Active reset
Adaptive density sweep
Maximum density
Green-wave coordination
Randomized stress
```

---

## 5. Verification Results

Fill this section using the actual ModelSim output.

```text
Simulation cycles       :
Safety checks           :
Density tests           :
Pedestrian requests     :
Pedestrian services A   :
Pedestrian services B   :
Green-wave tests        :
Emergency tests         :
Repeated emergency     :
Active reset tests      :
Randomized cycles       :
Total errors            :
Final result            :
```

Do not enter invented values.

---

## 6. Bugs Discovered

Use the actual contents of:

```text
bug_fix_log.md
```

for this section.

For each real issue, explain:

```text
Observed behavior
Expected behavior
Root cause
Correction
Verification after correction
```

If no issue was discovered, state that the verification run did not identify any unresolved defect.

---

## 7. Engineering Trade-Offs

### Deterministic Density Sampling

Sampling density at the beginning of a phase provides deterministic timing.

The trade-off is that a traffic-density change is not immediately reflected in the currently active green phase.

### Parameterization

Parameterization improves reuse and allows different junction timing configurations.

The trade-off is additional configuration complexity.

### Shared Arbitration

A shared arbiter simplifies fairness management.

The trade-off is that pedestrian service becomes dependent on the shared arbitration sequence.

### Separate Coordination Module

The green-wave coordinator isolates synchronization behavior.

The trade-off is that coordination must be checked carefully against the actual FSM timing.

---

## 8. Lessons Learned

The project demonstrates several practical RTL engineering principles:

- Separate control logic from reusable timing logic.
- Keep timing values parameterized.
- Use explicit state definitions.
- Include safe default state behavior.
- Verify abnormal conditions rather than only normal operation.
- Use self-checking testbenches.
- Preserve the exact verified RTL version.
- Document bugs rather than hiding them.
- Maintain a reproducible simulation flow.

---

## 9. Future Improvements

With additional development time, the design could be extended with:

- Real traffic sensors
- More advanced traffic-density estimation
- Multi-junction scalability
- Formal property verification
- FPGA hardware implementation
- More advanced green-wave optimization
- Improved pedestrian scheduling
- More detailed coverage collection

---

## 10. Final Delivery

The final repository packages:

- RTL
- Testbench
- Simulation scripts
- Simulation evidence
- Architecture documentation
- FSM documentation
- Verification documentation
- Technical report
- Coverage statement
- Bug/fix log
- Demonstration evidence

The delivered RTL must remain identical to the verified Task 5 implementation.