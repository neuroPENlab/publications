% Script for Running SPM T-test with Covariates' job
% Author: Maria Sunol, 2022
% This script runs the T-test analysis for GM differences between groups
% It prompts the user to select the necessary directories and inputs dynamically.

% List of open inputs
nrun = X; % Enter the number of runs here (X = number of subjects or conditions)
jobfile = {'Ttest_GM_JFMvsC_CovarAgeTotalGM_job.m'}; % Job file without hardcoded path
jobs = repmat(jobfile, 1, nrun); % Replicate the job for each run
inputs = cell(0, nrun); % Initialize the inputs cell array

% Prompt user for directories
data_dir = uigetdir('Select the directory containing the input data files'); % Data directory selection
output_dir = uigetdir('Select the output directory for the analysis results'); % Output directory selection

% Loop through each subject or condition to set the inputs dynamically
for crun = 1:nrun
    % Generate the full path for each subject's data dynamically
    inputs{1, crun} = {fullfile(data_dir, ['subject_' num2str(crun) '_data.nii'])};  % Adjust subject filenames
end

% Set the output directory for the analysis
matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir}; 

% Run the job using SPM
spm('defaults', 'FMRI'); % Set SPM defaults for fMRI
spm_jobman('run', jobs, inputs{:}); % Run the job with inputs
