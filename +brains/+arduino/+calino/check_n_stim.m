function n = check_n_stim(stim_comm)

ids = brains.arduino.calino.get_ids();

print_n_stim = ids.stim_params.print_n_stim;
ack = ids.ack;
err_id = ids.error;

fprintf( stim_comm, print_n_stim );

res = '';
timeout_check = tic();
max_wait = 5;
should_continue = true;

while ( should_continue )
  if ( stim_comm.BytesAvailable > 0 )
    some = fread( stim_comm, stim_comm.BytesAvailable, 'char' );
    some = char( some );
    ack_ind = some == ack;
    
    if ( ~any(ack_ind) )
      subset = some(:)';
    else
      ack_ind = find( ack_ind );
      subset = some(1:ack_ind-1)';
      should_continue = false;
    end
    
    res = [ res, subset ];
    
    should_continue = should_continue && toc(timeout_check) < max_wait;    
  end
end

err_ind = res == err_id;

n = str2double( res(~err_ind) );

end