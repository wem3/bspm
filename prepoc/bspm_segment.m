function matlabbatch = bspm_segment(in, varargin)
% BSPM_SEGMENT
%
%   USAGE: matlabbatch = bspm_segment(in, varargin)
%
%   ARGUMENTS:
%      in = cell array containing paths to all images to segment
%
%   Tissue Classes: 
%      1 - grey matter
%      2 - white matter
%      3 - CSF
%      4 - bone
%      5 - soft tissue
%      6 - background
%

% ------------------------- Copyright (C) 2014 -------------------------
%	Author: Bob Spunt
%	Affilitation: Caltech
%	Email: spunt@caltech.edu
%
%	$Revision Date: Aug_20_2014
if nargin < 1, disp('USAGE: matlabbatch = bspm_segment(in, varargin)'); return; end
if ischar(in), in = cellstr(in); end
def = { 'dartel_imported',  [1 1 0 0 0 0], ...
        'native_space',     [0 0 0 0 0 0], ...
        'ngaus',            [1 1 2 3 4 2], ...
        'forward_deform',   0, ...
        'inverse_deform',   0, ...
        'biasfield',        0, ...
        'biascorrected',    0 };
bspm_setdefaults(def, varargin); 
in      = strcat(in, ',1'); 
spm_dir = fileparts(which('spm'));
TPMimg  = fullfile(spm_dir, 'tpm', 'TPM.nii');

% | JOB
matlabbatch{1}.spm.spatial.preproc.channel.vols     = in; 
matlabbatch{1}.spm.spatial.preproc.channel.biasreg  = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write    = [biasfield biascorrected];
for i = 1:6
    matlabbatch{1}.spm.spatial.preproc.tissue(i).tpm    = {sprintf('%s,%d', TPMimg, i)};  
    matlabbatch{1}.spm.spatial.preproc.tissue(i).ngaus  = ngaus(i);
    matlabbatch{1}.spm.spatial.preproc.tissue(i).native = [native_space(i) dartel_imported(i)];
    matlabbatch{1}.spm.spatial.preproc.tissue(i).warped = [0 0];   
end
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1; % MRF parameter (cleanup) (default = 0)
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3; % sampling distance
matlabbatch{1}.spm.spatial.preproc.warp.write = [inverse_deform forward_deform]; 

% | RUN
if nargout==0,  spm_jobman('initcfg'); spm_jobman('run',matlabbatch); end

end
