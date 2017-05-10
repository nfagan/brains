function err = brains(is_master_arduino, is_master_monkey)

%   BRAINS -- Configure and run the brains task.
%
%     IN:
%       - `is_master_arduino` (true, false) -- Specify whether the current
%         computer is connected to the master or slave arduino
%       - `is_master_monkey` (true, false) -- Specify whether the current
%         computer will begin in the master or slave 

try
  opts = setup( is_master_arduino, is_master_monkey );
catch err
  sca;
  ListenChar( 0 );
  close_ports();
  print_error_stack( err );
  Eyelink( 'StopRecording' );
  return;
end

try
  run( opts );
  err = 0;
catch err
  cleanup( opts );
  commandwindow;
  print_error_stack( err );
end

end

function opts = setup( is_master_arduino, is_master_monkey )

%   SETUP -- Define constants and initial settings.
%
%   OUT:
%     - `opts` (struct)

addpath( fullfile(fileparts(which(mfilename)), 'helpers') );
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
INTERFACE.require_synch = false;
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
TIMINGS.do_reset = true;

for i = 1:numel(state_sequence)
  TIMINGS.timer_ids.(state_sequence{i}) = [];
end
TIMINGS.timer_ids.main = [];  % id of main timer
TIMINGS.timer_ids.last_arduino_message = [];

TIMINGS.fixations.fixation.duration = 3;
TIMINGS.fixations.left_rule_cue.duration = 2;
TIMINGS.fixations.right_rule_cue.duration = 2;
TIMINGS.fixations.response_target_left.duration = 1;
TIMINGS.fixations.response_target_right.duration = 1;
TIMINGS.fixations.gaze_cue_correct.duration = 3;
TIMINGS.fixations.gaze_cue_incorrect.duration = 3;

TIMINGS.start = 0;
TIMINGS.last_frame = 0;
TIMINGS.total_time = Inf; % total experiment time.
TIMINGS.synchronization_timeout = 5;  % seconds before synchronization is deemed unsuccessful.

TIMINGS.time_in.fixation = Inf;
TIMINGS.time_in.rule_cue = 2;
TIMINGS.time_in.post_rule_cue = 5;
TIMINGS.time_in.use_rule = 1;
TIMINGS.time_in.evaluate_choice = 1;
TIMINGS.time_in.iti = 2;

TIMINGS.debounce_arduino_messages = .001;  % seconds before a new message can be sent to the arduino.

% - COMMUNICATOR - %
if ( is_master_arduino )
  messages = { ...
    struct('message', 'SYNCHRONIZE', 'char', 'S'), ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'B'), ...
    struct('message', 'PRINT_GAZE', 'char', 'P'), ...
    struct('message', 'COMPARE_STATES', 'char', 'W' ), ...
    struct('message', 'COMPARE_GAZE', 'char', 'L') ...
  };
  port = 'COM4';
else
  messages = { ...
    struct('message', 'SYNCHRONIZE', 'char', 'S'), ...
    struct('message', 'REWARD1', 'char', 'A'), ...
    struct('message', 'REWARD2', 'char', 'N'), ...
    struct('message', 'PRINT_GAZE', 'char', 'P'), ...
    struct('message', 'COMPARE_STATES', 'char', 'W' ), ...
    struct('message', 'COMPARE_GAZE', 'char', 'L') ...
  };
  port = 'COM3';
end
baud_rate = 115200;
if ( INTERFACE.use_arduino )
  COMMUNICATOR = Communicator( messages, port, baud_rate );
else COMMUNICATOR = [];
end

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
STIMULI.fixation.make_target( TRACKER, TIMINGS.fixations.fixation.duration );

STIMULI.rule_cue_gaze_left = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.rule_cue_gaze_left.color = [151, 17, 178];
STIMULI.rule_cue_gaze_left.put( 'center-left' );

STIMULI.rule_cue_gaze_right = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.rule_cue_gaze_right.color = [178, 17, 57];
STIMULI.rule_cue_gaze_right.put( 'center-right' );

STIMULI.gaze_cue_correct = Image( WINDOW.index, WINDOW.rect, [250, 250], image_files{1} );
STIMULI.gaze_cue_correct.color = [50, 150, 57];
STIMULI.gaze_cue_correct.put( 'center-left' );

STIMULI.gaze_cue_incorrect = Image( WINDOW.index, WINDOW.rect, [250, 250], image_files{2} );
STIMULI.gaze_cue_incorrect.color = [178, 17, 20];
STIMULI.gaze_cue_incorrect.put( 'center-right' );
%   set up gaze targets
STIMULI.gaze_cue_correct.make_target( TRACKER, TIMINGS.fixations.gaze_cue_correct.duration );
STIMULI.gaze_cue_incorrect.make_target( TRACKER, TIMINGS.fixations.gaze_cue_incorrect.duration );

STIMULI.response_target_left = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.response_target_left.color = [17, 41, 178];
STIMULI.response_target_left.put( 'center-left' );

STIMULI.response_target_right = Rectangle( WINDOW.index, WINDOW.rect, [250, 250] );
STIMULI.response_target_right.color = [178, 178, 17];
STIMULI.response_target_right.put( 'center-right' );
%   set up gaze targets
STIMULI.response_target_left.make_target( TRACKER, TIMINGS.fixations.response_target_left.duration );
STIMULI.response_target_right.make_target( TRACKER, TIMINGS.fixations.response_target_right.duration );

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
opts.STRUCTURE =    STRUCTURE;
opts.STATES =       STATES;
opts.COMMUNICATOR = COMMUNICATOR;
opts.STIMULI =      STIMULI;
opts.REWARDS =      REWARDS;
opts.TRACKER =      TRACKER;

end

function run(opts)

%   RUN -- Run the task.
%
%   IN:
%     - `opts` (struct) -- Options as generated by `setup()`.

%   reset arduino
opts = reset_arduino( opts );

%   define starting state
opts.STATES.current = opts.STATES.new_trial;

%   add cumulative field to TIMINGS.fixations
fs = fieldnames( opts.TIMINGS.fixations );
for i = 1:numel(fs)
  opts.TIMINGS.fixations.(fs{i}).cumulative = 0;
end

%   start timing
timer_ids = fieldnames( opts.TIMINGS.timer_ids );
for i = 1:numel(timer_ids)
  opts = reset_timer( opts, timer_ids{i} );
end
opts.TIMINGS.start = get_time( opts, 'main' );
opts.TIMINGS.last_frame = opts.TIMINGS.start;

%   main loop
while ( true )
  
  %   STATE NEW_TRIAL
  if ( opts.STATES.current == opts.STATES.new_trial )
%     opts = await_matching_state( opts );
    clear_screen( opts );
    opts.TIMINGS.last_frame = get_time( opts, 'main' );
    %   get correct choice
    opts.STRUCTURE.correct_choice = 1;
    %   get type of cue for this trial
    %   MARK: goto: fixation
    opts.STATES.current = opts.STATES.fixation;
    opts = debounce_arduino( opts, @set_state, opts.STATES.current );
    opts.TIMINGS.do_reset = true;
  end
  
  %   STATE FIXATION
  if ( opts.STATES.current == opts.STATES.fixation )
    opts.TRACKER.update_coordinates();
    if ( opts.TIMINGS.do_reset )
      opts = await_matching_state( opts );
      opts = reset_timer( opts, 'fixation' );
      opts.STIMULI.fixation.reset_targets();
      opts.STIMULI.fixation.blink( 0 );
    end
    opts.STIMULI.fixation.update_targets();
    opts.STIMULI.fixation.draw();
    Screen( 'Flip', opts.WINDOW.index );
    opts = debounce_arduino( opts, @update_arduino_gaze );
    if ( opts.STIMULI.fixation.duration_met() )
      [opts, m2_gaze_matches] = debounce_arduino( opts, @gazes_match );
      opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
      if ( m2_gaze_matches )
        %   MARK: goto: rule cue
        opts.STATES.current = opts.STATES.rule_cue;
        opts.TIMINGS.do_reset = true;
      else
        %   TODO: \\ REMOVE THIS
        opts.STATES.current = opts.STATES.rule_cue;
        opts.TIMINGS.do_reset = true;
      end
    end
    if ( exceeded_time_in(opts, 'fixation') )
      %   MARK: goto: rule cue
      opts.STATES.current = opts.STATES.rule_cue;
      opts.TIMINGS.do_reset = true;
    end
  end
  
  %   STATE RULE_CUE
  if ( opts.STATES.current == opts.STATES.rule_cue )
    if ( opts.TIMINGS.do_reset )
      opts = reset_timer( opts, 'rule_cue' );
    end
    if ( opts.STRUCTURE.is_master_monkey )
      switch ( opts.STRUCTURE.rule_cue_type )
        case 'gaze'
          opts.STIMULI.rule_cue_gaze_left.draw_frame();
          opts.STIMULI.rule_cue_gaze_right.draw_frame();
        case 'laser'
          %   fill in
        otherwise
          error( 'Unrecognized rule_cue_type ''%s''', opts.STRUCTURE.rule_cue_type );
      end
      Screen( 'Flip', opts.WINDOW.index );
    else
      clear_screen( opts );
    end
    if ( exceeded_time_in(opts, 'rule_cue') )
      %   MARK: goto: post_rule_cue
      opts.STATES.current = opts.STATES.post_rule_cue;
      opts.TIMINGS.do_reset = true;
    end
  end
  
  %   STATE POST_RULE_CUE
  if ( opts.STATES.current == opts.STATES.post_rule_cue )
    opts.TRACKER.update_coordinates();
    is_master = opts.STRUCTURE.is_master_monkey;
    is_slave = ~is_master;
    if ( opts.TIMINGS.do_reset )
      opts = reset_timer( opts, 'post_rule_cue' );
      if ( rand() > .5 )
        opts.STIMULI.gaze_cue_incorrect.put( 'center-left' );
        opts.STIMULI.gaze_cue_correct.put( 'center-right' );
        correct_choice = 1;
      else
        opts.STIMULI.gaze_cue_correct.put( 'center-left' );
        opts.STIMULI.gaze_cue_incorrect.put( 'center-right' );
        correct_choice = 2;
      end
      opts.STIMULI.gaze_cue_incorrect.reset_targets();
      opts.STIMULI.gaze_cue_correct.reset_targets();
      correct_target = opts.STIMULI.gaze_cue_correct;
      incorrect_target = opts.STIMULI.gaze_cue_incorrect;
      last_pulse = NaN;
    end
    if ( is_slave )
      switch ( opts.STRUCTURE.rule_cue_type )
        case 'gaze'
          opts.STIMULI.gaze_cue_incorrect.update_targets();
          opts.STIMULI.gaze_cue_correct.update_targets();
          opts.STIMULI.gaze_cue_incorrect.draw();
          opts.STIMULI.gaze_cue_correct.draw();
        case 'laser'
          %   fill in
        otherwise
          error( 'Unrecognized rule_cue_type ''%s''', opts.STRUCTURE.rule_cue_type );
      end
      Screen( 'Flip', opts.WINDOW.index );
      if ( is_slave )
        opts = debounce_arduino( opts, @set_choice, correct_choice );
        if ( correct_target.in_bounds() )
          if ( isnan(last_pulse) )
            should_deliver = true;
            last_pulse = tic;
          else
            should_deliver = toc( last_pulse ) > opts.REWARDS.pulse_frequency;
          end
          if ( should_deliver )
            opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
            last_pulse = tic;
          end
        else
          last_pulse = tic;
        end
        if ( correct_target.duration_met() )
          %   MARK: goto: USE_RULE          
          opts.STATES.current = opts.STATES.use_rule;
          opts.TIMINGS.do_reset = true;
        end
        if ( incorrect_target.duration_met() )
          %   opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
          %   MARK: goto: USE_RULE
          opts.STATES.current = opts.STATES.use_rule;
          opts.TIMINGS.do_reset = true;
        end
      end
    else
      clear_screen( opts );
    end
    if ( exceeded_time_in(opts, 'post_rule_cue') )
      %   MARK: goto: USE_RULE
      opts.STATES.current = opts.STATES.use_rule;
      opts.TIMINGS.do_reset = true;
    end
  end
  
  %   STATE USE_RULE
  if ( opts.STATES.current == opts.STATES.use_rule )
    opts.TRACKER.update_coordinates();
    if ( opts.TIMINGS.do_reset )
      opts = reset_timer( opts, 'use_rule' );
      opts.STIMULI.response_target_left.reset_targets();
      opts.STIMULI.response_target_right.reset_targets();
    end
    if ( opts.STRUCTURE.is_master_monkey )
      opts.STIMULI.response_target_left.update_targets();
      opts.STIMULI.response_target_right.update_targets();
      opts.STIMULI.response_target_left.draw();
      opts.STIMULI.response_target_right.draw();
      Screen( 'Flip', opts.WINDOW.index );
    else
      clear_screen( opts );
    end
    made_choice = false;
    if ( opts.STIMULI.response_target_left.duration_met() )
      made_choice = true;
      opts.STRUCTURE.did_choose = 1;
      %   MARK: goto: evaluate_choice
      opts.STATES.current = opts.STATES.evaluate_choice;
      opts.TIMINGS.do_reset = true;
    end
    if ( opts.STIMULI.response_target_right.duration_met() )
      made_choice = true;
      opts.STRUCTURE.did_choose = 2;
      %   MARK: goto: evaluate_choice
      opts.STATES.current = opts.STATES.evaluate_choice;
      opts.TIMINGS.do_reset = true;
    end
    if ( exceeded_time_in(opts, 'use_rule') && ~made_choice )
      opts.STRUCTURE.did_choose = [];
      %   MARK: goto: evaluate_choice
      opts.STATES.current = opts.STATES.evaluate_choice;
      opts.TIMINGS.do_reset = true;
    end
  end
  
  %   STATE EVALUATE_CHOICE
  if ( opts.STATES.current == opts.STATES.evaluate_choice )
    clear_screen( opts );
    if ( opts.TIMINGS.do_reset )
      opts = reset_timer( opts, 'evaluate_choice' );
    end
    if ( opts.STRUCTURE.is_master_monkey )
      if ( isequal(opts.STRUCTURE.did_choose, opts.STRUCTURE.correct_choice) )
        %   reward
        fprintf( '\n was correct' );
      else
        fprintf( '\n was incorrect' );
      end
    end
    if ( exceeded_time_in(opts, 'evaluate_choice') )
      %   MARK: goto: iti
      opts.STATES.current = opts.STATES.iti;
      opts.TIMINGS.do_reset = true;
    end
  end
  
  %   STATE ITI
  if ( opts.STATES.current == opts.STATES.iti )
    if ( opts.TIMINGS.do_reset )
      opts = reset_timer( opts, 'iti' );
    end
    if ( exceeded_time_in(opts, 'iti') )
      %   MARK: goto: new_trial
      opts.STATES.current = opts.STATES.new_trial;
    end
  end
  
  %   Quit if error in EyeLink
  success = checkRecording( opts );
  if ( success ~= 0 )
    break;
  end
  %   Quit if key is pressed
  [key_pressed, ~, ~] = KbCheck();
  if ( key_pressed )
    break;
  end
  %   Quit if time exceeds total time
  total_elapsed_time = get_time( opts, 'main' ) - opts.TIMINGS.start;
  if ( total_elapsed_time > opts.TIMINGS.total_time )
    break;
  end
end

% opts = debounce_arduino( opts, @set_state, 0 );
% [opts, matches] = debounce_arduino( opts, @states_match );
% disp( 'Do the states match?' );
% disp( matches );
% disp( 'Do the gazes match?' );
% [opts, matches] = debounce_arduino( opts, @gazes_match );
% disp( matches );
ListenChar(0);
sca;

cleanup( opts );
% shutdownEyelink( opts );   

end

function opts = update_cumulative_fixation_time(opts, bounds, timing_type)

%   UPDATE_CUMULATIVE_FIXATION_TIME -- Update the total amount of time
%     spent fixating on a given target.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `bounds` (double) -- 4-element vector specifying valid fixation
%         boundaries (i.e., the vertices of the stimulus).
%       - `timing_type` (char) -- String corresponding to the cumulative
%         fixation variable to update.
%     OUT:
%       - `opts` (struct) -- Updated `opts` struct.

if ( ~newGazeDataReady(opts) || ~opts.INTERFACE.use_eyelink )
  return;
end

[gaze_success, gaze_x, gaze_y] = getGazeCoordinates( opts );

if ( ~gaze_success )
  return;
end

within_x = gaze_x >= bounds(1) && gaze_x < bounds(3);
within_y = gaze_y >= bounds(2) && gaze_y < bounds(4);

if ( within_x && within_y )
  delta = get_time(opts, 'main') - opts.TIMINGS.last_frame;
  opts.TIMINGS.fixations.(timing_type).cumulative = ...
    opts.TIMINGS.fixations.(timing_type).cumulative + delta;
else
  opts.TIMINGS.fixations.(timing_type).cumulative = 0;
end

opts.TIMINGS.last_frame = get_time( opts, 'main' );

end

function bounds = get_square_stimulus_bounds(opts, placement, sz)

%   GET_SQUARE_STIMULUS_BOUNDS -- Get vertices of a square of a given size,
%     placed in a given portion of the screen.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `placement` (char) -- Placement specifier. Current options are
%         'center'.
%       - `sz` (double) |SCALAR| -- Single number specifying the size (in
%         pixels) of the square.
%     OUT:
%       - `bounds` (double) -- 4-element row vector specifying the vertices
%         / bounds of the square.

center = opts.WINDOW.center;
position = round( [-sz/2, -sz/2, sz/2, sz/2] );

switch ( placement )
  case 'center'
    center = [ center, center ];
    bounds = center + position;
  case 'center-left'
    dx = center(1) - center(1)/2;
    dy = center(2);
    bounds = [ dx, dy, dx, dy ] + position;
  case 'center-right'
    dx = center(1) + center(1)/2;
    dy = center(2);
    bounds = [ dx, dy, dx, dy ] + position;
  otherwise
    error( 'Unrecognized object placement ''%s''', placement );
end

end

function draw_rect(opts, rect, color)

%   DRAW_RECT -- Display a rectangle of the specified dimensions and color.
%
%     IN:
%       - `opts` (struct) -- Options struct as generated by `setup()`.
%       - `rect` (double) -- 4-element vector specifying [x1, y1, x2, y2].
%       - `color` (double) -- 3-element vector specifying the fill-color.

window = opts.WINDOW.index;
Screen( 'FillRect', window, color, rect );

end

function draw_frame_rect(opts, rect, color)

%   DRAW_RECT -- Display a rect-frame of the specified dimensions and color.
%
%     IN:
%       - `opts` (struct) -- Options struct as generated by `setup()`.
%       - `rect` (double) -- 4-element vector specifying [x1, y1, x2, y2].
%       - `color` (double) -- 3-element vector specifying the fill-color.

window = opts.WINDOW.index;
Screen( 'FrameRect', window, color, rect );

end

function draw_image(opts, image, rect)

%   DRAW_IMAGE -- Display an image in the given position.
%
%     IN:
%       - `image` (double) -- Image matrix as loaded by imread()
%       - `rect` (double) -- 4-element 4-element vector specifying 
%       [x1, y1, x2, y2]; i.e., the vertices of the image.

texture = Screen( 'MakeTexture', opts.WINDOW.index, image );
Screen( 'DrawTexture', opts.WINDOW.index, texture, [], rect );

end

function clear_screen(opts)

%   CLEAR_SCREEN -- Fill the screen with the screen's background color.
%
%     IN:
%       - `opts` (struct) -- Options struct as generated by `setup()`.

color = opts.SCREEN.background_color;
rect = opts.WINDOW.rect;
window = opts.WINDOW.index;
draw_rect( opts, rect, color );
Screen( 'Flip', window );

end

function assert_isa(variable, kind, variable_name)

%   ASSERT_ISA -- Ensure a variable is of a given class.
%
%     IN:
%       - `variable` (/any/) -- Variable to check.
%       - `kind` (char) -- Expected class of `variable`.
%       - `variable_name` (char) |OPTIONAL| -- Optionally specify the
%         variable name to appear in the error text, if the assertion
%         fails.
  
if ( nargin < 3 ), variable_name = 'input'; end;
assert( isa(variable, kind), 'Expected %s to be a %s; was a %s' ...
  , variable_name, kind, class(variable) );
  
end

function tf = exceeded_fixation_to(opts, target)

%   EXCEEDED_FIXATION_TO -- Return whether the cumulative fixation
%     duration to a target is above the pre-determined threshold.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `target` (char) -- Fixation target as defined in setup().
%     OUT:
%       - `tf` (logical) |SCALAR|

tf = opts.TIMINGS.fixations.(target).cumulative > ...
  opts.TIMINGS.fixations.(target).duration;
  
end

function tf = exceeded_time_in(opts, state)

%   EXCEEDED_TIME_IN -- Return whether the cumulative time in a given state
%     is above the predetermined threshold.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `state` (char) -- State name.
%     OUT:
%       - `tf` (logical) |SCALAR|

tf = get_time(opts, state) > opts.TIMINGS.time_in.(state);

end





%{
    ARDUINO
%}





function opts = reset_arduino( opts )

%   RESET_ARDUINO -- Reset the states and gaze data to their defaults.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `opts` (struct)

opts.COMMUNICATOR.send_gaze( 'X', 0 );
opts.COMMUNICATOR.send_gaze( 'Y', 0 );
opts = set_state( opts, 0 );

end

function opts = update_arduino_gaze( opts )

%   UPDATE_ARDUINO_GAZE -- Send new gaze coordinates to the arduino.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `opts` (struct)

if ( ~newGazeDataReady(opts) || ~opts.INTERFACE.use_eyelink )
  return;
end

[gaze_success, gaze_x, gaze_y] = getGazeCoordinates( opts );

if ( ~gaze_success )
  return;
end

opts.COMMUNICATOR.send_gaze( 'X', round(gaze_x) );
opts.COMMUNICATOR.send_gaze( 'Y', round(gaze_y) );

end

function success = synchronize(opts)

%   SYNCHRONIZE -- Ensure two tasks running on two separate computers
%     proceed at the same time, via arduino communication.
%
%     IN:
%       - `opts` (struct) -- Options struct as obtained by `setup()`.
%     OUT:
%       - `success` (logical) |SCALAR| -- True if the response from the
%         other Arduino matches the communicator's 'synchronize' character.

communicator = opts.COMMUNICATOR;

if ( ~opts.INTERFACE.use_arduino )
  success = true;
  return;
end

if ( opts.INTERFACE.is_master_arduino )
  communicator.send( 'SYNCHRONIZE' );
end

synch_start = get_time( opts, 'main' );
success = false;

while ( communicator.communicator.bytesAvailable == 0 )
  current_time = get_time( opts, 'main' );
  synch_timed_out = current_time-synch_start > opts.TIMINGS.synchronization_timeout;
  if ( synch_timed_out )
    return;
  end
end

response = communicator.receive();
if ( isequal(response, communicator.get_char('SYNCHRONIZE')) )
  success = true;
end

end

function opts = await_matching_state( opts )

%   AWAIT_MATCHING_STATE -- Pause execution until computers are in the same
%     state.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `opts` (struct) -- Options struct updated to reflect the last
%         call to an arduino function.

if ( ~opts.INTERFACE.require_synch ), return; end;
matching_state = false;
while ( ~matching_state )
  [opts, matching_state] = debounce_arduino( opts, @states_match );
end
    
end

function [opts, tf] = matches_other( opts, message )

%   MATCHES_OTHER -- Determine whether the current computer's value matches
%     the other computer's value.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `message` (char) -- Message to send to the arduino.

opts.COMMUNICATOR.send( message );
response = opts.COMMUNICATOR.await_and_return_non_null();

tf = false;

switch( response )
  case '1'
    tf = true;
    return;
  case '0'
    return;
  otherwise
    error( 'Unrecognized response ''%s''', response );
end

end

function [opts, tf] = states_match( opts )

%   STATES_MATCH -- Return whether the two computers are in the same state.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `tf` (true, false)

[opts, tf] = matches_other( opts, 'COMPARE_STATES' );

end

function [opts, tf] = gazes_match( opts )

%   GAZES_MATCH -- Return whether the two monkeys are gazing in the same
%     location.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `tf` (true, false)

[opts, tf] = matches_other( opts, 'COMPARE_GAZE' );

end

function opts = set_state( opts, state_num )

%   SET_STATE -- Update the Arduino's state variable.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `state_num` (int)
%
%     OUT:
%       - `opts` (struct) -- Options struct updated to reflect the last
%         call to `set_state()`.

opts.COMMUNICATOR.send_state( state_num );

end

function opts = set_choice( opts, choice )

%   SET_CHOICE -- Update the Arduino's choice variable.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `choice` (int)
%
%     OUT:
%       - `opts` (struct) -- Options struct updated to reflect the last
%         call to `set_state()`.

opts.COMMUNICATOR.send_choice( choice );
end

function varargout = debounce_arduino( opts, func, varargin )

%   DEBOUNCE_ARDUINO -- Ensure messages are not sent too quickly to the
%     arduino.
%
%     The function passed to `debounce_arduino()` will not be called until
%     at least `opts.TIMINGS.debounce_arduino_messages` seconds have
%     elapsed since the last input to the arduino.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `func` (function_handle) -- Function to be called.
%       - `varargin` (/any/) |OPTIONAL| -- Any additional arguments to be
%         passed to the call to `func`.
%     OUT:
%       - `varargout` (/any/) -- Various outputs as required by `func`.

if ( ~opts.INTERFACE.use_arduino )
  return;
end

while ( get_time(opts, 'last_arduino_message') < opts.TIMINGS.debounce_arduino_messages )
  % wait.
end
opts = reset_timer( opts, 'last_arduino_message' );
[varargout{1:nargout()}] = func( opts, varargin{:} );

end

function opts = set_reward_size( opts, index, sz )

%   SET_REWARD_SIZE -- Set the reward size (in ms) for the given index.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `index` (double, int) -- I.e., 1 or 2, usually.
%       - `sz` (double, int) -- Reward size in ms.
%     OUT:
%       - `opts` (struct) -- Options struct updated to reflect the last
%         reward size sent.

if ( ~opts.INTERFACE.use_arduino )
  return;
end
communicator = opts.COMMUNICATOR;
%   get the character associated with the given reward index.
reward_char = communicator.get_char( ['REWARD' num2str(index)] );
communicator.send_reward_size( reward_char, sz );
opts.REWARDS.last_reward_size = sz;

end

function opts = reward( opts, index, sz )

%   REWARD -- Send a reward associated with a given index.
%
%     If no reward size is specified, the hard-coded default (i.e., the
%     size specified in master.ino or slave.ino) will be used. Otherwise,
%     the reward size will be updated if it is different from the last
%     recorded reward size.

last_size = opts.REWARDS.last_reward_size;

if ( isempty(last_size) || sz ~= last_size )
  opts = set_reward_size( opts, index, sz );
end

reward_str = sprintf( 'REWARD%d', index );
opts.COMMUNICATOR.send( reward_str );

end

%{
    TIMERS
%}

function t = get_time( opts, id_name )

%   GET_TIME -- Get the elapsed time associated with the given timer id.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `id_name` (char) -- Fieldname of the timer_ids struct in
%         opts.TIMING.
%     OUT:
%       - `t` (double) -- Elapsed time.

t = toc( opts.TIMINGS.timer_ids.(id_name) );

end

function opts = reset_timer( opts, id_name )

%   RESET_TIMER -- Reset the timer associated with the given id.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `id_name` (char) -- Fieldname of the timer_ids struct in
%         opts.TIMING.
%     OUT:
%       - `opts` (struct) -- Updated options struct.

opts.TIMINGS.timer_ids.(id_name) = tic;
opts.TIMINGS.do_reset = false;

end

function opts = reset_timers(opts, ids)

%   RESET_TIMERS -- Reset the timers associated with the given ids
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `ids` (cell array of strings, char) -- Fieldname(s) of the
%         timer_ids struct in opts.TIMING.
%     OUT:
%       - `opts` (struct) -- Updated options struct.

if ( ~iscell(ids) ), ids = { ids }; end;
for i = 1:numel(ids)
  opts = reset_timer( opts, ids{i} );
end

end

function opts = reset_fixation(opts, fixation_name)

%   RESET_FIXATION -- Reset the cumulative fixation duration to 0.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `fixation_name` (char) -- Name of the fixation-target.
%     OUT:
%       - `opts` (struct)

opts.TIMINGS.fixations.(fixation_name).cumulative = 0;

end


%{
    UTILS
%}

function print_error_stack( err )

%   PRINT_ERROR_STACK -- Display the complete function-stack upon error.
%
%     IN:
%       - `err` (MException)

stack = err.stack;
for i = numel(stack):-1:1
  fprintf( '\n %d - %s', stack(i).line, stack(i).name );
end
fprintf( '\n %s', err.message );

end



%   old routines



% %Cleanup routine:
% function cleanup(opts)
% %Restore keyboard output to Matlab:
% ListenChar( 0 );
% 
% use_mouse = opts.INTERFACE.use_mouse;
% use_eyelink = opts.INTERFACE.use_eyelink;
% 
% % finish up: stop recording eye-movements,
% % close graphics window, close data file and shut down tracker
% if ( ~use_mouse && use_eyelink )
%   Eyelink( 'Shutdown' );
% end
% 
% opts.COMMUNICATOR.stop();
% 
% if ( isfield(opts, 'TRACKER') )
%   opts.TRACKER.shutdown();
% end
% 
% sca;
% 
% close_ports();
% end

function cleanup( opts )

%Restore keyboard output to Matlab:
ListenChar( 0 );
opts.TRACKER.shutdown();
sca;
close_ports();

end

%Runs Eyelink Initialization procedures
function err = eyeTrackingInit(opts)

err = false;

if ( ~opts.INTERFACE.use_eyelink )
  return;
end

use_mouse = opts.INTERFACE.use_mouse;
if ( use_mouse )
  return; 
end

edf_file = opts.IO.edf_filename;

is_dummy_mode = 0;
success = EyelinkInit( is_dummy_mode, 1 );	

if ( ~success )
  err = true; 
  return;
end

Eyelink( 'command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY' );
Eyelink( 'command', 'link_event_filter = LEFT,RIGHT,FIXATION,BLINK,SACCADE,BUTTON' );
Eyelink( 'Openfile', edf_file );
Eyelink( 'StartRecording' );
end

%Returns a boolean indicating whether there is new gaze data available
function data_ready = newGazeDataReady(opts)

use_mouse = opts.INTERFACE.use_mouse;
use_eyelink = opts.INTERFACE.use_eyelink;
if ( use_mouse || ~use_eyelink )
  data_ready = true;
  return;
end
   
data_ready = Eyelink( 'NewFloatSampleAvailable' ) > 0;
end

%Returns the gaze coordinates and a bool indicating wether or not the query was successful
function [success, x, y] = getGazeCoordinates(opts)

persistent eye_used;
persistent el;

use_mouse = opts.INTERFACE.use_mouse;
window = opts.WINDOW.index;

if ( ~use_mouse && isempty(eye_used) )
  eye_used = -1;

  %Grab default Eyelink values
  el = EyelinkInitDefaults( window );
end

success = false;
x = 0;
y = 0;
if ( use_mouse )
  [x, y] = GetMouse();
  success = true;
  return;
end

event = Eyelink('NewestFloatSample');
if ( eye_used ~= -1 )
  %Get Eye Coordinates
  x = event.gx(eye_used+1);
  y = event.gy(eye_used+1);

  %If we have valid data
  if (x~=el.MISSING_DATA && y~=el.MISSING_DATA && event.pa(eye_used+1)>0)
    %then the data is valid
    success = true;
  end
else
  eye_used = Eyelink( 'EyeAvailable' );
  if (eye_used == el.BINOCULAR)
    eye_used = el.LEFT_EYE;
  end
  return;
end
end

%Checks the status of the Eyelink Recording
function err = checkRecording(opts)

  use_mouse = opts.INTERFACE.use_mouse;
  use_eyelink = opts.INTERFACE.use_eyelink;
	err = false;
	if ( use_mouse || ~use_eyelink )
		return;
  end
	err = Eyelink( 'CheckRecording' );
end

%Close down the Eyelink connection and download the file.
function shutdownEyelink(opts)

if ( ~opts.INTERFACE.use_eyelink )
  return;
end

edf_filename = opts.IO.edf_filename;

WaitSecs( 0.1 );
Eyelink( 'StopRecording' );
WaitSecs( 0.1 );
Eyelink( 'CloseFile' );
WaitSecs( 0.1 );

try
  fprintf( 'Receiving data file ''%s''\n', edf_filename );
  %   Request the file
  status = Eyelink( 'ReceiveFile', edf_filename, pwd, 1 );
  if ( status > 0 )
    fprintf( 'ReceiveFile status %d\n', status );
  end
  WaitSecs(0.1);
  if ( exist( edf_filename, 'file' ) == 2 )
    fprintf( 'Data file ''%s'' can be found in ''%s''\n', edf_filename, pwd );
  end
catch err
    fprintf( 'Problem receiving data file ''%s''\n', edf_filename );
    fprintf( '\n%s', err.message );
end

end