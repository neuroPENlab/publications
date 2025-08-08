% Job Script for Preprocessing sMRI Data with SPM12 (DARTEL workflow)
% Author: Maria Sunol, 2022
% This script sets up the job for preprocessing sMRI data using the SPM12 DARTEL workflow.
% It includes segmentation and normalization steps with a dynamic setup for flexibility.

% Prompt user for directories
data_dir = uigetdir('Select the directory containing the input data files'); % Select directory with input data
template_dir = uigetdir('Select the directory containing SPM templates'); % Select directory with SPM TPM (tissue probability maps)

% Set up channel data for each subject (dynamic file paths)
matlabbatch{1}.spm.spatial.preproc.channel.vols = {
    fullfile(data_dir, 'subject_001_data.nii,1')  % Modify for subject 1 data file
    fullfile(data_dir, 'subject_002_data.nii,1')  % Modify for subject 2 data file
    % Add more subjects as needed
};

% Set bias regularization and other preprocessing parameters
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;  % Bias regularization parameter
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;    % Full-width half-maximum for bias field smoothing
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];     % Do not write bias-corrected images

% Load tissue probability maps (TPM) dynamically from the selected template directory
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(template_dir, 'TPM.nii,1')};  % Modify according to TPM location
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;  % Number of Gaussians for tissue type 1 (background)
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 1];  % Native resolution for tissue type 1
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];  % Do not warp tissue type 1

% Repeat for other tissue types
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(template_dir, 'TPM.nii,2')};
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 1];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];

% Set preprocessing warp settings for normalization
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;  % Use Modulated Resampling Field for warping
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;  % Clean up after warping
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];  % Regularization parameters for warping
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';  % Use MNI space for affine registration
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;  % No smoothing during warping
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;  % Sampling ratio
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];  % Do not write warped images
matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;  % No specific voxel size
matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN; NaN NaN NaN];  % No bounding box for warped images

% Dartel flow setup (using segmentation results as input)
matlabbatch{2}.spm.tools.dartel.warp.images{1}(1) = cfg_dep('Segment: rc1 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','rc', '()',{':'}));
% Repeat for other tissue types (rc2, rc3, etc.)

% MNI normalization setup for Dartel (adjust flow fields and images)
matlabbatch{3}.spm.tools.dartel.mni_norm.template{1} = cfg_dep('Run Dartel (create Templates): Template (Iteration 6)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','template', '()',{7}));
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subjs.flowfields(1) = cfg_dep('Run Dartel (create Templates): Flow Fields', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files', '()',{':'}));
% Repeat for other subjects' images as needed
matlabbatch{3}.spm.tools.dartel.mni_norm.data.subjs.images{1}(1) = cfg_dep('Segment: c1 Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','tiss', '()',{1}, '.','c', '()',{':'}));

% Additional MNI normalization settings
matlabbatch{3}.spm.tools.dartel.mni_norm.vox = [NaN NaN NaN];
matlabbatch{3}.spm.tools.dartel.mni_norm.bb = [NaN NaN NaN; NaN NaN NaN];
matlabbatch{3}.spm.tools.dartel.mni_norm.preserve = 1;  % Preserve original image dimensions
matlabbatch{3}.spm.tools.dartel.mni_norm.fwhm = [8 8 8];  % Apply smoothing during MNI normalization
