function cleanup()

sca;
brains.util.close_ports();
ListenChar( 0 );
try
  Eyelink( 'StopRecording' )
catch err
  fprintf( '\n The following error occurred when attempting to stop recording:' );
  fprintf( err.message );
end

end