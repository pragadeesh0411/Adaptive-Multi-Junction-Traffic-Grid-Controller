# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

## Task 3 – System Integration

## 1. Project Overview

The Adaptive Multi-Junction Traffic Grid Controller (AMTGC) integrates the reusable RTL modules developed in the previous stage into one complete two-junction traffic control system.

The system contains:

- Junction A
- Junction B
- Shared Pedestrian Arbiter
- Green-Wave Coordinator
- Generic Timer inside each Junction Controller
- AMTGC Top-Level Module

The two junctions operate as a coordinated system rather than as completely independent traffic controllers.

The system provides:

- North-South traffic control
- East-West traffic control
- All-red safety intervals
- Shared pedestrian arbitration
- Round-robin pedestrian fairness
- Green-wave coordination
- System-wide emergency override
- Reusable and parameterized junction controllers

RTL modules remain separate and communicate through defined interfaces.

---

# 2. Task 3 Objectives

The main objectives of this stage are:

1. Integrate the modules developed in the previous tasks.
2. Instantiate two `junction_controller` modules.
3. Use different timing parameters for Junction A and Junction B.
4. Integrate a shared `ped_arbiter`.
5. Integrate the `green_wave_coordinator`.
6. Add the system-wide `emergency_override`.
7. Maintain strict hierarchical RTL structure.
8. Use named port connections.
9. Prevent fixed-priority pedestrian arbitration.
10. Verify the green-wave timing relationship using simulation.
11. Verify simultaneous pedestrian requests.
12. Verify pedestrian fairness.
13. Verify emergency operation.
14. Verify safe recovery after emergency operation.

---

# 3. Repository Structure

```text
AMTGC_Task3/
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
│   ├── generic_timer_tb.v
│   ├── junction_controller_tb.v
│   └── amtgc_top_tb.v
│
├── sim/
│   └── task3_run.do
│
└── screenshots/
    └── Task 3 screenshots