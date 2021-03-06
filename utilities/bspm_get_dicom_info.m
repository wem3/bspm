function dicominfo = bspm_get_dicom_info(in,disptag)
% BSPM_GET_DICOM_INFO
%
% USAGE: dicominfo = bspm_get_dicom_info(in,disptag)
%
%   ARGUMENTS
%       in = dicom file
%       disptag = 1 (default) will display (requires f(n) strucdisp)
%
%   OUTPUT EXAMPLE
%       dicominfo.parameterinfo.TR = 2500;
%       dicominfo.parameterinfo.voxelsize = 3;
%       dicominfo.parameterinfo.matrixsize = 64;
%       dicominfo.parameterinfo.echotime = 30;
%       dicominfo.parameterinfo.flipangle = 80;
%       dicominfo.parameterinfo.bandwidth = 2604;
%       dicominfo.sequenceinfo.name = TOM;
%       dicominfo.sequenceinfo.type = EP;
%       dicominfo.sequenceinfo.pulsename = *epfid2d1_64;
%       dicominfo.sequenceinfo.timestamp = MR20130328094606;
%       dicominfo.sequenceinfo.order = 8;
%       dicominfo.subjectinfo.subjectid = AM_032813;
%       dicominfo.subjectinfo.age = 039Y;
%       dicominfo.subjectinfo.sex = F;
%       dicominfo.sliceinfo.spacing = 3;
%       dicominfo.sliceinfo.orientation = Tra>Cor(-21.2);
%       dicominfo.sliceinfo.acquisitiontimes[1] = 1252.5;
%       dicominfo.sliceinfo.order
%       dicominfo.sliceinfo.number = 46;
%

% ----------------------- Copyright (C) 2014 -----------------------
%	Author: Bob Spunt
%	Affilitation: Caltech
%	Email: spunt@caltech.edu
%
%	$Revision Date: Aug_20_2014

if nargin < 1, error('USAGE: bspm_get_dicom_info(in, disptag)'); end
if nargin < 2, disptag = 1; end
if iscell(in), in = char(in); end

try 
    load(in);
catch
    hdr = spm_dicom_headers(in);
end
allfield = structfields(hdr{1});

% scanner information
if isfield(hdr{1},'.ManufacturersModelName'), dicominfo.scannerinfo.model = hdr{1}.ManufacturersModelName; end
if cellstrfind(allfield,'32Ch'), dicominfo.scannerinfo.coil = 32; else dicominfo.scannerinfo.coil = 12; end
if isfield(hdr{1}, 'InstitutionName'), dicominfo.scannerinfo.facility = hdr{1}.InstitutionName; end
if isfield(hdr{1}, 'InstitutionAddress'), dicominfo.scannerinfo.location = hdr{1}.InstitutionAddress; end
    
% general information
dicominfo.parameterinfo.TR          = hdr{1}.RepetitionTime;
dicominfo.parameterinfo.voxelsize   = [hdr{1}.PixelSpacing' hdr{1}.SliceThickness];
dicominfo.parameterinfo.matrixsize  = hdr{1}.AcquisitionMatrix;
dicominfo.parameterinfo.echotime    = hdr{1}.EchoTime;
dicominfo.parameterinfo.flipangle   = hdr{1}.FlipAngle;
dicominfo.parameterinfo.bandwidth   = hdr{1}.PixelBandwidth;

% dicominfo.sequenceinfo
dicominfo.sequenceinfo.name = cleanupname(hdr{1}.ProtocolName); 
dicominfo.sequenceinfo.type = cleanupname(hdr{1}.ScanningSequence); 
dicominfo.sequenceinfo.pulsename = cleanupname(hdr{1}.SequenceName);
dicominfo.sequenceinfo.timestamp = cleanupname(hdr{1}.PerformedProcedureStepID); 
dicominfo.sequenceinfo.order = hdr{1}.SeriesNumber;
idx = cellstrfind(allfield,'TotalScanTimeSec');
tmp = allfield{idx};
idx = strfind(tmp,'TotalScanTimeSec');
tmp = tmp(idx:idx+100);
idx = strfind(tmp,'=');
tmp = tmp(idx(1)+1:idx(1)+5);
dicominfo.sequenceinfo.duration_secs = str2double(tmp);
str = 'sPat.lAccelFactPE                        = ';
idx = cellstrfind(allfield,str);
tmp = allfield{idx};
idx = strfind(tmp,str);
idx = idx+length(str);
dicominfo.sequenceinfo.ipatfactor = str2num(tmp(idx:idx+1));
str = 'dReadoutFOV';
idx = cellstrfind(allfield,str);
tmp = allfield{idx};
idx = strfind(tmp,str);
tmp = tmp(idx:idx+50);
idx = strfind(tmp,'=');
tmp = strtrim(tmp(idx(1)+1:idx(1)+5));
dicominfo.sequenceinfo.FOVread = str2num(tmp);

% dicominfo.subjectinfo
if isfield(hdr{1},'PatientName')
    dicominfo.subjectinfo.subjectid = strtrim(hdr{1}.PatientName);
    dicominfo.subjectinfo.age = strtrim(hdr{1}.PatientAge);
    dicominfo.subjectinfo.sex = strtrim(hdr{1}.PatientSex);
else
    dicominfo.subjectinfo.subjectid = strtrim(hdr{1}.PatientsName);
    dicominfo.subjectinfo.age = strtrim(hdr{1}.PatientsAge);
    dicominfo.subjectinfo.sex = strtrim(hdr{1}.PatientsSex);
end

% dicominfo.sliceinfo
if isfield(hdr{1},'Slicethickness'), dicominfo.sliceinfo.thickness = hdr{1}.SliceThickness; end
if isfield(hdr{1},'SpacingBetweenSlices'), dicominfo.sliceinfo.spacing = hdr{1}.SpacingBetweenSlices; end
if isfield(hdr{1},'Private_0051_100e'), dicominfo.sliceinfo.orientation = strtrim(hdr{1}.Private_0051_100e); end
if isfield(hdr{1},'Private_0019_1029')
    slicetimes = hdr{1}.Private_0019_1029';
    dicominfo.sliceinfo.acquisitiontimes = slicetimes;
    slicetimes(:,2) = 1:length(slicetimes);
    slicetimes = sortrows(slicetimes,1);
    dicominfo.sliceinfo.order = slicetimes(:,2);
    dicominfo.sliceinfo.number = length(dicominfo.sliceinfo.acquisitiontimes);
end

% display
if disptag
    tmp = which('strucdisp.m'); 
    if ~isempty(tmp), strucdisp(dicominfo); end
end

end

function cname = cleanupname(name); 

    cname = regexprep(strtrim(name), ' ', '_');
    cname = regexprep(cname, '\', '');

end






 
 
 
 
