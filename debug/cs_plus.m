function cs_plus()

%   RUN -- Run the task based on the saved config file options.
%
%     IN:
%       - `opts` (struct)

repo_dir = '/Volumes/My Passport/NICK/Chang Lab 2016/repositories';

addpath( genpath(fullfile(repo_dir, 'ptb_helpers')) );

edf_file = 'a.edf';
edf_folder = pwd;

tracker = EyeTracker( edf_file, edf_folder, 0 );
tracker.bypass = true;

try
  main( tracker );
catch err
  cleanup( tracker );
  throwAsCaller( err );
end

end

function main(tracker)

% addpath( '/path/to/ptb_helpers' );
% addpath( '/path/to/psychtoolbox' );
% addpath( '/path/to/example_task' );

timer = Timer();

timer.add_timer( 'fixation', Inf );
timer.add_timer( 'success', 1 );
timer.add_timer( 'task', Inf );

tracker.init();

window_size = [0, 0, 400, 400];
[window_index, window_size] = Screen( 'OpenWindow', 0, [0, 0, 0], window_size );

fix_targ = Rectangle( window_index, window_size, [10, 10] );
fix_targ.make_target( tracker, 1 );

current_state = 'fixation';
first_entry = true;

stop_key = KbName( 'escape' );
rwd_key = KbName( 'r' );

ListenChar( 2 );

while ( true )

  tracker.update_coordinates();
  fix_targ.update_targets();

  if ( strcmp(current_state, 'fixation') )
    if ( first_entry )
      disp( 'Entered fixation!' );
      Screen( 'Flip', window_index );
      timer.reset_timers( 'fixation' );
      fix_targ.reset_targets();
      fix_targ.put( 'center' );
      drew_fix_targ = false;
      first_entry = false;
    end
    if ( ~drew_fix_targ )
      fix_targ.draw();
      Screen( 'Flip', window_index );
      drew_fix_targ = true;
    end
    if ( fix_targ.duration_met() )
      current_state = 'success';
      first_entry = true;
    end
  end

  if ( strcmp(current_state, 'success') )
    if ( first_entry )
      disp( 'Entered success!' );
      timer.reset_timers( 'success' );
      Screen( 'Flip', window_index );
      first_entry = false;
    end
    if ( timer.duration_met('success') )
      current_state = 'fixation';
      first_entry = true;
    end
  end

  %   Quit if error in EyeLink
  err = tracker.check_recording();
  if ( err ~= 0 ), break; end

  % - Check if key is pressed
  [key_pressed, ~, key_code] = KbCheck();
  if ( key_pressed )
    if ( key_code(stop_key) ), break; end
    if ( key_code(rwd_key) )
      disp( 'Would reward!' );
    end
  end

  %   Quit if time exceeds total time
  if ( timer.duration_met('task') ), break; end
end
  
cleanup( tracker );

end

function cleanup(tracker)

if ( nargin >= 1 && ~isempty(tracker) )
  tracker.shutdown();
end

ListenChar( 0 );
sca;

end