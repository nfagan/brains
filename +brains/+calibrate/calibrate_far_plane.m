function keys = calibrate_far_plane( pts, light_dur )

%   CALIBRATE_FAR_PLANE -- Calibrate with distant LEDs.
%
%     keys = ... calibrate_far_plane( 1:3 ) enables the first 3 LED
%     far-plane targets. Pressing 1, 2, or 3 on the number pad activates
%     that target, and lights up the corresponding LED. Pressing return
%     captures the current gaze coordinates and associates them with
%     the active target, returning the results in `keys`.
%
%     IN:
%       - `pts` (double)
%     OUT:
%       - `keys` (struct)

assert( ~isempty(pts), 'Points can''t be empty.' );
arrayfun( @(x) assert(isa(x, 'double') && mod(x, 1) == 0 ...
      , 'Points must be whole-number doubles.'), pts );

    
try
  fprintf( '\n Initializing ... ' );
  
  conf = brains.config.load();

  tracker = EyeTracker( '~', cd, 0 );
  tracker.bypass = ~conf.INTERFACE.use_eyelink;
  tracker.link_gaze();
  tracker.start_recording();

  reward_comm = brains.arduino.get_serial_comm();
  reward_comm.bypass = ~conf.INTERFACE.use_arduino;
%   reward_comm.bypass = true;
  reward_comm.start();
  
  led_comm = brains.arduino.get_led_calibration_serial_comm();
  led_comm.start();

  KbName( 'UnifyKeyNames' );
  ListenChar( 2 );
  reward_key_timer = NaN;
  keys = struct();

  for i = 1:numel(pts)
    keys.(sprintf('key__%d', pts(i))) = struct( ...
        'coordinates', [0, 0] ...
      , 'was_pressed', false ...
      , 'key_code', KbName(sprintf('%d', pts(i))) ...
      , 'led_index', pts(i) ...
      , 'timer', NaN ...
      );
  end
  
  if ( nargin < 2 )
    LED_DURATION = 1000; % ms
  else
    LED_DURATION = light_dur;
  end

  key_debounce_time = 0.2; % s
  accept_key = KbName( 'return' );
  key_fields = fieldnames( keys );
  active_field = key_fields{1};
  
  target_size = 20;
  first_targ_color = 2;
  target_colors = first_targ_color:(first_targ_color+numel(key_fields)-1);
  
  fprintf( 'Done.' );
  
  task();
  cleanup();
catch err
  brains.util.print_error_stack( err );
  cleanup();
end

%
% task
%

function task()

fprintf( '\n Listening ...' );
  
while ( true )  
  last_coords = tracker.coordinates;
  tracker.update_coordinates();
  reward_comm.update();
  led_comm.update();
  if ( isempty(tracker.coordinates) )
    tracker.coordinates = last_coords;
  end
  should_abort = handle_key_press();
  if ( should_abort ), break; end
end

all_pressed = true;

for ii = 1:numel(key_fields)
  if ( ~keys.(key_fields{ii}).was_pressed )
    fprintf( '\nWARNING: ''%s'' was never registered.', key_fields{ii} );
    all_pressed = false;
  end
end

if ( all_pressed )
  fprintf( '\n OK: All targets registered.' );
end

end

%
% key press handling
%

function should_abort = handle_key_press()
  should_abort = false;
  known_key = false;
  
  [key_pressed, ~, key_code] = KbCheck();
  
  if ( ~key_pressed ), return; end
  
  if ( key_code(conf.INTERFACE.stop_key) )
    should_abort = true;
    return; 
  end
  
  if ( key_code(conf.INTERFACE.rwd_key) )
    if ( isnan(reward_key_timer) )
      should_reward = true;
    else
      should_reward = toc( reward_key_timer ) > conf.REWARDS.main/1e3;
    end
    if ( should_reward )
      reward_comm.reward( 1, conf.REWARDS.main );
      reward_key_timer = tic;
    end
    known_key = true;
  end
  
  for i_ = 1:numel(key_fields)
    current = keys.(key_fields{i_});
    if ( key_code(current.key_code) )
      if ( isnan(current.timer) || toc(current.timer) > key_debounce_time )
        fprintf( '\n Activated ''%s''.', key_fields{i_} );
        led_comm.light( current.led_index, LED_DURATION );
        active_field = key_fields{i_};
        keys.(key_fields{i_}).timer = tic();
      end
      known_key = true;
      break;
    end
  end
  
  if ( key_code(accept_key) )
    current = keys.(active_field);
    if ( isnan(current.timer) || toc(current.timer) > key_debounce_time )
      fprintf( '\n Registered ''%s''.', active_field );
      if ( ~current.was_pressed )
        keys.(active_field).was_pressed = true;
      end
      keys.(active_field).coordinates = tracker.coordinates;
      keys.(active_field).timer = tic();
      brains.util.draw_far_plane_rois( keys, target_size, target_colors, tracker.bypass );
    end
    known_key = true;
  end
  
  if ( ~known_key )
    key_name = KbName( find(key_code, 1, 'first') );
    fprintf( '\n WARNING: Unregistered key ''%s''.', key_name );
  end
end

%
% cleanup
%

function cleanup()
  ListenChar( 0 );
  led_comm.close();
  reward_comm.close();
  tracker.stop_recording();
end

end