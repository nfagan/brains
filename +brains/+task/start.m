function err = start(is_master_arduino, is_master_monkey)

try
  opts = brains.task.setup( is_master_arduino, is_master_monkey );
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