function opts = setup( opts )

%   SETUP -- Define constants and initial settings.
%
%     IN:
%       - `opts` (struct) -- Global interface options to override the
%         defaults below. Pass in an empty struct to avoid the override.
%
%     OUT:
%       - `opts` (struct) -- Complete options 

import brains.util.assert__file_does_not_exist;

PsychDefaultSetup( 1 );
ListenChar();

% - IO - %
IO.repo_folder =    get_repo_dir();
IO.edf_file =       'tstx.edf';
IO.data_file =      'tstx.mat';
IO.edf_folder =     fullfile( IO.repo_folder, 'brains', 'data' );
IO.data_folder =    fullfile( IO.repo_folder, 'brains', 'data' );
IO.stimuli_path =   fullfile( IO.repo_folder, 'brains', 'stimuli', 'm2' );

addpath( genpath(fullfile(IO.repo_folder, 'ptb_helpers')) );
addpath( genpath(fullfile(IO.repo_folder, 'arduino', 'communicator')) );

% assert__file_does_not_exist( fullfile(IO.data_folder, IO.data_file) );

% - INTERFACE - %
INTERFACE.save_data = false;
INTERFACE.use_eyelink = false;
INTERFACE.use_arduino = false;
INTERFACE.require_synch = false;
INTERFACE.rwd_key = KbName( 'r' );
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.is_master_arduino = true;
INTERFACE.is_master_monkey = true;

opt_fields = fieldnames( opts );
for i = 1:numel(opt_fields)
  INTERFACE.(opt_fields{i}) = opts.(opt_fields{i});
end

% - META - %
META.m1 = '';
META.m2 = '';
META.date = '';
META.etc = '';

% - SCREEN - %
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
% SCREEN.rect = [ 0 0, 1024*3, 768 ];
% SCREEN.rect = [];

sz = get( 0, 'screensize' );
if ( INTERFACE.is_master_monkey )
%   SCREEN.rect = [ 0, 0, sz(3)/2, sz(4) ];
  SCREEN.rect = [ 0, 0, sz(3)/2, sz(4)/2 ];
else
  SCREEN.rect = [ 0, 0, sz(3)/2, sz(4)/2 ];
%   SCREEN.rect = [ 0, sz(4)/2, sz(3)/2, sz(4) ];
%   SCREEN.rect = [ sz(3)/2, 0, sz(3), sz(4) ];
end

% - WINDOW - %
WINDOW.index = [];
WINDOW.width = [];
WINDOW.height = [];
WINDOW.rect = [];
WINDOW.center = [];

%   open windows
[windex, wrect] = Screen( 'OpenWindow', SCREEN.index, SCREEN.background_color, SCREEN.rect );
WINDOW.center = round( [mean(wrect([1 3])), mean(wrect([2 4]))] );
WINDOW.index = windex;
WINDOW.rect = wrect;

% - TRACKER - %
TRACKER = EyeTracker( IO.edf_file, IO.edf_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;
success = TRACKER.init();
assert( success, 'Eyelink initialization failed.' );

% - STRUCTURE - %
STRUCTURE.is_master_monkey = INTERFACE.is_master_monkey;
STRUCTURE.correct_choice = [];
STRUCTURE.did_choose = [];
STRUCTURE.rule_cue_type = 'gaze';

% - STATES - %
state_sequence = { 'new_trial', 'fixation', 'rule_cue', 'post_rule_cue' ...
  , 'use_rule', 'evaluate_choice', 'iti' };
for i = 0:numel(state_sequence)-1
  STATES.(state_sequence{i+1}) = i;
end
STATES.current = [];
STATES.sequence = state_sequence;

% - TIMINGS - %
fixations.fixation = .3;
fixations.left_rule_cue = .2;
fixations.right_rule_cue = .2;
fixations.response_target1 = .2;
fixations.response_target2 = .2;
fixations.gaze_cue_correct = .2;
fixations.gaze_cue_incorrect = .2;

time_in.task = Inf;
time_in.fixation = Inf;
time_in.rule_cue = 1;
time_in.post_rule_cue = 6;
time_in.use_rule = 2;
time_in.evaluate_choice = 0;
time_in.iti = 1;
time_in.debounce_arduino_messages = .1;

TIMINGS.fixations = fixations;
TIMINGS.time_in = time_in;
TIMINGS.synch_timeout = 10;

TIMER = Timer();
TIMER.register( time_in );

% - COMMUNICATOR - %
shared_messages = { ...
  struct('message', 'SYNCHRONIZE', 'char', 'S'), ...
  struct('message', 'PRINT_GAZE', 'char', 'P'), ...
  struct('message', 'COMPARE_STATES', 'char', 'W' ), ...
  struct('message', 'COMPARE_GAZE', 'char', 'L') ...
  struct('message', 'COMPARE_FIX_MET', 'char', 'w') ...
  struct('message', 'GET_CHOICE', 'char', '?' ) ...
};
if ( INTERFACE.is_master_arduino )
  master_messages = { ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'B'), ...
  };
  messages = [ shared_messages, master_messages ];
  serial_port = 'COM4';
else
  slave_messages = { ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'N'), ...
  };
  messages = [ shared_messages, slave_messages ];
  serial_port = 'COM3';
end
baud_rate = 115200;
if ( INTERFACE.use_arduino )
  COMMUNICATORS.serial_comm = Communicator( messages, serial_port, baud_rate );
else COMMUNICATORS.serial_comm = [];
end

if ( INTERFACE.is_master_monkey )
  others_address = '0.0.0.0';
  tcp_comm_constructor = @brains.server.Server;
else
  others_address = '127.0.0.1';
  tcp_comm_constructor = @brains.server.Client;
end
tcp_port = 55e3;
tcp_comm = tcp_comm_constructor( others_address, tcp_port );
tcp_comm.bypass = ~INTERFACE.require_synch;
tcp_comm.start();

COMMUNICATORS.tcp_comm = tcp_comm;

% - ROIS - %
ROIS.eyes = Target( TRACKER, [0 0 500 500], Inf );
ROIS.mouth = Target( TRACKER, [0 0 500 500], Inf );

% - STIMULI - %
image_files = dir( IO.stimuli_path );
image_files = { image_files(:).name };
image_files = image_files( cellfun(@(x) ~isempty(strfind(x, '.png')), image_files) );
image_files = cellfun( @(x) fullfile(IO.stimuli_path, x), image_files, 'un', false );
image_files = cellfun( @(x) imread(x), image_files, 'un', false );

STIMULI.fixation = Rectangle( WINDOW.index, WINDOW.rect, [150, 150] );
STIMULI.fixation.color = [96, 110, 132];
STIMULI.fixation.put( 'center' );
%   set up gaze targets
STIMULI.fixation.make_target( TRACKER, fixations.fixation );

STIMULI.rule_cue_gaze = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.rule_cue_gaze.color = [151, 17, 178];
STIMULI.rule_cue_gaze.put( 'center' );

STIMULI.rule_cue_laser = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.rule_cue_laser.color = [178, 17, 57];
STIMULI.rule_cue_laser.put( 'center' );

STIMULI.gaze_cue_correct = Image( WINDOW.index, WINDOW.rect, [300, 300], image_files{1} );
STIMULI.gaze_cue_correct.color = [50, 150, 57];
STIMULI.gaze_cue_correct.put( 'center-left' );

STIMULI.gaze_cue_incorrect = Image( WINDOW.index, WINDOW.rect, [300, 300], image_files{2} );
STIMULI.gaze_cue_incorrect.color = [178, 17, 20];
STIMULI.gaze_cue_incorrect.put( 'center-right' );
%   set up gaze targets
STIMULI.gaze_cue_correct.make_target( TRACKER, fixations.gaze_cue_correct );
STIMULI.gaze_cue_incorrect.make_target( TRACKER, fixations.gaze_cue_incorrect );
STIMULI.gaze_cue_correct.targets{1}.padding = 0;
STIMULI.gaze_cue_incorrect.targets{1}.padding = 0;

STIMULI.response_target1 = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.response_target1.color = [17, 41, 178];
STIMULI.response_target1.put( 'center-left' );

STIMULI.response_target2 = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.response_target2.color = [178, 178, 17];
STIMULI.response_target2.put( 'center-right' );
%   set up gaze targets
STIMULI.response_target1.make_target( TRACKER, fixations.response_target1 );
STIMULI.response_target2.make_target( TRACKER, fixations.response_target2 );

% - REWARDS - %
REWARDS.main = 250; % ms
REWARDS.pulse_frequency = .5;
REWARDS.last_reward_size = []; % ms

%   output as one struct
opts = struct();
opts.IO =             IO;
opts.INTERFACE =      INTERFACE;
opts.META =           META;
opts.SCREEN =         SCREEN;
opts.WINDOW =         WINDOW;
opts.TIMINGS =        TIMINGS;
opts.TIMER =          TIMER;
opts.STRUCTURE =      STRUCTURE;
opts.STATES =         STATES;
opts.COMMUNICATORS =  COMMUNICATORS;
opts.ROIS =           ROIS;
opts.STIMULI =        STIMULI;
opts.REWARDS =        REWARDS;
opts.TRACKER =        TRACKER;

end

function repo_dir = get_repo_dir()

%   GET_REPO_DIR -- Get the repositories directory in which the brains
%     package resides.
%
%     OUT:
%       - `repo_dir` (char)

if ( ispc() )
  slash = '\';
else slash = '/';
end

file_parts = strsplit( which('brains.task.setup'), slash );
brains_ind = strcmp( file_parts, 'brains' );
assert( any(brains_ind), 'Expected this function to reside in %s' ...
  , strjoin({'brains', '+brains', '+task'}, slash) );
repo_ind = find(brains_ind) - 1;
repo_dir = strjoin( file_parts(1:repo_ind), slash );

end