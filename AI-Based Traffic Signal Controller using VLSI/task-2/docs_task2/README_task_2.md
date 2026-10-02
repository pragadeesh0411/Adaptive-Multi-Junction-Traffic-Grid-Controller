# Adaptive Multi-Junction Traffic Grid Controller (AMTGC)

## Task 2 – Parameterized RTL Module Design

## 1. Introduction

This stage of the AMTGC project focuses on developing reusable and parameterized RTL modules for a traffic-junction controller.

The Task 2 design contains two main reusable modules:

1. `generic_timer`
2. `junction_controller`

The `generic_timer` provides independent configurable timing, while the `junction_controller` implements a Moore Finite State Machine (FSM) for controlling traffic signals and pedestrian operation.

The same `junction_controller` RTL is used for multiple junction configurations by changing parameter values instead of creating separate RTL designs.

---

## 2. Objectives

The main objectives of Task 2 are:

- Develop a reusable `generic_timer` module.
- Develop a parameterized `junction_controller` module.
- Implement the traffic controller using a Moore FSM.
- Use configurable timing parameters.
- Keep timer logic separate from FSM logic.
- Demonstrate hardware reusability.
- Verify the timer with multiple parameter configurations.
- Verify the complete junction traffic sequence.
- Verify pedestrian request handling.
- Test important corner cases.
- Produce ModelSim waveforms demonstrating correct operation.

---

## 3. Repository Structure

```text
AMTGC/
│
├── README.md
│
├── rtl/
│   ├── generic_timer.v
│   └── junction_controller.v
│
├── tb/
│   ├── generic_timer_tb.v
│   └── junction_controller_tb.v
│
├── docs/
│   └── Task 2 documentation
│
├── sim/
│   └── ModelSim simulation files and logs
│
└── screenshots/
    └── Task 2 waveform screenshots