function latest_dir = get_latest_data_dir(conf, date_fmt)

if ( nargin < 1 ), conf = brains.config.load(); end
if ( nargin < 2 ), date_fmt = 'mmddyy'; end

data_dir = fullfile( conf.IO.repo_folder, 'brains', 'data' );
shared_utils.assertions.assert__is_dir( data_dir );
dirs = shared_utils.io.dirnames( data_dir, 'folders' );

dirs = dirs( cellfun(@(x) numel(x) == numel(date_fmt), dirs) );

valid = false( size(dirs) );
nums = zeros( size(dirs) );

for i = 1:numel(dirs)
  try
    nums(i) = datenum( dirs{i}, date_fmt );
    valid(i) = true;
  catch err
    valid(i) = false;
  end
end

dirs = dirs( valid );

if ( isempty(dirs) ), return; end

[~, I] = sort( nums, 'descend' );

latest_dir = dirs{I};

end