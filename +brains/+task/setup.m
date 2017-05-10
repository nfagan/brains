function opts = setup( is_master_arduino, is_master_monkey )

%   SETUP -- Define constants and initial settings.
%
%   OUT:
%     - `opts` (struct)

addpath( genpath('C:\Repositories\ptb_helpers') );

PsychDefaultSetup( 1 );
ListenChar( 2 );

% - IO - %
IO.edf_filename = 'tstx.edf';
IO.save_folder = cd;

% - SCREEN - %
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
% SCREEN.rect = [ 0 0, 1024*2, 768 ];
SCREEN.rect = [];

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

% - INTERFACE - %
INTERFACE.use_mouse = true;
INTERFACE.use_eyelink = false;
INTERFACE.use_arduino = true;
INTERFACE.require_synch = true;
INTERFACE.stop_key = 'space';
INTERFACE.is_master_arduino = is_master_arduino;

% - TRACKER - %
TRACKER = EyeTracker( IO.edf_filename, IO.save_folder, WINDOW.index );
TRACKER.bypass = ~INTERFACE.use_eyelink;
success = TRACKER.init();
assert( success, 'Eyelink initialization failed.' );

% - STRUCTURE - %
STRUCTURE.is_master_monkey = is_master_monkey;
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
fixations.fixation.duration = 3;
fixations.left_rule_cue.duration = 2;
fixations.right_rule_cue.duration = 2;
fixations.response_target1.duration = 1;
fixations.response_target2.duration = 1;
fixations.gaze_cue_correct.duration = 3;
fixations.gaze_cue_incorrect.duration = 3;

time_in.task = Inf;
time_in.fixation = Inf;
time_in.rule_cue = 2;
time_in.post_rule_cue = 5;
time_in.use_rule = 2;
time_in.evaluate_choice = 0;
time_in.iti = 2;
time_in.debounce_arduino_messages = .08;

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
if ( is_master_arduino )
  master_messages = { ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'B'), ...
  };
  messages = [ shared_messages, master_messages ];
  port = 'COM4';
else
  slave_messages = { ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'N'), ...
  };
  messages = [ shared_messages, slave_messages ];
  port = 'COM3';
end
baud_rate = 115200;
if ( INTERFACE.use_arduino )
  COMMUNICATOR = Communicator( messages, port, baud_rate );
else COMMUNICATOR = [];
end

% - ROIS - %
ROIS.eyes = Target( TRACKER, [0 0 500 500], Inf );
ROIS.mouth = Target( TRACKER, [0 0 500 500], Inf );

% - STIMULI - %
stim_path = 'C:\Repositories\brains\stimuli\m2';
image_files = dir( stim_path );
image_files = { image_files(:).name };
image_files = image_files( cellfun(@(x) ~isempty(strfind(x, '.png')), image_files) );
image_files = cellfun( @(x) fullfile(stim_path, x), image_files, 'un', false );
image_files = cellfun( @(x) imread(x), image_files, 'un', false );

STIMULI.fixation = Rectangle( WINDOW.index, WINDOW.rect, [150, 150] );
STIMULI.fixation.color = [96, 110, 132];
STIMULI.fixation.put( 'center' );
%   set up gaze targets
STIMULI.fixation.make_target( TRACKER, fixations.fixation.duration );

STIMULI.rule_cue_gaze = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.rule_cue_gaze.color = [151, 17, 178];
STIMULI.rule_cue_gaze.put( 'center' );

STIMULI.rule_cue_laser = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.rule_cue_laser.color = [178, 17, 57];
STIMULI.rule_cue_laser.put( 'center' );

STIMULI.gaze_cue_correct = Image( WINDOW.index, WINDOW.rect, [250, 250], image_files{1} );
STIMULI.gaze_cue_correct.color = [50, 150, 57];
STIMULI.gaze_cue_correct.put( 'center-left' );

STIMULI.gaze_cue_incorrect = Image( WINDOW.index, WINDOW.rect, [250, 250], image_files{2} );
STIMULI.gaze_cue_incorrect.color = [178, 17, 20];
STIMULI.gaze_cue_incorrect.put( 'center-right' );
%   set up gaze targets
STIMULI.gaze_cue_correct.make_target( TRACKER, fixations.gaze_cue_correct.duration );
STIMULI.gaze_cue_incorrect.make_target( TRACKER, fixations.gaze_cue_incorrect.duration );

STIMULI.response_target1 = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.response_target1.color = [17, 41, 178];
STIMULI.response_target1.put( 'center-left' );

STIMULI.response_target2 = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.response_target2.color = [178, 178, 17];
STIMULI.response_target2.put( 'center-right' );
%   set up gaze targets
STIMULI.response_target1.make_target( TRACKER, fixations.response_target1.duration );
STIMULI.response_target2.make_target( TRACKER, fixations.response_target2.duration );

% - REWARDS - %
REWARDS.main = 100; % ms
REWARDS.pulse_frequency = .5;
REWARDS.last_reward_size = []; % ms

%   output as one struct

opts.IO =           IO;
opts.SCREEN =       SCREEN;
opts.INTERFACE =    INTERFACE;
opts.WINDOW =       WINDOW;
opts.TIMINGS =      TIMINGS;
opts.TIMER =        TIMER;
opts.STRUCTURE =    STRUCTURE;
opts.STATES =       STATES;
opts.COMMUNICATOR = COMMUNICATOR;
opts.ROIS =         ROIS;
opts.STIMULI =      STIMULI;
opts.REWARDS =      REWARDS;
opts.TRACKER =      TRACKER;

end