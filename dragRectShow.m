function hobj = dragRectShow(model, format)
% function hobj = dragRectShow(model, format)
% -----------------Input---------------
% model    : 'x' | 'y', line direction, the same as DRAGRECT
% format   : show STRING
%
% -----------------Output---------------
% hobj     : DRAGRECT HANDLE
%
% -----------------Example---------------
% dragRectShow();
% dragRectShow('yy');
% dragRectShow('xx', '[xx]:(%5.2f, %5.2f)\n[dx]: %5.2f');
% hobj = dragRectShow(__);

%% refine parameters
if nargin==0
    hobj = dragRect('xx');
elseif nargin>=1
    assert(ismember(model, {'xx', 'yy'}));
    hobj = dragRect(model);
end
isx = isequal(hobj.model, 'xx');
if nargin<2
    char1 = {'yy', 'xx'};
    char2 = {'dy', 'dx'};
    format = ['[',char1{isx+1}, ']: %f, %f\n[', char2{isx+1}, ']: %f\n'];
elseif nargin==2
    if isempty(regexp(format, '\\n$', 'match'))
        format = [format, '\n'];
    end
end
if isx 
    points1 = @()hobj.xPoints(1);
    points2 = @()hobj.xPoints(2);
    dpoints = @()hobj.xPoints(2)-hobj.xPoints(1);
else
    points1 = @()hobj.yPoints(1);
    points2 = @()hobj.yPoints(2);
    dpoints = @()hobj.yPoints(2)-hobj.yPoints(1);
end
%% link to draging callback
format_title = format(1:end-2);
hobj.DragingCallback = @(o,p)title(sprintf(format_title, points1(), points2(), dpoints()));
hobj.EndDragCallback = @(o,p)fprintf(format, points1(), points2(), dpoints());