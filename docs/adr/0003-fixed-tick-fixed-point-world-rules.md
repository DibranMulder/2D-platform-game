# Use fixed-tick, fixed-point authoritative world rules

World Instances advance at a fixed tick and store gameplay positions and
velocities as integers. Fixed-point rules make validation, replay, testing, and
cross-machine consistency easier than frame-delta floating-point simulation,
at the cost of explicit scale and range choices that must be profiled before
combat tuning is finalized.

