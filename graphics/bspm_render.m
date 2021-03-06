function [h1 hh1] = bspm_render(im, cmapflag, medialflag, outname)
% BSPM_RENDER Render 3D intensity map using Aaron Schultz's SurfPlot
%
%  USAGE: bspm_render(im, *cmapflag, *medialflag)	*optional input
% __________________________________________________________________________
%  INPUTS
%	im:  image filename
%	cmapflag: flag to include colormap (default = 1)
%	medialflag:  flag to include medial sections (default = 1)
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-10-07
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: bspm_render(im, *cmapflag, *medialflag)	*optional input'); return; end
if nargin < 2, cmapflag = 1; end
if nargin < 3, medialflag = 1; end

[d, h] = bspm_read_vol(im);
d(isnan(d)) = 0; 
% obj.colorlims = [ceil(min(d(d>0))) floor(max(d(:)))];
obj.colorlims = [0 floor(max(d(:)))];
obj.medialflag = medialflag; 
obj.input.m = d;
obj.input.he = h; 
obj.cmapflag = cmapflag; 
obj.figno = 0; % Figure number for output plot
obj.newfig = 1; 
obj.overlaythresh = 0; 
obj.colormap = 'hot';
obj.direction = '+';
obj.reverse = 0; 
obj.background = [0 0 0];
obj.mappingfile = [];  %%% See PreconfigureFSinfo.m for an example of how to create a mapping file.
obj.round = 0;  % if = 1, rounds all values on the surface to nearest whole number.  Useful for masks
obj.fsaverage = 'fsaverage';  %% Set which fsaverage to map to e.g. fsaverage, fsaverage3, fsaverage6
obj.surface = 'inflated';          %% Set the surface: inflated, pial, or white
obj.shading = 'sulc';          %% Set the shading information for the surface: curv, sulc, or thk
obj.shadingrange = [.1 .7];    %% Set the min anx max greyscale values for the surface underlay (range of 0 to 1)
obj.Nsurfs = 4;              %% Choose which hemispheres and surfaces to show:  4=L/R med/lat;  2= L/R lat; 1.9=L med/lat; 2.1 = R med/lat; -1= L lat; 1-R lat;

ss = get(0, 'ScreenSize');
ts = floor(ss/2);     
switch obj.Nsurfs
case 4
   ts(4) = ts(4)*.90;
case 2
   ts(4) = ts(4)*.60;
case 'L Lateral'
   obj.Nsurfs = -1;
case 1.9
   ts(4) = ts(4)*.60;
case 2.1
   ts(4) = ts(4)*.60;
otherwise
end
obj.position = ts; 



[h1, hh1] = surfPlot4(obj);

if nargin==4
    tightfig
    export_fig(outname, '-jpg', '-m1', '-zbuffer', gcf);
end

end
function out = threshold_image(in, thresh, extent)
    imdims = size(in);
    if ismember(thresh,[.10 .05 .01 .005 .001 .0005 .0001]);
        tmp = in_hdr.descrip;
        idx1 = regexp(tmp,'[','ONCE');
        idx2 = regexp(tmp,']','ONCE');
        df = str2num(tmp(idx1+1:idx2-1));
        thresh = bob_p2t(thresh, df);
    end
    in(in<thresh) = NaN;
    in(in==0)=NaN;
%     in(in>thresh(1) & in<thresh(2)) = NaN;
%     in(in==0) = NaN;s
    [X Y Z] = ind2sub(size(in), find(in));
    voxels = sortrows([X Y Z])';
    cl_index = spm_clusters(voxels);
    for i = 1:max(cl_index)
        a(cl_index == i) = sum(cl_index == i);
    end
    which_vox = (a >= extent);
    cluster_vox = voxels(:,which_vox);
    cluster_vox = cluster_vox';
    roi_mask = zeros(imdims);
    for i = 1:size(cluster_vox,1)
        roi_mask(cluster_vox(i,1),cluster_vox(i,2),cluster_vox(i,3)) = in(cluster_vox(i,1),cluster_vox(i,2),cluster_vox(i,3));
    end
    out = double(roi_mask);
    out(out==0) = NaN;
end
function [h, hh] = surfPlot4(obj)
%%% Written by Aaron P. Schultz - aschultz@martinos.org
%%%
%%% Copyright (C) 2014,  Aaron P. Schultz
%%%
%%% Supported in part by the NIH funded Harvard Aging Brain Study (P01AG036694) and NIH R01-AG027435 
%%%
%%% This program is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% any later version.
%%% 
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%%

pth = [fileparts(which('fsaverage.mat')) filesep];
load([pth obj.fsaverage '.mat']);

switch lower(obj.surface)
    case 'inflated'
        lVert = T.inflated.lVert;
        lFace = T.inflated.lFace;
        rVert = T.inflated.rVert;
        rFace = T.inflated.rFace;
    case 'pial'
        lVert = T.pial.lVert;
        lFace = T.pial.lFace;
        rVert = T.pial.rVert;
        rFace = T.pial.rFace;
    case 'white'
        lVert = T.white.lVert;
        lFace = T.white.lFace;
        rVert = T.white.rVert;
        rFace = T.white.rFace;
    otherwise
        error('Surface option Not Found:  Available options are inflated, pial, and white');
end

switch lower(obj.shading)
    case 'curv'
        lShade = -T.lCurv;
        rShade = -T.rCurv;
    case 'sulc'
        %lShade = -round(T.lSulc);
        %rShade = -round(T.rSulc);
        lShade = -(T.lSulc);
        rShade = -(T.rSulc);
    case 'thk'
        lShade = T.lThk;
        rShade = T.rThk;
    otherwise
         error('Shading option Not Found:  Available options are curv, sulc, and thk');
end

if obj.newfig
    if obj.figno>0
        figure(obj.figno); clf;
        set(gcf,'color',obj.background, 'position', obj.position); shg
    else
        figure('pos', obj.position); clf;
        set(gcf,'color',obj.background, 'position', obj.position); shg
        obj.figno = gcf;
    end
    
    rang = obj.shadingrange;
    
    c = lShade;
    c = demean(c);
    c = c./spm_range(c);
    c = c.*diff(rang);
    c = c-min(c)+rang(1);
    col1 = [c c c];
    
    
    
 if obj.Nsurfs == 4;
        
        subplot(2,12,1:5);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(270,0)
        
        subplot(2,12,13:17);
        h(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(90,0)
        
    elseif obj.Nsurfs == 2;
        
        subplot(1,11,1:5);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(270,0)
        
    elseif obj.Nsurfs == 1.9;
        
        subplot(1,24,1:10);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(270,0)
        
        subplot(1,24,13:22);
        h(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(90,0)
        
    elseif obj.Nsurfs == -1;    
        
        subplot(1,11,1:10);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        if ~obj.medialflag
            view(270,0)
        end
        
    end
    
    c = rShade;
    c = demean(c);
    c = c./spm_range(c);
    c = c.*diff(rang);
    c = c-min(c)+rang(1);
    
    col2 = [c c c];
    
    if obj.Nsurfs == 4;
        
        subplot(2,12,6:10);
        h(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
        subplot(2,12,18:22);
        h(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(270,0)
        
    elseif obj.Nsurfs == 2;
        
        subplot(1,11,6:10);
        h(2) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
    elseif obj.Nsurfs == 2.1;
        
        subplot(1,24,1:10);
        h(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
        subplot(1,24,13:22);
        h(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(270,0)
        
    elseif obj.Nsurfs == 1;
        
        subplot(1,11,1:10);
        h(1) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
    end
        
else
    
    tmp = get(obj.figno,'UserData');
    col1 = tmp{1};
    col2 = tmp{2};
    h = tmp{3};
    
end

%%%
lMNI = T.map.lMNI;
lv = T.map.lv;

rMNI =T.map.rMNI;
rv = T.map.rv;


if ischar(obj.input);
    [m he] = openIMG(obj.input);
else
    try
        m = obj.input.m;
        he = obj.input.he;
    catch
        he = obj.input;
        m = spm_read_vols(he);
    end
end
[x y z] = ind2sub(he.dim,(1:numel(m))');
mat = [x y z ones(numel(z),1)];
mni = mat*he.mat';
mni = mni(:,1:3);
% mni(:,1) = mni(:,1)+10;

if obj.reverse==1
    m = m*-1;
end
% keyboard;
if ~isempty(obj.mappingfile);
    load(obj.mappingfile);
    lVoxels = MP.lVoxels;
    rVoxels = MP.rVoxels;
    lWeights = MP.lWeights;
    rWeights = MP.rWeights;    
    
    lVals = m(lVoxels);
    lWeights(isnan(lVals))=NaN;
    lVals = nansum(lVals.*lWeights,2)./nansum(lWeights,2);
    
    rVals = m(rVoxels);
    rWeights(isnan(rVals))=NaN;
    rVals = nansum(rVals.*rWeights,2)./nansum(rWeights,2);
else    
    

%     %%%%%%%%%%%%%%%%%%%%%%
%     mloc = mloc(:,1:3);
%     a = sum(1-abs( (mloc-round(mloc)) ),2);
%     b = sum(1-abs( (mloc-ceil(mloc)) ),2);
%     c = sum(1-abs( (mloc-floor(mloc)) ),2);
%     
%     
%     w = [a b c];
%     w = w./repmat(sum(w,2),1,size(w,2));
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isfield(obj,'nearestneighbor') && obj.nearestneighbor == 1;
        mloc = ([T.map.lMNI ones(size(T.map.lMNI,1),1)]*inv(he.mat'));
        lVoxels = sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)));
        lWeights = 1;
        
        mloc = ([T.map.rMNI ones(size(T.map.rMNI,1),1)]*inv(he.mat'));
        rVoxels = sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)));
        rWeights = 1;
        
    else
        mloc = ([T.map.lMNI ones(size(T.map.lMNI,1),1)]*inv(he.mat'));
        lVoxels = [sub2ind(he.dim,floor(mloc(:,1)),floor(mloc(:,2)),floor(mloc(:,3))) sub2ind(he.dim,ceil(mloc(:,1)),ceil(mloc(:,2)),ceil(mloc(:,3))) sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)))];
        lWeights = (1/3);
        
        mloc = ([T.map.rMNI ones(size(T.map.rMNI,1),1)]*inv(he.mat'));
        rVoxels = [sub2ind(he.dim,floor(mloc(:,1)),floor(mloc(:,2)),floor(mloc(:,3))) sub2ind(he.dim,ceil(mloc(:,1)),ceil(mloc(:,2)),ceil(mloc(:,3))) sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)))];
        rWeights = (1/3);
    end
    lVals = nansum(m(lVoxels).*lWeights,2);
    rVals = nansum(m(rVoxels).*rWeights,2);
end

if isfield(obj,'round') && obj.round == 1;
    lVals = round(lVals);
    rVals = round(rVals);
end
%%%

% if contains('aschultz',{UserTime})
% %     keyboard; 
%     lVals = lVals+(lShade(T.map.lv+1)*2);
%     rVals = rVals+(rShade(T.map.rv+1)*2);
% end

if numel(obj.overlaythresh) == 1;
    if obj.direction == '+'
        ind1 = find(lVals>obj.overlaythresh);
        ind2 = find(rVals>obj.overlaythresh);
    elseif obj.direction == '-'
        ind1 = find(lVals<obj.overlaythresh);
        ind2 = find(rVals<obj.overlaythresh);
    end
else
    ind1 = find(lVals<=obj.overlaythresh(1) | lVals>=obj.overlaythresh(2));
    ind2 = find(rVals<=obj.overlaythresh(1) | rVals>=obj.overlaythresh(2));
end
%%%


val = max([abs(min([lVals; rVals])) abs(max([lVals; rVals]))]);
if obj.colorlims(1) == -inf
    obj.colorlims(1)=-val;
end
if obj.colorlims(2) == inf
    obj.colorlims(2)=val;
end


[cols CD] = cmap(lVals(ind1), obj.colorlims, obj.colormap);
% col1(lv(ind1)+1,:) = cols;
% set(h(1),'FaceVertexCdata',col1);
% set(h(2),'FaceVertexCdata',col1);

col = nan(size(col1));
col(lv(ind1)+1,:) = cols;
if obj.Nsurfs == 4;
    
    subplot(2,12,1:5);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(2,12,13:17);
    hh(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp;
    
elseif obj.Nsurfs == 1.9;
    
    subplot(1,24,1:10);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(1,24,13:22);
    hh(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp;    
    
elseif obj.Nsurfs == 2;
    
    subplot(1,11,1:5);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    
elseif obj.Nsurfs == -1;
    
    subplot(1,11,1:10);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    if obj.medialflag
        view(90,0)
    end
    
end


[cols CD] = cmap(rVals(ind2), obj.colorlims ,obj.colormap);
% col2(rv(ind2)+1,:) = cols;
% set(h(3),'FaceVertexCdata',col2);
% set(h(4),'FaceVertexCdata',col2);

col = nan(size(col2));
col(rv(ind2)+1,:) = cols;
if obj.Nsurfs == 4;
    
    subplot(2,12,6:10);
    hh(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(2,12,18:22);
    hh(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp;
    
elseif obj.Nsurfs == 2.1;
    
    subplot(1,24,1:10);
    hh(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(1,24,13:22);
    hh(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp;    
    
elseif obj.Nsurfs == 2;
    
    subplot(1,11,6:10);
    hh(2) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
elseif obj.Nsurfs == 1;
    
    subplot(1,11,1:10);
    hh(1) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
    
end

set(gcf,'UserData',{col1 col2,h});

drawnow;
if obj.cmapflag
if obj.Nsurfs == 4
    subplot(2,12,[12 24])
elseif obj.Nsurfs == 1.9 || obj.Nsurfs == 2.1;
    subplot(1, 22, 22);
else 
    subplot(1,11,11);
end
cla

mp = [];
mp(1:256,1,1:3) = CD;
ch = imagesc((1:256)');
set(ch,'CData',mp)

% 
%     if obj.Nsurfs == 4;
%         subplot(2,11,1:5);
%         h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
%         shading interp;
%         axis equal; axis tight; axis off;
%         view(270,0)
%         
%         subplot(2,11,12:16);
%         h(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
%         shading interp;
%         axis equal; axis tight; axis off;
%         view(90,0)
%     elseif obj.Nsurfs == 2;
%         subplot(1,11,1:5);
%         h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
%         shading interp;
%         axis equal; axis tight; axis off;
%         view(270,0)
%     elseif obj.Nsurfs == 1.9;
%         subplot(2,11,1:10);
%         h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
%         shading interp;
%         axis equal; axis tight; axis off;
%         view(270,0)
%         
%         subplot(2,11,12:21);
%         h(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
%         shading interp;
%         axis equal; axis tight; axis off;
%         view(90,0)
%     elseif obj.Nsurfs == -1;    
%         subplot(1,11,1:10);
%         h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
%         shading interp;
%         axis equal; axis tight; axis off;
%         view(270,0)
%     end
%     
%     c = rShade;
%     c = demean(c);
%     c = c./spm_range(c);
%     c = c.*diff(rang);
%     c = c-min(c)+rang(1);
%     
%     col2 = [c c c];
%     
%     if obj.Nsurfs == 4;
%         subplot(2,11,6:10);
%         h(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
%         shading interp;
%         axis equal; axis tight; axis off
%         view(90,0)
%         
%         subplot(2,11,17:21);
%         h(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
%         shading interp;
%         axis equal; axis tight; axis off
%         view(270,0)
%     elseif obj.Nsurfs == 2;
%         subplot(1,11,6:10);
%         h(2) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
%         shading interp;
%         axis equal; axis tight; axis off
%         view(90,0)
%     elseif obj.Nsurfs == 2.1;
%         subplot(2,11,1:10);
%         h(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
%         shading interp;
%         axis equal; axis tight; axis off
%         view(90,0)
%         
%         subplot(2,11,12:21);
%         h(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
%         shading interp;
%         axis equal; axis tight; axis off
%         view(270,0)
%     elseif obj.Nsurfs == 1;
%         subplot(1,11,1:10);
%         h(1) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
%         shading interp;
%         axis equal; axis tight; axis off
%         view(90,0)
%     end
%         
% else
%     tmp = get(obj.figno,'UserData');
%     col1 = tmp{1};
%     col2 = tmp{2};
%     h = tmp{3};
% end
% 
% %%%
% lMNI = T.map.lMNI;
% lv = T.map.lv;
% 
% rMNI =T.map.rMNI;
% rv = T.map.rv;
% 
% 
% if ischar(obj.input);
%     [m he] = openIMG(obj.input);
% else
%     try
%         m = obj.input.m;
%         he = obj.input.he;
%     catch
%         he = obj.input;
%         m = spm_read_vols(he);
%     end
% end
% [x y z] = ind2sub(he.dim,(1:numel(m))');
% mat = [x y z ones(numel(z),1)];
% mni = mat*he.mat';
% mni = mni(:,1:3);
% % mni(:,1) = mni(:,1)+10;
% 
% if obj.reverse==1
%     m = m*-1;
% end
% % keyboard;
% if ~isempty(obj.mappingfile);
%     load(obj.mappingfile);
%     lVoxels = MP.lVoxels;
%     rVoxels = MP.rVoxels;
%     lWeights = MP.lWeights;
%     rWeights = MP.rWeights;    
%     
%     lVals = m(lVoxels);
%     lWeights(isnan(lVals))=NaN;
%     lVals = nansum(lVals.*lWeights,2)./nansum(lWeights,2);
%     
%     rVals = m(rVoxels);
%     rWeights(isnan(rVals))=NaN;
%     rVals = nansum(rVals.*rWeights,2)./nansum(rWeights,2);
% else    
%     
% 
% %     %%%%%%%%%%%%%%%%%%%%%%
% %     mloc = mloc(:,1:3);
% %     a = sum(1-abs( (mloc-round(mloc)) ),2);
% %     b = sum(1-abs( (mloc-ceil(mloc)) ),2);
% %     c = sum(1-abs( (mloc-floor(mloc)) ),2);
% %     
% %     
% %     w = [a b c];
% %     w = w./repmat(sum(w,2),1,size(w,2));
% %     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     
%     if isfield(obj,'nearestneighbor') && obj.nearestneighbor == 1;
%         mloc = ([T.map.lMNI ones(size(T.map.lMNI,1),1)]*inv(he.mat'));
%         lVoxels = sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)));
%         lWeights = 1;
%         
%         mloc = ([T.map.rMNI ones(size(T.map.rMNI,1),1)]*inv(he.mat'));
%         rVoxels = sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)));
%         rWeights = 1;
%         
%     else
%         mloc = ([T.map.lMNI ones(size(T.map.lMNI,1),1)]*inv(he.mat'));
%         lVoxels = [sub2ind(he.dim,floor(mloc(:,1)),floor(mloc(:,2)),floor(mloc(:,3))) sub2ind(he.dim,ceil(mloc(:,1)),ceil(mloc(:,2)),ceil(mloc(:,3))) sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)))];
%         lWeights = (1/3);
%         
%         mloc = ([T.map.rMNI ones(size(T.map.rMNI,1),1)]*inv(he.mat'));
%         rVoxels = [sub2ind(he.dim,floor(mloc(:,1)),floor(mloc(:,2)),floor(mloc(:,3))) sub2ind(he.dim,ceil(mloc(:,1)),ceil(mloc(:,2)),ceil(mloc(:,3))) sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)))];
%         rWeights = (1/3);
%     end
%     lVals = nansum(m(lVoxels).*lWeights,2);
%     rVals = nansum(m(rVoxels).*rWeights,2);
% end
% 
% if isfield(obj,'round') && obj.round == 1;
%     lVals = round(lVals);
%     rVals = round(rVals);
% end
% %%%
% 
% % if contains('aschultz',{UserTime})
% % %     keyboard; 
% %     lVals = lVals+(lShade(T.map.lv+1)*2);
% %     rVals = rVals+(rShade(T.map.rv+1)*2);
% % end
% 
% if numel(obj.overlaythresh) == 1;
%     if obj.direction == '+'
%         ind1 = find(lVals>obj.overlaythresh);
%         ind2 = find(rVals>obj.overlaythresh);
%     elseif obj.direction == '-'
%         ind1 = find(lVals<obj.overlaythresh);
%         ind2 = find(rVals<obj.overlaythresh);
%     end
% else
%     ind1 = find(lVals<=obj.overlaythresh(1) | lVals>=obj.overlaythresh(2));
%     ind2 = find(rVals<=obj.overlaythresh(1) | rVals>=obj.overlaythresh(2));
% end
% %%%
% 
% 
% val = max([abs(min([lVals; rVals])) abs(max([lVals; rVals]))]);
% if obj.colorlims(1) == -inf
%     obj.colorlims(1)=-val;
% end
% if obj.colorlims(2) == inf
%     obj.colorlims(2)=val;
% end
% 
% 
% [cols CD] = cmap(lVals(ind1), obj.colorlims, obj.colormap);
% % col1(lv(ind1)+1,:) = cols;
% % set(h(1),'FaceVertexCdata',col1);
% % set(h(2),'FaceVertexCdata',col1);
% 
% col = nan(size(col1));
% col(lv(ind1)+1,:) = cols;
% if obj.Nsurfs == 4;
%     subplot(2,11,1:5);
%     hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
%     shading interp
%     subplot(2,11,12:16);
%     hh(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
%     shading interp;
% elseif obj.Nsurfs == 1.9;
%     subplot(2,11,1:10);
%     hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
%     shading interp
%     subplot(2,11,12:21);
%     hh(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
%     shading interp;    
% elseif obj.Nsurfs == 2;
%     subplot(1,11,1:5);
%     hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
%     shading interp
% elseif obj.Nsurfs == -1;
%     subplot(1,11,1:10);
%     hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
%     shading interp
% end
% 
% 
% [cols CD] = cmap(rVals(ind2), obj.colorlims ,obj.colormap);
% % col2(rv(ind2)+1,:) = cols;
% % set(h(3),'FaceVertexCdata',col2);
% % set(h(4),'FaceVertexCdata',col2);
% 
% col = nan(size(col2));
% col(rv(ind2)+1,:) = cols;
% if obj.Nsurfs == 4;
%     subplot(2,11,6:10);
%     hh(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
%     shading interp
%     subplot(2,11,17:21);
%     hh(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
%     shading interp;
% elseif obj.Nsurfs == 2.1;
%     subplot(2,11,1:10);
%     hh(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
%     shading interp
%     subplot(2,11,12:21);
%     hh(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
%     shading interp;    
% elseif obj.Nsurfs == 2;
%     subplot(1,11,6:10);
%     hh(2) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
%     shading interp
% elseif obj.Nsurfs == 1;
%     subplot(1,11,1:10);
%     hh(1) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
%     shading interp
% end
% 
% set(gcf,'UserData',{col1 col2,h});
% 
% drawnow;
% 
% if obj.Nsurfs == 4 || obj.Nsurfs == 1.9 || obj.Nsurfs == 2.1;
%     subplot(2,11,[11 22]);
% else 
%     subplot(1,11,[11]);
% end
% cla
% mp = [];
% mp(1:256,1,1:3) = CD;
% ch = imagesc((1:256)');
% set(ch,'CData',mp)


try
[cl trash indice] = cmap(obj.overlaythresh,obj.colorlims,obj.colormap);
catch
    keyboard; 
end

tickmark = unique(sort([1 122 255 indice(:)']));
ticklabel = unique(sort([obj.colorlims(1) mean(obj.colorlims) obj.colorlims(2) obj.overlaythresh])');
tickmark = tickmark([1 end]);
ticklabel = ticklabel([1 end]);
% keyboard;
set(gca,'YDir','normal','YAxisLocation','right','XTick',[],'YTick',(tickmark),'YTickLabel',(ticklabel),'fontsize',14,'YColor','w');
shading interp
end

end
 
 
 
 
