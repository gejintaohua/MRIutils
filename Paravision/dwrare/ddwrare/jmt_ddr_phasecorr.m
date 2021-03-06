function [k_corr, dphi_y, dphi_y_est] = jmt_ddr_phasecorr(k, method, info, phi_0, debug)
% Phase correct DWI k-space using S(0) k-space phase.
%
% SYNTAX: k_corr = jmt_ddr_phasecorr(k,method,info,phi_0,debug)
%
% ARGS:
% k = 3D complex k-space to be corrected
% method = phase correction method:
%   'none'     : no correction applied (debugging)
%   'simple'   : estimate from full k-space
%   'reduced'  : estimate from central k-space
%   'unwrapped': estimate from central k-space with phase unwrapping
% info = information structure for DWI
% phi_0 = reference phase for simple correction
%
% RETURNS:
% k_corr     = phase corrected complex k-space
% dphi_y     = raw per-echo phase difference from reference
% dphi_y_est = estimated per-echo phase correction 
%
% AUTHOR: Mike Tyszka, Ph.D.
% PLACE: Caltech
% DATES: 09/11/2007 JMT From scratch
%        2015-04-05 JMT Update to return per-echo phase vectors
%
% The MIT License (MIT)
%
% Copyright (c) 2016 Mike Tyszka
%
%   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
%   documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
%   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
%   permit persons to whom the Software is furnished to do so, subject to the following conditions:
%
%   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
%   Software.
%
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
%   WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
%   COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
%   OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

fprintf('Phase correction : %s\n', method);

% k-space dimension
[nx,ny,nz] = size(k);

% k-space phase map
phi = angle(k);

% Phase difference between DWI and reference k-spaces
dphi = phi - phi_0;

% Echo train parameters
etl = info.etl;
nshots = fix(ny/info.etl); % Number of RARE shots = block size

switch lower(method)
  
  case 'none'
    
    % Apply null phase correction
    phi_corr = zeros(size(dphi));
  
  case 'simple'
  
    % Phase correction is simple phase difference between current and
    % reference k-spaces. Effectively replaces current phase with reference
    % phase.
    phi_corr = dphi;
    
  case 'reduced'
    
    % Take the median phase of the central even and odd echoes without unwrapping,
    % then replicate to the other echoes assuming even and odd echoes have
    % the same baseline offset.
    
    % Collapse to 2nd dimension using median
    dphi_y = squeeze(median(median(dphi,1),3));
    
    % Adjust phase offset
    dphi_y = dphi_y - fix(median(dphi_y)/(2*pi))*2*pi;
    
    if debug
      figure(10); clf
      subplot(121), plot(dphi_y); title('Median xz projection to y');
    end
    
    % Reshape to nshots x etl
    dphi_y = reshape(dphi_y, [nshots etl]);

    % Create phase correction
    dphi_med = median(dphi_y,1);
    
    % Take median background phase in central two echoes and replicate
    % to whole ky dimension
    e0 = (-info.EncStart1/2 * info.etl);
    
    if e0 == 1
      e1 = e0 + 1;
    else
      e1 = e0 -1;
    end
    
    fprintf('Central echo # = %d\n', e0);
    
    if e0 == fix(e0/2)*2
      e_even = e0; e_odd = e1;
    else
      e_even = e1; e_odd = e0;
    end

    dphi_odd = dphi_med(e_odd);
    dphi_even = dphi_med(e_even);
    dphi_med = repmat([dphi_odd dphi_even],[1 fix(etl/2)]);
    
    % Replicate to size of k-space
    phi_corr = repmat(dphi_med,[nshots 1]);
    phi_corr = phi_corr(:)';
    phi_corr = repmat(phi_corr,[nx 1 nz]);
    
    if debug
      figure(10);
      dphi_corr_y = squeeze(median(median(phi_corr,1),3));
      subplot(122), plot(dphi_corr_y); title('Phase correction (y proj)');
      drawnow
    end

  case 'unwrapped'
    
    % Estimate the phase offset of each echo and the replication across ky
    [~, dphi_y_est] = jmt_ddr_echo_phase_est(dphi, nshots, etl, debug);
    
    % Replicate dphi_y_est back to full k-space to use as a correction
    phi_corr = repmat(dphi_y_est, [nx 1 nz]);
    
  otherwise
    
    % Null correction
    phi_corr = zeros(size(k));
    
end

% Apply phase correction to k-space
k_corr = exp(-1i * phi_corr) .* k;
