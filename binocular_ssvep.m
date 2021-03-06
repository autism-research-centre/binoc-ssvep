function binocular_ssvep

clear all
global pxsize frameWidth ycen xcen fixWidth scr l_key u_key d_key r_key esc_key stimRect fixLines fixPoint frameRect;

try
%% Get basic info, set filename.
rng('shuffle');
% subject info and screen info

ID = input('Participant ID? ', 's');
diagnosis = input('Diagnosis? ');
scr_diagonal = 24;
scr_distance = 60;

tstamp = clock;
if ~isdir( fullfile(pwd, 'Results', mfilename, num2str(diagnosis)) )
    mkdir( fullfile(pwd, 'Results', mfilename, num2str(diagnosis)) );
end
savefile = fullfile(pwd, 'Results', mfilename, num2str(diagnosis), [sprintf('%02d-%02d-%02d-%02d%02d-', tstamp(1), tstamp(2), tstamp(3), tstamp(4), tstamp(5)), ID, '.mat']);

%% Experiment Variables.
scr_background = 127.5;
scr_no = 0;
scr_dimensions = Screen('Rect', scr_no);
xcen = scr_dimensions(3)/2;
ycen = scr_dimensions(4)/2;

% Frame Duration
frame_dur = 1/144;

% Frequencies
freq1 = 36;
freq2 = 28.8;
nframe{1} = 144/freq1;
nframe{2} = 144/freq2;

% Trialtime in seconds
trialdur = 12;

% Stimulus
% percentage of maximum contrast
contr = 0.6;
% stimsize in degree
stimsize = 6;
% cycles per degree
cycpdegree = 2;

%% Set up Keyboard, Screen, Sound
% Keyboard
KbName('UnifyKeyNames');
u_key = KbName('UpArrow');
d_key = KbName('DownArrow');
l_key = KbName('LeftArrow');
r_key = KbName('RightArrow');
esc_key = KbName('Escape');
ent_key = KbName('Return'); ent_key = ent_key(1);
keyList = zeros(1, 256);
keyList([u_key, d_key, esc_key, ent_key]) = 1;
KbQueueCreate([], keyList); clear keyList

% I/O driver
config_io
address = hex2dec('D010');
% in the triggers, 0=no, 1=right, 10=up, 11=up+right, 100=left,
% 101=left+right, 110=left+up, 111=left+up+right

% Sound
% InitializePsychSound;
% pa = PsychPortAudio('Open', [], [], [], [], [], 256);
% bp400 = PsychPortAudio('CreateBuffer', pa, [MakeBeep(400, 0.2); MakeBeep(400, 0.2)]);
% PsychPortAudio('FillBuffer', pa, bp400);

% Open Window
scr = Screen('OpenWindow', scr_no, scr_background);
HideCursor;
Screen('BlendFunction', scr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%% Prepare stimuli
% Stimsize
pxsize = visual_angle2pixel(6, scr_diagonal, scr_distance, scr_no);

% Make Stimuli
grating1 = make_grating(pxsize, cycpdegree*stimsize, contr, 0);
grating{1} = Screen('MakeTexture', scr, grating1);
grating2 = make_grating(pxsize, cycpdegree*stimsize, -contr, 0);
grating{2} = Screen('MakeTexture', scr, grating2);

% Vergence Cues
fixWidth = visual_angle2pixel(stimsize / 40, scr_diagonal, scr_distance, scr_no);
fixLength = visual_angle2pixel(stimsize / 15, scr_diagonal, scr_distance, scr_no);
frameWidth = visual_angle2pixel( stimsize / 30, scr_diagonal, scr_distance, scr_no);
fixLines = [-fixLength, +fixLength, 0, 0; 0, 0, -fixLength, +fixLength];

angle{1} = 45;
angle{2} = -45;


%% Calibrate
find_offset;

%% Demonstrate
for k = 1:2
    Screen('DrawTexture', scr, grating{1}, [], stimRect{k}, angle{1});
    Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
    Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
end
Screen('Flip', scr);
WaitSecs(0.5); KbWait;
for k = 1:2
    Screen('DrawTexture', scr, grating{1}, [], stimRect{k}, angle{2});
    Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
    Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
end
Screen('Flip', scr);
WaitSecs(0.5); KbWait;
for k = 1:2
    Screen('DrawTexture', scr, grating{1}, [], stimRect{k}, angle{k});
    Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
    Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
end
Screen('Flip', scr);
WaitSecs(0.5); KbWait;
for k = 1:2
    Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
    Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
end
Screen('Flip', scr);
WaitSecs(0.5); KbWait;


%% Try without Flicker

pressSecs = zeros([trialdur*144, 1]);
pressList = zeros([trialdur*144, 3]);
trigg = zeros([trialdur*144, 1]);

Priority(1);
outp(address, 101); WaitSecs(0.002); outp(address, 0);
for i = 2:trialdur*144
    
    for k = 1:2
        Screen('DrawTexture', scr, grating{1}, [], stimRect{k}, angle{k});
        Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
        Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
    end
    Screen('Flip', scr);
    [~, pressSecs(i), firstPress] = KbCheck;
    pressList(i, 1:3) = firstPress(1, [l_key, u_key, r_key]);
    if sum(pressList(i, 1:3) ~= pressList(i-1, 1:3))
        outp(address, binaryVectorToDecimal(pressList(i, 1:3))+1);
        WaitSecs(0.002); outp(address, 0);
    end
    
    
end
outp(address, 99); WaitSecs(0.002); outp(address, 0);
Priority(0);
trialNoFlicker = struct( 'trigg', trigg, 'pressList', pressList, 'pressSecs', pressSecs );

trial_break(10, mfilename);

%% Try with Flicker
timestamps = zeros(1, trialdur*144);
timestamps(1) = GetSecs;

pressSecs = zeros([trialdur*144, 1]);
pressList = zeros([trialdur*144, 3]);
trigg = zeros([trialdur*144, 1]);

Priority(1);
outp(address, 102);
for i = 2:trialdur*144
    
    for k = 1:2
        Screen('DrawTexture', scr, grating{mod(floor(i/nframe{k}), 2) + 1}, [], stimRect{k}, angle{k});
        Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
        Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
    end
    timestamps(i) = Screen('Flip', scr); %, timestamps(i-1)+0.8*frame_dur, 1);
    [~, pressSecs(i), firstPress] = KbCheck;
    pressList(i, 1:3) = firstPress(1, [l_key, u_key, r_key]);
    if sum(pressList(i, 1:3) ~= pressList(i-1, 1:3))
        outp(address, binaryVectorToDecimal(pressList(i, 1:3))+1);
        WaitSecs(0.002); outp(address, 0);
        trigg(i) = binaryVectorToDecimal(pressList(i, 1:3)) +1;
    end
    
end
outp(address, 99); WaitSecs(0.002); outp(address, 0);
Priority(0);
timediff = timestamps(2:end) - timestamps(1:end-1);
practiceFlicker = struct( 'trigg', trigg, 'pressList', pressList, 'pressSecs', pressSecs, 'timediff', timediff );

trial_break(10, mfilename);

%% Trials
% make schedule
j = 0;
for iflickerLeft = 0:1
   for iangleLeft = 0:1
        for itrialNo = 1:4
            j = j+1;
            flickerOrder(1, j) = iflickerLeft +1; %#ok<*AGROW>
            angleOrder(1, j) = iangleLeft +1;
            flickerOrder(2, j) = ~iflickerLeft +1;
            angleOrder(2, j) = ~iangleLeft +1;
        end
   end
end
sched = randperm(j);
flickerOrder(1:2, :) = flickerOrder(1:2, sched);
angleOrder(1:2, :) = angleOrder(1:2, sched);


% run trials
for currTrial = 1:j;
    timestamps = zeros(1, trialdur*144);
    timestamps(1) = GetSecs;

    pressSecs = zeros([trialdur*144, 1]);
    pressList = zeros([trialdur*144, 3]);
    trigg = zeros([trialdur*144, 1]);
    
    Priority(1);
    outp(address, 200+currTrial); WaitSecs(0.002); outp(address, 0);
    for i = 2:trialdur*144

        for k = 1:2
            Screen('DrawTexture', scr, grating{mod(floor(i/nframe{flickerOrder(k, currTrial)}), 2) + 1}, [], stimRect{k}, angle{angleOrder(k, currTrial)});
            Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
            Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
        end
        timestamps(i) = Screen('Flip', scr); %, timestamps(i-1)+0.8*frame_dur, 1);
        [~, pressSecs(i), firstPress] = KbCheck;
        pressList(i, 1:3) = firstPress(1, [l_key, u_key, r_key]);
        if sum(pressList(i, 1:3) ~= pressList(i-1, 1:3))
            outp(address, binaryVectorToDecimal(pressList(i, 1:3))+1);
            WaitSecs(0.002); outp(address, 0);
            trigg(i) = binaryVectorToDecimal(pressList(i, 1:3)) +1;
        end

    end
    outp(address, 99); WaitSecs(0.002); outp(address, 0);
    Priority(0);
    
    timediff = timestamps(2:end) - timestamps(1:end-1);
    trialData(currTrial) = struct( 'trigg', trigg, 'pressList', pressList, 'pressSecs', pressSecs, 'timediff', timediff );
    trial_break(10, mfilename);
end
error('End');

catch err
%% Catch
    sca;
    PsychPortAudio('Close');
    save(savefile);
    Priority(0);
    save('temp_binocular_ssvep.mat');
    rethrow(err);
end
end