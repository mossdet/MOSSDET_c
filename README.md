# MOSSDET_c

This MATLAB compatible 64 bit executable reads row-vectors corresponding to a signal from a single channel. The detections are output as a matrix with 3 rows corresponding to:

**Row one: Code for the detection class:**
- Ripples (1)
- Fast-Ripples (2)
- Spikes (3)

**Row two:  Detection start time in seconds**

**Row three: Detection end-time in seconds**


- The files DLP_MicromedReader.m and detectHFO.m provide an example respectively on how to read different file formats using the field trip toolbox (http://www.fieldtriptoolbox.org/) and call the executable MOSSDET_c.exe.

Publication on the detectors: https://iopscience.iop.org/article/10.1088/1741-2552/ab4560/meta

Contact: daniel.lachner@hotmail.com
