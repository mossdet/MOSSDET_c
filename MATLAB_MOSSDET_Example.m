%Example of MATLAB function used to detect HFO, the signal must be at least one minute long to allow the correct normalization of the features used for the detection
%System requirements: Windows 64 bit
function hfoDetections = detectHFO(signal, samplingRate)
        
    hfoDetectorFolder = 'D:\MATLAB\Projects\DetectHFO\MOSSDET_c\';												%Location of the .exe and .dat files
    signal = transpose(signal);																					% a matrix with nr.samples Rows and 1 Column is expected
    savedSignalPath = strcat(hfoDetectorFolder, 'mossdetSignal.mat');											%path of temporary file used for detection
    save(savedSignalPath,'signal');
    outputFolder = strcat(hfoDetectorFolder);																	% path to save the detection output
    
    mossdetVariables.exePath = strcat(hfoDetectorFolder, 'MOSSDET_c.exe');
    mossdetVariables.signalFilePath = savedSignalPath;
    mossdetVariables.decFunctionsPath = hfoDetectorFolder;
    mossdetVariables.outputPath = outputFolder;
    mossdetVariables.startTime = 0;																				% set needed start time
    mossdetVariables.endTime = 60*60*243*65;																	% set needed end time, infinite equals signal length
    mossdetVariables.samplingRate = samplingRate;
    mossdetVariables.eoiType = 'All';
    mossdetVariables.verbose = 0;																				% set to 1 to enable outputs to teh matlab console and check detection progress
    mossdetVariables.saveDetections = 0;																		% set to 1 to save text files with the detections channel, start and end time

    command = strcat(mossdetVariables.exePath, {' '},...
                     mossdetVariables.signalFilePath, {' '},...
                     mossdetVariables.decFunctionsPath, {' '}, ...
                     mossdetVariables.outputPath, {' '},...
                     num2str(mossdetVariables.startTime), {' '},...
                     num2str(mossdetVariables.endTime), {' '},...
                     num2str(mossdetVariables.samplingRate), {' '},...
                     mossdetVariables.eoiType, {' '},...
                     num2str(mossdetVariables.verbose), {' '},...
                     num2str(mossdetVariables.saveDetections));

    system(command{1})																							% call executable with the set parameters
    detectOutFilename = strcat(mossdetVariables.outputPath, 'MOSSDET_Output\', 'MOSSDET_Detections.mat');
    load(detectOutFilename);																					% load file with the detections
   
   %The detections file contains three rows
   %Row one: Marks indicating the detected event
        % 1 -> any Ripple
        % 2 -> any FR
        % 3 -> any IES
   %Row two: start time of the detected event
   %Row three: end time of the detected event

    hfoDetections.mark = 		MOSSDET_Detections(1,:);
    hfoDetections.startTime = 	MOSSDET_Detections(2,:);
    hfoDetections.endTime = 	MOSSDET_Detections(3,:);	
end