function varargout = SDK_colorpicker(varargin)
% SIMPLE_GUI2 Select a data set from the pop-up menu, then
% click one of the plot-type push buttons. Clicking the button
% plots the selected data in the axes.

colors = {'ffcc99','ccff99','99ffcc','ccffff','ccccff','ffbbff','ffcccc','ffffcc','f0f0f0','ff0000','00ff00','0000ff'};
if numel(varargin)==1;
    if isnumeric(varargin{1})
        varargout{1} = SDK_hex2rgb(colors{varargin{1}+1});
        return
    end
    height = 330;
else
    height = 300;
end

%  Create and then hide the UI as it is being constructed.
f = figure('Visible','off','Position',[0,0,60,height]);
set(f, 'MenuBar', 'none');
set(f, 'ToolBar', 'none');



handles = {};
for iColor = 1:numel(colors)
    handles{iColor} = uicontrol('Style','pushbutton',...
            'BackgroundColor',SDK_hex2rgb(colors{iColor})/255,...
             'String','','Position',[0,300-25*iColor,110,25],...
             'Callback',{@setColor,iColor}); 
end
if numel(varargin)==1
uicontrol(f,'Style','text',...
                'String',varargin{1},...
                'Position',[5,300,100,30]);
end
                
                
% Assign the a name to appear in the window title.
f.Name = 'SDK_ColorPicker';
% Move the window to the center of the screen.
movegui(f,'center')
% Make the window visible.
f.Visible = 'on';
uiwait(gcf)



   function setColor(source,eventdata,selectedcolor)
    uiresume(gcf)
    varargout{1} = selectedcolor-1;
    


    close(gcf)
   end

      if nargout==2
        varargout{2} = SDK_hex2rgb(colors(varargout{1}+1))/255;
    end
end