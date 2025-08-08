% Script for Preprocessing sMRI Data with SPM12
% Author: Maria Sunol, 2022
% This script runs the preprocessing job for multiple subjects, allowing
% the user to select directories dynamically to ensure portability.

% List of open inputs
nrun = X; % Enter the number of runs here, X corresponds to the number of subjects
jobfile = {'Preprocess_sMRI_VBM_DARTEL_job.m'};  % Job file without hardcoded path for portability
jobs = repmat(jobfile, 1, nrun); % Replicate the job file for each run
inputs = cell(0, nrun); % Initialize the inputs cell array

% Prompt user for directories
data_dir = uigetdir('Select the directory containing the input data files'); % Data directory selection
template_dir = uigetdir('Select the directory containing SPM templates'); % SPM template directory selection

% Loop through each subject and set the inputs dynamically
for crun = 1:nrun
    % Generate the full path for each subject's data dynamically
    inputs{1, crun} = {fullfile(data_dir, ['subject_' num2str(crun) '_data.nii'])};  % Adjust subject filenames
end

% Run the preprocessing job using the selected directories and generated inputs
spm('defaults', 'FMRI'); % Set SPM defaults for fMRI
spm_jobman('run', jobs, inputs{:}); % Run the preprocessing job with inputs
