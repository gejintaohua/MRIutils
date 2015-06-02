function kf = pvmspatfilt(k, filttype, fr, fw, echopos)
% Apply spatial filter to k-space data
%
% SYNTAX: kf = pvmspatfilt(k, filttype, fr, fw, echopos)
%
% ARGS:
% k = 2D or 3D complex k-space
% filttype = filter type: 'hamming','gauss','fermi'
% fr = normalized filter radius or PSF FWHM for Gauss filtering [0.5]
% fw = normalized filter width (0 - 0.5) [0.0]. Unused by Gauss filtering
% echopos = echo location in 1st dimension (0-100%) [50%]
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech
% DATES  : 09/10/2007 JMT Extract and adapt from parxrecon.m
%          2015-04-05 JMT Map fr to FWHM for Gauss filtering
%
% Copyright 2007-2015 California Institute of Technology.
% All rights reserved.

% k-space dimensionality (presumed <= 3)
nDim = ndims(k);
[nx,ny,nz] = size(k);

%----------------------------------------------------------
% Spatial filter
%----------------------------------------------------------

switch filttype

  case 'hamming'

    switch nDim
      case 2
        Hfilt = hamming2([nx ny], fr, echopos/100);
        Hfilt = repmat(Hfilt,[1 1 nz]);
      case 3
        Hfilt = hamming3([nx ny nz], fr, echopos/100);
    end

    % Apply filter
    kf = k .* Hfilt;

  case 'gauss'
    
    % For Gauss filtering, fr is the FWHM of the PSF in voxels
    FWHM = fr;

    switch nDim
      case 2
        Hfilt = gauss2([nx ny], FWHM, echopos/100);
        Hfilt = repmat(Hfilt,[1 1 nz]);
      case 3
        Hfilt = gauss3([nx ny nz], FWHM, echopos/100);
    end

    % Apply filter
    kf = k .* Hfilt;

  case 'fermi'

    switch nDim
      case 2
        Hfilt = fermi2([nx ny], fr, fw, echopos/100);
      case 3
        Hfilt = fermi3([nx ny nz], fr, fw, echopos/100);
    end

    % Apply filter
    kf = k .* Hfilt;

  otherwise

    % Do nothing
    kf = k;
    
end