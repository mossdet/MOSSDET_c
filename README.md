# MOSSDET_c

This MATLAB compatible executable reads row-vectors corresponding to a signal from a single channel. The detections are output as a matrix with 3 rows corresponding to:

Row one: Code for the detection class:
Ripple and FR only(1)
Ripple only(2)
FR only (3)
Spike only (4)
Spike and Ripple and FR only (5)
Spike and Ripple only (6)
Spike and FR only (7)

Row two:  Detection start time in seconds

Row three: Detection end-time in seconds


- The file callMOSSDET.m provides an example on how to call the executable MOSSDET_c.exe
- The file mattest.m provides an example of the expected input data:a signal from a single channel in the form of a row-vector
- The folder MOSSDET_Output provides an example of the generated output
