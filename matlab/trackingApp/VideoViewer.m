classdef VideoViewer < handle
    % VideoViewer  - internal class - display component for video feed
    properties
        Panel
    end
    properties
        ImageAxes
        Image
    end
    
    methods
        function obj  = VideoViewer(figH, units, pos)
            obj.Panel = uipanel('Parent',figH,'Units',units,'Position',pos);
            obj.ImageAxes = axes('Parent',obj.Panel,...
                'Units','norm','Position',[0.025 0.025 0.95 0.95]);
            axis(obj.ImageAxes,'image')
            im = uint8(255*ones(240,320,3));
            obj.Image = imshow(im,'InitialMagnification','fit',...
                'Parent', obj.ImageAxes, 'Border','tight');
        end
        
        function updateImage(obj, im)
            set(obj.Image,'CData',im);
            drawnow();
        end
    end
    
end