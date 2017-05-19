classdef Client < brains.server.IPInterface
  
  properties
  end
  
  methods
    function obj = Client(address, port)
      
      obj = obj@brains.server.IPInterface( address, port, 'client' );
    end
  end
  
end