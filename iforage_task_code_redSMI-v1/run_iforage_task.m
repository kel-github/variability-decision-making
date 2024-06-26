% Variability and learning: visual foraging task
% K. Garner 2018
% NOTES:
%
% Dimensions calibrated for 530 mm x 300 mm TSUS NVIDIA monitor (with viewing distance
% of 570 mm)
%
% If running on a different monitor, remember to set the monitor
% dimensions, eye to monitor distances, and refresh rate (lines 119-133)!!!!
% RUN ON SINGLE MONITOR DISPLAY ONLY
%
% Psychtoolbox 3.0.14 - Flavor: beta - Corresponds to SVN Revision 8301
% Matlab R2015a|R2017a
%
% SMI eyetracker functionality requires use of 32-bit Matlab (I used
% 2012a).
%
% Task is a visual search/foraging task. Participants seek the target which
% is randomly placed behind 1 of 16 doors. There are two conditions - high
% certainty (animal always in 1 of 4 locs) and low-certainty (1 of 12)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all the things
sca
clear all
clear mex

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up outputs

% make .json files functions to be written
%%%%%% across participants
% http://bids.neuroimaging.io/bids_spec.pdf
% 2. metadata file for the experiment - to go in the highest level, include
% task, pc, matlab and psychtoolbox version, eeg system (amplifier, hardware filter, cap, placement scheme, sample
% rate), red smi system, description of file structure
%%%%%% manual things
% 1. generate sub-XX_task-YY_runZZ_electrodes.tsv - using template
sub.num = input('sub number? ');
sub.sess = input('session? ');
sub_dir = make_sub_folders(sub.num);

sub.head = input('head circumference? in mm ');
generate_channel_loc_json(sub.head, sub.num, sub_dir); % generate eeg cap metadata
start_trial_num = input('trial number init?, 0 or last trial run ');
% sub.hand = input('left or right hand? (1 or 2)?');
% sub.sex = input('sub sex (note: not gender? (1=male,2=female,3=inter)');
% sub.age = input('sub age?');
sub.stage = input('pilot_beh, pilot_eeg, or exp? ');
version   = 1; % change to update output files with new versions

% set randomisation seed based on sub/sess number
r_num = [num2str(sub.num) num2str(sub.sess)];
r_num = str2double(r_num);
rand('state',r_num);
randstate = rand('state');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% generate trial structure for participants
if ~any(start_trial_num) % if beginning the session then initialise the parameters
    [beh_form, beh_fid] = initiate_sub_beh_file(sub.num, sub.sess, sub_dir, version); % this is the behaviour and the events log
    % probabilities of target location
    ntrials = 80; % per condition - must be a multiple of 20
    load('probs_cert_world_v2.mat')
    cert_probs   = probs_cert_world;
    clear probs_cert_world
    load('probs_uncert_world_v2.mat')
    uncert_probs = probs_uncert_world;
    load('loc_configs.mat')
    sub_loc_config = loc_config(:, sub.num);
    % get subject counterbalance for 1st block
    load('learn_blocks.mat')
    init_order = learn_blocks(sub.num);
    clear learn_blocks
    [trials, cert_p_order, uncert_p_order] = generate_trial_structure_v3(ntrials, sub_loc_config, cert_probs, uncert_probs, init_order);
    door_ps = [cert_p_order; uncert_p_order; repmat(1/16, 1, 16)];
    
    % add the 10 practice trials to the start of the matrix
    n_practice_trials = 5;
    practice = [ repmat(999, n_practice_trials, 1), ...
        repmat(3, n_practice_trials, 1), ...
        datasample(1:16, n_practice_trials)', ...
        repmat(999, n_practice_trials, 1), ...
        datasample(1:100, n_practice_trials)'];
    trials   = [practice; trials];
    
    if sub.num < 10
        trlfname   = sprintf('sub-0%d_ses-%d_task-iforage-v%d_trls.tsv', sub.num, sub.sess, version);
        trgfname   = sprintf('sub-0%d_ses-%d_task-iforage-v%d_events.tsv', sub.num, sub.sess, version);
    else
        trlfname   = sprintf('sub-%d_ses-%d_task-iforage-v%d_trls.tsv', sub.num, sub.sess);
        trgfname   = sprintf('sub-%d_ses-%d_task-iforage-v%d_events.tsv', sub.num, sub.sess);
    end
    % define trial log file
    trlg_fid = fopen([sub_dir, '/beh/' trlfname], 'w');
    fprintf(trlg_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub','sess','t','cond','loc','prob','tgt');
    fprintf(trlg_fid, '%d\t%d\t%d\t%d\t%d\t%d\t%d\n', [repmat(sub.num, 1, length(trials(:,1)))', repmat(sub.sess, 1, length(trials(:,1)))', trials]');
    fclose(trlg_fid);
    
    % define triger log file
    trglg_fid = fopen([sub_dir, '/eeg/' trgfname], 'w');
    fprintf(trglg_fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\n', 'sub', 'sess', 't', 'cond', 'trig', 'event', 'onset');
    trg_form = '%d\t%d\t%d\t%d\t%d\t%s\t%.8f\n';
    
    if sub.num < 10
        sess_params_mat_name = sprintf('sub-%0d-ses-%d_task-iforage-v%d_sess-params', sub.num, sub.sess, version);
    else
        sess_params_mat_name = sprintf('sub-%d-ses-%d_task-iforage-v%d_sess-params', sub.num, sub.sess, version);
    end
    
    save(sess_params_mat_name, 'sub', 'trials', 'trg_form', 'beh_form', 'ntrials', 'cert_probs', 'uncert_probs', ...
                               'sub_loc_config', 'init_order', 'door_ps');
else % load previously defined parameter variables
    n_practice_trials = 5;

    if sub.num < 10
        sess_params_mat_name = sprintf('sub-%0d-ses-%d_task-iforage-v%d_sess-params', sub.num, sub.sess, version);
    else
        sess_params_mat_name = sprintf('sub-%d-ses-%d_task-iforage-v%d_sess-params', sub.num, sub.sess, version);
    end
    load(sess_params_mat_name);
    
    % now load files for appending to
        
    if sub.num < 10
        trgfname   = sprintf('sub-0%d_ses-%d_task-iforage-v%d_events.tsv', sub.num, sub.sess, version);
        behfname   = sprintf('sub-0%d_ses-%d_task-iforage-v%d_beh.tsv', sub.num, sub.sess, version);
    else
        trgfname   = sprintf('sub-%d_ses-%d_task-iforage-v%d_events.tsv', sub.num, sub.sess);
        behfname   = sprintf('sub-%d_ses-%d_task-iforage-v%d_beh.tsv', sub.num, sub.sess, version);
    end
    beh_fid   = fopen( [sub_dir, '/beh/' behfname], 'a');
    trglg_fid = fopen( [sub_dir, '/eeg/' trgfname], 'a');  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% define colours allotted to each condition
blue_world   = [51 153 255; 0 102 204; 153 204 255];
orange_world = [255 178 102; 204 102 0; 255 229 204]; 
prac_world   = [160 160 160; 96 96 96; 224 224 224];
if mod(sub.num, 2)
    world_colours = cat(3, blue_world, orange_world, prac_world);
else
    world_colours = cat(3, orange_world, blue_world, prac_world);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up eyetracker if using
% set up the screen environment values that the redM needs to know to initialize
envProfile.setupName = 'KG_test'; % a profile name, come back to this and test
envProfile.screenXmm = 530; % viewable screen width in mm
envProfile.screenYmm = 300; % viewable screen height in mm
envProfile.red2screenVmm = -2; % vertical distance that redM sensor is to the viewable screen
envProfile.red2screenHmm = 60; % horizontal distance that redM sensor is to the viewable screen
envProfile.red2screenAdeg = 20; % angle of inclination that the redM sensor is to the viewable screen surface

eye.numvalspercal = 1; % number of validatios that will be attempted before its decided that the calibration is crap
eye.validationaccuracy = 1; % maximum degrees of error for validation to be considered ok

mon.ID = 2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up eeg stuff
port_address = hex2dec('D050');
ioObj        = io32();
status       = io32(ioObj);
io32( ioObj, port_address, 0); % set port to off
% triggers % REMEMBER TO KEEP MATCHED WITH THE FUNCTION 'send_trigger.m'
% other triggers sent = 1 or 2 or 3 for trial start, cert or uncert or practice respectively
trgId.open    = 4;
trgId.close   = 5;
trgId.emr_cal = 6;
trgId.tgt_pse = [7, 8, 20]; % pause before tgt cert | uncert | practice
trgId.tgt_on  = [9, 10, 21]; % tgt onset cert | uncert | practice
trgId.all_doors_on = 11;
% breaks and get outs
breaks = 20; % how many trials inbetween breaks?
count_blocks = 0;
emr_cal = 0; % set the 'emergency calibration' marker to 0. Will be set to 1 if the experimentor hits 'x'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now we're ready to run through the experiment
if any(start_trial_num)
    run_init_setup = 1; % if starting from the last trial number from a previously terminated exp, then run initial things
end
for count_trials = (start_trial_num+1):length(trials(:,1))
    
    % is it the start of the block? and are we eyetracking? if so, start
    % the eyetracker, initiate a subject file and calibrate
    if count_trials == 1 | (~any(mod((count_trials-n_practice_trials)-1, breaks))) | count_trials == n_practice_trials+1 | any(run_init_setup)
        
        count_blocks = count_blocks + 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%% CLOSE PSYCHTOOLBOX THINGS
        Screen('CloseAll');
        
        % CALIBRATE AND VALIDATE SMI

        % initialise and connect
        REDm_info = SMI_Redm_Init(envProfile); % starts iviewX software server and initiates data structures.
        connected = SMI_Redm_ConnectEyetracker(REDm_info,'iViewXSDK_Matlab_GazeContingent_Demo.txt'); % log file does not contain data, defined elsewhere, this is just for some operational intel

        if connected
            % calibrate eyetracker
            cal_scale = 0.65; % multiplier to reduce the calibration area 
            REDm_info = SMI_Redm_SetGeometry(REDm_info);
            happy = 0; % happy will be = 1 when get a good calibration/validation
            
            while happy == 0
                
                xPix = 1680;
                yPix = 1050;
                SMI_Redm_CalibrateEyetracker(REDm_info,mon.ID,xPix,yPix,cal_scale); % monitor 2 = test room
                
                validationcount = 0; % number of attempts at having a happy validation
                
                while happy == 0 && validationcount <= eye.numvalspercal
                    
                    validationcount  = validationcount  + 1;
                    
                    % validate eyetracker for use
                    [REDm_info, accdata] = SMI_Redm_ValidateEyetracker(REDm_info);
                    
                    if max([accdata.deviationLX accdata.deviationRX accdata.deviationLY accdata.deviationRY]) < eye.validationaccuracy % in degrees (smaller the more accurate)
                        happy = 1;
                        disp('good validation')
                        accdata % print to screen just for kicks
                        
                    else
                        disp('bad validation')
                        cal_scale = 1;
                    end
                end
            end
        else
            
            disp('eyetracker not connected - not running task')
            keyboard;
        end
        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% SET UP PSYCHTOOLBOX THINGS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % set up screens and mex
        KbCheck;
        KbName('UnifyKeyNames');
        GetSecs;
        AssertOpenGL
        Screen('Preference', 'SkipSyncTests', 0);
        %PsychDebugWindowConfiguration;
        monitorXdim = 530; % in mm
        monitorYdim = 300; % in mm
%         eye_to_top = 600; % in mm
%         eye_to_bottom = 600; % in mm
%         ref_rate = 59;
        screens = Screen('Screens');
        %screenNumber = max(screens);
        screenNumber = 0;
        white = WhiteIndex(screenNumber);
        black = BlackIndex(screenNumber);
        back_grey = 200;
        [window, windowRect] = PsychImaging('OpenWindow', screenNumber, back_grey);
        ifi = Screen('GetFlipInterval', window);
        waitframes = 1;
        [screenXpixels, screenYpixels] = Screen('WindowSize', window);
        [xCenter, yCenter] = RectCenter(windowRect);
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        topPriorityLevel = MaxPriority(window);
        Priority(topPriorityLevel);
        
        % compute pixels for background rect
        pix_per_mm = screenYpixels/monitorYdim;
        %base_pix   = 200*pix_per_mm; % option 1
        %base_pix   = 180*pix_per_mm; % option 2
        display_scale = .65; % VARIABLE TO SCALE the display size
        base_pix   = 180*pix_per_mm*display_scale; % option 3
        backRect   = [0 0 base_pix base_pix];
        % and door pixels for door rects (which are defined in draw_doors.m
        nDoors     = 16;
        % doorPix    = 26.4*pix_per_mm; % may have to round this down % option 1
        %doorPix   = 20*pix_per_mm; % may have to round this down % option
        %2
        doorPix    = 26.4*pix_per_mm*display_scale; % option 3
        [doorRects, xPos, yPos]  = define_door_rects_v2(backRect, xCenter, yCenter, doorPix);
        % define arrays for later comparison
        xPos = repmat(xPos, 4, 1);
        yPos = repmat(yPos', 1, 4);
        r = abs((diff(xPos(1,[1 2]))/2)) * .95; % radius is 95% of half the distance between each door centre
        col = [176, 112, 218];
        
        % fixation
        %nFixLoc  = 9;
        fixPix   = 5*pix_per_mm*display_scale;
        fixBase  = [0, 0, fixPix, fixPix];
        %fixRects = CenterRectOnPointd(fixBase, xCenter-.5*fixPix, yCenter-.5*fixPix);
        fixRects = CenterRectOnPointd(fixBase, xCenter, yCenter);
        fixCol   = white;
        
        % timing
        time.ifi = Screen('GetFlipInterval', window);
        time.frames_per_sec = round(1/time.ifi);
        time.door_cycle_frames = time.frames_per_sec*.75; % rate at which door should oscillate when selected
        time.door_cycle_time = time.door_cycle_frames * time.ifi;
        time.tgt_on = .75;
        time.find_to_tgt = .4;
        time.fix_on = 1;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%% DONE SETTING UP PSYCHTOOLBOX THINGS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if count_trials == 1
            run_instructions(window, screenYpixels);
            KbWait;
            WaitSecs(1);
        end
        
        % start recording eyetracking data for the duration of this block
        SMI_Redm_StartRecordingData
        WaitSecs(1);
        SMI_Redm_SendMessage('start session')
        
        
        run_init_setup = 0; % don't run again
    end
    
    %%%%%%%% SEND TRIAL NUMBER TO SMI IF USING

    WaitSecs(0.1);
    SMI_Redm_SendMessage(sprintf('StartTrial_number_%d', count_trials));
    WaitSecs(0.1);
    HideCursor;

    %%%%%%% trial start settings
    % set tgt flag as unfound
    tgt_flag = 0;
    idxs = 0; % refresh 'door selected' idx
    % assign tgt loc and onset time
    tgt_loc = trials(count_trials, 3);
    tgt_flag = tgt_loc;
    % set colours according to condition
    col = world_colours(1, :, trials(count_trials, 2)); % background colours
    doors_closed_cols = repmat(world_colours(2, :, trials(count_trials, 2))', 1, nDoors); % door colours
    door_open_col = world_colours(3, :, trials(count_trials, 2)); % door colours
    
    % initial fixation
    draw_background(window, backRect, xCenter, yCenter, back_grey);
    %     fix_idx = randperm(nFixLoc, 1);
    tmpfixRect = fixRects;
    maxFixDiam = max(tmpfixRect) * 1.01;
    Screen('FillOval', window, fixCol, tmpfixRect, maxFixDiam);
    start_fix = Screen('Flip',window);
    pre_fix_sample = 100; % sample for 1000 msec min
    pre_fix_thresh = 50; % eyes in place for 500 msec
    % use eyes to start trial
    tflag = 0;
    emr_cal = 0;
    while ~any(tflag)
        [tflag, ~, emr_cal] = check_fix_to_start_trial(REDm_info, xCenter, yCenter, r, count_trials, pre_fix_sample, pre_fix_thresh, tflag, emr_cal);
        if emr_cal == 1
            start_cal = GetSecs;
            send_trigger(trgId.emr_cal, sub.num, sub.sess, count_trials, trials(count_trials,2), start_cal, ioObj, port_address, trglg_fid, trg_form);
            [emr_cal, window, windowRect, screenXpixels, screenYpixels, xCenter, yCenter] = emergency_calibration(REDm_info, mon.ID, xPix, yPix, cal_scale, screenNumber, black, eye);
        
            draw_background(window, backRect, xCenter, yCenter, black);
            %     fix_idx = randperm(nFixLoc, 1);
            tmpfixRect = fixRects;
            maxFixDiam = max(tmpfixRect) * 1.01;
            Screen('FillOval', window, fixCol, tmpfixRect, maxFixDiam);
            start_fix = Screen('Flip',window);
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% run trial
    %start = Screen('Flip', window); % will save this output
    tgt_found = 0;
    % initial onset and fixation
    draw_background(window, backRect, xCenter, yCenter, col);
    Screen('FillOval', window, fixCol, tmpfixRect, maxFixDiam);
    trial_start = Screen('Flip', window);
    send_trigger(trials(count_trials, 2), sub.num, sub.sess, count_trials, trials(count_trials,2), trial_start, ioObj, port_address, trglg_fid, trg_form);
    trial_start_sample = 120; % sample foR 600 msec min
    trial_start_thresh = 100; % eyes in place for 500 msec
    % use eyes to start trial
    tflag   = 0;
    emr_cal = 0;
    while ~any(tflag)
        [tflag, ~, emr_cal] = check_fix_to_start_trial(REDm_info, xCenter, yCenter, r, count_trials, trial_start_sample, trial_start_thresh, tflag, emr_cal);
        if emr_cal == 1
            start_cal = GetSecs;
            send_trigger(trgId.emr_cal, sub.num, sub.sess, count_trials, trials(count_trials,2), start_cal, ioObj, port_address, trglg_fid, trg_form);
            [emr_cal, window, windowRect, screenXpixels, screenYpixels, xCenter, yCenter] = emergency_calibration(REDm_info, mon.ID, xPix, yPix, cal_scale, screenNumber, black, eye);
       
            draw_background(window, backRect, xCenter, yCenter, col);
            Screen('FillOval', window, fixCol, tmpfixRect, maxFixDiam);
            trial_start = Screen('Flip', window);
        end
    end
    
    % draw doors and start
    draw_background(window, backRect, xCenter, yCenter, col);
    draw_doors(window, doorRects, doors_closed_cols);
    Screen('FillOval', window, fixCol, tmpfixRect, maxFixDiam);
    trial_start = Screen('Flip', window);
    send_trigger(trgId.all_doors_on, sub.num, sub.sess, count_trials, trials(count_trials,2), trial_start, ioObj, port_address, trglg_fid, trg_form);
    
    while ~any(tgt_found)


        door_on_flag = 0; % poll until a door has been selected
        while ~any(door_on_flag)
            startTime = GetSecs; % write this to the trial log and the trigger log
            [emr_cal, didx, startTime, door_on_flag] = do_doors_for_no_eye_gaze_v3(doors_closed_cols, window, backRect, xCenter, yCenter, ...
                col, doorRects, REDm_info, trial_start, beh_fid, beh_form, sub.num, sub.sess, count_trials, trials(count_trials,2), ...
                tgt_flag, startTime, xPos, yPos, r, fixCol, tmpfixRect, maxFixDiam, door_ps(trials(count_trials,2), :), emr_cal, trgId.close, ioObj, port_address, trglg_fid, trg_form);
            % emergency calibration?
            if emr_cal == 1
                start_cal = GetSecs;
                send_trigger(trgId.emr_cal, sub.num, sub.sess, count_trials, trials(count_trials,2), start_cal, ioObj, port_address, trglg_fid, trg_form);
                [emr_cal, window, windowRect, screenXpixels, screenYpixels, xCenter, yCenter] = emergency_calibration(REDm_info, mon.ID, xPix, yPix, cal_scale, screenNumber, black, eye);
            end
        end
        
        % door has been selected, so open it
        while any(door_on_flag)
            [emr_cal, tgt_found, didx, startTime, door_on_flag] = eye_door_open_v4(REDm_info, trial_start, startTime, sub.num, sub.sess, ...
                count_trials, trials(count_trials,2), door_ps(trials(count_trials,2), :), tgt_flag, window, ...
                backRect, xCenter, yCenter, col, ...
                doorRects, doors_closed_cols, door_open_col,...
                didx, beh_fid, beh_form, xPos, yPos, r, fixCol, tmpfixRect, maxFixDiam, emr_cal, trgId.open, ioObj, port_address, trglg_fid, trg_form);
            % emergency calibration?
            if emr_cal == 1
                start_cal = GetSecs;
                send_trigger(trgId.emr_cal, sub.num, sub.sess, count_trials, trials(count_trials,2), start_cal, ioObj, port_address, trglg_fid, trg_form);                
                [emr_cal, window, windowRect, screenXpixels, screenYpixels, xCenter, yCenter] = emergency_calibration(REDm_info, mon.ID, xPix, yPix, cal_scale, screenNumber, black, eye);
            end
        end
    end
    
    %WaitSecs(time.find_to_tgt);
    draw_target_v2(window, backRect, col, doorRects, doors_closed_cols, door_open_col, didx, trials(count_trials,5), xCenter, yCenter, time.door_cycle_time, fixCol, tmpfixRect, maxFixDiam, ...
                   trials(count_trials,2), [trgId.tgt_pse; trgId.tgt_on], sub.num, sub.sess, count_trials, ioObj, port_address, trglg_fid, trg_form);
    WaitSecs(time.tgt_on);
    
    if count_trials == n_practice_trials
        
        end_practice(window, screenYpixels);
        KbWait;
        WaitSecs(1);
    end
    
    
    if any(mod(count_trials-n_practice_trials, breaks))
    else
        if count_trials == n_practice_trials
        else
            take_a_break(window, count_trials-n_practice_trials, ntrials*2, breaks, backRect, xCenter, yCenter, screenYpixels);
            KbWait;
        end
        WaitSecs(1);

            % close eyelink file
            SMI_Redm_SendMessage('stop session')
            WaitSecs(0.5);
            eye_fname = sprintf('sub%d_sess%d_block%d', sub.num, sub.sess, count_blocks);
            SMI_Redm_StopRecordingSaveData([sub_dir, '/eyetrack/' eye_fname], 'DL');
    end
    
end

sca;
Priority(0);
Screen('CloseAll');
ShowCursor
SMI_Redm_DisconnectEyetracker
SMI_Redm_Shutdown
