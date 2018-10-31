clear all;clc;close all;

executablePath = 'C:\\Users\\lachner\\Documents\\MOSSDET_c\\MOSSDET_c.exe';
matlabFilePath = 'C:\\Users\\lachner\\Documents\\MOSSDET_c\\mattest.mat';
decisionFunctionsPath = 'C:\\Users\\lachner\\Documents\\MOSSDET_c';
outputPath = decisionFunctionsPath;
startTimeSec = 0;
endTimeSec = 3600;
samplingRate = 2000;
eoiType = 'Ripples'; 'HFO+IES';'Ripples';'FastRipples';'IES';

command = strcat(executablePath, {' '}, matlabFilePath, {' '}, decisionFunctionsPath, {' '}, outputPath, {' '}, num2str(startTimeSec), {' '}, num2str(endTimeSec), {' '}, num2str(samplingRate), {' '}, eoiType);
system(command{1})
load(strcat(outputPath, '\\MOSSDET_Output\\MOSSDET_Detections.mat'));

%MOSSDET_Detections.mat has a detected event on each column. 
%First Row is event type, second row is star time and third row is end time

%Detection Classes
%coincident R and FR = 1
%isolated Ripple = 2
%isolated FR = 3

%isolated IES= 4

%IES and Ripple and FR = 5
%IES and Ripple = 6
%IES and FR = 7
