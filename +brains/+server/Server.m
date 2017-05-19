classdef Server < brains.server.IPInterface
  
  properties
  end
  
  methods    
    function obj = Server(address, port)
      
      obj = obj@brains.server.IPInterface( address, port, 'server' );
    end
  end
  
end
  
  