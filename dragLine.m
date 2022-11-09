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
%2016-1-14 V1.0��[-inf inf]system by static_fnc
%2016-1-26 V1.6, add "dragLine.linkline()":
%           Link dragLine objs, when one dragging 1 of each, other will...
%           move synchronously; even synchronous rise each own drag-callback
classdef dragLine < counter & hgsetget
%%% begin counter
	properties (Hidden,Constant)
	  sub_name='dragLine' ;% ����
	end
	methods(Static)
	  function h=findall()%���Ҹ����������Чhandle
		  h = counter.findall(dragLine.sub_name);
	  end
	  function deleteall()%ɾ�������������Чhandle
		  counter.deleteall(dragLine.sub_name);
	  end
	  function num =isexist(objname)%�Ƿ�����Чhandle
		  num = counter.isexist(dragLine.sub_name,objname);
	  end
	end
%%% end counter
    properties (Hidden,Constant)
        %��Ϊ��������Զ���߶Σ����ԣ�����ֱ����΢��������档
        %�Ƽ� 1~10;
        aboveAxisFactor=0;
    end
    properties (SetAccess = protected,Hidden)
        lh_Start; %��Ӧevent
        lh_Draging;
        lh_End;
        lh_reFreshLim;
    end
    properties (SetAccess = protected)
        model; %'x'��'y'
        hline; %ֱ�ߵĶ���
    end
    properties (SetObservable=true) %�����������
        color='r';
        linewidth = 2;
		visible = 'on';	
		paintrange;
	end
	properties
        point; %ֱ�ߵ�����Ҫ����
        
        %�û��Զ��� �ص�����
        %�������@ll1   function ll1(hobj,evnt); �޶�����ֻ��2������
        %����1=Ŀǰ dragLine_hobj, 
        %����2=EventData����<.Source == ����1; EventName='evnt_Darging'>
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
    
    
    methods %����
        function hobj= dragLine(model,point)
           if ~exist('model','var');model='x';end
           model = lower(model);
           if ~strcmp(model,'x')
               if ~strcmp(model,'y'); error('modelȡ''x''��''y''');end;
           end
           hobj.model = lower(model);
           
           %���� line
           xylim = axis;gca;hold on; %auto run "hold on"
           if hobj.model == 'x'
               if ~exist('point','var');point=mean(xlim);end
               xdata = point*[1 1];
               ydata = xylim(3:4);
               hobj.dargPointer='left'; %dragʱ�ļ�ͷ
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
		    k=dragLine.aboveAxisFactor;%����Զϵ�� k>1
		    hobj.paintrange=[xlims(1)-k*range(xlims),xlims(2)+k*range(xlims),...
				ylims(1)-k*range(ylims),ylims(2)+k*range(ylims)];
		   %���ü����������Ա仯
			addlistener(hobj,'color','PostSet',@hobj.SetInnerProp);
			addlistener(hobj,'linewidth','PostSet',@hobj.SetInnerProp);
			addlistener(hobj,'visible','PostSet',@hobj.SetInnerProp);
			addlistener(hobj,'paintrange','PostSet',@hobj.SetInnerProp);
            %set this line larger than axis-range 
            hobj.selffllowup();

        end
        
        function set.point(hobj,point)  
            hobj.point = point;
            if ~ishandle(hobj.hline); return;end; %��������û����
            switch hobj.model
                case 'x'
                    %�ƶ�����
                     set(hobj.hline,'xdata',point*[1 1]);
                case 'y'
                     set(hobj.hline,'ydata',point*[1 1]);
            end
        end
        
        %��������lh, �������û��Զ����callback
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
            %��clear dl1 �޷������ͼ�Σ�ֻ����delete.
           if ishandle (hobj.hline);delete(hobj.hline);end
           delete(hobj.lh_reFreshLim);
        end
        
    end
    
    methods (Access = private) %˽��,drag�������������㲥 drag�¼�
        function FcnStartDrag(hobj,varargin)
            %���ļ�ͷ������windowfcn
            set(gcf,'pointer',hobj.dargPointer);
            hobj.saveWindowFcn.Motion = get(gcf,'WindowButtonMotionFcn');
            hobj.saveWindowFcn.Up = get(gcf,'WindowButtonUpFcn');
            set(gcf,'WindowButtonMotionFcn',@hobj.FcnDraging);
            set(gcf,'WindowButtonUpFcn',@hobj.FcnEndDrag);
            %�㲥�������û��Զ����StartDragCallback
            notify(hobj,'evnt_StartDarg');
        end
        function FcnDraging(hobj,varargin)
            pt = get(gca,'CurrentPoint');
            xpoint = pt(1,1);
            ypoint = pt(1,2);
            switch hobj.model
                case 'x'
                    hobj.point = xpoint; %set ���Դ��� line��ͼ���޸�
%                     set(hobj.hline,'xdata',xpoint*[1 1]);
                case 'y'
                    hobj.point = ypoint;
%                     set(hobj.hline,'ydata',ypoint*[1 1]);
            end
            %�㲥�������û��Զ����DragingCallback
            notify(hobj,'evnt_Darging');
        end
        function FcnEndDrag(hobj,varargin)
            %��ԭ��ͷ����windowfcn
            set(gcf,'pointer','arrow');
            set(gcf,'WindowButtonMotionFcn',hobj.saveWindowFcn.Motion);
            set(gcf,'WindowButtonUpFcn',hobj.saveWindowFcn.Up);
            %�㲥�������û��Զ����EndDragCallback
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
			axis(haxes,lims);%�̶� inactive 'axis tight'
            xlims = lims(1:2);ylims=lims(3:4);
			k=dragLine.aboveAxisFactor; %����Զϵ�� k>1
		    hobj.paintrange=[xlims(1)-k*range(xlims),xlims(2)+k*range(xlims),...
				ylims(1)-k*range(ylims),ylims(2)+k*range(ylims)];		
		end
		
		function selflinkline(hobj_now,hobjs,callbackName,evt)%��Ҫ��������
			% hobjs_other �����ƶ�
			hobjs_other = setdiff(hobjs,hobj_now);
			set(hobjs_other,'point',get(hobj_now,'point'));
			% ��Ҫ�����callback
			if isempty(callbackName);return;end
            % Ҫ�����callback
            for i=1:length(hobjs_other)
                if isempty(hobjs_other(i).(callbackName)); continue; end
                hobjs_other(i).(callbackName)(hobjs_other(i),evt);
                %�ر�ע�⣬��ʱ���ݵ� ��һ������'hobjs_other(i)'�Ǹ�����
                %       �ڶ�����evt��������              
            end
		end
		
    end
	
	methods(Static)
		function fllowup() %ˢ�����е�axes,չ������
			hobjs = dragLine.findall();
            for i=1:length(hobjs)
                hobjs(i).selffllowup()
            end
		end
		function axisauto(haxes) %ָ��һ/���axes�����ʱ��
        %Ĭ��haxes�����е�axes
		%����dragLine���� dragRect������dragRect.axisauto() ��һ���Ե���������
			if ~exist('haxes','var');haxes =findobj('type','axes');end;
			hobjs = dragLine.findall();
			for i=1:length(hobjs) %���ݿɼ�����
				temp{i}=get(hobjs(i),'visible');
            end
            set(hobjs,'visible','off');
			axis(haxes,'auto');
			for i=1:numel(haxes) %�̶�����
				axis(haxes(i),axis(haxes(i)));
			end
			for i=1:length(hobjs) %��ԭ�ɼ�����
				set(hobjs(i),'visible',temp{i});
			end
			dragLine.fllowup(); %��������㡣
		end
		function linkline(hobjs,varargin )	
		%%%ģʽ1 ɾ�����н�������ϵ(�ƶ���callback)
		%demo:		dragLine.linkline('deleteall');
			persistent lh;%cell
			if strcmpi(hobjs,'deleteall')
                if ~isempty(lh);delete([lh{:}]);lh=cell(1,0);end
                return
            end			
		%%%ģʽ2 ������ϵ(�ƶ�����ѡcallback)
			%hobjs:		dragLine����>=2;1_v
			%varargin:(�ɶ�ȡֵ������)
			%		'StartDragCallback' �������ԵĿ�ʼ�϶�callback�������飩
			%		'DragingCallback' �������飩
			%		'EndDragCallback' ����  �飩
			%		''     (������)
            %       'StartDragCallback DragingCallback EndDragCallback'(��������)
			if ~isa(hobjs,'dragLine');error('����������󣬱���Ϊ''dragLine''����!');end
			if length(hobjs)<=1;error('link�������������1!');end
			%% ���������ϵ
			nobjs=length(hobjs);
            contains = @(A, a)~isempty(A)&&~isempty(strfind(A{1}, a));
			if contains(varargin,'StartDragCallback') %�ҵ��ò���
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
