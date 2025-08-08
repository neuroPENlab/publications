% Job Script for T-test Analysis with Covariates
% Author: Maria Sunol, 2022
% This script sets up the job for a two-sample T-test analysis using SPM12
% It includes factorial design setup with covariates (Age and Total GM) and contrast specification.

% Prompt user for directories (for input data and templates)
data_dir = uigetdir('Select the directory containing the input data files'); % Select input data directory
template_dir = uigetdir('Select the directory containing SPM templates'); % Select directory containing SPM templates

% Set up the factorial design (group comparisons with covariates)
matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = {
    fullfile(data_dir, 'Controls', 'Preprocess_C', 'smwc1subject_001_data.nii,1')  % Adjust for subject 1 data
    fullfile(data_dir, 'Controls', 'Preprocess_C', 'smwc1subject_002_data.nii,1')  % Adjust for subject 2 data
    % Add more subjects as needed
};

% Set up the second group (JFM) for the comparison
matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = {
    fullfile(data_dir, 'JFM', 'Preprocess_JFM', 'smwc1subject_005_data.nii,1')  % Adjust for subject 1 data
    fullfile(data_dir, 'JFM', 'Preprocess_JFM', 'smwc1subject_006_data.nii,1')  % Adjust for subject 2 data
    % Add more subjects as needed
};

% Covariates (Age and Total GM)
matlabbatch{1}.spm.stats.factorial_design.cov(1).c = [17.8, 17.4, 16.4, 16.2, 17.2, 15.4, 15.8, 17.9, 18, 15.9]; % Example Age data
matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'Age';  % Covariate name
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;  % Centered First Moment
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;   % Include in the covariance model

% Total GM covariate
matlabbatch{1}.spm.stats.factorial_design.cov(2).c = [857.93, 718.29, 813.27, 701.95, 719.18, 819.8]; % Example Total GM data
matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'TotalGM';  % Covariate name
matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI = 1;  % Centered First Moment
matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;   % Include in the covariance model

% Specify masking and global scaling options
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tma.athresh = 0.2;  % Threshold for tissue masking
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;  % Omit global normalization
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;  % No global scaling for GM data
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;  % Global normalization option

% Contrast specification
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'C>JFM';  % Contrast: Controls > JFM
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 -1];  % Weight for the contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';  % No session repetition

matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'C<JFM';  % Contrast: Controls < JFM
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [-1 1];  % Weight for the contrast
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';  % No session repetition

matlabbatch{3}.spm.stats.con.delete = 0;  % Keep the contrast in the output
