function srfittest
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

n = 16;
nreps = 100;
T1 = 111;
A = 5;
SNR = 30;

t  = linspace(0,5*T1,n);
s0 = A * (1 - exp(-t / T1));

tc = zeros(1,nreps);

for rc = 1:nreps
  
  sn = s0 + randn(1,n) * A / SNR;

  tic;
  [Afit, T1fit, sfit] = srfit(t,sn);
  tc(rc) = toc;
  
  plot(t,s0,t,sn,'o',t,sfit);
  drawnow;

  fprintf('T1 = %0.3f (%0.3f)\n', T1fit, T1);

end

fprintf('Mean time = %0.3fs\n', mean(tc));
