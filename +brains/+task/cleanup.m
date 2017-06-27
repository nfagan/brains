function cleanup()

sca;
brains.arduino.close_ports();
ListenChar( 0 );
try
  if ( Eyelink('IsConnected') && Eyelink('CheckRecording') == 0 )
    Eyelink( 'StopRecording' );
  end
catch err
  fprintf( '\n The following error occurred when attempting to stop recording:' );
  fprintf( err.message );
end

end