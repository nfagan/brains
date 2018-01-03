function close_ports()

s = instrfind();
if ( ~isempty(s) )
  fclose( s );
end

end