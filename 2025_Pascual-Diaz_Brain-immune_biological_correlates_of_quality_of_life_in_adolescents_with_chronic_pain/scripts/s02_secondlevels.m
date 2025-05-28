clear
clc

%% 1. Datasets and paths
% Paths //SPM_GLM_firstlevels
pedsql_dir = '/path/to/SPRINT';
git_dir = '/path/to/github';

%Output dir
output_dir = ['/path/to/output'];

%% 2. Loading covariables
cov_path = ['/path/to/covariates.csv'];
cov = readtable(cov_path);

%% 3. Second levels variables

cov_name = 'pedsq_physical';

for i = 1:size(cov, 1)
    s_name = char(cov.sid(i));
    s_ID = s_name(8:11);
    s_covs = cov(ismember(cov.sid, s_name),:);
    s_cov = s_covs(:,cov_name);
    in_file = ['path/to/SPM_GLM_firstlevels/sub-' num2str(s_ID) '/ses-baseline/func/con_0001.nii'];
    if ~isfile(in_file)
        continue
    end

    if isnan(table2array(s_cov)) == 1
        continue
    end

    if exist('s_filelist','var')
        cov_list = [cov_list; table2array(s_cov)];
    else
        cov_list = table2array(s_cov);
        s_filelist = char(in_file);
    end
end
s_filelist = cellstr(s_filelist);
brainmask_path = '/path/to/brainmask.nii';
%%

% Run the SPM job
matlabbatch{1}.spm.stats.factorial_design.dir = {'output_dir'};

%%
matlabbatch{1}.spm.stats.factorial_design.des.mreg.scans = ['s_filelist'];

%%
matlabbatch{1}.spm.stats.factorial_design.des.mreg.mcov = struct('c', {}, 'cname', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.des.mreg.incint = 1;
%%
matlabbatch{1}.spm.stats.factorial_design.cov(1).c = ['cov_list'];

%%
matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'cov_name';
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;
matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;

matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 'none';
matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {'brainmask_path'};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = [cov_name '_pos'];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [0 1 0];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = [cov_name '_neg'];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = [0 -1 0];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;
spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);
