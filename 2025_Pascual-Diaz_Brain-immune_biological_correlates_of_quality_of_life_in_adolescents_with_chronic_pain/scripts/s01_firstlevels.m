%% 0. Cleaning workspace
clc
clear

%% 1. Datasets and paths

whosample_pat = [{'sub-1001'};{'sub-1002'}];
% [{'sub-1001'};{'sub-1002'}, etc...];

%% Global paths
sprint_dir = '/path/to/data';
git_dir = '/path/to/git/scripts';
input_dir = [sprint_dir '/CONN_main_preprocessing/data_task']; 
conf_pref = [input_dir '/art_regression'];
output_dir = '/path/to/output';

%% Onset file
onsets_path = '/path/to/multisensory_onsets.csv';
onsets = readtable(onsets_path);

%% Run first-levels
for i = 1:size(whosample_pat, 1)
    s_name = whosample_pat{i};
    ID = s_name(5:8);
    input_file = [input_dir '/dswu' s_name '_task-multisensory_bold.nii'];
    output_sdir = [output_dir '/' s_name];

    % CONFOUNDS %%%%%%%%%%%%%%%
    % Subject confounds
    FDs_path = [conf_pref '_timeseries_usub-' ID '_task-multisensory_bold.mat'];
    spikes_path = [conf_pref '_outliers_usub-' ID '_task-multisensory_bold.mat'];
    if ~isfile(FDs_path)
        disp(['Confounds file not found for subject: ' num2str(ID) FDs_path]);
        continue
    end

    if ~exist(output_sdir)
        mkdir(output_sdir)
    else
        continue
    end

    FDs = load(FDs_path).R(:,2);
    if isfile(spikes_path)
        spikes = load(spikes_path).R;
        % Filtering spikes
        spikes_sum = sum(spikes, 2);
        count = 0;
        new_cluster = 0;
        for i = 1:size(spikes, 1)
            if spikes_sum(i) == 1
                if new_cluster == 0
                    new_cluster = 1;
                    count = count + 1;
                end
            end
            if spikes_sum(i) == 0
                if new_cluster == 1
                    new_cluster = 0;
                end
            end
        end
        
        spikes_filtered = zeros(size(spikes, 1), count);
        count = 0;
        new_cluster = 0;
        for i = 1:size(spikes, 1)
            if spikes_sum(i) == 1
                if new_cluster == 0
                    new_cluster = 1;
                    count = count + 1;
                    spikes_filtered(i,count) = 1;
                else
                    spikes_filtered(i,count) = 1;
                end
            end
            if spikes_sum(i) == 0
                if new_cluster == 1
                    new_cluster = 0;
                end
            end
        end
 
        c = [FDs spikes_filtered];
    else
        c = FDs;
    end

    conf = [output_dir '/conf/conf-FDSpikes_usub-' ID '_task-multisensory_bold.txt'];
    writetable(array2table(c),conf,'WriteVariableNames',0);

    % Subject onsets
    subject_onsets = onsets(ismember(onsets.sid, ['SPRINT-' ID]),:);
    
    multisensory_onsets = [ subject_onsets.multisensory_onset_1; ...
        subject_onsets.multisensory_onset_2; ...
        subject_onsets.multisensory_onset_3; ...
        subject_onsets.multisensory_onset_4];
    
    multisensory_durations = [ subject_onsets.multisensory_duration_1; ...
        subject_onsets.multisensory_duration_2; ...
        subject_onsets.multisensory_duration_3; ...
        subject_onsets.multisensory_duration_4];
    
    VAS_onsets = [ subject_onsets.VAS_onset_1; ...
        subject_onsets.VAS_onset_2; ...
        subject_onsets.VAS_onset_3; ...
        subject_onsets.VAS_onset_4];
    
    VAS_durations = [ subject_onsets.VAS_duration_1; ...
        subject_onsets.VAS_duration_2; ...
        subject_onsets.VAS_duration_3; ...
        subject_onsets.VAS_duration_4];
        
    % SPM job definition for first level
    matlabbatch{1}.spm.stats.fmri_spec.dir = {output_sdir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.5;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t = 16;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 8;
    matlabbatch{1}.spm.stats.fmri_spec.sess.scans = {input_file};
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name = 'Multisensory';
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = multisensory_onsets;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = multisensory_durations;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name = 'VAS_Unpleas';
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = VAS_onsets;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = VAS_durations;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).orth = 1;
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi = {''};
    matlabbatch{1}.spm.stats.fmri_spec.sess.regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {conf};
    matlabbatch{1}.spm.stats.fmri_spec.sess.hpf = 180;
    matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0; % Change to 0.8 for masking
    matlabbatch{1}.spm.stats.fmri_spec.mask = {'/path/to/MNI152_T1_2mm_brainmask.nii'};
    matlabbatch{1}.spm.stats.fmri_spec.cvi = 'none';

    % Estimation step
    matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('fMRI model specification: SPM.mat File', ...
        substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
        substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
    matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;

    % Contrast definition
    matlabbatch{3}.spm.stats.con.spmmat(1) = cfg_dep('Model estimation: SPM.mat File', ...
        substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), ...
        substruct('.','spmmat'));
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Activation_Multisensory';
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
    matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Deactivation_Multisensory';
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = -1;
    matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
    matlabbatch{3}.spm.stats.con.delete = 0;
    
    % Run the SPM job
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);

    disp(['First level analysis completed for subject: ' ID]);
end
