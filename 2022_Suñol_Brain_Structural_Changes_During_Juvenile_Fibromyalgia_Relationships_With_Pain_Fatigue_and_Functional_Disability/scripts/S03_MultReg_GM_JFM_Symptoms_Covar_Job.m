% Job Script for Regression Analysis with Covariates (Generalized)
% Author: Maria Sunol, 2022
% This script sets up the job for a regression analysis with user-defined
% variables of interest and covariates. It includes factorial design 
% setup with multiple covariates and contrast specification.

% Prompt user for directories (for input data and templates)
data_dir = uigetdir('Select the directory containing the input data files'); % Select input data directory
template_dir = uigetdir('Select the directory containing SPM templates'); % Select directory containing SPM templates

% Set up the regression design (user-defined variable of interest)
matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = {
    fullfile(data_dir, 'subject_001_data.nii,1')  % Adjust for subject 1 data
    fullfile(data_dir, 'subject_002_data.nii,1')  % Adjust for subject 2 data
    % Add more subjects as needed
};

% User input for covariates (create a loop or manual entry as needed)
for idx = 1:length(covariates)
    % Example: Add covariate data for each covariate dynamically
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov(idx).c = eval(covariates{idx});  % Use the covariate data input
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov(idx).cname = covariates{idx};  % Covariate name
    matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov(idx).iCC = 1;  % Include covariate in the model
end

% Masking and global scaling options
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tma.athresh = 0.2;  % Threshold for tissue masking
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;  % Omit global normalization
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;  % No global scaling for GM data
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;  % Global normalization option

% Specify the contrasts
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = ['Pos_' var_of_interest];  % Contrast name based on variable of interest
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 repmat(0, 1, length(covariates))];  % Weights for the contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';  % No session repetition

matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = ['Neg_' var_of_interest];  % Negative contrast name
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [-1 repmat(0, 1, length(covariates))];  % Negative contrast weights
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';  % No session repetition

matlabbatch{3}.spm.stats.con.delete = 0;  % Keep the contrast in the output
