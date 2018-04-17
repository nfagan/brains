function conf = reconcile(conf)

if ( nargin < 1 )
  conf = brains.config.load(); 
end

display = false;
missing = brains.config.diff( conf, display );

if ( isempty(missing) )
  return;
end

%   don't save
do_save = false;
created = brains.config.create( do_save );

for i = 1:numel(missing)
  current = missing{i};
  eval( sprintf('conf%s = created%s;', current, current) );
end

end