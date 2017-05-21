function create()

%   CREATE -- Create the config file.
%
%     Define constants and initial settings to be passed to 
%     brains.task.setup()
%
%     OUT:
%       - `opts` (struct) -- Complete options.

% - IO - %
IO.repo_folder =    get_repo_dir();
IO.edf_file =       'tstx.edf';
IO.data_file =      'tstx.mat';
IO.edf_folder =     fullfile( IO.repo_folder, 'brains', 'data' );
IO.data_folder =    fullfile( IO.repo_folder, 'brains', 'data' );
IO.stimuli_path =   fullfile( IO.repo_folder, 'brains', 'stimuli' );

% - INTERFACE - %
KbName( 'UnifyKeyNames' );
INTERFACE.save_data = false;
INTERFACE.allow_overwrite = true;
INTERFACE.use_eyelink = false;
INTERFACE.use_arduino = false;
INTERFACE.require_synch = false;
INTERFACE.rwd_key = KbName( 'r' );
INTERFACE.stop_key = KbName( 'escape' );
INTERFACE.is_master_arduino = true;
INTERFACE.is_master_monkey = true;
INTERFACE.gui_fields.exclude = { 'rwd_key', 'stop_key' };

% - META - %
META.m1 = '';
META.m2 = '';
META.date = '';
META.etc = '';

% - SCREEN - %
sz = get( 0, 'screensize' );
SCREEN.full_size = sz;
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
SCREEN.rect.M1 = [ 0, 0, sz(3)/2, sz(4)/2 ];
SCREEN.rect.M2 = [ 0, 0, sz(3)/2, sz(4)/2 ];
% SCREEN.rect = [ 0 0, 1024*3, 768 ];

% - STRUCTURE - %
STRUCTURE.is_master_monkey = INTERFACE.is_master_monkey;
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

% - COMMUNICATORS - %

% - Serial
SERIAL.messages.shared = { ...
  struct('message', 'SYNCHRONIZE', 'char', 'S'), ...
  struct('message', 'PRINT_GAZE', 'char', 'P'), ...
  struct('message', 'COMPARE_STATES', 'char', 'W' ), ...
  struct('message', 'COMPARE_GAZE', 'char', 'L') ...
  struct('message', 'COMPARE_FIX_MET', 'char', 'w') ...
  struct('message', 'GET_CHOICE', 'char', '?' ) ...
};
SERIAL.messages.M1 = { ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'B'), ...
  };
SERIAL.ports.M1 = 'COM4';
SERIAL.ports.M2 = 'COM3';
SERIAL.baud_rate = 115200;

% - TCP
TCP.server_address = '0.0.0.0';
TCP.client_address = '127.0.0.1';
TCP.port = 55000;

% - ROIS - %
ROIS.eyes = [ 0, 0, 500, 500 ];
ROIS.mouth = [ 0, 0, 500, 500 ];

% - STIMULI - %
non_editable_properties = { 'class' };
STIMULI.fixation = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 150, 150 ] ...
  , 'color',            [ 96, 110, 132 ] ...
  , 'placement',        'center' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.fixation ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.rule_cue_gaze = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 250, 250 ] ...
  , 'color',            [ 151, 17, 178 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.rule_cue_laser = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 250, 250 ] ...
  , 'color',            [ 178, 17, 57 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.gaze_cue_correct = struct( ...
    'class',            'Image' ...
  , 'image_file',       fullfile( 'm2', '1.png' ) ...
  , 'size',             [ 300, 300 ] ...
  , 'color',            [ 50, 150, 57 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.gaze_cue_correct ...
  , 'target_padding',   100 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.gaze_cue_incorrect = struct( ...
    'class',            'Image' ...
  , 'image_file',       fullfile( 'm2', '2.png' ) ...
  , 'size',             [ 300, 300 ] ...
  , 'color',            [ 178, 17, 20 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.gaze_cue_incorrect ...
  , 'target_padding',   100 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.response_target1 = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 250, 250 ] ...
  , 'color',            [ 17, 41, 178 ] ...
  , 'placement',        'center-left' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.response_target1 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

STIMULI.response_target2 = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 250, 250 ] ...
  , 'color',            [ 178, 178, 17 ] ...
  , 'placement',        'center-right' ...
  , 'has_target',       true ...
  , 'target_duration',  fixations.response_target1 ...
  , 'target_padding',   0 ...
  , 'non_editable',     non_editable_properties ...
);

% - REWARDS - %
REWARDS.main = 250; % ms
REWARDS.pulse_frequency = .5;
REWARDS.last_reward_size = []; % ms

%   export as one struct
opts = struct();
opts.IO =             IO;
opts.INTERFACE =      INTERFACE;
opts.META =           META;
opts.SCREEN =         SCREEN;
opts.TIMINGS =        TIMINGS;
opts.STRUCTURE =      STRUCTURE;
opts.STATES =         STATES;
opts.SERIAL =         SERIAL;
opts.TCP =            TCP;
opts.ROIS =           ROIS;
opts.STIMULI =        STIMULI;
opts.REWARDS =        REWARDS;

brains.config.save( opts );

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

% SCREEN.rect = [];

% sz = get( 0, 'screensize' );
% if ( INTERFACE.is_master_monkey )
%   SCREEN.rect = [ 0, 0, sz(3)/2, sz(4) ];
%   SCREEN.rect = [ 0, 0, sz(3)/2, sz(4)/2 ];
% else
%   SCREEN.rect = [ 0, 0, sz(3)/2, sz(4)/2 ];
%   SCREEN.rect = [ 0, sz(4)/2, sz(3)/2, sz(4) ];
%   SCREEN.rect = [ sz(3)/2, 0, sz(3), sz(4) ];
% end


% STIMULI.fixation = Rectangle( WINDOW.index, WINDOW.rect, [150, 150] );
% STIMULI.fixation.color = [96, 110, 132];
% STIMULI.fixation.put( 'center' );
% %   set up gaze targets
% STIMULI.fixation.make_target( TRACKER, fixations.fixation );
% 
% STIMULI.rule_cue_gaze = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
% STIMULI.rule_cue_gaze.color = [151, 17, 178];
% STIMULI.rule_cue_gaze.put( 'center' );
% 
% STIMULI.rule_cue_laser = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
% STIMULI.rule_cue_laser.color = [178, 17, 57];
% STIMULI.rule_cue_laser.put( 'center' );
% 
% STIMULI.gaze_cue_correct = Image( WINDOW.index, WINDOW.rect, [300, 300], image_files{1} );
% STIMULI.gaze_cue_correct.color = [50, 150, 57];
% STIMULI.gaze_cue_correct.put( 'center-left' );
% 
% STIMULI.gaze_cue_incorrect = Image( WINDOW.index, WINDOW.rect, [300, 300], image_files{2} );
% STIMULI.gaze_cue_incorrect.color = [178, 17, 20];
% STIMULI.gaze_cue_incorrect.put( 'center-right' );
% %   set up gaze targets
% STIMULI.gaze_cue_correct.make_target( TRACKER, fixations.gaze_cue_correct );
% STIMULI.gaze_cue_incorrect.make_target( TRACKER, fixations.gaze_cue_incorrect );
% STIMULI.gaze_cue_correct.targets{1}.padding = 0;
% STIMULI.gaze_cue_incorrect.targets{1}.padding = 0;