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
IMAGES  =       opts.IMAGES;
STRUCTURE =     opts.STRUCTURE;
INTERFACE =     opts.INTERFACE;
REWARDS =       opts.REWARDS;
TIMINGS =       opts.TIMINGS;
tcp_comm =      opts.COMMUNICATORS.tcp_comm;
serial_comm =   opts.COMMUNICATORS.serial_comm;

first_entry = true;
STATES.current = STATES.new_trial;

GAZE_CUE_SHIFT_AMOUNT = 100;

ALIGN_CENTER_STIMULI_TO_TOP = false;
SCREEN_HEIGHT = 27.3;
SCREEN_OFFSET = 19.5;
SCREEN_HEIGHT_PX = 768;

DATA = struct();
PROGRESS = struct();
TRIAL_NUMBER = 0;
trial_in_block = 0;
FRAMES.stp = 1;
FRAMES.mean = 0;
FRAMES.min = Inf;
FRAMES.max = -Inf;

trial_type_num = STRUCTURE.trial_type_nums(1);

errors = struct( ...
    'initial_fixation_not_met', false ...
  , 'broke_fixation', false ...
  , 'm2_wrong_target', false ...
  , 'm2_no_choice', false ...
  , 'm2_fix_delay_no_look', false ...
  );
n_correct = 0;

reward_key_timer = NaN;

%   main loop
while ( true )
  
  %%   STATE NEW_TRIAL
  if ( STATES.current == STATES.new_trial )
    Screen( 'Flip', opts.WINDOW.index );
    if ( INTERFACE.DEBUG )
      disp( 'Entered new_trial' );
    end
    if ( TRIAL_NUMBER > 0 )
      tn = TRIAL_NUMBER;
      DATA(tn).trial_number = tn;
      DATA(tn).m1_chose = STRUCTURE.m1_chose;
      DATA(tn).m2_chose = STRUCTURE.m2_chose;
      DATA(tn).rule_cue_type = STRUCTURE.rule_cue_type;
      DATA(tn).correct_location = correct_location;
      DATA(tn).incorrect_location = incorrect_location;
      DATA(tn).events = PROGRESS;
      DATA(tn).errors = errors;
        %   display data
      clc;
      disp( DATA(TRIAL_NUMBER).errors );
      fprintf( '\n - Trial number: %d', tn );
      err_types = fieldnames( errors );
      for ii = 1:numel(err_types)
        n_errors = sum( arrayfun(@(x) x.errors.(err_types{ii}), DATA) );
        fprintf( '\n - N errors (%s): %d', err_types{ii}, n_errors );
      end
      if ( ~any(structfun(@(x) x, errors)) )
        n_correct = n_correct + 1;
      end
      fprintf( '\n - N correct: %d', n_correct );
    end
    TRIAL_NUMBER = TRIAL_NUMBER + 1;
    trial_in_block = trial_in_block + 1;
    %   reset event times
    PROGRESS = structfun( @(x) NaN, PROGRESS, 'un', false );
    errors = structfun( @(x) false, errors, 'un', false );
    %   determine rule cue type
    if ( INTERFACE.IS_M1 || ~INTERFACE.require_synch )
      if ( STRUCTURE.trials_per_block == 0 )
        if ( rand() > .5 )
          trial_type_num = 1;
        else
          trial_type_num = 2;
        end
        %   -1 for gaze, -2 for led
      elseif ( sign(STRUCTURE.trials_per_block) == -1 )
        trial_type_num = -STRUCTURE.trials_per_block;
      else
        if ( trial_in_block == STRUCTURE.trials_per_block )
          trial_in_block = 0;
          STRUCTURE.trial_type_nums = fliplr( STRUCTURE.trial_type_nums );
          trial_type_num = STRUCTURE.trial_type_nums(1);
        end
      end
      STRUCTURE.rule_cue_type = STRUCTURE.rule_cue_types{trial_type_num};
      tcp_comm.send_when_ready( 'trial_type', trial_type_num );
    else
      trial_type_num = tcp_comm.await_data( 'trial_type' );
      %   make sure we received a valid `laser_location`, unless
      %   require_synch is false.
      if ( isnan(trial_type_num) )
        assert( ~INTERFACE.require_synch, 'Received NaN for trial_type.' );
        trial_type_num = 1;
      end
      STRUCTURE.rule_cue_type = STRUCTURE.rule_cue_types{trial_type_num};
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
    %   make the led cue appear on the side opposite of the gaze target.
    if ( ~INTERFACE.IS_M1 || ~INTERFACE.require_synch )
      led_location = incorrect_is;
      tcp_comm.send_when_ready( 'choice', led_location );
    else
      led_location = tcp_comm.await_data( 'choice' );
      %   make sure we received a valid `laser_location`, unless
      %   require_synch is false.
      if ( isnan(led_location) )
        assert( ~INTERFACE.require_synch, 'Received NaN for laser_location.' );
        led_location = 1;
      end
    end
    if ( INTERFACE.DEBUG )
      disp( 'Trialtype is:' );
      disp( STRUCTURE.rule_cue_type );
    end
    %   set fixation delay time
    if ( INTERFACE.IS_M1 )
      fix_delays = TIMINGS.delays.fixation_delay;
      ind = randperm( numel(fix_delays) );
      fixation_delay_time = fix_delays( ind(1) );
      tcp_comm.send_when_ready( 'delay', fixation_delay_time );
    else
      fixation_delay_time = tcp_comm.await_data( 'delay' );
      if ( isnan(fixation_delay_time) )
        assert( ~INTERFACE.require_synch, 'Received NaN for fixation_delay.' );
        fixation_delay_time = TIMINGS.delays.fixation_delay(1);
      end
    end
    if ( TRIAL_NUMBER == 1 && ALIGN_CENTER_STIMULI_TO_TOP )
      align_stimuli_to_top( {STIMULI.fixation, STIMULI.rule_cue_gaze ...
        , STIMULI.rule_cue_led, STIMULI.m2_second_fixation_picture ...
        , STIMULI.error_cue, STIMULI.fixation_error_cue} ...
        , SCREEN_HEIGHT, SCREEN_OFFSET, SCREEN_HEIGHT_PX);
    end
    %   reset choice parameters
    STRUCTURE.m1_chose = [];
    STRUCTURE.m2_chose = [];
    %   get type of cue for this trial
    %   MARK: goto: fixation
    STATES.current = STATES.fixation;
    tcp_comm.send_when_ready( 'state', STATES.current );
    %   trial start
    TRACKER.send_message( sprintf('TRIAL__%d', TRIAL_NUMBER) );
    PROGRESS.trial_start = TIMER.get_time( 'task' );
    serial_comm.sync_pulse( 1 );
    %   END
    first_entry = true;
  end
  
  %%   STATE FIXATION
  if ( STATES.current == STATES.fixation )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      if ( INTERFACE.DEBUG )
        disp( 'Entered fixation' );
      end
      tcp_comm.await_matching_state( STATES.current );
      TIMER.reset_timers( 'fixation' );
      fix_targ = STIMULI.fixation;
      fix_targ.reset_targets();
      fix_targ.blink( 0 );
      %   SHIFT FIXATION SQUARE UP
      if ( TRIAL_NUMBER == 1 )
        fix_targ.vertices([2, 4]) = fix_targ.vertices([2, 4]) - 0;
      end
      log_progress = true;
      fix_met = 0;
      tcp_comm.send_when_ready( 'fix_met', fix_met );
      first_entry = false;
    end
    tcp_comm.update();
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
      if ( INTERFACE.DEBUG )
        disp( 'Met fixation' );
      end
      PROGRESS.fixation_acquired = TIMER.get_time( 'task' );
      if ( INTERFACE.require_synch )
        other_fix_met = tcp_comm.consume( 'fix_met' ) == 1;
      else other_fix_met = 1;
      end
      fix_met = 1;
      if ( other_fix_met )
        if ( INTERFACE.require_synch && INTERFACE.IS_M1 )
          serial_comm.reward( 1, REWARDS.bridge );
          serial_comm.reward( 2, REWARDS.bridge );
        elseif ( ~INTERFACE.require_synch )
          serial_comm.reward( 1, REWARDS.bridge );
        end
        %   MARK: goto: rule cue
        STATES.current = STATES.rule_cue;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    else
      fix_met = 0;
    end
    tcp_comm.send_when_ready( 'fix_met', fix_met );
    if ( TIMER.duration_met('fixation') )
      %   MARK: goto: rule cue
      %
      %   @FixMe
      %
      %   This will break when we introduce synchronization!
      if ( fix_met )
        STATES.current = STATES.rule_cue;
      else
        STATES.current = STATES.error;
        errors.initial_fixation_not_met = true;
      end
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %%   STATE RULE_CUE
  if ( STATES.current == STATES.rule_cue )
    if ( first_entry )
      if ( INTERFACE.DEBUG ), disp( 'Entered rule cue' ); end
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.rule_cue = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'rule_cue' );
      switch ( STRUCTURE.rule_cue_type )
        case 'gaze'
          rule_cue = STIMULI.rule_cue_gaze;
        case 'led'
          rule_cue = STIMULI.rule_cue_led;
        otherwise
          error( 'Unrecognized rule cue ''%s''', STRUCTURE.rule_cue_type );
      end
      %   draw the peripheral targets
      wrect = opts.WINDOW.rect;
      frame_width = wrect(3)/3;
      frame_height = wrect(4);
      periph_targ_names = { 'frame_cue_left', 'frame_cue_right' };
      periph_targ_place = { 'top-left', 'top-right' };
      frame_cues = struct();
      frame_cues.frame_cue_left = STIMULI.frame_cue_left;
      frame_cues.frame_cue_right = STIMULI.frame_cue_right;
      for ii = 1:numel(periph_targ_names)
        targ_name = periph_targ_names{ii};
        frame_cues.(targ_name).width = frame_width;
        frame_cues.(targ_name).len = frame_height;
        frame_cues.(targ_name).vertices = [ 0, 0, frame_width, frame_height ];
        frame_cues.(targ_name).put( periph_targ_place{ii} );
        frame_cues.(targ_name).scale( .95 );
        frame_cues.(targ_name).color = rule_cue.color;
      end
      log_progress = true;
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
      rule_cue.draw();
      if ( STRUCTURE.draw_frame_cues )
        structfun( @(x) x.draw_frame(), frame_cues );
      end
      Screen( 'Flip', opts.WINDOW.index );
      PROGRESS.rule_cue_onset = TIMER.get_time( 'task' );
      serial_comm.sync_pulse( 2 );
      did_show = true;
    end
    TRACKER.update_coordinates();
    rule_cue.update_targets();
    %   if fixation to the rule cue is broken, abort the trial and return
    %   to the new trial state.
    if ( ~rule_cue.in_bounds() )
      %   MARK: goto: error
      tcp_comm.send_when_ready( 'error', 2 );
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      errors.broke_fixation = true;
      first_entry = true;
    end
    if ( tcp_comm.consume('error') == 2 )
      %   MARK: goto: error
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
    if ( TIMER.duration_met('rule_cue') )
      %   MARK: goto: cue_display
      STATES.current = STATES.cue_display2;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  
  %%   STATE CUE_DISPLAY
  if ( STATES.current == STATES.cue_display ) 
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      if ( INTERFACE.DEBUG )
        disp( 'Entered cue_display' );
      end
      PROGRESS.rule_cue_offset = TIMER.get_time( 'task' );
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.post_rule_cue = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'cue_display' );
      TIMER.reset_timers( 'time_to_cue_fixation' );
      is_gaze_trial = strcmp( STRUCTURE.rule_cue_type, 'gaze' );
      is_m2 = ~INTERFACE.IS_M1;
      if ( is_gaze_trial )
        correct_target = STIMULI.gaze_cue_correct;
        incorrect_target = STIMULI.gaze_cue_incorrect;
        incorrect_target.put( incorrect_location );
        correct_target.put( correct_location );
        incorrect_target.reset_targets();
        correct_target.reset_targets();
      end
      chosen_target = [];
      STRUCTURE.m2_chose = [];
      last_pulse = NaN;
      log_progress = true;
      lit_led = false;
      made_cue_error = false;
      did_show = false;
      did_show_choice = false;
      failed_to_choose_in_time = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    fix_targ.update_targets();
    if ( is_m2 && is_gaze_trial )
      incorrect_target.update_targets();
      correct_target.update_targets();
      if ( ~did_show )
        incorrect_target.draw();
        correct_target.draw();
        Screen( 'Flip', opts.WINDOW.index );
        did_show = true;
      end
      if ( log_progress )
        PROGRESS.m2_target_onset = TIMER.get_time( 'task' );
        log_progress = false;
      end
      if ( correct_target.duration_met() )
        if ( ~did_show_choice )
          fprintf( '\nM2: made choice %d\n', correct_is );
          did_show_choice = true;
        end
%         if ( isnan(last_pulse) )
%           should_reward = true;
%         else
%           should_reward = toc( last_pulse ) > REWARDS.pulse_frequency/1e3;
%         end
%         if ( should_reward )
%           disp( 'Rewarding ...' );
%           serial_comm.reward( 1, REWARDS.main );
%           last_pulse = tic;
%         end
        chosen_target = correct_target;
        STRUCTURE.m2_chose = correct_is;
        tcp_comm.send_when_ready( 'choice', correct_is );
      end
      if ( incorrect_target.duration_met() )
        if ( ~did_show_choice )
          fprintf( '\nM2: made choice %d\n', incorrect_is );
          did_show_choice = true;
        end
        chosen_target = incorrect_target;
        STRUCTURE.m2_chose = incorrect_is;
        tcp_comm.send_when_ready( 'choice', incorrect_is );
        %   MARK: goto error
        STATES.current = STATES.error;
        first_entry = true;
      end
      %   once the made a choice, if they look away from the target ...
      if ( ~isa(chosen_target, 'double') )
        if ( ~chosen_target.in_bounds() )
          %   MARK: goto: error
          made_cue_error = true;
          tcp_comm.send_when_ready( 'error', 3 );
          STATES.current = STATES.error;
          tcp_comm.send_when_ready( 'state', STATES.current );
          first_entry = true;
        end
      end
    elseif ( is_m2 && ~is_gaze_trial )
      if ( ~lit_led )
        serial_comm.LED( led_location, opts.TIMINGS.LED );
        lit_led = true;
      end
      if ( ~did_show )
        fix_targ.draw();
        Screen( 'Flip', opts.WINDOW.index );
        did_show = true;
      end
      if ( ~fix_targ.in_bounds() )
        %   MARK: goto: error
        tcp_comm.send_when_ready( 'error', 3 );
        STATES.current = STATES.error;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    else
      Screen( 'Flip', opts.WINDOW.index );
    end
    if ( tcp_comm.consume('error') == 3 )
      %   MARK: goto: error
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
    if ( TIMER.duration_met('time_to_cue_fixation') )
      if ( isempty(STRUCTURE.m2_chose) )
        %   MARK: goto: error
        tcp_comm.send_when_ready( 'choice', 0 );
        STATES.current = STATES.error;
        STRUCTURE.m2_chose = 0;
        failed_to_choose_in_time = true;
        first_entry = true;
      end
    end
    if ( TIMER.duration_met('cue_display') && ~failed_to_choose_in_time )
      %   MARK: goto: fixation_delay
      if ( is_m2 && isempty(STRUCTURE.m2_chose) )
        tcp_comm.send_when_ready( 'choice', 0 );
        STRUCTURE.m2_chose = 0;
      end
      if ( ~made_cue_error )
        %   MARK: goto: iti
        STATES.current = STATES.fixation_delay;
%         STATES.current = STATES.iti;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    end
  end
  
  %%   STATE CUE_DISPLAY2
  if ( STATES.current == STATES.cue_display2 )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      if ( INTERFACE.DEBUG ), disp( 'Entered cue_display2' ); end
      PROGRESS.rule_cue_offset = TIMER.get_time( 'task' );
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.post_rule_cue = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'cue_display' );
      TIMER.reset_timers( 'time_to_cue_fixation' );
      is_gaze_trial = strcmp( STRUCTURE.rule_cue_type, 'gaze' );
      is_m2 = ~INTERFACE.IS_M1;
      if ( is_gaze_trial )
        correct_target = STIMULI.gaze_cue_correct;
        incorrect_target = STIMULI.gaze_cue_incorrect;
        incorrect_target.put( incorrect_location );
        correct_target.put( correct_location );
        incorrect_target.reset_targets();
        correct_target.reset_targets();
        
         %   SHIFT GAZE CUES DOWN
        correct_target.shift(0, GAZE_CUE_SHIFT_AMOUNT);
        incorrect_target.shift(0, GAZE_CUE_SHIFT_AMOUNT);
      end
      chosen_target = [];
      STRUCTURE.m2_chose = [];
      last_pulse = NaN;
      log_progress = true;
      lit_led = false;
      made_cue_error = false;
      did_show = false;
      did_show_choice = false;
      did_look = false;
      did_log_plex_progress = false;
      failed_to_choose_in_time = false;
      looked_away = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    fix_targ.update_targets();
    if ( is_m2 && is_gaze_trial )
      incorrect_target.update_targets();
      correct_target.update_targets();
      if ( ~did_show )
        incorrect_target.draw();
        correct_target.draw();
        Screen( 'Flip', opts.WINDOW.index );
        did_show = true;
      end
      if ( log_progress )
        PROGRESS.m2_target_onset = TIMER.get_time( 'task' );
        log_progress = false;
      end
      if ( correct_target.in_bounds() )
        if ( ~did_log_plex_progress )
          PROGRESS.gaze_cue_target_acquire = TIMER.get_time( 'task' );
          serial_comm.sync_pulse( 3 );
          did_log_plex_progress = true;
        end
        STRUCTURE.m2_chose = correct_is;
        tcp_comm.send_when_ready( 'choice', correct_is );
        did_look = true;
      elseif ( did_look )
        %   MARK: goto: error
        STATES.current = STATES.error;
        tcp_comm.send_when_ready( 'error', 3 );
        tcp_comm.send_when_ready( 'choice', 0 );
        tcp_comm.send_when_ready( 'state', STATES.current );
        looked_away = true;
        first_entry = true;
      end
      if ( incorrect_target.in_bounds() )
        errors.m2_wrong_target = true;
        if ( ~did_log_plex_progress )
          PROGRESS.gaze_cue_target_acquire = TIMER.get_time( 'task' );
          serial_comm.sync_pulse( 3 );
          did_log_plex_progress = true;
        end
        did_look = true;
        %   MARK: goto: error
        STATES.current = STATES.error;
        tcp_comm.send_when_ready( 'state', STATES.current );
        tcp_comm.send_when_ready( 'error', 3 );
        tcp_comm.send_when_ready( 'choice', incorrect_is );
        first_entry = true;
      end
      if ( correct_target.duration_met() )
        chosen_target = correct_target;
        STRUCTURE.m2_chose = correct_is;
        tcp_comm.send_when_ready( 'choice', correct_is );
        %   MARK: GOTO: fixation_delay
        STATES.current = STATES.fixation_delay;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    elseif ( is_m2 && ~is_gaze_trial )
      if ( ~lit_led )
        serial_comm.LED( led_location, opts.TIMINGS.LED );
        lit_led = true;
      end
      if ( ~did_show )
        fix_targ.draw();
        Screen( 'Flip', opts.WINDOW.index );
        did_show = true;
      end
      if ( ~fix_targ.in_bounds() )
        %   MARK: goto: error
        tcp_comm.send_when_ready( 'error', 3 );
        STATES.current = STATES.error;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    else
      Screen( 'Flip', opts.WINDOW.index );
    end
    if ( tcp_comm.consume('error') == 3 )
      %   MARK: goto: error
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    elseif ( TIMER.duration_met('time_to_cue_fixation') )
      if ( ~is_m2 )
        STATES.current = STATES.fixation_delay;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
      if ( isempty(STRUCTURE.m2_chose) && is_m2 )
        %   MARK: goto: error
        errors.m2_no_choice = true;
        tcp_comm.send_when_ready( 'choice', 0 );
        STATES.current = STATES.error;
        STRUCTURE.m2_chose = 0;
        failed_to_choose_in_time = true;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    end
  end
  
  %%   STATE FIXATION_DELAY
  if ( STATES.current == STATES.fixation_delay )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      if ( INTERFACE.DEBUG )
        disp( 'Entered fixation_delay' );
      end
      tcp_comm.await_matching_state( STATES.current );
      tcp_comm.consume( 'fix_met' );
      PROGRESS.fixation_delay = TIMER.get_time( 'task' );
      TIMER.set_durations( 'fixation_delay', Inf );
      TIMER.reset_timers( {'fixation_delay', 'pre_fixation_delay'} );
      m2_active_target = STIMULI.m2_second_fixation_picture;
      m2_active_target.reset_targets();
      did_show = false;
      did_look = false;
      is_fixating = 0;
      did_begin_timer = false;
      made_error = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    m2_active_target.update_targets();
    if ( ~did_show )
      m2_active_target.draw();
      Screen( 'Flip', opts.WINDOW.index );
      PROGRESS.fixation_delay_stim_onset = TIMER.get_time( 'task' );
      serial_comm.sync_pulse( 4 );
      did_show = true;
    end
    if ( m2_active_target.in_bounds() )
      is_fixating = 1;
      did_look = true;
%       if ( isnan(last_pulse) )
%         should_reward = true;
%       else
%         should_reward = toc( last_pulse ) > REWARDS.pulse_frequency/1e3;
%       end
%       if ( should_reward )
%         if ( INTERFACE.DEBUG )
%           disp( 'Rewarding ...' );
%         end
%         serial_comm.reward( 1, REWARDS.main );
%         last_pulse = tic;
%       end
    elseif ( did_look )
      errors.broke_fixation = true;
      made_error = true;
      tcp_comm.send_when_ready( 'error', 4 );
       %   MARK: goto: error
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
    tcp_comm.send_when_ready( 'fix_met', is_fixating );
    if ( INTERFACE.require_synch )
      other_is_fixating = tcp_comm.consume( 'fix_met' );
      other_is_fixating = ~isnan( other_is_fixating ) && other_is_fixating > 0;
    else
      other_is_fixating = 1;
    end
    if ( other_is_fixating && is_fixating )
      if ( ~did_begin_timer )
        TIMER.set_durations( 'fixation_delay', fixation_delay_time );
        TIMER.reset_timers( 'fixation_delay' );
        did_begin_timer = true;
      end
    end
    if ( tcp_comm.consume('error') == 4 )
      made_error = true;
      %   MARK: goto: error
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
    if ( TIMER.duration_met('fixation_delay') && ~made_error )
      %   MARK: goto: response
      STATES.current = STATES.response;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
    if ( TIMER.duration_met('pre_fixation_delay') && ~did_look )
      errors.m2_fix_delay_no_look = true;
      tcp_comm.send_when_ready( 'error', 4 );
      %   MARK: goto: error
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %%   STATE RESPONSE
  if ( STATES.current == STATES.response )
    if ( first_entry )
      Screen( 'Flip', opts.WINDOW.index );
      if ( INTERFACE.DEBUG )
        disp( 'Entered response' );
      end
      PROGRESS.m2_target_offset = TIMER.get_time( 'task' );
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.response = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'response' );
      response_target1 = STIMULI.response_target1;
      response_target2 = STIMULI.response_target2;
      response_target1.reset_targets();
      response_target2.reset_targets();
      m2_active_target = STIMULI.m2_second_fixation_picture;
      m2_active_target.reset_targets();
      if ( INTERFACE.IS_M1 )
        STRUCTURE.m2_chose = tcp_comm.await_data( 'choice' );
        if ( INTERFACE.DEBUG )
          fprintf( '\nM1: Received choice value %d\n', STRUCTURE.m2_chose );
        end
      else
        tcp_comm.consume( 'choice' );
      end
      STRUCTURE.m1_chose = [];
      did_show = false;
      made_error = false;
      first_entry = false;
    end
    TRACKER.update_coordinates();
    m2_active_target.update_targets();
    if ( INTERFACE.IS_M1 )
      response_target1.update_targets();
      response_target2.update_targets();
      if ( ~did_show )
        response_target1.draw();
        response_target2.draw();
        Screen( 'Flip', opts.WINDOW.index );
        did_show = true;
      end
      if ( response_target1.duration_met() )
        if ( INTERFACE.DEBUG )
          fprintf( '\nM1: made choice %d\n', 1 );
        end
        STRUCTURE.m1_chose = 1;
        %   MARK: goto: evaluate_choice
        STATES.current = STATES.evaluate_choice;
        tcp_comm.send_when_ready( 'choice', 1 );
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
      if ( response_target2.duration_met() )
        if ( INTERFACE.DEBUG )
          fprintf( '\nM1: made choice %d\n', 2 );
        end
        STRUCTURE.m1_chose = 2;
        %   MARK: goto: evaluate_choice
        STATES.current = STATES.evaluate_choice;
        tcp_comm.send_when_ready( 'choice', 2 );
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    else
      if ( ~did_show )
        m2_active_target.draw();
        Screen( 'Flip', opts.WINDOW.index );
        did_show = true;
      end
      if ( ~m2_active_target.in_bounds() )
        made_error = true;
        tcp_comm.send_when_ready( 'error', 5 );
        %   MARK: goto: error;
        STATES.current = STATES.error;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      else
%         if ( isnan(last_pulse) )
%           should_reward = true;
%         else
%           should_reward = toc( last_pulse ) > REWARDS.pulse_frequency/1e3;
%         end
%         if ( should_reward )
%           if ( INTERFACE.DEBUG )
%             disp( 'Rewarding ...' );
%           end
%           serial_comm.reward( 1, REWARDS.main );
%           last_pulse = tic;
%         end
      end
      received_m1_choice = tcp_comm.consume( 'choice' );
      if ( ~isnan(received_m1_choice) && ~made_error )
        if ( INTERFACE.DEBUG )
          fprintf( '\nM2: Received choice value: %d\n', received_m1_choice );
        end
        STRUCTURE.m1_chose = received_m1_choice;
        %   MARK: goto: evaluate_choice
        STATES.current = STATES.evaluate_choice;
        tcp_comm.send_when_ready( 'state', STATES.current );
        first_entry = true;
      end
    end
    if ( tcp_comm.consume('error') == 5 )
      %   MARK: goto: error;
      STATES.current = STATES.error;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    elseif ( TIMER.duration_met('response') )
      if ( INTERFACE.IS_M1 && isempty(STRUCTURE.m1_chose) )
        tcp_comm.send_when_ready( 'choice', 0 );
        STRUCTURE.m1_chose = 0;
      end
      if ( ~INTERFACE.IS_M1 && isnan(received_m1_choice) )
        received_m1_choice = tcp_comm.await_data( 'choice' );
        STRUCTURE.m1_chose = received_m1_choice;
        if ( INTERFACE.DEBUG )
          fprintf( '\nM2: Received choice value: %d\n', received_m1_choice );
        end
      end
      %   MARK: goto: evaluate_choice
      STATES.current = STATES.evaluate_choice;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %%   STATE EVALUATE_CHOICE
  if ( STATES.current == STATES.evaluate_choice )
    if ( first_entry )
      if ( INTERFACE.DEBUG )
        disp( 'Entered evaluate_choie' );
      end
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.evaluate_choice = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'evaluate_choice' );
      m1_chose = STRUCTURE.m1_chose;
      m2_chose = STRUCTURE.m2_chose;
      if ( INTERFACE.DEBUG)
        fprintf( '\nM1 chose: %d', m1_chose );
        fprintf( '\nM2 chose: %d', m2_chose );
      end
      both_made_choices = m1_chose ~= 0 && m2_chose ~= 0;
      %   a left choice (1) for m1 is a right choice (2) for m2. So, e.g,
      %   for a led trial, if the correct led location is 2, the
      %   correct choice for m1 is 1.
      matching_choices = both_made_choices && abs( m1_chose-m2_chose ) == 1;
      matching_laser = both_made_choices && abs( m1_chose-led_location ) == 1;
      if ( INTERFACE.IS_M1 )
        %   if trialtype is 'gaze', and choices match ...
        if ( strcmp(STRUCTURE.rule_cue_type, 'gaze') && matching_choices )
          serial_comm.reward( 1, REWARDS.main );
          serial_comm.reward( 2, REWARDS.main );
        %   if trialtype is 'led', and m1's choice matches laser_location
        elseif ( strcmp(STRUCTURE.rule_cue_type, 'led') && matching_laser )
          serial_comm.reward( 1, REWARDS.main );
          serial_comm.reward( 2, REWARDS.main );
        else
          if ( INTERFACE.DEBUG), disp( 'M1 was not correct' ); end;
        end
      end
      first_entry = false;
    end
    if ( TIMER.duration_met('evaluate_choice') )
      if ( ~INTERFACE.IS_M1 )
        for j = 1:REWARDS.iti_pulses
          serial_comm.reward( 1, REWARDS.main );
          WaitSecs( 0.05 );
        end
      end
      %   MARK: goto: iti
      STATES.current = STATES.iti;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %%   STATE ITI
  if ( STATES.current == STATES.iti )
    if ( first_entry )
      if ( INTERFACE.DEBUG )
        disp( 'Entered ITI' );
      end
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.iti = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'iti' );
      first_entry = false;
    end
    if ( TIMER.duration_met('iti') )
      %   MARK: goto: new_trial
      STATES.current = STATES.new_trial;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %%   STATE ERROR
  if ( STATES.current == STATES.error )
    if ( first_entry )
      if ( INTERFACE.DEBUG )
        disp( 'Entered error' );
      end
      Screen( 'Flip', opts.WINDOW.index );
      tcp_comm.await_matching_state( STATES.current );
      PROGRESS.error = TIMER.get_time( 'task' );
      TIMER.reset_timers( 'error' );
      if ( errors.initial_fixation_not_met )
        err_cue = STIMULI.fixation_error_cue;
      else
        err_cue = STIMULI.error_cue;
      end
      did_show = false;
      first_entry = false;
    end
    if ( ~did_show )
      err_cue.draw();
      Screen( 'Flip', opts.WINDOW.index );
      did_show = true;
    end
    if ( TIMER.duration_met('error') )
      %   MARK: goto: iti
      STATES.current = STATES.iti;
      tcp_comm.send_when_ready( 'state', STATES.current );
      first_entry = true;
    end
  end
  
  %%  EVERY ITERATION
  
  TRACKER.update_coordinates();  
  
  if ( INTERFACE.DEBUG )
    disp( TRACKER.coordinates );
  end
  
  if ( ~isempty(TRACKER.coordinates) && INTERFACE.IS_M1 )
    gaze_info = get_gaze_setup_info();
    roi_info = get_roi_info();
    pixel_coords = TRACKER.coordinates;
    in_bounds = debug__test_roi_2( pixel_coords, [0, 0, 3072, 768] ...
      , roi_info.eye_origin_far_verts, gaze_info );
    if ( in_bounds )
      func = @(x) serial_comm.reward(1, 50);
      debounce( 100/1e3, func );
    end
  end
  
  % - Update tcp_comm
  tcp_comm.update();
  if ( ~INTERFACE.IS_M1 )
    tcp_comm.send_when_ready( 'gaze', TRACKER.coordinates );
  else
    current_looks_m2 = tcp_comm.consume( 'gaze' );
    is_valid_looks = ~any( isnan(current_looks_m2) );
    % - Determine frame times.
    if ( is_valid_looks )
      if ( FRAMES.stp > 1 )
        FRAMES.current = TIMER.get_time( 'task' );
        FRAMES.delta = FRAMES.current - FRAMES.last;
        FRAMES.last = FRAMES.current;
        FRAMES.min = min( [FRAMES.min, FRAMES.delta] );
        FRAMES.max = max( [FRAMES.max, FRAMES.delta] );
        N1 = FRAMES.stp - 1;
        N2 = FRAMES.stp - 2;
        FRAMES.mean = (FRAMES.mean*N2 + FRAMES.delta) / N1;
      else
        FRAMES.last = TIMER.get_time( 'task' );
        FRAMES.mean = 0;
      end
      FRAMES.stp = FRAMES.stp + 1;
    end
  end
  
  % - If an error occurred, return to the new trial.
  if ( ~isnan(tcp_comm.consume('error')) )
    %   MARK: goto: error
    STATES.current = STATES.error;
    tcp_comm.send_when_ready( 'state', STATES.current );
    first_entry = true;
  end
  
  % - Update rewards  
  serial_comm.update();
  
  % - Quit if error in EyeLink
  success = TRACKER.check_recording();
  if ( success ~= 0 ), break; end;
  
  % - Check if key is pressed
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    % - Quit if stop_key is pressed
    if ( key_code(INTERFACE.stop_key) ), break; end;
    %   Deliver reward if reward key is pressed
    if ( key_code(INTERFACE.rwd_key) )
      if ( isnan(reward_key_timer) )
        should_reward = true;
      else
        should_reward = toc( reward_key_timer ) > REWARDS.iti/1e3;
      end
      if ( should_reward )
        serial_comm.reward( 1, REWARDS.iti );
        reward_key_timer = tic;
      end
    end
  end
  
  % - Quit if time exceeds total time
  if ( TIMER.duration_met('task') ), break; end;
end

TRACKER.shutdown();

if ( INTERFACE.save_data )
  data = struct();
  data.DATA = DATA;
  data.opts = opts;
  data.opts.FRAMES = FRAMES;
  save( fullfile(IO.data_folder, IO.data_file), 'data' );
end

end

function gaze_info = get_gaze_setup_info()

gaze_info.dist_to_monitor_cm = 100;
gaze_info.x_dist_to_monitor_cm = 20;
gaze_info.y_dist_to_monitor_cm = 20;

gaze_info.screen_dims_cm = [111.3, 30.5];
gaze_info.dist_to_roi_cm = 200;

end

function roi_info = get_roi_info()

import brains.util.gaze.*;

roi_info.eye_origin_far_img_rect = [-8, -8, 8, 8];
roi_info.local_verts = [0.7, 1.5, 14.7, 6.6];
roi_info.stim_width_cm = 16;
roi_info.stim_height_cm = 16;
roi_info.local_fractional_verts = ...
  get_fractional_vertices( roi_info.local_verts, [roi_info.stim_width_cm, roi_info.stim_height_cm] );
roi_info.eye_origin_far_verts = ...
  get_pixel_verts_from_fraction( roi_info.eye_origin_far_img_rect, roi_info.local_fractional_verts );

end

function align_stimuli_to_top(stim, scr_height_cm, offset, scr_height_px)
  cellfun( @(x) align_stimulus_to_top(x, scr_height_cm, offset, scr_height_px) ...
    , stim );
end

function align_stimulus_to_top(stim, scr_height_cm, offset_y_cm, screen_height_y_px)
current_height = stim.vertices(4) - stim.vertices(2);
stim.vertices([2, 4]) = [ 0, current_height ];

for i = 1:numel(stim.targets)
  new_y0 = get_target_offset(scr_height_cm, offset_y_cm, screen_height_y_px);
  new_y1 = new_y0 + current_height;
  stim.targets{i}.bounds(2) = new_y0;
  stim.targets{i}.bounds(4) = new_y1;
end

end

function pixel_offset = get_target_offset( scr_height_cm, offset_y_cm, screen_height_y_px )

pixel_offset = (offset_y_cm / scr_height_cm) * screen_height_y_px;

end

function debounce( amt, func, varargin )

persistent last_call;

if ( isempty(last_call) )
  func( varargin{:} );
  last_call = tic();
else
  if ( toc(last_call) > amt )
    func( varargin{:} );
    last_call = tic();
  end
end

end