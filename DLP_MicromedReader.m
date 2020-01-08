hddLetter = 'F'; %in case data is saved on a portable memory
files = {':\DLP_Projekt\PatientFiles\PatA.TRC'};     
plotsDir = 'F:\DLP_Projekt\Plots_Folder\';
hfoDetectorFolder = 'F:\DLP_Projekt\MOSSDET_c\';
ignoreChannels  = { 'C3', 'C4', 'Cz', 'F3', 'F4', 'F7', 'F8', 'Fp1', 'FP1', 'Fp2', 'FP2', 'Fz', 'FZ', 'O1', 'O2', 'P3', 'P4', 'Pz', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'igger',...
                    'ekg', 'ECG1', 'ECG2', 'EKG', 'EMG', 'emg', 'EOG','EOG_o', 'EOG_u', 'EOG_li', 'EOG_re',...
                    'MKR1+', 'ecg1', 'ecg2', 'delg1', 'delg2', 'deld1', 'deld2', 'PULS+', 'BEAT+', 'SpO2+', 'MKR2+'};

plotOK = 1;

for fileIdx = 1:size(files,2)
    filename = strcat(hddLetter, files{fileIdx});
    
    % make bipolar montages with same letter channles and only(!)
    % consecutive chann.numbers
    
    %ignore channels in list
    
    header = ft_read_header(filename);
    plotsDir = strcat(plotsDir, header.orig.name, header.orig.surname, '\');
    mkdir(plotsDir);

    %Read Data
    channsList = header.label;
    signals = ft_read_data(filename);
    samplingRate = header.Fs;
    
    %Delete data from channels to ignore
    deleteChannelsIdx = contains(channsList, ignoreChannels);
    channsList(deleteChannelsIdx) = [];
    signals(deleteChannelsIdx,:) = [];

    %Remove characters that are not letter or numbers in order to be able
    %to generate the bipolar montages
    channsList = strrep(channsList, '''', ''); 
    nrChanns = length(channsList);
    for chi = 1:nrChanns 
        channsList{chi} = strrep(channsList{chi}, '''', ''); 
    end
        
    [unipolarContacts, bipolarMontages] = getBipolarMontageLabels(channsList);
    [bipolarSignals, bipolarChannelsList] = getBipolarMontageSignals(signals, bipolarMontages);
    
    nrBipolarChanns = length(bipolarMontages);
    %use of parfor is possible here if enough RAM avaibalable
    for bchi = 1:nrBipolarChanns
        signal = bipolarSignals(bchi,:);
        montageName = bipolarChannelsList{bchi};
        detectHFO(hfoDetectorFolder, signal(1:60*samplingRate)', samplingRate, montageName, plotsDir, plotOK); 
    end
end

function [unipolarContacts, bipolarMontages] = getBipolarMontageLabels(allChannsList)
	unipolarContacts = [];
    bipolarMontages = [];
    nrUnipolarChanns = length(allChannsList);
    numbers = ['0','1','2','3','4','5','6','7','8','9'];
    useTenTwenty = 0;
    tenTwentyChannels = { 'C3', 'P3', 'C4', 'P4', 'F3', 'C3', 'F4', 'C4', 'F7', 'Sp1', 'SP1', 'F8', 'Sp2', 'SP2', 'Fp1', 'FP1', 'F3', 'F7', 'Fp2', 'FP2', 'F4', 'F8', 'P3', 'O1', 'P4', 'O2', 'T3', 'T1', 'T2', 'T4', 'T3', 'T5', 'T4', 'T6', 'T5', 'O1', 'T6', 'O2', 'Pz', 'Cz', 'PZ', 'CZ' , 'FZ', 'Fz' };
    notUsedChannels = { 'EKG', 'ekg', 'ECG', 'ecg', 'EMG', 'emg', 'EOG', 'eog', 'igger', 'IGGER', 'Triggerpulse', 'triggerpulse' };

    %Get Unipolar contacts
    for uniChIdx = 1:nrUnipolarChanns
		chLabel = allChannsList{uniChIdx};
		contact.contactName = chLabel;
		contact.contactGlobalIdx = uniChIdx;
		
		foundNrIndices = [];
		for ni = 1:length(numbers)
			strIdx = strfind(chLabel, numbers(ni));
			foundNrIndices = cat(1, foundNrIndices, strIdx);
		end
		firstNumIdx = min(foundNrIndices);
		lastNumIdx = max(foundNrIndices);
		contact.contactNr = str2double(chLabel(firstNumIdx:lastNumIdx));
		contact.electrodeName = chLabel(1:firstNumIdx-1);

        if isempty(contact.electrodeName) ||...
                (useTenTwenty == 0 && sum(contains(tenTwentyChannels, chLabel)) > 0) ||...
                (sum(contains(notUsedChannels, contact.electrodeName)) > 0) ||...
                (contains(chLabel, 'igger'))
            continue;
        end
        
        unipolarContacts = cat(1, unipolarContacts, contact);        
    end
    
    %Get Bipolar Montages
    montageNr = 1;
    for upi = 1:size(unipolarContacts, 1)-1
        montage.firstElectrodeName = unipolarContacts(upi).electrodeName;
        montage.firstContactNr = unipolarContacts(upi).contactNr;
        montage.firstContactGlobalIdx = unipolarContacts(upi).contactGlobalIdx;

        montage.secondElectrodeName = unipolarContacts(upi+1).electrodeName;
        montage.secondContactNr = unipolarContacts(upi+1).contactNr;
        montage.secondContactGlobalIdx = unipolarContacts(upi+1).contactGlobalIdx;

        montage.montageName = strcat(unipolarContacts(upi).electrodeName, num2str(unipolarContacts(upi).contactNr),...
                                    '-',...
                                     unipolarContacts(upi+1).electrodeName, num2str(unipolarContacts(upi+1).contactNr));
                                 
        montage.montageMOSSDET_Nr = montageNr;
        
        if strcmp(montage.firstElectrodeName, montage.secondElectrodeName)
            bipolarMontages = cat(1, bipolarMontages, montage); 
        end
    end
end

function [bipolarSignals, bipolarChannelsList] = getBipolarMontageSignals(allSignals, bipolarMontages)
    nrBipolarSignals = size(bipolarMontages,1);
    nrSamples = size(allSignals, 2);
    bipolarSignals = zeros(nrBipolarSignals, nrSamples);
    bipolarChannelsList = cell(nrBipolarSignals, 1);

    for bpi = 1:nrBipolarSignals
        signalA = allSignals(bipolarMontages(bpi).firstContactGlobalIdx, :);
        signalB = allSignals(bipolarMontages(bpi).secondContactGlobalIdx, :);

        bipolarSignals(bpi, :) = (signalA(:)-signalB(:))*-1;
        bipolarChannelsList{bpi,1} = bipolarMontages(bpi).montageName;
    end
end
