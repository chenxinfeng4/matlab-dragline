% hobj = dragLine(model,point);
% --------------------Example-------------------
% ---Create---
% dragLine();          %add a dragLine in X-DIRECTION
% dragLine('y');       %add a dragLine in Y-DIRECTION
% dragLine('x', 3);    %add a dragLine in X-DIRECTION, X==3
% hobj = dragLine(__); %assign dragLine to a HANDLE
%
% ---Property---
% hobj.color = 'b';    %set LINE-COLOR
% hobj.point = 3;      %set dragLine position
% point = hobj.point;  %get dragLine position
% hline = hobj.hline;  %retrieve the core LINE-OBJECT
%
% ---Drag Callback---
% hobj.StartDragCallback = @(o,p)fprintf('Bg = %f\n', o.point); %Begin
% hobj.DragingCallback   = @(o,p)fprintf('...  %f\n', o.point); %Draging
% hobj.EndDragCallback   = @(o,p)fprintf('Ed =  %f\n', o.point); %Draging
%
% ---Refresh Length---
% hobj.axisauto();      %refresh a DRAGLINE by fitting its length to axis
% dragLine.fllowup();   %refresh all DRAGLINEs
%
% ---Link DragLines----
% dragLine.linkline([hobj1 hobj2]);        %let them move simultaneously.
% dragLine.linkline([hobj1 hobj2], 'StartDragCallback'); %link callbacks.
% dragLine.linkline([hobj1 hobj2], ...
%        'StartDragCallback DragingCallback EndDragCallback'); %all callbacks.
%
%Chenxinfeng, Huazhong University of Science and Technology
%2016-1-14 V1.0，[-inf inf]system by static_fnc
%2016-1-26 V1.6, add "dragLine.linkline()":
%           Link dragLine objs, when one dragging 1 of each, other will...
%           move synchronously; even synchronous rise each own drag-callback
classdef dragLine < counter & hgsetget
%%% begin counter
	properties (Hidden,Constant)
	  sub_name='dragLine' ;% 隐藏
	end
	methods(Static)
	  function h=findall()%查找该类的所有有效handle
		  h = counter.findall(dragLine.sub_name);
	  end
	  function deleteall()%删除该类的所有有效handle
		  counter.deleteall(dragLine.sub_name);
	  end
	  function num =isexist(objname)%是否有有效handle
		  num = counter.isexist(dragLine.sub_name,objname);
	  end
	end
%%% end counter
    properties (Hidden,Constant)
        %因为不是无限远的线段，所以，设置直线稍微长于轴界面。
        %推荐 1~10;
        aboveAxisFactor=0;
    end
    properties (SetAccess = protected,Hidden)
        lh_Start; %对应event
        lh_Draging;
        lh_End;
        lh_reFreshLim;
    end
    properties (SetAccess = protected)
        model; %'x'或'y'
        hline; %直线的对象
    end
    properties (SetObservable=true) %对象固有属性
        color='r';
        linewidth = 2;
		visible = 'on';	
		paintrange;
	end
	properties
        point; %直线的最重要属性
        
        %用户自定义 回调函数
        %句柄，如@ll1   function ll1(hobj,evnt); 限定有且只有2个参数
        %参数1=目前 dragLine_hobj, 
        %参数2=EventData对象<.Source == 参数1; EventName='evnt_Darging'>
        StartDragCallback;    
        DragingCallback;
        EndDragCallback;
    end
    properties (Access = private)
       saveWindowFcn;
       dargPointer;
    end
    events
       evnt_StartDarg;
       evnt_Darging;
       evnt_EndDarg;
    end
    
    
    methods %公有
        function hobj= dragLine(model,point)
           if ~exist('model','var');model='x';end
           model = lower(model);
           if ~strcmp(model,'x')
               if ~strcmp(model,'y'); error('model取''x''或''y''');end;
           end
           hobj.model = lower(model);
           
           %制作 line
           xylim = axis;gca;hold on; %auto run "hold on"
           if hobj.model == 'x'
               if ~exist('point','var');point=mean(xlim);end
               xdata = point*[1 1];
               ydata = xylim(3:4);
               hobj.dargPointer='left'; %drag时的箭头
           else
               if ~exist('point','var');point=mean(ylim);end
               xdata = xylim(1:2);
               ydata = point*[1 1];
               hobj.dargPointer='top';
           end
           hobj.point = point;
           hobj.hline = plot(xdata,ydata,...
               'color',hobj.color,...
               'linewidth',hobj.linewidth);
           set(hobj.hline,'ButtonDownFcn',@hobj.FcnStartDrag)
		   addlistener(hobj.hline,'ObjectBeingDestroyed',@(o,e)hobj.delete());
		   %set as fix axis
		    axis([xlim ylim]);
            xlims=xlim;ylims=ylim;
		    k=dragLine.aboveAxisFactor;%无线远系数 k>1
		    hobj.paintrange=[xlims(1)-k*range(xlims),xlims(2)+k*range(xlims),...
				ylims(1)-k*range(ylims),ylims(2)+k*range(ylims)];
		   %设置监听固有属性变化
			addlistener(hobj,'color','PostSet',@hobj.SetInnerProp);
			addlistener(hobj,'linewidth','PostSet',@hobj.SetInnerProp);
			addlistener(hobj,'visible','PostSet',@hobj.SetInnerProp);
			addlistener(hobj,'paintrange','PostSet',@hobj.SetInnerProp);
            %set this line larger than axis-range 
            hobj.selffllowup();

        end
        
        function set.point(hobj,point)  
            hobj.point = point;
            if ~ishandle(hobj.hline); return;end; %可能线条没建立
            switch hobj.model
                case 'x'
                    %移动线条
                     set(hobj.hline,'xdata',point*[1 1]);
                case 'y'
                     set(hobj.hline,'ydata',point*[1 1]);
            end
        end
        
        %定义听众lh, 当设置用户自定义的callback
        function set.StartDragCallback(hobj,hfcn)
           delete(hobj.lh_Start);
           if isempty(hfcn);hfcn=@(x,y)[];end;
           hobj.StartDragCallback = hfcn;
           hobj.lh_Start = addlistener(hobj,'evnt_StartDarg',hfcn);
        end
        function set.DragingCallback(hobj,hfcn)
           delete(hobj.lh_Draging);
           if isempty(hfcn);hfcn=@(x,y)[];end;
           hobj.DragingCallback = hfcn;
           hobj.lh_Draging = addlistener(hobj,'evnt_Darging',hfcn);
        end
        function set.EndDragCallback(hobj,hfcn)
           delete(hobj.lh_End);
           if isempty(hfcn);hfcn=@(x,y)[];end;
           hobj.EndDragCallback = hfcn;
           hobj.lh_End = addlistener(hobj,'evnt_EndDarg',hfcn);
        end
        function delete(hobj)
            %用clear dl1 无法清除该图形，只能用delete.
           if ishandle (hobj.hline);delete(hobj.hline);end
           delete(hobj.lh_reFreshLim);
        end
        
    end
    
    methods (Access = private) %私有,drag线条（自身），广播 drag事件
        function FcnStartDrag(hobj,varargin)
            %更改箭头，保存windowfcn
            set(gcf,'pointer',hobj.dargPointer);
            hobj.saveWindowFcn.Motion = get(gcf,'WindowButtonMotionFcn');
            hobj.saveWindowFcn.Up = get(gcf,'WindowButtonUpFcn');
            set(gcf,'WindowButtonMotionFcn',@hobj.FcnDraging);
            set(gcf,'WindowButtonUpFcn',@hobj.FcnEndDrag);
            %广播，运行用户自定义的StartDragCallback
            notify(hobj,'evnt_StartDarg');
        end
        function FcnDraging(hobj,varargin)
            pt = get(gca,'CurrentPoint');
            xpoint = pt(1,1);
            ypoint = pt(1,2);
            switch hobj.model
                case 'x'
                    hobj.point = xpoint; %set 属性触发 line的图像修改
%                     set(hobj.hline,'xdata',xpoint*[1 1]);
                case 'y'
                    hobj.point = ypoint;
%                     set(hobj.hline,'ydata',ypoint*[1 1]);
            end
            %广播，运行用户自定义的DragingCallback
            notify(hobj,'evnt_Darging');
        end
        function FcnEndDrag(hobj,varargin)
            %还原箭头，和windowfcn
            set(gcf,'pointer','arrow');
            set(gcf,'WindowButtonMotionFcn',hobj.saveWindowFcn.Motion);
            set(gcf,'WindowButtonUpFcn',hobj.saveWindowFcn.Up);
            %广播，运行用户自定义的EndDragCallback
            notify(hobj,'evnt_EndDarg');
        end
		function SetInnerProp(hobj,varargin)
			set(hobj.hline,'color',hobj.color);
			set(hobj.hline,'linewidth',hobj.linewidth);
			set(hobj.hline,'visible',hobj.visible);
			switch hobj.model
                case 'x'
                    set(hobj.hline,'ydata',hobj.paintrange(3:4)); 
                case 'y'
                    set(hobj.hline,'xdata',hobj.paintrange(1:2));
            end
		end
		
		function selffllowup(hobj)
			haxes = get(hobj.hline,'parent');
			lims =axis(haxes);
			axis(haxes,lims);%固定 inactive 'axis tight'
            xlims = lims(1:2);ylims=lims(3:4);
			k=dragLine.aboveAxisFactor; %无线远系数 k>1
		    hobj.paintrange=[xlims(1)-k*range(xlims),xlims(2)+k*range(xlims),...
				ylims(1)-k*range(ylims),ylims(2)+k*range(ylims)];		
		end
		
		function selflinkline(hobj_now,hobjs,callbackName,evt)%不要主动调用
			% hobjs_other 红线移动
			hobjs_other = setdiff(hobjs,hobj_now);
			set(hobjs_other,'point',get(hobj_now,'point'));
			% 不要求调用callback
			if isempty(callbackName);return;end
            % 要求调用callback
            for i=1:length(hobjs_other)
                if isempty(hobjs_other(i).(callbackName)); continue; end
                hobjs_other(i).(callbackName)(hobjs_other(i),evt);
                %特别注意，此时传递的 第一参数是'hobjs_other(i)'是跟随者
                %       第二参数evt是主导者              
            end
		end
		
    end
	
	methods(Static)
		function fllowup() %刷新所有的axes,展现线条
			hobjs = dragLine.findall();
            for i=1:length(hobjs)
                hobjs(i).selffllowup()
            end
		end
		function axisauto(haxes) %指定一/多个axes，合适标度
        %默认haxes是所有的axes
		%既有dragLine又有 dragRect，请用dragRect.axisauto() 可一次性调整！！！
			if ~exist('haxes','var');haxes =findobj('type','axes');end;
			hobjs = dragLine.findall();
			for i=1:length(hobjs) %备份可见属性
				temp{i}=get(hobjs(i),'visible');
            end
            set(hobjs,'visible','off');
			axis(haxes,'auto');
			for i=1:numel(haxes) %固定好轴
				axis(haxes(i),axis(haxes(i)));
			end
			for i=1:length(hobjs) %还原可见属性
				set(hobjs(i),'visible',temp{i});
			end
			dragLine.fllowup(); %这样方便点。
		end
		function linkline(hobjs,varargin )	
		%%%模式1 删除所有建立的联系(移动和callback)
		%demo:		dragLine.linkline('deleteall');
			persistent lh;%cell
			if strcmpi(hobjs,'deleteall')
                if ~isempty(lh);delete([lh{:}]);lh=cell(1,0);end
                return
            end			
		%%%模式2 建立联系(移动，可选callback)
			%hobjs:		dragLine对象>=2;1_v
			%varargin:(可多取值，或无)
			%		'StartDragCallback' 触发各自的开始拖动callback（不建议）
			%		'DragingCallback' （不建议）
			%		'EndDragCallback' （建  议）
			%		''     (不链接)
            %       'StartDragCallback DragingCallback EndDragCallback'(链接所有)
			if ~isa(hobjs,'dragLine');error('输入参数错误，必须为''dragLine''对象!');end
			if length(hobjs)<=1;error('link的数量必须大于1!');end
			%% 逐个建立联系
			nobjs=length(hobjs);
            contains = @(A, a)~isempty(A)&&~isempty(strfind(A{1}, a));
			if contains(varargin,'StartDragCallback') %找到该参数
				for i=1:nobjs
                    hobj_now=hobjs(i);
					lh{end+1}=addlistener(hobj_now,'evnt_StartDarg',...
						@(o,e)hobj_now.selflinkline(hobjs,'StartDragCallback',e));
                end
                disp('Done link StartDragCallback');
			end
			if contains(varargin,'DragingCallback')
				for i=1:nobjs
                    hobj_now=hobjs(i);
					lh{end+1}=addlistener(hobj_now,'evnt_Darging',...
						@(o,e)hobj_now.selflinkline(hobjs,'DragingCallback',e));
                end
                disp('Done link DragingCallback');
			else
				for i=1:nobjs
                    hobj_now=hobjs(i);
					lh{end+1}=addlistener(hobj_now,'evnt_Darging',...
						@(o,e)hobj_now.selflinkline(hobjs,''));
				end		
			end
			if contains(varargin,'EndDragCallback')
				for i=1:nobjs
                    hobj_now=hobjs(i);
					lh{end+1}=addlistener(hobj_now,'evnt_EndDarg',...
						@(o,e)hobj_now.selflinkline(hobjs,'EndDragCallback',e));
                end
                disp('Done link EndDragCallback');
			else
				for i=1:nobjs
                    hobj_now=hobjs(i);
					lh{end+1}=addlistener(hobj_now,'evnt_EndDarg',...
						@(o,e)hobj_now.selflinkline(hobjs,''));
				end		
            end
            disp('Done link Movement');
		end%end function
	end
end
