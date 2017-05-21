function err = start(opts)

try
%   opts = brains.task.setup( opts );
  opts = brains.task.setup2();
catch err
  brains.task.cleanup();
  brains.util.print_error_stack( err );
  return;
end

try
  err = 0;
  brains.task.run( opts );
  brains.task.cleanup();
catch err
  brains.task.cleanup();
  brains.util.print_error_stack( err );
end

end