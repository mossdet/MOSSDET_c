%Example of MATLAB function used to detect HFO, the signal must be at least one minute long to allow the correct normalization of the features used for the detection
%System requirements: Windows 64 bit
function hfoDetections = detectHFO(hfoDetectorFolder, hfoSignal, samplingRate, montageName, plotsDir, plotOK)        
    %detect the HFO
    hfoDetections = [];
    hfoSignal = transpose(hfoSignal);
    savedSignalPath = strcat(hfoDetectorFolder, montageName, '.mat');
    save(savedSignalPath,'hfoSignal');
    outputFolder = strcat(hfoDetectorFolder, montageName, '\');
    outputFolder = strrep(outputFolder, '\', '\\'); % this string is passed to a c++ program so the backslash needs to be escaped by anoter backslash
    %outputFolder = strcat('D:\\MATLAB\\Projects\\CCEP_ver3\\MOSSDET_c\\', stimMontageName, '_', responseChannel,'\\');
    
    mossdetVariables.exePath = strcat(hfoDetectorFolder, 'MOSSDET_c.exe');
    mossdetVariables.signalFilePath = savedSignalPath;
    mossdetVariables.decFunctionsPath = hfoDetectorFolder;
    mossdetVariables.outputPath = outputFolder;
    mossdetVariables.startTime = 0;
    mossdetVariables.endTime = 60*60*243*65;    
    mossdetVariables.samplingRate = samplingRate;
    mossdetVariables.eoiType = 'HFO+IES'; %Options are 'HFO+IES' or 'SleepSpindles';
    mossdetVariables.verbose = 0;
    mossdetVariables.saveDetections = 1;

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

    system(command{1})
    
    %read detections from generated text files instead of generating a
    %matlab file, which fails often
    MOSSDET_Detections = [];
    MOSSDET_Detections = readDetections(mossdetVariables.outputPath, montageName, 'Ripple', MOSSDET_Detections);
    MOSSDET_Detections = readDetections(mossdetVariables.outputPath, montageName, 'FastRipple', MOSSDET_Detections);
    MOSSDET_Detections = readDetections(mossdetVariables.outputPath, montageName, 'Spike', MOSSDET_Detections);

    delete(mossdetVariables.signalFilePath);
    rmdir(mossdetVariables.outputPath, 's');
    MOSSDET_Detections = getIES_CoincidentHFO(MOSSDET_Detections);
    
    if isempty(MOSSDET_Detections)
        hfoDetections.mark = [];
        hfoDetections.startSample = [];
        hfoDetections.endSample = []; 
    else
        [~,idx] = sort(MOSSDET_Detections(2,:)); % sort just the second row
        MOSSDET_Detections = MOSSDET_Detections(:,idx);   % sort the whole matrix using the sort indices

        hfoDetections.mark = int64(MOSSDET_Detections(1,:));
        detectionStartTimesLocal = MOSSDET_Detections(2,:);
        detectionEndTimesLocal = MOSSDET_Detections(3,:);
        detectionStartSamplesLocal = int64(double(detectionStartTimesLocal).*double(samplingRate));
        detectionEndSamplesLocal = int64(double(detectionEndTimesLocal).*double(samplingRate));
        hfoDetections.startSample = detectionStartSamplesLocal;
        hfoDetections.endSample = detectionEndSamplesLocal; 
    end
        
    % plot the events being detected on the responses generated by
    % a single stimulated channel
    if plotOK > 0
        %transform to uV
        hfoSignal = hfoSignal*1000*1000;
        
        %Variables from the complete signal
        order = 128;
        filterDelay = order/2;
        h = fir1(order/2, [80/(samplingRate/2) 500/(samplingRate/2)], 'bandpass'); % 'low' | 'bandpass' | 'high' | 'stop' | 'DC-0' | 'DC-1'
        filteredHFO_SignalWhole = filter(h, 1, flip(hfoSignal));
        filteredHFO_SignalWhole = filter(h, 1, flip(filteredHFO_SignalWhole));
        filteredHFO_SignalWhole(1:filterDelay) = filteredHFO_SignalWhole(filterDelay+1);
        filteredHFO_SignalWhole(end-filterDelay:end) = filteredHFO_SignalWhole(end-filterDelay-1);
        timeWhole = 0:length(hfoSignal)-1;
        timeWhole = timeWhole/samplingRate;
        
        [minPossFreq,maxPossFreq] = cwtfreqbounds(length(filteredHFO_SignalWhole), samplingRate);
        minFreq = 60;
        maxFreq = 600;
        if (minPossFreq > minFreq) || (maxPossFreq < maxFreq) 
            stop = 1;
        end
        [cfs,frq, coi] = cwt(filteredHFO_SignalWhole, 'amor', samplingRate, 'FrequencyLimits',[minFreq maxFreq]);
        absCFS = abs(cfs);
        normCFS_Whole = (absCFS - mean(absCFS,'all'))/std(absCFS,0,'all');
                
        %Plot every X second
        periodToPlot = 1;   % in seconds
        signalLength = length(filteredHFO_SignalWhole);
        for loopSample = 1:samplingRate*periodToPlot:signalLength
            startS = loopSample;
            endS = startS + samplingRate*periodToPlot;
            if startS >=  signalLength || endS >  signalLength
                break;
            end
            
            %select the variables for teh corresponding plot
            filteredHFO_Signal = filteredHFO_SignalWhole(startS:endS);
            time = timeWhole(startS:endS);
            normCFS = normCFS_Whole(:, startS:endS);
            rawSignal = hfoSignal(startS:endS);
            selectedHFO_Detections = hfoDetections;
            ignoreIdxs = selectedHFO_Detections.startSample < startS | selectedHFO_Detections.endSample > endS;
            selectedHFO_Detections.mark(ignoreIdxs) = [];
            selectedHFO_Detections.startSample(ignoreIdxs) = [];
            selectedHFO_Detections.endSample(ignoreIdxs) = [];
            
            if not(isempty(selectedHFO_Detections.mark))
                close all;
                clear h;
                figName = strcat(montageName, '-', num2str(int64(startS/samplingRate)), 's');
                f2 = figure('Name', figName,'NumberTitle','off', 'Color', 'w');
                subplot(4,1,1)
                h1 = plot(time(), filteredHFO_Signal,'k','LineWidth',0.01); hold on;
                h1.Color(4) = 0.3;
                legendStr{1} = 'Band-Passed (80-500 Hz)';
                legendIdx = 2;
                nrRipples = 0;
                nrFR = 0;
                for detIdx = 1:length(selectedHFO_Detections.mark)
                    allRipples = selectedHFO_Detections.mark(detIdx) == 1;     
                    if allRipples
                        startSample = selectedHFO_Detections.startSample(detIdx)-startS;
                        endSample = selectedHFO_Detections.endSample(detIdx)-startS;
                        h2 = plot(time(startSample:endSample), filteredHFO_Signal(startSample:endSample),'b','LineWidth',0.01); hold on;
                        nrRipples = nrRipples+1;
                    end
                    allFR = selectedHFO_Detections.mark(detIdx) == 2;
                    if allFR
                        startSample = selectedHFO_Detections.startSample(detIdx)-startS;
                        endSample = selectedHFO_Detections.endSample(detIdx)-startS;
                        h3 = plot(time(startSample:endSample), filteredHFO_Signal(startSample:endSample),'g','LineWidth',0.01); hold on;
                        nrFR = nrFR+1;
                    end
                end
                legendArray = h1;
                if nrRipples > 0 
                    legendStr{legendIdx} = strcat('Ripple Detections (', num2str(nrRipples), ')');
                    legendIdx = legendIdx+1;
                    legendArray = cat(2, legendArray, h2);
                end
                if nrFR > 0
                    legendStr{legendIdx} = strcat('FR Detections (', num2str(nrFR), ')');
                    legendIdx = legendIdx+1;
                    legendArray = cat(2, legendArray, h3);
                end
                xlim([min(time) max(time)])
                xlabel('Time (s)')
                ylabel('Amplitude (uV)')
                title('all HFO', 'FontSize',20)
                [~, hobj, ~, ~] = legend(legendArray, legendStr, 'FontSize',16, 'Box', 'off');
                hl = findobj(hobj,'type','line');
                set(hl,'LineWidth',5);

                subplot(4,1,2)
                hfoPlot = plot(time(), filteredHFO_Signal,'k','LineWidth',0.01); hold on;
                hfoPlot.Color(4) = 0.2;
                legendStr{1} = 'Band-Passed (80-500 Hz)';
                legendIdx = 2;
                nrIESRipples = 0;
                nrIESFR = 0;
                for detIdx = 1:length(selectedHFO_Detections.mark)
                    allRipples = selectedHFO_Detections.mark(detIdx) == 4;
                    if allRipples
                        startSample = selectedHFO_Detections.startSample(detIdx)-startS;
                        endSample = selectedHFO_Detections.endSample(detIdx)-startS;
                        plot(time(startSample:endSample), filteredHFO_Signal(startSample:endSample),'m','LineWidth',0.01); hold on;
                        nrIESRipples = nrIESRipples+1;
                    end
                    allFR = selectedHFO_Detections.mark(detIdx) == 5;
                    if allFR
                        startSample = selectedHFO_Detections.startSample(detIdx)-startS;
                        endSample = selectedHFO_Detections.endSample(detIdx)-startS;
                        plot(time(startSample:endSample), filteredHFO_Signal(startSample:endSample),'c','LineWidth',0.01); hold on;
                        nrIESFR = nrIESFR+1;
                    end
                end
                if nrIESRipples > 0 
                    legendStr{legendIdx} = strcat('IES-Ripple Detections (', num2str(nrIESRipples), ')');
                    legendIdx = legendIdx+1;
                end
                if nrIESFR > 0
                    legendStr{legendIdx} = strcat('IES-FR Detections (', num2str(nrIESFR), ')');
                    legendIdx = legendIdx+1;
                end
                xlim([min(time) max(time)])
                xlabel('Time (s)')
                ylabel('Amplitude (uV)')
                title('IES-HFO', 'FontSize',20)
                [~, hobj, ~, ~] = legend(legendStr, 'FontSize',16, 'Box', 'off');                
                hl = findobj(hobj,'type','line');
                set(hl,'LineWidth',5);

                subplot(4,1,3)
                hfoPlot = plot(time, rawSignal,'k','LineWidth',0.01); hold on;
                hfoPlot.Color(4) = 0.2;
                nrEOI = 0;
                for detIdx = 1:length(selectedHFO_Detections.mark)
                    ies = selectedHFO_Detections.mark(detIdx) == 3;
                    if ies
                        startSample = selectedHFO_Detections.startSample(detIdx)-startS;
                        endSample = selectedHFO_Detections.endSample(detIdx)-startS;
                        plot(time(startSample:endSample), rawSignal(startSample:endSample),'r','LineWidth',0.01); hold on;
                        nrEOI = nrEOI+1;
                    end
                end
                title('IES', 'FontSize',20)
                xlim([min(time) max(time)])
                xlabel('Time (s)')
                [~, hobj, ~, ~] = legend('Raw',  strcat('IES Detections (', num2str(nrEOI), ')'), 'FontSize',16, 'Box', 'off');
                hl = findobj(hobj,'type','line');
                set(hl,'LineWidth',5);
                
                %ylabel('Amplitude')


                %Plot wavelet decomposition
                subplot(4,1,4)
                contour(time,frq,abs(normCFS), 'LineStyle','none', 'LineColor',[0 0 0], 'Fill','on')
                title('Wavelet Power Spectrum')
                %colorbar
                xlabel('Time (s)')
                ylabel('Frequency (Hz)')
                set(gca,'yscale','log')
                set(gcf,'Colormap',jet)
                set(gca,'XLim',[min(time) max(time)], 'YLim',[min(frq) max(frq)],'XGrid','On', 'YGrid','On')
                colorbar('east', 'AxisLocation','in', 'Color', 'w', 'FontSize', 12)
                %caxis([min(normCFS_Whole,[],'all') max(normCFS_Whole,[],'all')])

                set(gcf, 'Position', get(0, 'Screensize'));

                figOneFileName =  strcat(plotsDir, montageName, '_', num2str(int64(startS/samplingRate)), 's');
                %savefig(f2, figOneFileName, 'compact');
                hgexport(gcf, figOneFileName, hgexport('factorystyle'), 'Format', 'jpeg');
                close();
            end
        end    
    end

end

function MOSSDET_Detections = readDetections(outputFolder, channelsInfo, eventName, MOSSDET_Detections)

    outputFolder = strrep(outputFolder, '\\', '\');
    detectionOutFilename = strcat(outputFolder, 'MOSSDET_Output\', channelsInfo, '\DetectionFiles\', channelsInfo, '_', eventName, 'DetectionsAndFeatures.txt');
    if not(isfile(detectionOutFilename))
        detectionOutFilename
        stop = 1;
        return;
    end
    %Description	ChannelName	StartTime(s)	EndTime(s)	MaxEventAmplitude	MaxEventPower	MaxEventSpectralPeak (Hz)	AvgBackgroundAmplitude	AvgBackgroundPower	BackgroundStdDev
    [Description, ChannelName, StartTime, EndTime, MaxEventAmplitude, MaxEventPower, MaxEventSpectralPeak, AvgBackgroundAmplitude, AvgBackgroundPower, BackgroundStdDev] =...   
    textread(detectionOutFilename, '%s\t%s\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f', 'headerlines', 1);

    delete(detectionOutFilename);
    mark = 0;
    if strcmp(eventName, 'Ripple')
        mark = 1;
    elseif strcmp(eventName, 'FastRipple')
        mark = 2;
    elseif strcmp(eventName, 'Spike')
        mark = 3;    
    end
    marksVec = zeros(1, length(Description)) + mark;
    StartTime = transpose(StartTime);
    EndTime = transpose(EndTime);
    
    detectionsMatrix = [];
    if isempty(MOSSDET_Detections)
        detectionsMatrix = cat(1, detectionsMatrix, marksVec);
        detectionsMatrix = cat(1, detectionsMatrix, StartTime);
        detectionsMatrix = cat(1, detectionsMatrix, EndTime);
    else
        detectionsMatrix = cat(1, detectionsMatrix, cat(2, MOSSDET_Detections(1, :), marksVec));
        detectionsMatrix = cat(1, detectionsMatrix, cat(2, MOSSDET_Detections(2, :), StartTime));
        detectionsMatrix = cat(1, detectionsMatrix, cat(2, MOSSDET_Detections(3, :), EndTime));
    end
    MOSSDET_Detections = detectionsMatrix;
end

function MOSSDET_Detections = getIES_CoincidentHFO(MOSSDET_Detections)
    nrDetections = size(MOSSDET_Detections, 2);
    
    for fdi = 1:nrDetections    %iterate through HFO
        iesCoincidence = 0;
        fdType = MOSSDET_Detections(1, fdi);
        fdStart = MOSSDET_Detections(2, fdi);
        fdEnd = MOSSDET_Detections(3, fdi);
        fdDuration = fdEnd - fdStart;
        
        if(fdType == 3)
            continue;
        end
        
        for sdi = 1:nrDetections    %iterate through IES
            if (fdi == sdi || MOSSDET_Detections(1, sdi) ~= 3)
                continue;
            end
            sdStart = MOSSDET_Detections(2, sdi);
            sdEnd = MOSSDET_Detections(3, sdi);
            sdDuration = sdEnd - sdStart;
            overlapTime = getEventsOverlap(fdStart, fdEnd, sdStart, sdEnd);
            overlapPerc = 100*(overlapTime / fdDuration);
            if (100 * (overlapTime / sdDuration) > overlapPerc)
                overlapPerc = 100 * (overlapTime / sdDuration);
            end
            if overlapPerc > 50.0
                iesCoincidence = 1;
                break;
            end
        end
        
        %     - All Ripples     (1) -> any Ripple
        %     - All FR          (2) -> any FR
        %     - All IES         (3) -> any IES

        %     - IES_Ripples     (4) -> any Ripple coinciding with a IES
        %     - IES_FR          (5) -> any FR coinciding with a IES
        %     - isolRipples     (6) -> any Ripple not coinciding with IES
        %     - isolFR          (7) -> any FR not coinciding with IES

        if fdType == 1
            if iesCoincidence > 0
                MOSSDET_Detections = cat(2, MOSSDET_Detections, [4; fdStart; fdEnd]);
            else
                MOSSDET_Detections = cat(2, MOSSDET_Detections, [6; fdStart; fdEnd]);
            end
        elseif fdType == 2 
            if iesCoincidence > 0
                MOSSDET_Detections = cat(2, MOSSDET_Detections, [5; fdStart; fdEnd]);
            else
                MOSSDET_Detections = cat(2, MOSSDET_Detections, [7; fdStart; fdEnd]);
            end
        end
    end
end

function overlapTime = getEventsOverlap(feStart, feEnd, seStart, seEnd)
    overlapTime = 0;
    feDuration = feEnd - feStart;
    seDuration = seEnd - seStart;
    
    if feStart <= seStart && feEnd >= seEnd % first fully encompassing second
        overlapTime = seDuration;        
    elseif seStart <= feStart && seEnd >= feEnd % second fully encompassing first
        overlapTime = feDuration;        
    elseif (feStart <= seStart && feEnd >= seStart && feEnd <= seEnd) %last part of first inside second
        overlapTime = feEnd - seStart;
    elseif (seStart <= feStart && seEnd >= feStart && seEnd <= feEnd) %last part of second inside first
        overlapTime = seEnd - feStart;
    else
        overlapTime = 0;
    end
end
