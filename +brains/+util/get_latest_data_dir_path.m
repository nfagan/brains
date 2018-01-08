function p = get_latest_data_dir_path()

conf = brains.config.load();
p = fullfile( conf.IO.data_folder, datestr(now, 'mmddyy') );

end