function [theta_total, axis_total] = total_rotation(theta_x, theta_y, theta_z)
% Total rotation for a three-axis gimble rotation
%
% USAGE : [theta_total, axis_total] = total_rotation(theta_x, theta_y, theta_z)
%
% Adapted from the discussion thread at http://www.mathworks.com/matlabcentral/newsreader/view_thread/160945
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech
% DATES  : 2012-02-10 JMT From scratch
%          2015-01-21 JMT Add total rotation axis code from thread above
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

theta_x = theta_x(:);
theta_y = theta_y(:);
theta_z = theta_z(:);

% Find length of angle vectors
n = length(theta_x);

% Make space for results
theta_total = zeros(n,1);
axis_total  = zeros(n,3);

for ac = 1:length(theta_x)
  
  % Construct total rotation matrix
  ctx = cos(theta_x(ac));
  stx = sin(theta_x(ac));
  Rx = [1 0 0; 0 ctx -stx; 0 stx ctx];
  
  cty = cos(theta_y(ac));
  sty = sin(theta_y(ac));
  Ry = [cty 0 sty; 0 1 0; -sty 0 cty];
  
  ctz = cos(theta_z(ac));
  stz = sin(theta_z(ac));
  Rz = [ctz -stz 0; stz ctz 0; 0 0 1];
  
  % Total rotation matrix
  A = Rz * Ry * Rx;
  
  % Direct calculation of angle and axis from A
  % Code adapted from thread response by Bruno Luong
  
  % Rotation axis u = [x, y, z]
  u = [ A(3,2)-A(2,3), A(1,3)-A(3,1), A(2,1)-A(1,2) ];

  % Rotation sine and cosine
  c = trace(A) - 1;
  s = norm(u);
  
  % Better than using acos or asin
  theta_total(ac) = atan2(s,c);
  
  % Adjust rotation to be positive, flipping axis if necessary
  if s > 0
    u = u/s;
  else
    % warning('A close to identity, arbitrary result');
    u = [1, 0, 0];
  end
  
  % Save axis result
  axis_total(ac,:) = u;

end
