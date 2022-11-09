function hobj = dragLineShow(model, format)
% function hobj = dragLineShow(model, format)
% -----------------Input---------------
% model    : 'x' | 'y', line direction, the same as DRAGLINE
% format   : show STRING
%
% -----------------Output---------------
% hobj     : DRAGLINE HANDLE
%
% -----------------Example---------------
% dragLineShow();
% dragLineShow('y');
% dragLineShow('x', '[x] = %.2f');
% hobj = dragLineShow(__);

%% refine parameters
if nargin==0
    hobj = dragLine();
    format = '[x]: %f\n';
elseif nargin==1
    hobj = dragLine(model);
    format = ['[', hobj.model, ']: %f\n'];
elseif nargin==2
    hobj = dragLine(model);
    if isempty(regexp(format, '\\n', 'match'))
        format = [format, '\n'];
    end
end

%% link to draging callback
format_title = format(1:end-2);
hax = gca();
hobj.DragingCallback = @(o,p)title(hax, sprintf(format_title, hobj.point));
hobj.EndDragCallback = @(o,p)fprintf(format, hobj.point);