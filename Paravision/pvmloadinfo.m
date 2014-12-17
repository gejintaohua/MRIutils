function [info, status, errmsg] = pvmloadinfo(serdir)
% [info, status, errmsg] = pvmloadinfo(serdir)
%
% Load information from a PvM data directory.
% Assumes that serdir contains a method file and
% that the parent directory contains a subject text file.
% Non-essential missing information (eg patient name)
% is filled with sensible default values.
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech BIC
% DATES  : 09/10/2002 JMT Adapt from parxloadinfo.m (JMT)
%          01/05/2004 JMT Update for CSI data
%          02/09/2005 JMT Add support for G60 amps
%          01/17/2006 JMT M-Lint corrections
%
% Copyright 2002-2006 California Institute of Technology.
% All rights reserved.

% Default arg
if nargin < 1; serdir = '.'; end
if strcmp(serdir,'.'); serdir = pwd; end

% Local definition of gamma 1H in MHz/T
gamma_1H = 42.57;

% Default status 1 => everything ok
status = 1;
errmsg = [];

% Default structure member
info.name = 'Unknown';

% Check for existence of method file
methodfile = fullfile(serdir,'method'); 
if ~exist(methodfile,'file')
  status = -1;
  errmsg = 'No method file\n';
  return
end

% Check for existence of acqp file
acqpfile = fullfile(serdir,'acqp'); 
if ~exist(acqpfile,'file')
  status = -2;
  errmsg = 'No acqp file\n';
  return
end

% Check for existence of subject file
subjfile = fullfile(serdir,'..','subject'); 
if ~exist(subjfile,'file')
  status = -3;
  errmsg = 'No subject file\n';
  return
end

% Check for existence of reco file
recofile = fullfile(serdir,'pdata','1','reco'); 
if ~exist(recofile,'file')
  status = -4;
  errmsg = 'No reco file\n';
  return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse the method file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the full contents into a cell array of strings
% Don't use Matlab textread if standalone code is required
methodinfo = parxtextread(methodfile);
if isempty(methodinfo)
  status = -5;
  return
end

% Assume the series number is also the containing directory number
[~,tmpdir,~] = fileparts(serdir);
info.serno = str2double(tmpdir);
info.scanno = info.serno; % Duplicate for backwards consistency

% Pulse sequence parameters
info.method  = parxextractstring(methodinfo, '##$Method=');
info.vsize   = parxextractmatrix(methodinfo, '##$PVM_SpatResol=');
info.slthick = parxextractdouble(methodinfo, '##$PVM_SliceThick=');
info.dim     = parxextractmatrix(methodinfo, '##$PVM_Matrix=');
info.sw      = parxextractdouble(methodinfo, '##$PVM_EffSWh=');
info.te      = parxextractdouble(methodinfo, '##$PVM_EchoTime=');
info.te_list = parxextractmatrix(methodinfo, '##$EffectiveTE=');
info.tr      = parxextractdouble(methodinfo, '##$PVM_RepetitionTime=');
info.ti      = parxextractdouble(methodinfo, '##$PVM_InversionTime=');
info.navs    = parxextractdouble(methodinfo, '##$PVM_NAverages=');
info.bw      = parxextractdouble(methodinfo, '##$PVM_EffSWh=');
info.acqtime = parxextractstring2(methodinfo, '##$PVM_ScanTimeStr=');
info.echopos = parxextractdouble(methodinfo, '##$PVM_EchoPosition=');
info.anti_alias = parxextractmatrix(methodinfo, '##$PVM_AntiAlias=');

% Echo position trap
if isnan(info.echopos); info.echopos = 50.0; end

% Spectral widths (MRS and CSI)
info.sw_spec_Hz  = parxextractmatrix(methodinfo, '##$PVM_SpecSWH=');
info.sw_spec_ppm = parxextractmatrix(methodinfo, '##$PVM_SpecSW=');
info.sw_offset_Hz  = parxextractdouble(methodinfo, '##$PVM_SpecOffsetHz=');
info.sw_offset_ppm = parxextractdouble(methodinfo, '##$PVM_SpecOffsetppm=');

% Geometry parameters
info.sloffset = parxextractdouble(methodinfo, '##$PVM_SPackSliceOffset=');
info.rdoffset = parxextractdouble(methodinfo, '##$PVM_SPackReadOffset=');

% Handle conditional parameters
switch lower(info.method)
  
  case 'bic_shim'
    
    info.esp = parxextractdouble(methodinfo, '##$BIC_SHIM_EchoSpacing=');
    info.uflare_echopath = 'AddedCoherently';
    
  case 'bic_rare'
    
    echopos = parxextractdouble(methodinfo, '##$PVM_EchoPosition=');
    if echopos == 25
      info.uflare_echopath = 'Displaced';
    else
      info.uflare_echopath = 'AddedCoherently';
    end

    info.esp = parxextractdouble(methodinfo, '##$BIC_RARE_ESP=');
    info.etl = parxextractdouble(methodinfo, '##$BIC_RARE_ETL=');
    info.uflare_flip = parxextractdouble(methodinfo, '##$BIC_uflare_flip=');
    info.diffmode = parxextractyesno(methodinfo, '##$BIC_RARE_diff_mode=');
    
    % Get diffusion-weighting information
    if info.diffmode
      info.diffdir = parxextractmatrix(methodinfo, '##$BIC_RARE_diff_dir=');
      info.bfactor = parxextractmatrix(methodinfo, '##$BIC_RARE_b_vector=');
      info.little_delta = parxextractdouble(methodinfo, '##$BIC_RARE_little_delta=');
      info.big_delta = parxextractdouble(methodinfo, '##$BIC_RARE_big_delta=');
      info.Gdiff = parxextractdouble(methodinfo, '##$BIC_RARE_diff_grad_amp=');
    end
    
  case 'bic_mike'
    
    echopos = parxextractdouble(methodinfo, '##$PVM_EchoPosition=');
    if echopos == 25
      info.uflare_echopath = 'Displaced';
    else
      info.uflare_echopath = 'AddedCoherently';
    end

    info.esp = parxextractdouble(methodinfo, '##$BIC_MIKE_ESP=');
    info.etl = parxextractdouble(methodinfo, '##$BIC_MIKE_ETL=');
    info.uflare_flip = parxextractdouble(methodinfo, '##$BIC_uflare_flip=');
    info.diffmode = parxextractyesno(methodinfo, '##$BIC_MIKE_diff_mode=');
    
    % Get diffusion-weighting information
    if info.diffmode
      info.diffdir = parxextractmatrix(methodinfo, '##$BIC_MIKE_diff_dir=');
      info.bfactor = parxextractmatrix(methodinfo, '##$BIC_MIKE_b_vector=');
      info.little_delta = parxextractdouble(methodinfo, '##$BIC_MIKE_little_delta=');
      info.big_delta = parxextractdouble(methodinfo, '##$BIC_MIKE_big_delta=');
      info.Gdiff = parxextractdouble(methodinfo, '##$BIC_MIKE_diff_grad_amp=');
    end
    
  case 'bic_dwse'
    
    info.uflare_echopath = 'AddedCoherently';

    info.esp = 0;
    info.etl = 1;
    info.uflare_flip = 0;
    
    % Get diffusion-weighting information
    info.diffdir = parxextractmatrix(methodinfo, '##$BIC_DWSE_diff_dir=');
    info.bfactor = parxextractmatrix(methodinfo, '##$BIC_DWSE_b_vector=');
    info.little_delta = parxextractdouble(methodinfo, '##$BIC_DWSE_little_delta=');
    info.big_delta = parxextractdouble(methodinfo, '##$BIC_DWSE_big_delta=');
    info.Gdiff = parxextractdouble(methodinfo, '##$BIC_DWSE_diff_grad_amp=');
    info.diffmode = 'Yes'; % Constant on
    
    % Extract RF pulse information
    info.excpulse = pvmextractrfpulse(methodinfo, '##$BIC_DWSE_ExcPulse=');
    info.refpulse = pvmextractrfpulse(methodinfo, '##$BIC_DWSE_RfcPulse=');
    
    % Extract spoiler information
    info.G_hspoil = parxextractdouble(methodinfo, '##$BIC_DWSE_SpoilerAmp=');
    info.t_hspoil = parxextractdouble(methodinfo, '##$BIC_DWSE_SpoilerDuration=');
    
  case 'bic_dwste'
    
    info.uflare_echopath = 'AddedCoherently';

    info.esp = 0;
    info.etl = 1;
    info.uflare_flip = 0;
    
    % Get diffusion-weighting information
    info.diffdir = parxextractmatrix(methodinfo, '##$BIC_DWSTE_diff_dir=');
    info.bfactor = parxextractmatrix(methodinfo, '##$BIC_DWSTE_b_vector=');
    info.little_delta = parxextractdouble(methodinfo, '##$BIC_DWSTE_little_delta=');
    info.big_delta = parxextractdouble(methodinfo, '##$BIC_DWSTE_big_delta=');
    info.Gdiff = parxextractdouble(methodinfo, '##$BIC_DWSTE_diff_grad_amp=');
    info.diffmode = 'Yes'; % Constant on

    % Mixing time
    info.tm = parxextractdouble(methodinfo, '##$BIC_DWSTE_MixingTime=');
    
    % Extract RF pulse information
    info.excpulse = pvmextractrfpulse(methodinfo, '##$BIC_DWSTE_ExcPulse=');
    
    % Extract spoiler information
    info.G_hspoil = parxextractdouble(methodinfo, '##$BIC_DWSTE_SpoilerAmp=');
    info.t_hspoil = parxextractdouble(methodinfo, '##$BIC_DWSTE_SpoilerDuration=');
    info.G_tmspoil = parxextractdouble(methodinfo, '##$BIC_DWSTE_TMSpoilerAmp=');
    info.t_tmspoil = parxextractdouble(methodinfo, '##$BIC_DWSTE_TMSpoilerDuration=');
    
  otherwise
    
    % Default conditional parameters
    info.uflare_echopath = 'AddedCoherently';
    info.esp = 0;
    info.etl = 1;
    info.uflare_flip = 0;
    info.diffmode = 'No';
    info.diffdir = [0 0 0];
    info.bfactor = 0;
    info.little_delta = 0;
    info.big_delta = 0;
    info.Gdiff = 0;
    
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse the ACQP file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the full contents into a cell array of strings
acqpinfo = parxtextread(acqpfile);
if isempty(acqpinfo)
  status = -6;
  return
end

% Extract useful parameters from acqp file
info.etl  = parxextractdouble(acqpinfo, '##$ACQ_rare_factor=');
info.nechoes = parxextractdouble(acqpinfo, '##$NECHOES=');
info.nims = parxextractdouble(acqpinfo, '##$NI=');
info.nreps = parxextractdouble(acqpinfo, '##$NR=');
info.time = parxextractstring2(acqpinfo, '##$ACQ_time=');
info.acq_scantime = parxextractdouble(acqpinfo, '##$ACQ_scan_time=')/1000; % seconds
info.prefill = parxextractdouble(acqpinfo, '##$DSPFVS=');
info.cf = parxextractdouble(acqpinfo, '##$BF1=');

% Gradient calibration
info.gradset = parxextractstring2(acqpinfo,'##$ACQ_status=');
switch info.gradset
  case 'Micro2.5' % With 50A gradient amps
    info.gradcal = 406780; % Hz/cm at max gradient
    info.maxgrad = info.gradcal / ((gamma_1H) / (2 * pi * 1e4)); % G/cm max gradient
    info.t_ramp = 80e-3; % Ramp time in ms
  case 'Micro2.5_G60' % With Great60 amps
    info.gradcal = 621233; % Hz/cm at max gradient
    info.maxgrad = info.gradcal / ((gamma_1H) / (2 * pi * 1e4)); % G/cm max gradient
    info.t_ramp = 100e-3; % Ramp time in ms
  case 'S116' % 7T and 9.4T systems
    info.gradcal = 171499; % Hz/cm at max gradient
    info.maxgrad = info.gradcal / ((gamma_1H) / (2 * pi * 1e4)); % G/cm max gradient
    info.t_ramp = 140e-3; % Ramp time in ms
  case 'S205'
    info.gradcal = 84000; % Hz/cm at max gradient
    info.maxgrad = info.gradcal / ((gamma_1H) / (2 * pi * 1e4)); % G/cm max gradient
    info.t_ramp = 300e-3; % Ramp time in ms
  otherwise
    % Default gradient set 1G/cm max grad, 1ms ramp time
    info.gradcal = 4258; % Hz/cm at max gradient
    info.maxgrad = info.gradcal / ((gamma_1H) / (2 * pi * 1e4)); % 1.0 G/cm max gradient
    info.t_ramp = 1.0; % Ramp time in ms
end

% Get FOV from ACQP - accounts for spectral dimensions
info.fov = parxextractmatrix(acqpinfo,'##$ACQ_fov=') * 10.0; % cm -> mm

% Get sample dimensions for ACQP (closer to acquisition)
info.sampdim = parxextractmatrix(acqpinfo, '##$ACQ_size=');
info.sampdim(1) = info.sampdim(1)/2;

% Record number of spatial dimensions
info.ndim = length(info.sampdim);

% Determine acquisition bit depth - essential for offline recon
wordsize = parxextractstring(acqpinfo, '##$ACQ_word_size=');
if isempty(wordsize); wordsize = 'Unknown'; end
switch wordsize
case '_32_BIT'
  info.acqdepth = 32;
case '_16_BIT'
  info.acqdepth = 16;
otherwise
  fprintf('Unknown acq bit-depth - defaulting to 32\n');
  info.acqdepth = 32;
end

% Multislice interleaved slice ordering
info.objorder = parxextractmatrix(acqpinfo, '##$ACQ_obj_order=');
info.slicepos = parxextractmatrix(acqpinfo, '##$ACQ_slice_offset=');

% Dimension types (spatial or spectral)
info.dimDesc = parxextractstring2(acqpinfo,'##$ACQ_dim_desc=');

% Determine which dims are spatial, spectral
spatind = findstr('Spatial',info.dimDesc);
specind = findstr('Spectroscopic',info.dimDesc);

info.nSpatDim = length(spatind);
info.nSpecDim = length(specind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse the SUBJECT file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the full contents into a cell array of strings
subjinfo = parxtextread(subjfile);
if isempty(subjinfo)
  status = -7;
  return
end

% Extract useful parameters from subject file
info.id = parxextractstring2(subjinfo, '##$SUBJECT_id=');
info.name = parxextractstring2(subjinfo, '##$SUBJECT_name_string=');
info.purpose = parxextractstring2(subjinfo, '##$SUBJECT_purpose=');
info.studyname = parxextractstring2(subjinfo, '##$SUBJECT_study_name=');
info.studyno = parxextractdouble(subjinfo, '##$SUBJECT_study_nr=');
info.remarks = parxextractstring2(subjinfo,'##$SUBJECT_remarks=');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parse the RECO file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the full contents into a cell array of strings
recoinfo = parxtextread(recofile);
if isempty(recoinfo)
  status = -8;
  return
end

% Extract useful parameters from reco file
info.recodim = parxextractmatrix(recoinfo,'##$RECO_ft_size=');
info.recotx  = parxextractmatrix(recoinfo,'##$RECO_transposition=');
info.recorot = parxextractmatrix(recoinfo,'##$RECO_rotate=');

% RECO normally assumes phase chopping in the X (read) dimension
switch info.ndim
  case 2
    info.recorot(:,1) = 0.5;
  otherwise
    info.recorot(1) = 0.5;
end

% Recalculate slice roll for 3D spatial data from slicepack offset
if length(info.nSpatDim) == 3
  info.recorot(3) = mod(info.sloffset / info.fov(3) + 0.5,1);
end

% Determine the recon bit depth
switch parxextractstring(recoinfo, '##$RECO_wordtype=');
case '_16BIT_SGN_INT'
  info.recodepth = 16;
case '_32BIT_SGN_INT'
  info.recodepth = 32;
otherwise
  fprintf('Unknown recon bit-depth - defaulting to 32\n');
  info.recodepth = 32;
end

% Need to deal with byte ordering with switch to Intel LINUX
info.byteorder = parxextractstring(recoinfo,'##$RECO_byte_order=');

% Extract the image intensity mapping parameters
% These values must be used for correct quantitative scaling
info.map_mode = parxextractstring(recoinfo,'##$RECO_map_mode=');
info.map_range = parxextractmatrix(recoinfo,'##$RECO_map_range=');
info.map_percentile = parxextractmatrix(recoinfo,'##$RECO_map_percentile=');
info.map_error = parxextractdouble(recoinfo,'##$RECO_map_error=');
info.minima = parxextractmatrix(recoinfo,'##$RECO_minima=');
info.maxima = parxextractmatrix(recoinfo,'##$RECO_maxima=');
info.map_min = parxextractmatrix(recoinfo,'##$RECO_map_min=');
info.map_max = parxextractmatrix(recoinfo,'##$RECO_map_max=');
info.map_offset = parxextractmatrix(recoinfo,'##$RECO_map_offset=');
info.map_slope = parxextractmatrix(recoinfo,'##$RECO_map_slope=');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dependent parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Catch empty FOV vector
if isequal(length(info.fov),0)
  info.fov = [0 0 0 0];
end

% Fill 4D sampled spatial dimensions
switch info.ndim
  case 1 % 1D
    info.sampdim(3:4,1) = info.nreps;
  case 2 % 2D
    info.sampdim(1:2,1) = info.sampdim(1:2);
    info.sampdim(3,1)   = info.nims;
    info.sampdim(4,1)   = info.nreps;
  case 3 % 3D
    info.sampdim(1:3,1) = info.sampdim(1:3);
    info.sampdim(4,1)   = info.nreps * info.nims;
  otherwise
    % Do nothing - may require special handling in future
end

% Fill 4D recon spatial dimensions
switch info.ndim
  case 1 % 1D
    info.recodim(3:4,1) = info.nreps;
    info.fov = [info.fov(1); 0.0; 0.0; 0.0];
  case 2 % 2D
    info.recodim(1:2,1) = info.recodim(1:2);
    info.recodim(3,1) = info.nims;
    info.recodim(4,1) = info.nreps;
    info.fov = [info.fov(1:2); 0.0; 0.0];
  case 3 % 3D
    info.recodim(1:3,1) = info.recodim(1:3);
    info.recodim(4,1) = info.nreps * info.nims;
    info.fov = [info.fov(1:3); 0.0];
  otherwise
    % Do nothing - may require special handling in future
end

% Calculate voxel size in um from FOV and recon'd matrix
info.vsize = info.fov ./ (info.recodim + eps) * 1e3;

% Adjust read direction voxel size for displaced UFLARE
if isequal(info.uflare_echopath,'Displaced')
  info.vsize(1) = info.vsize(1) * 2.0;
end
