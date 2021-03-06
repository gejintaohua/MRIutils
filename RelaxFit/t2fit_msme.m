function [T2,S0,C,Mask] = t2fitim(examdir,scanno,verbose)
% [T2,S0,C,Mask] = t2fitim(examdir,scanno,verbose)
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech BIC
% DATES  : 02/13/2003 JMT From scratch. Use srfitn and srfit (JMT)
%          11/06/2007 JMT Update for PV4.0
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

fprintf('T2 Mapping : Pv4.0\n');
fprintf('--------------------------\n');
fprintf('AUTHOR: Mike Tyszka, Ph.D.\n');
fprintf('Copyright 2007 Caltech\n');

% Initialize return arguments
T2 = [];
S0 = [];
C  = [];
Mask = [];

if nargin < 2
  help t2fitim
  return
end

% Verbosity flag
% 0 = no verbose output
% 1 = fit text results only
% 2 = fit text and graph
if nargin < 3 verbose = 2; end

if isempty(examdir) examdir = pwd; end

scandir = fullfile(examdir,num2str(scanno));
  
fprintf('Loading scan %d\n', scanno);

options.filttype = 'none';
[ME,info,errmsg] = parxrecon(scandir,options);

if ~isempty(errmsg)
  fprintf(errmsg);
  return
end

ME = squeeze(ME);

% Gauss filter image
gauss_fwhm = 1.0;
fprintf('Gauss filtering : FWHM = %0.1f\n',gauss_fwhm);
ne = size(ME,3);
for ic = 1:ne
  ME(:,:,ic) = gaussfilt2(ME(:,:,ic),gauss_fwhm);
end

fprintf('TE      : %0.3f ms\n', info.te);
fprintf('NEchoes : %d\n', info.nechoes);

% Construct echo time vector
nt = info.nechoes;
TE = (1:nt) * info.te;

% Start stopwatch
t0 = clock;

% Fit T2 equation to the image stack
[S0, T2, C, Mask] = t2fitn(TE, ME, verbose);

% Report calculation time
t = etime(clock,t0);
fprintf('Elapsed time : %0.1fs\n',t);

% Save results
fprintf('Saving results to T2_fit_results\n');
save T2_fit_results info S0 T2 C Mask

% Display results figure
figure(1); clf; colormap(flame);
subplot(121), imagesc(T2,robustrange(T2)); axis image xy off; title('T2 (ms)'); colorbar;
subplot(122), imagesc(S0,robustrange(S0)); axis image xy off; title('S0 (AU)'); colorbar;

fprintf('Printing figure to T2_fit_figure.png\n');
print('T2_fit_figure.png','-dpng','-r300');
