function gatherlyxtex(file)
%GATHERLYXTEX Gathers all support files from a lyx-compiled tex file
%
% gatherlyxtex(texfile)
%
% This function gathers together all the child documents of a lyx-generated
% .tex file and places them in the same folder as the main file.  All
% changes are made to copies, so original files are not affected.  This is
% intended to make things easier for submission to journals.
%
% This probably works for non-Lyx files too, but I haven't tried it yet.
%
% Input variables:
%
%   texfile:    name of .tex file to parse.  The new files are added to a
%               new folder called xxx_texfiles, where xxx.tex is this file.

% Copyright 2012 Kelly Kearney


% [pth, fname, ext] = fileparts(file);
% 
% fid = fopen(file);
% txt = textscan(fid, '%s', 'delimiter', '\n');
% fclose(fid);
% txt = txt{1};

file = GetFullPath(file);

%-------------------------
% Find all files needed to
% properly render this
%-------------------------

% Look for any additional tex file included via \include or \input

list = {file, {[], []}};

% texfile{1} = file; % absolute name
% texref{1,1} = [];  % how it's referred to by parent
% texref{1,2} = [];  % parent

nfile = 0;

while size(list,1) > nfile
    prevnum = nfile;
    nfile = size(list,1);
 
    for ii = (prevnum+1):nfile
        [cabs, crel] = findtex(list{ii,1});
        list = addtolist(list, cabs, crel, list{ii,1});
        
    end
end

for ii = 1:size(list,1)
    [~,~,ex] = fileparts(list{ii,1});
    if isempty(ex)
        list{ii,1} = [list{ii,1} '.tex'];
    end
end

        
%         % Classify files as either new, old but referenced differently
%         
%         for ic = 1:length(cabs)
%             [tf, loc] = ismember(cabs{ic}, texfile);
%             if ~tf % is new
%                 newinfo = {cabs{ic} {crel{ic} texfile{ii}}};
%                 texfile = [texfile; newinfo];
%             elseif tf 
%                 texfile{ii,2} = [texfile{ii,2}; [crel texfile{ii}]];
%             end
%         
%         end
%         
%     end
%     
% end

%-------------------------
% Find child files
%-------------------------

clist = cell(0,2);

for it = 1:size(list,1)
    [cabs, crel] = findchild(list{it,1});
    clist = addtolist(clist, cabs, crel, list{it,1});
end

%-------------------------
% Rename files and copy to
% folder
%-------------------------

nref1 = cellfun(@(x) size(x,1), list(:,1));
nref2 = cellfun(@(x) size(x,1), clist(:,1));

if any([nref1; nref2] > 1)
    error('Have not worked out multiple-reference thingy yet');
end

biglist = [list(:,1)  cat(1, list{:,2}); ...
           clist(:,1) cat(1, clist{:,2})];
nall = size(biglist,1);

basename = cellstr(num2str((1:(nall-1))', 'childfile%02d'));
[blah, blah, ext] = cellfun(@fileparts, biglist(2:end,1), 'uni', 0);

newname = cellfun(@(a,b) [a b], basename, ext, 'uni', 0);
newname = ['main.tex'; newname];

biglist = [biglist newname];

% Create new folder

[path, fl, ex] = fileparts(file);
newfolder = sprintf('%s_texfiles', fl);
mkdir(newfolder);

% Replace references in text

texidx = find(regexpfound(biglist(:,end), '\.tex$'));
for ii = texidx'
    
    fid = fopen(biglist{ii,1});
    txt = textscan(fid, '%s', 'delimiter', '\n');
    fclose(fid);
    txt = txt{1};
    
    for ic = 1:nall
        if strcmp(biglist{ii,1}, biglist{ic,3})
            txt = strrep(txt, biglist{ic,2}, biglist{ic,4});
        end
    end
    
    printtextarray(txt, fullfile(newfolder, biglist{ii,4}));
    
end

% Copy files

idx = setdiff(1:nall, texidx);

for ii = idx
    f1 = biglist{ii,1};
    f2 = fullfile(newfolder, biglist{ii,4});
    
    [pth1, fl1, ex1] = fileparts(f1);
    [pth2, fl2, ex2] = fileparts(f2);
    
    if isempty(ex1) && isempty(ex2)
        f1 = fullfile(pth1, [fl1 '.tex']);
        f2 = fullfile(pth2, [fl2 '.tex']);
    else
        copyfile(f1, f2);
    end
        
    
%     copyfile(biglist{ii,1}, fullfile(newfolder, biglist{ii,4}));
end


% 
% %-------------------------
% % Find child files
% %-------------------------
% 
% % Graphics (assuming pdflatex)
%     
% isgph = ~cellfun('isempty', regexp(txt, '\\includegraphics'));
% gphfile = regexp(txt(isgph), '(?<={).*(?=})', 'match', 'once');
% 
% % Include
% 
% isinc = ~cellfun('isempty', regexp(txt, '\\include')) & ~isgph;
% incfile = regexp(txt(isinc), '(?<={).*(?=})', 'match', 'once');
% 
% % Input
% 
% isinp = ~cellfun('isempty', regexp(txt, '\\input'));
% inpfile = regexp(txt(isinp), '(?<={).*(?=})', 'match', 'once');
% 
% % Bibliography file
% 
% isbib = ~cellfun('isempty', regexp(txt, '\\bibliography{'));
% bibfile = regexp(txt(isbib), '(?<={).*(?=})', 'match', 'once');
% 
% % Counts
% 
% ngph = length(gphfile);
% ninc = length(incfile);
% ninp = length(inpfile);
% nbib = length(bibfile);
% 
% %-------------------------
% % Construct full and new
% % file names
% %-------------------------
% 
% % How it's referred to in .tex file 
% 
% refname = [gphfile; incfile; inpfile; bibfile]; 
% nchild = length(refname);
% 
% % Construct full filename by adding extensions and relative path where
% % necessary
% 
% absname = refname;
% 
% for ig = 1:ngph
%     [gpth, gfile, gext] = fileparts(gphfile{ig});
%     if isempty(gext)
%         gext = '.pdf';
%     end
%     absname{ig} = fullfile(gpth, [gfile gext]); 
% end
% 
% for ib = (ngph+ninc+ninp+1):nchild
%     [bpth, bfile, bext] = fileparts(absname{ib});
%     if isempty(bext)
%         bext = '.bib';
%     end
%     absname{ib} = fullfile(bpth, [bfile bext]); 
% end
% 
% 
% for ia = 1:nchild
%    if ~strncmp(absname{ia}, filesep, 1)
%        absname{ia} = fullfile(pth, absname{ia});
%    end
% end
% 
% % Create new names for files
% 
% newname = cell(nchild,1);
% for ii = 1:nchild
%     [blah, blah, ext] = fileparts(absname{ii});
%     newname{ii} = sprintf('childfile%02d%s', ii, ext);
% end
% 
% newrefname = regexprep(newname, '\.pdf$', '');  % Don't need extension for pdfs
% newrefname = regexprep(newrefname, '\.bib$', ''); % ... or bibliography
% 
% % Replace old file references in .tex file text with new ones
% 
% for ii = 1:nchild
%     txt = strrep(txt, refname{ii}, newrefname{ii});
% end
% 
% %-------------------------
% % Create new files
% %-------------------------
% 
% mkdir(newfolder);
% 
% printtextarray(txt, fullfile(newfolder, 'main.tex'));
% 
% for ii = 1:nchild
%    copyfile(absname{ii}, fullfile(newfolder, newname{ii})); 
% end

%-------------------------
% Find files in text
%-------------------------

function [absname, refname] = findtex(file)

[pth, fname, ext] = fileparts(file);

if ~exist(file, 'file')
    [s,r] = system(sprintf('kpsewhich %s', file));
    if ~s
        file = regexprep(r, '\n', '');
    else
        error(r);
    end
end

% if isempty(ext)
%     file = fullfile(pth, [fname '.tex']);
% end

fid = fopen(file);
txt = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);
txt = txt{1};

inpfile = regexp(txt, '(?<=\\input{).*(?=})', 'match');
incfile = regexp(txt, '(?<=\\include{).*(?=})', 'match');

refname = cat(1, inpfile{:}, incfile{:});
absname = getabsolutepath(pth, refname);

function [absname, refname] = findchild(file)

[pth, fname, ext] = fileparts(file);

if ~exist(file, 'file')
    [s,r] = system(sprintf('kpsewhich %s', file));
    if ~s
        file = regexprep(r, '\n', '');
    else
        error(r);
    end
end

% if isempty(ext)
%     file = fullfile(pth, [fname '.tex']);
% end

fid = fopen(file);
txt = textscan(fid, '%s', 'delimiter', '\n');
fclose(fid);
txt = txt{1};

marker = {'includegraphics' 'bibliography'};
ext    = {{'pdf','png'}      {'bib'}}; 

refname = cell(0);
absname = cell(0);
for im = 1:length(marker)
    pattern = ['(?<=\\' marker{im} '{)[^}]*(?=})|(?<=\\' marker{im} '\[[^\]]*\]{)[^}]*(?=})'];
    newfile = regexp(txt, pattern, 'match');
    newfile = cat(1, newfile{:});
    newabs = getabsolutepath(pth, newfile);
    for in = 1:length(newabs)
        [blah, blah, newex] = fileparts(newabs{in});
        if isempty(newex)
            for ie = 1:length(ext{im})
                tmp = [newabs{in} '.' ext{im}{ie}];
                if exist(tmp, 'file')
                    break
                end
            end   
            newabs{in} = tmp;
            
        end
    end
    refname = [refname; newfile];
    absname = [absname; newabs];
end
    
%-------------------------
% Relative to absolute
% path names
%-------------------------

function absname = getabsolutepath(pth, files)

if ischar(files)
    files = {files};
end

isrel = ~strncmp(files, filesep, 1);

tmp = cell(size(files));
for ii = 1:length(tmp)
    if isrel(ii)
        tmp{ii} = fullfile(pth, files{ii});
    else
        tmp{ii} = files{ii};
    end
end
absname = GetFullPath(tmp);

%-------------------------
% Build list of files
%-------------------------

function list = addtolist(list, absname, refname, parent)

for ii = 1:length(absname)
    [tf, loc] = ismember(absname{ii}, list(:,1));
    if tf % Already in list
        list{loc,2} = {refname{ii}, parent};
    else % New entry
        list = [list; {absname{ii}, {refname{ii}, parent}}];
    end 
end
    
    



