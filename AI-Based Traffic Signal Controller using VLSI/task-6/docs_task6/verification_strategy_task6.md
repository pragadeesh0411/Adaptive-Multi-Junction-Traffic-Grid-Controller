# AMTGC Verification Strategy

## Objective

The AMTGC design is verified using a unified top-level self-checking testbench.

The verification does not depend only on manually observing waveforms.

## Directed Tests

The verification environment includes directed testing for:

- Normal traffic sequencing
- Pedestrian requests
- Simultaneous pedestrian requests
- Pedestrian fairness
- Emergency operation
- Repeated emergency operation
- Active reset
- Adaptive density operation
- Maximum density
- Mid-green density change
- Green-wave coordination

## Randomized Test

A randomized test is included to vary:

```text
A traffic density
B traffic density
Pedestrian request A
Pedestrian request B
Emergency override
```

The configured randomized test length is:

```text
1000 clock cycles
```

## Self-Checking

The testbench automatically checks:

- Invalid controller states
- Conflicting traffic greens
- Opposite red requirement
- Pedestrian all-red safety
- Simultaneous pedestrian grants
- All-red safety transitions
- Emergency all-red behavior
- Adaptive timing limits
- Green-wave timing

## Supporting Waveforms

Waveforms are archived for:

```text
Normal traffic
Pedestrian operation
Emergency override
Maximum traffic density
Green-wave coordination
```

Waveforms support the automated results; they do not replace automatic checking.

## Reproducibility

The ModelSim script:

```text
sim/task5_run.do
```

provides a repeatable compile and simulation flow.

The final repository must contain the exact RTL version used for the verified run.