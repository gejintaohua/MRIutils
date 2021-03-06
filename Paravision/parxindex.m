function parxindex(rootdir, indexfile)
% PARXINDEX : Create text index of Paravision studies
%
% AUTHOR : Mike Tyszka, Ph.D.
% PLACE  : Caltech BIC
% DATES  : 05/21/2001 From scratch
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

% Splash text
fprintf('\n');
fprintf('Paravision Indexer\n');
fprintf('------------------\n');

% Defaults
if nargin < 1
  rootdir = '.';
end
if nargin < 2
  indexfile = fullfile(rootdir,'index.txt');
end

% Get a cell structure array containing info about all PARX series in rootdir
fprintf('Search directory tree for Paravision data ... ');
serlist = parxfindseries([], rootdir, [], {});
fprintf('done\n');

% Write the index
fprintf('Writing the index file to :\n  %s\n', indexfile);
fd = fopen(indexfile, 'w');
if fd < 0
  fprintf('*** ERROR : Could not open index file to write ***\n');
  return
end

% Column headers
fprintf(fd,'%s\t','ExamID');
fprintf(fd,'%s\t','StudyName');
fprintf(fd,'%s\t','Study');
fprintf(fd,'%s\t','Series');
fprintf(fd,'%s\t','Name');
fprintf(fd,'%s\t','Date');
fprintf(fd,'%s\t','Method');
fprintf(fd,'%s\t','TRms');
fprintf(fd,'%s\t','TEms');
fprintf(fd,'%s\t','Dims');
fprintf(fd,'%s\t','DIMx','DIMy','DIMz','NIms');
fprintf(fd,'%s\t','FOVxcm','FOVycm','FOVzcm');
fprintf(fd,'%s\t','Slicemm');
fprintf(fd,'%s','Remarks');
fprintf(fd,'\n');

% Loop over all exams

for sc = 1:length(serlist)
  
  se = serlist(sc);

  % Zero pad FOV to length 3
  if length(se.fov) < 3
    fov = zeros(1:3);
    fov(1:length(se.fov)) = se.fov;
  else
    fov = se.fov;
  end

  fprintf(fd,'%s\t', se.id);
  fprintf(fd,'%s\t',se.studyname);
  fprintf(fd,'%d\t', se.studyno);
  fprintf(fd,'%d\t', se.serno);
  fprintf(fd,'%s\t', se.name);
  fprintf(fd,'%s\t', se.time);
  fprintf(fd,'%s\t', se.method);
  fprintf(fd,'%0.1f\t', se.tr);
  fprintf(fd,'%0.1f\t', se.te);
  fprintf(fd,'%d\t', se.ndim);
  fprintf(fd,'%d\t', se.dim); % Repeated for each DIM element
  fprintf(fd,'%0.1f\t', fov(1:3)); % Repeated for each FOV element
  fprintf(fd,'%0.2f\t', se.slthick);

  % Replace white-space in remarks with underscores
  se.remarks(findstr(se.remarks,' ')) = '_';
  fprintf(fd,'%s', se.remarks);
  
  fprintf(fd,'\n');
end

% Close the index file
fclose(fd);
