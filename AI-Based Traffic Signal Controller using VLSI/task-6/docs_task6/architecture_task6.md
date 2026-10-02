# AMTGC Final Architecture

## 1. System Architecture

The final system contains two traffic-junction controllers connected through shared pedestrian arbitration and green-wave coordination.

```text
                         +----------------------+
                         |       AMTGC TOP      |
                         +----------+-----------+
                                    |
              +---------------------+---------------------+
              |                                           |
              v                                           v
      +---------------+                           +---------------+
      |  JUNCTION A   |                           |  JUNCTION B   |
      | Moore FSM     |                           | Moore FSM     |
      | Adaptive Ctrl |                           | Adaptive Ctrl |
      +-------+-------+                           +-------+-------+
              |                                           |
              |                                           |
      +-------v-------+                           +-------v-------+
      | Generic Timer |                           | Generic Timer |
      +---------------+                           +---------------+

              ^                                           ^
              |                                           |
              +---------------+-------------+-------------+
                              |
                    +---------v---------+
                    | Pedestrian Arbiter|
                    |  Round-Robin      |
                    +-------------------+

                              ^
                              |
                    +---------+---------+
                    | Green-Wave        |
                    | Coordinator       |
                    +-------------------+

Emergency Override
        |
        +--------------------> Junction A
        |
        +--------------------> Junction B
```

---

## 2. Functional Responsibilities

### Junction Controller

Each `junction_controller` is responsible for:

- Traffic phase sequencing
- Yellow phases
- All-red safety phases
- Pedestrian phase
- Emergency handling
- Density sampling
- Adaptive green-time calculation
- Timer control

### Generic Timer

The timer performs only generic count/done functionality.

It does not know:

- Traffic density
- Pedestrian requests
- Emergency control
- Traffic-light phases

### Pedestrian Arbiter

The arbiter determines which junction receives a pedestrian grant when requests compete.

### Green-Wave Coordinator

The coordinator generates the timing relationship associated with Junction A NS green and Junction B NS green.

### Top-Level Integration

`amtgc_top` connects all functional modules using explicit named ports.

---

## 3. Adaptive Timing Location

Adaptive timing is implemented inside the `junction_controller`.

Reason:

```text
traffic_density
      |
      v
sampled_density
      |
      v
adaptive green calculation
      |
      v
green timer target
      |
      v
generic_timer
```

The controller has knowledge of traffic phases, while the generic timer remains reusable.

The Task 4 design uses parameterized values including green time, minimum/maximum green time, extension per density level, yellow time, red time, pedestrian time, counter width, and green-wave configuration. :contentReference[oaicite:0]{index=0}

---

## 4. Density Sampling

The implemented strategy samples density when a new green phase begins.

```text
New Green Phase
      |
      v
Sample traffic_density
      |
      v
Calculate target
      |
      v
Run complete green phase
```

A density change during the active green phase is therefore applied to a later green phase rather than continuously changing the running phase. :contentReference[oaicite:1]{index=1}