# MOSSDET_c

MATLAB-compatible executable which reads and writes MATLAB variables. The MATLAB compatible executable reads row-vectors corresponding to a signal from a single channel. The detections are output as a matrix with 3 rows corresponding to:

Row one: Code for the detection class:
  o	Ripple and FR only(1)
  o	Ripple only(2)
  o	FR only (3)
  o	Spike only (4)
  o	Spike and Ripple and FR only (5)
  o	Spike and Ripple only (6)
  o	Spike and FR only (7)

Row two:  Detection start time in seconds
Row three: Detection end-time in seconds
