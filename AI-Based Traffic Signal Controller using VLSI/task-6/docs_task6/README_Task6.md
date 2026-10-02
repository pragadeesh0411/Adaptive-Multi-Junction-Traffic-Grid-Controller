# AMTGC – Adaptive Multi-Junction Traffic Grid Controller

## Professional Documentation and Delivery

### 1. Project Overview

AMTGC (Adaptive Multi-Junction Traffic Grid Controller) is a Verilog-based traffic control system designed for two coordinated 4-way traffic junctions, Junction A and Junction B.

The project combines:

- Moore finite-state traffic control
- Adaptive traffic-density-based green timing
- Pedestrian request handling
- Fair pedestrian arbitration
- Emergency override
- Green-wave coordination
- Reusable generic timing
- Self-checking verification

Task 6 packages the completed and verified design into a reproducible engineering repository.

The repository contains the final RTL, unified verification testbench, simulation scripts, documentation, verification evidence, waveforms, and technical report.

---

## 2. Repository Structure

```text
AMTGC_Task6/
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
│   └── amtgc_task5_tb.v
│
├── sim/
│   ├── task5_run.do
│   └── task5_simulation.log
│
├── docs/
│   ├── architecture.md
│   ├── junction_fsm.md
│   ├── verification_strategy.md
│   ├── technical_report.md
│   ├── coverage_statement.md
│   └── bug_fix_log.md
│
├── screenshots/
│   ├── 01_normal_operation.png
│   ├── 02_pedestrian_fairness.png
│   ├── 03_emergency_override.png
│   ├── 04_maximum_density.png
│   └── 05_green_wave.png
│
└── .gitignore
```

---

## 3. Main Features

### Traffic Control

Each junction contains independent traffic phases:

```text
NS GREEN
NS YELLOW
ALL RED
EW GREEN
EW YELLOW
ALL RED
PEDESTRIAN
```

The controller uses a Moore FSM.

### Adaptive Traffic Density

Each junction accepts a 3-bit traffic-density input:

```text
0 to 7
```

The adaptive green-time calculation uses parameterized values:

```text
Adaptive Green Time
=
GREEN_TIME
+
traffic_density × GREEN_EXTENSION_PER_LEVEL
```

The result is limited by:

```text
MIN_GREEN_TIME
≤
Adaptive Green Time
≤
MAX_GREEN_TIME
```

Traffic density is sampled at green-phase entry so the active green phase remains deterministic.

### Pedestrian Control

Pedestrian requests from both junctions are handled using a shared arbiter.

The arbitration policy is round-robin so repeated simultaneous requests can be serviced without permanent starvation.

### Emergency Override

A system-wide emergency signal is provided.

During emergency operation, the traffic controllers are driven toward the documented all-red safety condition.

### Green-Wave Coordination

Junction B receives a coordination signal associated with Junction A NS-green operation.

The wave relationship is checked through simulation and measured in clock cycles.

### Generic Timer

The `generic_timer` module is reusable and independent from traffic-density logic.

Adaptive timing is calculated by the `junction_controller`, not by the timer.

---

## 4. Software Requirements

The project is intended to run using:

- Intel ModelSim / Questa-compatible Verilog simulator
- Verilog-2001 compatible compilation
- Git
- GitHub for repository hosting

Recommended simulator environment:

```text
Intel FPGA / ModelSim
```

---

## 5. Compilation

Open ModelSim and navigate to the project root.

Create the work library:

```tcl
vdel -lib work -all
vlib work
```

Compile the RTL:

```tcl
vlog rtl/generic_timer.v
vlog rtl/ped_arbiter.v
vlog rtl/green_wave_coordinator.v
vlog rtl/junction_controller.v
vlog rtl/amtgc_top.v
```

Compile the unified Task 5 testbench:

```tcl
vlog tb/amtgc_task5_tb.v
```

---

## 6. Start Simulation

Load the unified testbench:

```tcl
vsim work.amtgc_task5_tb
```

Open the waveform window:

```tcl
view wave
```

Run the complete verification:

```tcl
run -all
```

The testbench automatically reports PASS/FAIL results in the ModelSim Transcript.

---

## 7. Using the Simulation Script

The repository contains:

```text
sim/task5_run.do
```

The script compiles the RTL, compiles the unified testbench, loads the simulation, adds important waveform signals, and runs the verification.

From the project root:

```tcl
do sim/task5_run.do
```

---

## 8. Verification Testbench

The unified Task 5 testbench verifies:

- Normal traffic operation
- Pedestrian operation
- Simultaneous pedestrian requests
- More than 100 pedestrian requests
- Pedestrian fairness
- Density values 0 through 7
- Maximum-density operation
- Mid-green density changes
- Five green-wave density combinations
- Emergency override in all controller phases
- Emergency hold
- Repeated emergency operation
- Reset during active operation
- Randomized input testing
- Safety checks
- Final automatic PASS/FAIL

---

## 9. Expected Verification Summary

The testbench prints a final summary similar to:

```text
================================================
AMTGC TASK 5 FINAL VERIFICATION SUMMARY
================================================

Simulation cycles       = XXXX
Safety checks           = XXXX
Density tests           = XXXX / 8
Pedestrian requests     = XXXX
Pedestrian services A   = XXXX
Pedestrian services B   = XXXX
Green-wave tests        = XXXX / 5
Emergency tests         = XXXX / 7
Repeated emergency     = XXXX
Active reset tests      = XXXX
Randomized cycles       = XXXX / 1000
Total errors            = XXXX

================================================
PASS: AMTGC TASK 5 SELF-CHECKING VERIFICATION
================================================
```

The values in the repository must be taken from the actual ModelSim simulation.

---

## 10. Reproducibility

A new user should be able to:

```text
Clone repository
     ↓
Open ModelSim
     ↓
Navigate to project directory
     ↓
Run task5_run.do
     ↓
View automatic verification output
     ↓
Inspect archived waveform evidence
```

No source-file modification should be required for normal reproduction.

---

## 11. Verification Evidence

The repository archives:

```text
ModelSim simulation log
Normal-operation waveform
Pedestrian verification evidence
Emergency waveform
Maximum-density waveform
Green-wave waveform
Coverage statement
Bug/fix documentation
```

All archived results must correspond to the final RTL version used for Task 5 verification.

---

## 12. Documentation

### Architecture

See:

```text
docs/architecture.md
```

### FSM

See:

```text
docs/junction_fsm.md
```

### Verification Strategy

See:

```text
docs/verification_strategy.md
```

### Technical Report

See:

```text
docs/technical_report.md
```

### Coverage

See:

```text
docs/coverage_statement.md
```

### Bug and Fix Log

See:

```text
docs/bug_fix_log.md
```

---

## 13. Final RTL Consistency

The RTL stored in this repository must be identical to the version used for final Task 5 verification.

No unverified last-minute RTL modifications are permitted.

Any change made after the verified Task 5 run must trigger a new verification run before being considered a final version.

---

## 14. GitHub Repository

Create a public GitHub repository with a suitable name such as:

```text
AMTGC-Adaptive-Multi-Junction-Traffic-Grid-Controller
```

Recommended first commands:

```bash
git init
git add .
git commit -m "AMTGC Task 6 final delivery"
git branch -M main
git remote add origin <YOUR_PUBLIC_GITHUB_URL>
git push -u origin main
```

Replace:

```text
<YOUR_PUBLIC_GITHUB_URL>
```

with the actual public repository URL.

---

## 15. Final Submission Checklist

```text
[ ] Final RTL copied from verified Task 5
[ ] Unified testbench copied
[ ] ModelSim script copied
[ ] Simulation log archived
[ ] Architecture documentation completed
[ ] Block diagram completed
[ ] Junction FSM diagrams completed
[ ] Verification strategy documented
[ ] Technical report completed
[ ] Coverage statement completed
[ ] Bug/fix log completed
[ ] Waveform screenshots archived
[ ] README completed
[ ] GitHub repository created
[ ] Repository made public
[ ] GitHub clone/reproduction tested
[ ] Demonstration video recorded
[ ] Final RTL not modified after verification
```

---

## 16. Engineering Improvements

Potential future improvements include:

- More advanced traffic-density estimation
- Sensor-based real-time traffic measurements
- More than two coordinated junctions
- Formal verification
- Assertion-based verification using a dedicated property framework
- FPGA hardware demonstration
- Improved green-wave prediction
- More sophisticated pedestrian scheduling
- Centralized adaptive traffic optimization

These are considered future improvements and are not required to change the verified Task 5 implementation.

---

## 17. Final Delivery Principle

The repository is intended to be treated as an engineering handoff.

Another engineer should be able to:

1. Understand the architecture.
2. Identify each RTL module.
3. Understand the FSM.
4. Understand the verification strategy.
5. Compile the RTL.
6. Run the simulation.
7. Inspect the verification evidence.
8. Identify documented bugs and fixes.
9. Reproduce the reported results.

The final repository should therefore contain only verified RTL and clearly documented evidence.