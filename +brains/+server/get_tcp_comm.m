function tcp_comm = get_tcp_comm()

%   GET_TCP_COMM -- Get an instantiated IPInterface object.
%
%     See also brains.server.IPInterface
%
%     OUT:
%       - `tcp_comm` (IPInterface)

conf = brains.config.load();

INTERFACE = conf.INTERFACE;
TCP = conf.TCP;
IS_MASTER = INTERFACE.is_master_arduino;

if ( IS_MASTER )
  tcp_comm_constructor = @brains.server.Server;
  address = TCP.client_address;
else
  tcp_comm_constructor = @brains.server.Client;
  address = TCP.server_address;
end

tcp_port = TCP.port;
tcp_comm = tcp_comm_constructor( address, tcp_port );
tcp_comm.bypass = ~INTERFACE.require_synch;

end