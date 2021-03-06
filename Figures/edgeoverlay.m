function over_edge_rgb = edgeoverlay(bg,over,rng,poscmap,negcmap)
% Overlay edges on an image
%
% over_edge_rgb = edgeoverlay(bg,over,rng,cmap1,cmap2)
%
% Create an overlay on an edge detected anatomic image.
% Intended for CSI, fMRI or SPM overlays.
%
% If overlay is signed, rng is used symmetrically for positive and negative
% values. Hot body colormap is used for positive values. Cold body is used for
% negative values if present.
%
% ARGS:
% bg   = background image
% over = overlay image (signed data allowed)
% rng  = clamp range for overlay
% poscmap = positive range colormap
% negcmap = negative range colormap
%
% RETURNS:
% over_edge_rgb = RGB color overlay image
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech BIC
% DATES  : 08/25/2004 JMT Adapt from ismrm04.m (JMT)
%          08/31/2004 JMT Add return args
%          02/21/2005 JMT Remove return cmap. Add cmap args
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

% Default args
if nargin < 4; poscmap = hot; end
if nargin < 5; negcmap = cold; end

%---------------------------------------------------------------
% Process anatomic reference
%---------------------------------------------------------------

% Resample to make maximum dimension = 1280
[nx,ny] = size(bg);
ar = nx / ny;
if nx > ny
  nxi = 1280;
  nyi = 1280 / ar;
else
  nxi = 1280 * ar;
  nyi = 1280;
end

bg = imresize(bg,[nxi nyi],'bicubic');

% Edge detect
bg_edge = double(edge(bg,'canny',[],1.0));

% Blur out slightly
h = fspecial('gaussian',[3 3],2.0);
bg_edge = imfilter(bg_edge,h);

% Convert background edges to RGB
bg_rgb = colorize(bg_edge,[],gray);

% Resize overlay to same size as background
over = imresize(over,size(bg_edge),'bicubic');

% Colorize positive overlay values
over_pos_rgb = colorize(over, rng, poscmap);

% Colorize negative overlay values
over_neg_rgb = colorize(-over, rng, negcmap);

% Merge positive and negative overlays
over_rgb = over_pos_rgb + over_neg_rgb;
over_rgb(over_rgb > 1) = 1;
over_rgb(over_rgb < 0) = 0;

% Overlay on edge detected anatomy
over_edge_rgb = overlayrgb(over_rgb,bg_rgb,1,0.5,'normal');
