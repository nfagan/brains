function err = start(task_name)

%   START -- Start a task.
%
%     IN:
%       - `task_name` |OPTIONAL| -- Name of the task to start.
%     OUT:
%       - `err` (MException, double) -- The thrown error if one occurs,
%       else 0.

if ( nargin == 0 ), task_name = 'main'; end

try
  opts = brains.task.setup();
catch err
  brains.task.cleanup();
  brains.util.print_error_stack( err );
  return;
end

try
  err = 0;
  switch ( task_name )
    case 'main'
      brains.task.run( opts );
    case 'fixation'
      brains.task.run_fixation( opts );
    otherwise
      error( 'Unrecognized task name ''%s''', task_name );
  end
  brains.task.cleanup();
catch err
  brains.task.cleanup();
  brains.util.print_error_stack( err );
end

end