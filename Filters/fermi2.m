function H = fermi2(dims, fr, fw, echopos)
% H = fermi2(dims, fr, fw, echopos)
%
% Return the 2D Fermi filter function
%
% ARGS:
% dims  = filter dimensions
% fr    = fractional filter radius in each dimension
% fw    = fractional filter transition width in each dimension
% echopos = fractional echo position in readout window (1st dimension)
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech Biological Imaging Center
% DATES  : 02/04/2003 JMT Adapt from hamming3.m (JMT)

% Default arguments
if nargin < 2, fr = 0.45; end
if nargin < 3, fw = 0.05; end
if nargin < 4, echopos = 0.5; end

if length(fr) == 1, fr = [fr fr]; end
if length(fw) == 1, fw = [fw fw]; end

% Adjust the filter radius for the echo position
fr(1) = 2 * (0.5 + abs(echopos - 0.5)) * fr(1);

% Construct a normalized spatial matrix
FOV = [1 1];
Offset = [-echopos -0.5];
[xc,yc] = voxelgrid2(dims, FOV, Offset);

% Construct 2D Fermi filter matrix
Hx = 1 ./ (1 + exp((abs(xc) - fr(1))/fw(1)));
Hy = 1 ./ (1 + exp((abs(yc) - fr(2))/fw(2)));
H = Hx .* Hy;
