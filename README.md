# MOSSDET_c

This MATLAB compatible 64 bit executable reads row-vectors corresponding to a signal from a single channel. The detections are output as a matrix with 3 rows corresponding to:

**Row one: Code for the detection class:**
- Ripples (1)
- Fast-Ripples (2)
- Spikes (3)

**Row two:  Detection start time in seconds**

**Row three: Detection end-time in seconds**


- The file MATLAB_MOSSDET_Example.m provides an example on how to call the executable MOSSDET_c.exe
- The file mattest.m provides an example of the expected input data:a signal from a single channel in the form of a row-vector



Publication on the detectors: https://iopscience.iop.org/article/10.1088/1741-2552/ab4560/meta
