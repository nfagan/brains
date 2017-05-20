function run( opts )

%   RUN -- Run the task.
%
%   IN:
%     - `opts` (struct) -- Options as generated by `setup()`.

%   extract
IO =            opts.IO;
ROIS =          opts.ROIS;
TIMER =         opts.TIMER;
STATES =        opts.STATES;
TRACKER =       opts.TRACKER;
STIMULI =       opts.STIMULI;
STRUCTURE =     opts.STRUCTURE;
tcp_comm =      opts.COMMUNICATORS.tcp_comm;
serial_comm =   opts.COMMUNICATORS.serial_comm;

first_entry = true;
STATES.current = STATES.new_trial;

DATA = struct();
PROGRESS = struct();
TRIAL_NUMBER = 0;

%   main loop
while ( true )
  
  %   STATE NEW_TRIAL
  if ( STATES.current == STATES.new_trial )
    Screen( 'Flip', opts.WINDOW.index );
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      DATA(tn).trial_number = tn;
      DATA(tn).m1_chose = STRUCTURE.m1_chose;
      DATA(tn).m2_chose = STRUCTURE.m2_chose;
      DATA(tn).rule_cue_type = STRUCTURE.rule_cue_type;
      DATA(tn).correct_location = correct_location;
      DATA(tn).incorrect_location = incorrect_location;
      DATA(tn).events = PROGRESS;
    end
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    %   reset event times
    PROGRESS = structfun( @(x) NaN, PROGRESS, 'un', false );
    %   determine rule cue type
    if ( rand() > .5 )
      STRUCTURE.rule_cue_type = 'gaze';
    else
      STRUCTURE.rule_cue_type = 'laser';
    end
    %   get correct target location for m2
    if ( rand() > .5 )
      incorrect_location = 'center-left';
      correct_location = 'center-right';
      incorrect_is = 1;
      correct_is = 2;
    else
      incorrect_location = 'center-right';
      correct_location = 'center-left';
      incorrect_is = 2;
      correct_is = 1;
    end
    %   reset choice parameters
    STRUCTURE.m1_chose = [];
    STRUCTURE.m2_chose = [];
    %   get type of cue for this trial
    %   MARK: goto: fixation
    STATES.current = STATES.fixation;
    tcp_comm.send_when_ready( 'state', STATES.current );
    first_entry = true;
  end
  
  %   STATE FIXATION
  if ( STATES.current == STATES.fixation )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state();
      TIMER.reset_timers( 'fixation' );
      fix_targ = STIMULI.fixation;
      fix_targ.reset_targets();
      fix_targ.blink( 0 );
      tcp_comm.send_when_ready( 'fix_met', 0 );
      log_progress = true;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    structfun( @(x) x.update(), ROIS );
    fix_targ.update_targets();
    fix_targ.draw();
    Screen( 'Flip', opts.WINDOW.index );
    if ( log_progress )
      PROGRESS.fixation_onset = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( fix_targ.duration_met() )
      PROGRESS.fixation_acquired = TIMER.get_time( 'task' );
      tcp_comm.send_when_ready( 'fix_met', 1 );
      fix_was_met = tcp_comm.consume( 'fix_met' );
      fix_was_met = ~isnan( fix_was_met ) && fix_was_met ~= 0;
      if ( fix_was_met )
        opts = debounce_arduino( opts, @reward, 1, 150 );
        %   MARK: goto: rule cue
        STATES.current = STATES.rule_cue;
        opts = debounce_arduino( opts, @set_state, STATES.current );
        first_entry = true;
      else
        if ( ~fix_targ.in_bounds() )
          tcp_comm.send_when_ready( 'fix_met', 0 );
          fix_targ.reset_targets();
        end
      end
    end
    if ( TIMER.duration_met('fixation') )
      %   MARK: goto: rule cue
      STATES.current = STATES.rule_cue;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %   STATE RULE_CUE
  if ( STATES.current == STATES.rule_cue )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state();
      PROGRESS.rule_cue = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'rule_cue' );
      gaze_cue = STIMULI.rule_cue_gaze;
      laser_cue = STIMULI.rule_cue_laser;
      log_progress = true;
      first_entry = false;
    end
    if ( STRUCTURE.is_master_monkey )
      switch ( STRUCTURE.rule_cue_type )
        case 'gaze'
         gaze_cue.draw_frame();
        case 'laser'
          laser_cue.draw_frame();
        otherwise
          error( 'Unrecognized rule_cue_type ''%s''', STRUCTURE.rule_cue_type );
      end
    end
    Screen( 'Flip', opts.WINDOW.index );
    if ( log_progress )
      PROGRESS.rule_cue_onset = TIMER.get_time( 'task' );
      log_progress = false;
    end
    if ( TIMER.duration_met('rule_cue') )
      %   MARK: goto: post_rule_cue
      STATES.current = STATES.post_rule_cue;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %   STATE POST_RULE_CUE
  if ( STATES.current == STATES.post_rule_cue ) 
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      PROGRESS.rule_cue_offset = TIMER.get_time( 'task' );
      tcp_comm.await_matching_state();
      PROGRESS.post_rule_cue = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'post_rule_cue' );
      correct_target = STIMULI.gaze_cue_correct;
      incorrect_target = STIMULI.gaze_cue_incorrect;
      incorrect_target.put( incorrect_location );
      correct_target.put( correct_location );
      incorrect_target.reset_targets();
      correct_target.reset_targets();
      last_pulse = NaN;
      log_progress = true;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    is_master = STRUCTURE.is_master_monkey;
    is_slave = ~is_master;
    if ( is_slave )
      incorrect_target.update_targets();
      correct_target.update_targets();
      incorrect_target.draw();
      correct_target.draw();
      Screen( 'Flip', opts.WINDOW.index );
      if ( log_progress )
        PROGRESS.m2_target_onset = TIMER.get_time( 'task' );
        log_progress = false;
      end
      if ( correct_target.duration_met() )
        %   MARK: goto: USE_RULE
        STRUCTURE.m2_chose = correct_is;
        opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
        opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
        opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
        STATES.current = STATES.use_rule;
        tcp_comm.send_when_ready( 'choice', correct_is );
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
      if ( incorrect_target.duration_met() )
        STRUCTURE.m2_chose = incorrect_is;
        %   MARK: goto: USE_RULE
        tcp_comm.send_when_ready( 'choice', incorrect_is );
        STATES.current = STATES.use_rule;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    else
      Screen( 'Flip', opts.WINDOW.index );
    end
    if ( TIMER.duration_met('post_rule_cue') )
      %   MARK: goto: USE_RULE
      STATES.current = STATES.use_rule;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %   STATE USE_RULE
  if ( STATES.current == STATES.use_rule )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      PROGRESS.m2_target_offset = TIMER.get_time( 'task' );
      tcp_comm.await_matching_state();
      PROGRESS.use_rule = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'use_rule' );
      response_target1 = STIMULI.response_target1;
      response_target2 = STIMULI.response_target2;
      response_target1.reset_targets();
      response_target2.reset_targets();
      if ( STRUCTURE.is_master_monkey )
        STRUCTURE.m2_chose = tcp_comm.await_choice();
      end
      STRUCTURE.m1_chose = [];
      first_entry = false;
    end
    TRACKER.update_coordinates();
    if ( STRUCTURE.is_master_monkey )
      response_target1.update_targets();
      response_target2.update_targets();
      response_target1.draw();
      response_target2.draw();
      Screen( 'Flip', opts.WINDOW.index );
    end
    if ( response_target1.duration_met() )
      STRUCTURE.m1_chose = 1;
      %   MARK: goto: evaluate_choice
      STATES.current = STATES.evaluate_choice;
      tcp_comm.send_when_ready( 'state', STATES.CURRENT );
      first_entry = true;
    end
    if ( response_target2.duration_met() )
      STRUCTURE.m1_chose = 2;
      %   MARK: goto: evaluate_choice
      STATES.current = STATES.evaluate_choice;
      tcp_comm.send_when_ready( 'state', STATES.CURRENT );
      first_entry = true;
    end
    if ( TIMER.duration_met('use_rule') )
      %   MARK: goto: evaluate_choice
      STATES.current = STATES.evaluate_choice;
      tcp_comm.send_when_ready( 'state', STATES.CURRENT );
      first_entry = true;
    end
  end
  
  %   STATE EVALUATE_CHOICE
  if ( STATES.current == STATES.evaluate_choice )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state();
      PROGRESS.evaluate_choice = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'evaluate_choice' );
      if ( STRUCTURE.is_master_monkey )
        if ( isequal(STRUCTURE.m1_chose, STRUCTURE.m2_chose) )
          opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
        end
      end
      first_entry = false;
    end
    if ( TIMER.duration_met('evaluate_choice') )
      %   MARK: goto: iti
      STATES.current = STATES.iti;
      tcp_comm.send_when_ready( 'state', STATES.CURRENT );
      first_entry = true;
    end
  end
  
  %   STATE ITI
  if ( STATES.current == STATES.iti )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state();
      PROGRESS.iti = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'iti' );
      first_entry = false;
    end
    if ( TIMER.duration_met('iti') )
      %   MARK: goto: new_trial
      STATES.current = STATES.new_trial;
      tcp_comm.send_when_ready( 'state', STATES.CURRENT );
      first_entry = true;
    end
  end
  
  % - Update tcp_comm
  tcp_comm.update();
  tcp_comm.send_when_ready( 'gaze', TRACKER.coordinates );
  
  % - Quit if error in EyeLink
  success = TRACKER.check_recording();
  if ( success ~= 0 ), break; end;
  
  % - Check if key is pressed
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    % - Quit if stop_key is pressed
    if ( key_code(opts.INTERFACE.stop_key) ), break; end;
    %   Deliver reward if reward key is pressed
    if ( key_code(opts.INTERFACE.rwd_key) )
      opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
    end
  end
  
  % - Quit if time exceeds total time
  if ( TIMER.duration_met('task') ), break; end;
end

TRACKER.shutdown();

if ( opts.INTERFACE.save_data )
  data = struct();
  data.DATA = DATA;
  data.opts = opts;
  save( fullfile(IO.data_folder, IO.data_file), 'data' );
end

end




%{
    private utilities
%}



%{
    ARDUINO
%}


function opts = flush_buffer( opts )

%   FLUSH_BUFFER -- Flush the Arduino's buffer.

if ( opts.COMMUNICATORS.serial_comm.communicator.BytesAvailable > 0 )
  opts.COMMUNICATORS.serial_comm.communicator.receive_all();
end

end


function opts = reset_arduino( opts )

%   RESET_ARDUINO -- Reset the states and gaze data to their defaults.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `opts` (struct)

if ( ~opts.INTERFACE.use_arduino ), return; end;
opts.COMMUNICATORS.serial_comm.send_gaze( 'X', 0 );
opts.COMMUNICATORS.serial_comm.send_gaze( 'Y', 0 );
opts = set_state( opts, 0 );

end

function opts = update_arduino_gaze( opts )

%   UPDATE_ARDUINO_GAZE -- Send new gaze coordinates to the arduino.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `opts` (struct)

tracker = opts.TRACKER;
if ( tracker.bypass || ~tracker.gaze_ready ), return; end;

gaze_x = tracker.coordinates(1);
gaze_y = tracker.coordinates(2);

opts.COMMUNICATORS.serial_comm.send_gaze( 'X', round(gaze_x) );
opts.COMMUNICATORS.serial_comm.send_gaze( 'Y', round(gaze_y) );

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
% [opts, matching_state] = debounce_arduino( opts, @states_match );
% if ( ~matching_state )
%   opts = await_matching_state( opts );
% end
% 
matching_state = false;
start_synch = tic;
while ( ~matching_state )
  [opts, matching_state] = debounce_arduino( opts, @states_match );
  if ( toc(start_synch) > opts.TIMINGS.synch_timeout )
    error( 'Synchronization timed out.' );
  end
end

% comm = opts.COMMUNICATORS.serial_comm;
% comm.send( 'COMPARE_STATES' );
% matching_state = comm.await_and_return_non_null();
% if ( ~isfield(opts.TIMING, 'synch_timer') || isnan(opts.TIMING.synch_timer) )
%   opts.TIMING.synch_timer = tic;
% end
% if ( toc(opts.TIMING.synch_timer) > opts.TIMING.synch_timeout )
%   error( 'Synchronization timed out.' );
% end
% if ( ~matching_state )
%   await_mathing_state( opts );
% end
    
end

function [opts, response] = get_choice( opts )

%   GET_CHOICE -- Get M2's choice.

if ( ~opts.INTERFACE.use_arduino ), response = []; return; end;
opts.COMMUNICATORS.serial_comm.send( 'GET_CHOICE' );
response = opts.COMMUNICATORS.serial_comm.await_and_return_non_null();
response = str2double( response );

end

function [opts, tf] = matches_other( opts, message )

%   MATCHES_OTHER -- Determine whether the current computer's value matches
%     the other computer's value.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `message` (char) -- Message to send to the arduino.

opts.COMMUNICATORS.serial_comm.send( message );
response = opts.COMMUNICATORS.serial_comm.await_and_return_non_null();

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

if ( ~opts.INTERFACE.use_arduino ), tf = true; return; end;
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

if ( ~opts.INTERFACE.use_arduino ), tf = true; return; end;
[opts, tf] = matches_other( opts, 'COMPARE_GAZE' );

end

function [opts, tf] = fix_met_match( opts )

%   FIX_MET_MATCH -- Return whether the two monkeys have fixated for the
%     required duration.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%     OUT:
%       - `tf` (true, false)

if ( ~opts.INTERFACE.use_arduino ), tf = true; return; end;
if ( ~opts.INTERFACE.require_synch ), tf = true; return; end;
[opts, tf] = matches_other( opts, 'COMPARE_FIX_MET' );

end

function opts = set_fix_met( opts, tf )

%   SET_FIX_MET -- Update the Arduino's FixMet variable.
%
%     IN:
%       - `opts` (struct) -- Options struct.
%       - `state_num` (int)
%
%     OUT:
%       - `opts` (struct) -- Options struct updated to reflect the last
%         call to `set_state()`.

if ( ~opts.INTERFACE.use_arduino ), return; end;
opts.COMMUNICATORS.serial_comm.send_fix_met( tf );
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

if ( ~opts.INTERFACE.use_arduino ), return; end;
opts.COMMUNICATORS.serial_comm.send_state( state_num );

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

if ( ~opts.INTERFACE.use_arduino ), return; end;
opts.COMMUNICATORS.serial_comm.send_choice( choice );
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

if ( ~opts.INTERFACE.use_arduino ), return; end;
while ( ~opts.TIMER.duration_met('debounce_arduino_messages') )
  %   wait
end
opts.TIMER.reset_timers( 'debounce_arduino_messages' );
[varargout{1:nargout()}] = func( opts, varargin{:} );

% while ( get_time(opts, 'last_arduino_message') < opts.TIMINGS.debounce_arduino_messages )
%   % wait.
% end
% opts = reset_timer( opts, 'last_arduino_message' );
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

if ( ~opts.INTERFACE.use_arduino ), return; end;
communicator = opts.COMMUNICATORS.serial_comm;
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

if ( ~opts.INTERFACE.use_arduino ), return; end;

reward_str = sprintf( 'REWARD%d', index );
opts.COMMUNICATORS.serial_comm.send( reward_str );

end


%{
    TIMERS
%}

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

%       if ( correct_target.in_bounds() )
%         if ( isnan(last_pulse) )
%           should_deliver = true;
%           last_pulse = tic;
%         else
%           should_deliver = toc( last_pulse ) > opts.REWARDS.pulse_frequency;
%         end
%         if ( should_deliver )
%           opts = debounce_arduino( opts, @reward, 1, opts.REWARDS.main );
%           last_pulse = tic;
%         end
%       else
%         last_pulse = tic;
%       end