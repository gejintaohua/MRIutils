function [s_ap,phi_c] = pvmcsiautophase(ppm,s,ppmA,ppmB,verbose)
% [s_ap,phi]  = pvmcsiautophase(ppm,s,ppmA,ppmB,verbose)
%
% 0th and 1st order auto phasing of a typical 1H CSI spectrum
%
% ARGS:
% ppm  = chemical shift vector
% s    = complex spectrum (same size as ppm)
% ppmA = ppm limits for region A (min max)
% ppmB = ppm limits for region B (min max)
% verbose = verbosity flag (0 = no output, 1 = graph output)
%
% RETURNS:
% s_ap  = linear phase corrected spectrum
% phi_c = linear phase correction coefficients
%         phi(ppm) = phi_c(1) * ppm + phi_c(2)
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech BIC
% DATES  : 02/09/2004 JMT From scratch
%          01/17/2006 JMT M-Lint corrections
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

if nargin < 3; ppmA = [0 3]; end
if nargin < 4; ppmB = [3 6]; end
if nargin < 5; verbose = 0; end

% Flatten vectors
s = s(:);
ppm = ppm(:);

m_ppmA = mean(ppmA);
m_ppmB = mean(ppmB);

s_sA = sum(s(ppm >= ppmA(1) & ppm <= ppmA(2)));
s_sB = sum(s(ppm >= ppmB(1) & ppm <= ppmB(2)));

phiA = angle(s_sA);
phiB = angle(s_sB);

% Duplicate phase if signal from one region dominates the other
if s_sA / s_sB > 10
  phiB = phiA;
end
if s_sB / s_sA > 10
  phiA = phiB;
end

% Correct for proximity to -pi or +pi
dphi = phiB - phiA;
if dphi > pi; phiB = phiB - 2 * pi; end
if dphi < -pi; phiB = phiB + 2 * pi; end

phi_c = polyfit([m_ppmA m_ppmB],[phiA phiB],1);

phi = polyval(phi_c,ppm);

s_ap = s .* exp(-i * phi);

if verbose
  plot(ppm, real(s), ppm, real(s_ap));
  legend('Original','Phased');
end
