function bspm_img2nii(in, rmtag)
% BSPM_IMG2NII
%
%   USAGE: bspm_img2nii(in, rmtag)
%       
%       in  =  array of images OR wildcard pattern for finding them
%       rmtag = flag to delete old image, 0=No (default), 1=Yes 
%

% ----------------------- Copyright (C) 2014 -----------------------
%	Author: Bob Spunt
%	Affilitation: Caltech
%	Email: spunt@caltech.edu
%
%	$Revision Date: Aug_20_2014

if nargin<1, disp('USAGE: bspm_img2nii(in)'); return; end
if nargin<2, rmtag = 0; end
if ~iscell(in) & strfind(in,'*'); in = files(in); end
if ischar(in), in = cellstr(in); end

%% just a test

for i = 1:length(in)
    
    hdr = spm_vol(in{i});
    img = spm_read_vols(hdr);
    oldname = hdr.fname;
    [p n e] = fileparts(oldname);
    hdr.fname = [p filesep n '.nii'];
    if rmtag, delete([n '*']); end
    spm_write_vol(hdr, img);
    
end

 
 
 
 
