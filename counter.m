classdef (Abstract) counter <hgsetget
%不依赖
%用于继承，而非做元素
    %% 子类 唯一需要设定的就是“sub_name”
        %classdef test1<counter %counter<handle
        %properties (Hidden,Constant)
        %   sub_name='test1' ;% 隐藏
        %end
        %methods(Static)
        %   function h=findall()%查找该类的所有有效handle
        %       h = counter.findall(test1.sub_name);
        %   end
        %   function deleteall()%删除该类的所有有效handle
        %       counter.deleteall(test1.sub_name);
        %   end
        %   function num =isexist(objname)%是否有有效handle
        %       num = counter.isexist(test1.sub_name,objname);
        %   end
        %end

    
    %% 请勿修改
    properties (Abstract,Hidden,Constant) %要防止子类自己不断的变更“sub_name”；防止不同类同“sub_name”
        sub_name; %'字符串'且符合变量的命名规范。
    end
    properties (Constant,Access=private)
        datasuit = timer();%只是用其 userdata
    end
    properties (Dependent,Access=private)
        every_sub_hobjs ; %相当于静态变量,记录一个<子对象所有的句柄>
    end
    
    methods
        function data=get.every_sub_hobjs(hobj)
            %父对象下的兄弟姐妹只能得到父'userdata'下自己的那份数据。
            %most important
            familys_data = get(counter.datasuit ,'userdata');
            if ~isfield(familys_data,hobj.sub_name)
                familys_data.(hobj.sub_name)=[];
            end
            data = familys_data.(hobj.sub_name);            
        end
        
        function set.every_sub_hobjs(hobj,data)
            familys_data = get(counter.datasuit ,'userdata');
            familys_data.(hobj.sub_name)=data;
            set(hobj.datasuit ,'userdata', familys_data);
        end
        
        function hobj=counter() %hobj is a sub_handle obj
            data = hobj.every_sub_hobjs;
            data{end+1} = hobj;
            hobj.every_sub_hobjs=data;
        end
        
        function delete(hobj)
            data = hobj.every_sub_hobjs;
            hobjs = counter.findall(hobj.sub_name);
            ind = find(hobjs==hobj);
            data(ind)=[];
            hobj.every_sub_hobjs =data;
        end   
    end
    
    methods (Static)
            function hobjs = findall(sub_name)%返回所有句柄
                familys_data = get(counter.datasuit ,'userdata');
                if ~isfield(familys_data,sub_name)
                    familys_data.(sub_name)=cell(0,1);
                end
                cells = familys_data.(sub_name);
                hobjs = [cells{:}];
            end
            
            function deleteall(sub_name)
                hobjs = counter.findall(sub_name);
                cellfun(@(obj)delete(obj),{hobjs});
            end
             
            function num =isexist(sub_name,objname)
                %hobj2表示要查找的。
                %是否对象依然存在。1==没被删除的句柄，0==句柄后的对象已经清除
                 if length(objname)>1;error('请输入单个元素');end;
                 hobjs = counter.findall(sub_name);
                if isempty(hobjs)
                    warning('发现对象早已完全清空，返回0')
                    num=false;
                    return;
                end
                ind = find(hobjs==objname);
                num = length(ind)>=1;%实际上只会 ==1 或==0
            end
    end
    
end