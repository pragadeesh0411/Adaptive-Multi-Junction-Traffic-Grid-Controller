# Junction Controller FSM

## State Encoding

The implemented controller uses seven states:

```text
000 = NS GREEN
001 = NS YELLOW
010 = ALL RED TO EW
011 = EW GREEN
100 = EW YELLOW
101 = ALL RED TO NS
110 = PEDESTRIAN
```

## State Flow

```text
                 +-------------+
                 |  NS GREEN   |
                 +------+------+
                        |
                        v
                 +------+------+
                 | NS YELLOW   |
                 +------+------+
                        |
                        v
                 +------+------+
                 | ALL RED EW  |
                 +------+------+
                        |
                        v
                 +------+------+
                 |  EW GREEN   |
                 +------+------+
                        |
                        v
                 +------+------+
                 | EW YELLOW   |
                 +------+------+
                        |
                        v
                 +------+------+
                 | ALL RED NS  |
                 +------+------+
                        |
                        v
                 +------+------+
                 |  NS GREEN   |
                 +-------------+

Pedestrian service may occur from the appropriate all-red state:

                 ALL RED
                    |
                    v
              +-------------+
              | PEDESTRIAN  |
              +-------------+
                    |
                    v
             Resume traffic
```

## Emergency Behavior

The emergency override has priority over normal next-state operation.

Conceptually:

```text
Any active state
      |
      | emergency_override
      v
ALL RED
```

The exact response timing should be taken from the verified simulation evidence.

## Moore Output Behavior

The traffic outputs depend on the current FSM state.

### NS GREEN

```text
NS green = 1
EW red   = 1
```

### NS YELLOW

```text
NS yellow = 1
EW red    = 1
```

### ALL RED

```text
NS red = 1
EW red = 1
```

### EW GREEN

```text
NS red   = 1
EW green = 1
```

### EW YELLOW

```text
NS red    = 1
EW yellow = 1
```

### PEDESTRIAN

```text
NS red = 1
EW red = 1
Pedestrian active = 1
```

## Default State

The default branch places the controller into a safe all-red behavior.