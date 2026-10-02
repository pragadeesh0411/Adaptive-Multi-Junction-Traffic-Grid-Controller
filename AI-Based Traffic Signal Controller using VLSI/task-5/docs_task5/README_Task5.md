# AMTGC – Task 5: Full Verification

## Adaptive Multi-Junction Traffic Grid Controller

### 1. Project Overview

Task 5 performs complete verification of the Adaptive Multi-Junction Traffic Grid Controller (AMTGC).

Unlike the earlier tasks, Task 5 uses one unified top-level self-checking testbench to verify the complete integrated AMTGC system under both normal and abnormal operating conditions.

The verification environment checks:

- Normal traffic operation
- Pedestrian requests
- Pedestrian arbitration and fairness
- Emergency override
- Adaptive traffic-density control
- Green-wave coordination
- Reset during active operation
- Repeated emergency operation
- Corner cases identified during Tasks 2–4
- Randomized input conditions

The testbench automatically reports PASS or FAIL. Waveforms are used as supporting evidence and not as the only verification method.

---

## 2. Task 5 Objectives

The main objectives are:

1. Verify the complete integrated AMTGC system.
2. Verify all important scenarios planned in Task 1.
3. Verify corner cases identified during Tasks 2–4.
4. Create one unified self-checking testbench.
5. Automatically determine PASS/FAIL.
6. Test pedestrian arbitration fairness with more than 100 requests.
7. Test emergency override during every traffic phase.
8. Test repeated emergency assertion and deassertion.
9. Test reset while the controller is actively operating.
10. Verify adaptive traffic-density operation.
11. Verify green-wave coordination under at least five density combinations.
12. Include randomized verification.
13. Generate ModelSim logs and waveform evidence.
14. Prepare a coverage statement.
15. Document any bugs and fixes discovered during verification.

---

## 3. Project Structure

```text
AMTGC_Task5/
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
│   ├── verification_plan.md
│   ├── coverage_statement.md
│   └── bug_fix_log.md
│
└── screenshots/
    ├── normal_operation.png
    ├── pedestrian_fairness.png
    ├── emergency_override.png
    ├── maximum_density.png
    └── green_wave.png
4. RTL Design Under Verification

The Task 5 testbench verifies the complete RTL developed during Tasks 2–4.

generic_timer.v

Reusable timer used by the junction controllers.

Responsibilities:

Count clock cycles.
Compare count with the target.
Generate the timer completion signal.
Handle reset.
Handle zero-count target.

The timer remains independent of traffic-density calculations.

junction_controller.v

Parameterized Moore finite-state machine for one traffic junction.

Responsibilities:

NS green control.
NS yellow control.
EW green control.
EW yellow control.
All-red safety intervals.
Pedestrian phase.
Emergency override.
Adaptive green-time calculation.
Traffic-density sampling.
ped_arbiter.v

Shared pedestrian arbiter.

Responsibilities:

Accept requests from Junction A and Junction B.
Provide a fair grant.
Prevent permanent starvation.
Use round-robin arbitration.
green_wave_coordinator.v

Generates the green-wave coordination signal used between Junction A and Junction B.

amtgc_top.v

Top-level AMTGC integration module.

It connects:

Junction A
Junction B
Pedestrian arbiter
Green-wave coordinator
Emergency override
Traffic-density inputs
5. State Encoding

The junction controller uses the following states:

000 = NS GREEN
001 = NS YELLOW
010 = ALL RED TO EW
011 = EW GREEN
100 = EW YELLOW
101 = ALL RED TO NS
110 = PEDESTRIAN

The default state behavior places the controller in a safe all-red condition.

6. Self-Checking Verification

Task 5 uses automatic verification rather than relying only on visual waveform inspection.

The testbench contains:

Automatic checkers
PASS/FAIL counters
State checks
Safety checks
Pedestrian service counters
Density checks
Emergency checks
Green-wave checks
Randomized stimulus
Final verification summary

The testbench reports the final result automatically.

Expected final message format:

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

The values above are examples of the output format. Actual values must come from ModelSim.

7. Normal Traffic Verification

The testbench verifies the normal junction sequence:

NS GREEN
    ↓
NS YELLOW
    ↓
ALL RED
    ↓
EW GREEN
    ↓
EW YELLOW
    ↓
ALL RED
    ↓
NS GREEN

The verification checks:

No conflicting green signals.
Correct yellow transitions.
All-red safety interval.
Both traffic directions receive service.
No invalid controller state.
8. Pedestrian Verification

The testbench verifies:

Pedestrian request acceptance.
Pedestrian phase activation.
Pedestrian phase safety.
Vehicle signals remain red during pedestrian operation.
Simultaneous requests.
Fair arbitration.
No permanent starvation.
Pedestrian Request During Yellow

A pedestrian request generated during yellow is checked to make sure it is not unintentionally lost or duplicated.

9. Pedestrian Fairness Test

Task 5 requires more than 100 pedestrian requests.

This project uses:

60 simultaneous request rounds

Each round contains:

Junction A request
Junction B request

Therefore:

60 × 2 = 120 pedestrian requests

The testbench records:

Total requests
Junction A services
Junction B services
Total services

The final verification checks that:

More than 100 requests were generated.
Requests are serviced.
Both junctions receive service.
The round-robin arbitration remains balanced.

Actual service counts are taken from ModelSim.

10. Emergency Override Verification

Emergency override is tested during every controller phase.

The seven controller states are:

1. NS GREEN
2. NS YELLOW
3. ALL RED TO EW
4. EW GREEN
5. EW YELLOW
6. ALL RED TO NS
7. PEDESTRIAN

For each state:

Normal operation
      ↓
Emergency ON
      ↓
System moves to all-red
      ↓
Emergency remains active
      ↓
Both junctions remain all-red
      ↓
Emergency OFF
      ↓
Safe recovery

The testbench automatically checks the emergency response.

11. Repeated Emergency Verification

Emergency override is repeatedly asserted and deasserted.

The test includes five repeated operations.

The verification checks:

No stuck emergency condition.
No conflicting greens.
All-red during emergency.
Safe recovery after release.
12. Active Reset Verification

Reset is tested during active system operation.

Reset is not tested only at simulation time zero.

The testbench asserts reset while traffic operation is in progress.

The verification checks:

Safe reset behavior.
Vehicle signals become all-red.
No illegal state is produced.
The system recovers correctly after reset release.
13. Adaptive Traffic-Density Verification

Traffic density is represented using a 3-bit input:

0 to 7

The adaptive green-time calculation is:

Adaptive Green Time
=
GREEN_TIME
+
traffic_density × GREEN_EXTENSION_PER_LEVEL

The result is limited by:

MIN_GREEN_TIME
≤
Adaptive Green Time
≤
MAX_GREEN_TIME

The complete density range is tested:

0
1
2
3
4
5
6
7
14. Maximum-Density Verification

Maximum traffic density is:

traffic_density = 7

The testbench verifies:

Green time does not exceed MAX_GREEN_TIME.
Minimum green limits remain valid.
Both traffic directions continue to receive service.
No invalid adaptive timing value is generated.
15. Mid-Green Density Change

The Task 4 design uses density sampling at the beginning of a green phase.

Therefore:

Green phase starts
       ↓
Density sampled
       ↓
Green duration fixed
       ↓
External density changes
       ↓
Current green continues
       ↓
Next green phase uses new density

The testbench verifies that a density change during an active green phase does not unexpectedly change the current green target.

16. Green-Wave Verification

Green-wave coordination is tested under at least five traffic-density combinations.

The selected combinations are:

Test 1: A = 0, B = 7
Test 2: A = 1, B = 6
Test 3: A = 2, B = 5
Test 4: A = 4, B = 3
Test 5: A = 7, B = 0

For each test, the testbench measures:

Junction A NS-green start
Junction B NS-green start
Measured offset
Expected delay
Allowed tolerance

The actual measured values must be taken from the ModelSim simulation output.

17. Randomized Verification

A randomized stress test is included.

The randomized simulation uses:

1000 clock cycles

During these cycles:

A traffic density → random 0–7
B traffic density → random 0–7
Pedestrian requests → randomized
Emergency override → randomized

The normal safety checker remains active during the randomized test.

The randomized test is intended to exercise combinations that may not be reached by only manually selected directed tests.

18. Automatic Safety Checks

The testbench checks the following continuously:

No conflicting greens

The same junction must never have:

NS GREEN = 1
EW GREEN = 1

at the same time.

Correct opposing red

When NS is green:

EW must be RED

When EW is green:

NS must be RED
Pedestrian safety

When pedestrian phase is active:

NS = RED
EW = RED
Arbiter safety

Both pedestrian grants must not be active simultaneously.

State validity

Invalid or unknown controller states are detected.

All-red safety

The controller must not directly change from one traffic direction's yellow state to the opposite green state without the all-red safety interval.

19. ModelSim Compilation

Compile in this order:

vdel -lib work -all
vlib work

vlog rtl/generic_timer.v
vlog rtl/ped_arbiter.v
vlog rtl/green_wave_coordinator.v
vlog rtl/junction_controller.v
vlog rtl/amtgc_top.v
vlog tb/amtgc_task5_tb.v

Then load the testbench:

vsim work.amtgc_task5_tb

Open the waveform window:

view wave

Run the complete verification:

run -all
20. ModelSim .do Script

The project includes:

sim/task5_run.do

The script is intended to:

Delete the old work library.
Create a new work library.
Compile the RTL.
Compile the Task 5 testbench.
Load the testbench.
Add important waveform signals.
Run the complete simulation.

Run it from the project root using:

do sim/task5_run.do
21. Required Waveform Screenshots

Save waveform evidence in:

screenshots/

Recommended screenshots:

01_normal_operation.png
02_pedestrian_fairness.png
03_emergency_override.png
04_maximum_density.png
05_green_wave.png
Normal Operation Screenshot

Show:

A state
A traffic lights
B state
B traffic lights
clock
Pedestrian Screenshot

Show:

pedestrian request
pedestrian grant
pedestrian active
traffic signals
Emergency Screenshot

Show:

emergency_override
A traffic signals
B traffic signals
A state
B state
Maximum Density Screenshot

Show:

traffic_density = 7
green phase
timer target
Green-Wave Screenshot

Show:

A NS green
B NS green
wave_start_b
clock
22. Verification Coverage Statement

Create:

docs/coverage_statement.md

The coverage statement compares the Task 1 verification plan with the tests actually executed in Task 5.

Each requirement should be marked honestly as:

Covered
Partially Covered
Not Covered

The evidence should reference:

ModelSim log
Waveform screenshot
Testbench output

Do not claim coverage for a scenario that was not actually tested.

23. Bug and Fix Documentation

Create:

docs/bug_fix_log.md

For each actual bug discovered during verification, record:

Bug ID
Test that found the bug
Observed behavior
Expected behavior
Root cause
Earlier design decision responsible
Correction
Re-test result
Final status

Example format:

BUG-001

Test:
Emergency during pedestrian phase

Observed behavior:
[record actual result]

Expected behavior:
Both junctions should enter all-red within the documented bound.

Root cause:
[record actual root cause]

Correction:
[record actual correction]

Re-test:
[record actual result]

Status:
FIXED / OPEN

Only document actual simulation findings.

24. Verification Evidence

The following evidence should be collected after simulation:

1. ModelSim compilation output
2. ModelSim simulation transcript
3. Final PASS/FAIL summary
4. Normal traffic waveform
5. Pedestrian fairness waveform/log
6. Emergency waveform
7. Maximum-density waveform
8. Green-wave waveform
9. Coverage statement
10. Bug/fix log
25. Final Verification Checklist
[ ] New Task 5 project created
[ ] All five RTL files added
[ ] Unified Task 5 testbench added
[ ] ModelSim .do script added
[ ] RTL compiles without errors
[ ] Testbench compiles without errors
[ ] Simulation loads successfully
[ ] Normal traffic verified
[ ] Pedestrian phase verified
[ ] Simultaneous pedestrian requests verified
[ ] More than 100 pedestrian requests tested
[ ] Pedestrian fairness checked
[ ] Density values 0–7 tested
[ ] Maximum density tested
[ ] Mid-green density change tested
[ ] Green wave tested with 5 combinations
[ ] Emergency tested in all 7 phases
[ ] Emergency hold tested
[ ] Repeated emergency tested
[ ] Active reset tested
[ ] Randomized test completed
[ ] Automatic PASS/FAIL generated
[ ] Simulation log saved
[ ] Normal waveform saved
[ ] Pedestrian waveform saved
[ ] Emergency waveform saved
[ ] Maximum-density waveform saved
[ ] Green-wave waveform saved
[ ] Coverage statement completed
[ ] Bug/fix log completed
[ ] Final files reviewed
26. Important Rule

The final report must contain actual simulation results.

Do not invent:

PASS results
FAIL results
Timing measurements
Coverage percentages
Pedestrian service counts
Green-wave offsets
Bug counts

All numerical results must come from the actual ModelSim simulation.

27. Task 5 Completion

Task 5 is complete when the unified self-checking verification environment demonstrates the required normal, safety, adaptive, pedestrian, emergency, reset, green-wave, and randomized tests, with simulation evidence and an honest coverage statement.