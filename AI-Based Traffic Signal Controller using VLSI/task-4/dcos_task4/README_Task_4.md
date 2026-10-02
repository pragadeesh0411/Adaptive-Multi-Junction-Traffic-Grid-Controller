# AMTGC – Adaptive Multi-Junction Traffic Grid Controller

## Task 4: Adaptive Green-Time Control Using Traffic Density

### 1. Project Overview

AMTGC (Adaptive Multi-Junction Traffic Grid Controller) is a SystemVerilog/Verilog-based traffic signal control system for two coordinated 4-way junctions, Junction A and Junction B.

In Task 4, the controller is enhanced with a **3-bit traffic-density input** for each junction. The measured traffic density dynamically changes the duration of the green phase while maintaining minimum and maximum safety limits and preserving green-wave coordination.

The design keeps the timer generic and reusable. Adaptive timing is calculated inside the `junction_controller`, not inside the `generic_timer`.

---

## 2. Task 4 Objectives

The Task 4 implementation provides:

- A 3-bit `traffic_density` input for Junction A and Junction B.
- Adaptive green-time calculation inside each `junction_controller`.
- Parameterized minimum and maximum green-time limits.
- Separate, reusable `generic_timer` logic.
- Green-wave coordination between Junction A and Junction B.
- Pedestrian arbitration using a shared fair round-robin arbiter.
- Emergency override that places both junctions in an all-red state.
- Simulation of all density values from `0` to `7`.
- Verification of green-wave behavior for at least five density combinations.
- Verification that density changes during a green phase do not continuously change the active timer value.

These requirements follow the supplied Task 4 assignment specification. fileciteturn0file1L13-L15

---

## 3. Adaptive Green-Time Method

The adaptive green time is calculated using:

```text
Adaptive Green Time
    = GREEN_TIME + traffic_density × GREEN_EXTENSION_PER_LEVEL
```

The calculated value is then limited to the configured range:

```text
MIN_GREEN_TIME ≤ Adaptive Green Time ≤ MAX_GREEN_TIME
```

### Default Parameters

```text
GREEN_TIME = 5
MIN_GREEN_TIME = 4
MAX_GREEN_TIME = 8
GREEN_EXTENSION_PER_LEVEL = 1
```

### Expected Density Mapping

| Traffic Density | Calculated Green Time | Final Green Target |
|---:|---:|---:|
| 0 | 5 | 5 |
| 1 | 6 | 6 |
| 2 | 7 | 7 |
| 3 | 8 | 8 |
| 4 | 9 | 8 |
| 5 | 10 | 8 |
| 6 | 11 | 8 |
| 7 | 12 | 8 |

Therefore, higher traffic density increases green time until the configured maximum is reached.

---

## 4. Density Sampling Strategy

The traffic density is **sampled at the beginning of each new green phase**.

Once a green phase begins, the sampled density remains fixed for that phase. A change in the external `traffic_density` input during an active green phase does not continuously modify the running green timer.

The new density value is used when the next green phase begins.

This approach provides deterministic timing and avoids continuously changing the active green duration during a phase.

---

## 5. Design Architecture

```text
                +----------------------+
                |     AMTGC TOP        |
                +----------+-----------+
                           |
          +----------------+----------------+
          |                                 |
          v                                 v
 +-------------------+             +-------------------+
 | Junction A        |             | Junction B        |
 | Controller        |             | Controller        |
 |                   |             |                   |
 | Traffic Density   |             | Traffic Density   |
 | Adaptive Timing   |             | Adaptive Timing   |
 | Moore FSM         |             | Moore FSM         |
 +---------+---------+             +---------+---------+
           |                                 |
           +----------------+----------------+
                            |
                    Green-Wave Coordination
                            |
                    Pedestrian Arbiter
                            |
                     Emergency Override

        generic_timer is instantiated inside
        each junction_controller and remains
        a separate reusable timing module.
```

### Why adaptive logic is inside `junction_controller`

The `junction_controller` knows which phase is currently active and whether the phase is a green phase. Therefore, adaptive timing is calculated there.

The `generic_timer` only performs generic count-and-done functionality. It is not aware of traffic density, traffic phases, pedestrian requests, or junction-specific behavior.

**Task 4 constraint:** `generic_timer.v` must not be modified for adaptive traffic-density behavior. fileciteturn0file1L13-L15

---

## 6. Project Directory Structure

```text
AMTGC_Task4/
│
├── README.md
│
├── rtl/
│   ├── generic_timer.v
│   ├── junction_controller.v
│   ├── ped_arbiter.v
│   ├── green_wave_coordinator.v
│   └── amtgc_top.v
│
├── tb/
│   └── amtgc_task4_tb.v
│
├── sim/
│   └── task4_run.do
│
├── docs/
│   ├── task4_architecture.md
│   └── adaptive_logic.md
│
└── screenshots/
```

---

## 7. RTL Modules

### `generic_timer.v`

Reusable parameterized timer used by the junction controllers.

Responsibilities:

- Count clock cycles while enabled.
- Compare the current count with `count_target`.
- Generate `done` when the target is reached.
- Handle reset and zero-count corner cases.

The timer does not calculate adaptive green time.

### `junction_controller.v`

Main Moore FSM for each junction.

Responsibilities:

- Control NS and EW traffic phases.
- Control yellow and all-red transitions.
- Handle pedestrian phases.
- Handle emergency override.
- Sample traffic density at green-phase entry.
- Calculate adaptive green duration.
- Start the generic timer using the calculated target.

### `ped_arbiter.v`

Shared pedestrian-request arbiter.

Responsibilities:

- Accept pedestrian requests from both junctions.
- Grant access fairly.
- Prevent starvation.
- Use round-robin behavior for repeated simultaneous requests.

### `green_wave_coordinator.v`

Generates the coordination signal used to maintain the required green-wave relationship between the two junctions.

### `amtgc_top.v`

Top-level integration module connecting:

- Junction A controller.
- Junction B controller.
- Pedestrian arbiter.
- Green-wave coordinator.
- Emergency override.
- Traffic-density inputs.

All connections should use explicit named port connections.

---

## 8. Main Interface Signals

Typical top-level signals include:

```text
clk
reset
traffic_density_a[2:0]
traffic_density_b[2:0]
ped_request_a
ped_request_b
emergency_override
```

Traffic-light outputs are generated independently for Junction A and Junction B.

---

## 9. Verification Plan

The Task 4 testbench verifies the adaptive behavior and integration requirements.

### Density Sweep

Test all eight density values:

```text
0, 1, 2, 3, 4, 5, 6, 7
```

For every density value, verify that the target green duration is calculated correctly and respects the minimum and maximum limits.

### Mid-Green Density Change

Change the `traffic_density` input while a green phase is already active.

Expected behavior:

```text
Current green phase -> continues using its sampled density
Next green phase   -> uses the newly sampled density
```

### Maximum Density

Apply:

```text
traffic_density = 7
```

Verify that the green duration does not exceed `MAX_GREEN_TIME` and that every traffic direction still receives at least the configured minimum green time.

### Green-Wave Verification

Repeat the green-wave test for at least five density combinations, for example:

```text
A=0, B=7
A=1, B=6
A=2, B=5
A=4, B=3
A=7, B=0
```

Measure the observed timing relationship between Junction A NS green and Junction B NS green and document the measured offset/tolerance in the report.

---

## 10. Corner Cases

The verification environment should include:

- `count_target = 0`.
- Reset while the timer is counting.
- Pedestrian request during yellow.
- Simultaneous pedestrian requests.
- Emergency override during pedestrian operation.
- Repeated emergency activation.
- Maximum traffic density.
- Density changes during an active green phase.
- Recovery from reset and emergency conditions.

---

## 11. Expected Simulation Evidence

The following screenshots should be captured for the final submission:

### Screenshot 1 – Compilation

Show that all RTL and testbench files compile successfully without unresolved errors.

### Screenshot 2 – Density Sweep

Show waveform or console output demonstrating density values `0` through `7` and the corresponding adaptive green targets.

### Screenshot 3 – Mid-Green Density Change

Show that density changes during an active green phase do not immediately alter the current phase duration.

### Screenshot 4 – Maximum Density

Show `traffic_density = 7` and confirm that the target is clamped to `MAX_GREEN_TIME`.

### Screenshot 5 – Green Wave

Show Junction A and Junction B NS green signals and the measured timing offset for the selected density combinations.

### Screenshot 6 – Emergency Override

Show both junctions entering/staying in the all-red condition when `emergency_override` is asserted.

### Screenshot 7 – Pedestrian Arbitration

Show simultaneous or repeated requests and the resulting fair grant sequence.

---

## 12. Simulation Procedure

Open the ModelSim project and compile the files in this order:

```text
rtl/generic_timer.v
rtl/junction_controller.v
rtl/ped_arbiter.v
rtl/green_wave_coordinator.v
rtl/amtgc_top.v
tb/amtgc_task4_tb.v
```

Then simulate:

```text
vsim work.amtgc_task4_tb
```

Run the provided command file:

```text
sim/task4_run.do
```

The testbench should print clear PASS/FAIL messages for the checked scenarios.

Do not claim a test passed in the README or report unless the actual ModelSim output confirms it.

---

## 13. Design Assumptions

1. The controller and timer operate in one common clock domain.
2. Traffic density is represented by a 3-bit value from `0` to `7`.
3. Density is sampled once when a green phase starts.
4. The sampled density remains constant throughout that green phase.
5. Adaptive timing uses only parameterized values; no hard-coded green extension constants are used inside the FSM.
6. `generic_timer.v` remains unchanged for Task 4.
7. Green-wave coordination is verified using measured simulation timing rather than assumed behavior.

---

## 14. Parameterization

The adaptive controller should expose parameters such as:

```verilog
GREEN_TIME
MIN_GREEN_TIME
MAX_GREEN_TIME
GREEN_EXTENSION_PER_LEVEL
YELLOW_TIME
RED_TIME
PED_TIME
COUNTER_WIDTH
USE_GREEN_WAVE
```

This allows the same controller architecture to be reused with different timing configurations.

---

## 15. Task 4 Completion Checklist

```text
[ ] New ModelSim project created
[ ] generic_timer.v added without modification
[ ] junction_controller.v added
[ ] traffic_density implemented as 3-bit input
[ ] Adaptive green-time calculation implemented
[ ] Minimum green limit verified
[ ] Maximum green limit verified
[ ] Density sampled at green-phase entry
[ ] Mid-green density change verified
[ ] ped_arbiter.v integrated
[ ] green_wave_coordinator.v integrated
[ ] amtgc_top.v integrated
[ ] Emergency override verified
[ ] All density values 0–7 tested
[ ] At least 5 green-wave density combinations tested
[ ] Waveforms captured
[ ] ModelSim console/log saved
[ ] README completed
[ ] Architecture diagram completed
[ ] Adaptive-logic explanation completed
[ ] Final submission files reviewed
```

---

## 16. Summary

Task 4 extends the AMTGC system from fixed-time traffic control to **adaptive traffic-density-based green control**. The green duration is calculated inside the junction controller using parameterized limits and density-dependent extension. Density is sampled at the start of each green phase so the current phase remains deterministic. The generic timer is kept unchanged and reusable, while pedestrian arbitration, emergency override, and green-wave coordination remain part of the integrated system.

