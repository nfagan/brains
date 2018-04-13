config_p = 'C:\Repositories\brains\config\config_files\m2\';

fname = fullfile( config_p, 'Ephron_FIXATION_TaskTraining.mat' );

conf = shared_utils.io.fload( fname );

non_editable_properties = {{ 'placement', 'has_target' }};

conf.STIMULI.m2_wrong_cue = struct( ...
    'class',            'Rectangle' ...
  , 'size',             [ 300 ] ...
  , 'color',            [ 0 255 0 ] ...
  , 'placement',        'center' ...
  , 'has_target',       false ...
  , 'non_editable',     non_editable_properties ...
);

conf.SERIAL.outputs.reward = [ 2, 1 ];

save( fname, 'conf' );

%%

config_mats = shared_utils.io.find( config_p, '.mat', true );

for i = 1:numel(config_mats)
  conf = shared_utils.io.fload( config_mats{i} );
  
  if ( isfield(conf.CALIBRATION, 'far_plane_type') )
    continue;
  end
  
  conf.CALIBRATION.far_plane_type = 'outer';
  
  save( config_mats{i}, 'conf' );
end