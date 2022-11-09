classdef (Abstract) counter <hgsetget
%������
%���ڼ̳У�������Ԫ��
    %% ���� Ψһ��Ҫ�趨�ľ��ǡ�sub_name��
        %classdef test1<counter %counter<handle
        %properties (Hidden,Constant)
        %   sub_name='test1' ;% ����
        %end
        %methods(Static)
        %   function h=findall()%���Ҹ����������Чhandle
        %       h = counter.findall(test1.sub_name);
        %   end
        %   function deleteall()%ɾ�������������Чhandle
        %       counter.deleteall(test1.sub_name);
        %   end
        %   function num =isexist(objname)%�Ƿ�����Чhandle
        %       num = counter.isexist(test1.sub_name,objname);
        %   end
        %end

    
    %% �����޸�
    properties (Abstract,Hidden,Constant) %Ҫ��ֹ�����Լ����ϵı����sub_name������ֹ��ͬ��ͬ��sub_name��
        sub_name; %'�ַ���'�ҷ��ϱ����������淶��
    end
    properties (Constant,Access=private)
        datasuit = timer();%ֻ������ userdata
    end
    properties (Dependent,Access=private)
        every_sub_hobjs ; %�൱�ھ�̬����,��¼һ��<�Ӷ������еľ��>
    end
    
    methods
        function data=get.every_sub_hobjs(hobj)
            %�������µ��ֵܽ���ֻ�ܵõ���'userdata'���Լ����Ƿ����ݡ�
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
            function hobjs = findall(sub_name)%�������о��
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
                %hobj2��ʾҪ���ҵġ�
                %�Ƿ������Ȼ���ڡ�1==û��ɾ���ľ����0==�����Ķ����Ѿ����
                 if length(objname)>1;error('�����뵥��Ԫ��');end;
                 hobjs = counter.findall(sub_name);
                if isempty(hobjs)
                    warning('���ֶ���������ȫ��գ�����0')
                    num=false;
                    return;
                end
                ind = find(hobjs==objname);
                num = length(ind)>=1;%ʵ����ֻ�� ==1 ��==0
            end
    end
    
end