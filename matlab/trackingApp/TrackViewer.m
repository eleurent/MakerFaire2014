% Copyright 2014 The MathWorks, Inc.
classdef TrackViewer < handle
    % TrackViewer  - internal class - display component for the followed track

    properties (Access = private)
        Theta = 0;
        FlashDuration = 5;
    end
    properties
        Panel
        Image
        Axes
    end
    properties (Access = private)
        VideoView
        Track
        TargetsFound
        TargetsRemaining
        TargetsLocated
        TargetsLabel
        Robot
        Highlight
        VisibilityPatch
        BackGround
    end
    
    methods
        function obj  = TrackViewer(figH, units, pos)
            obj.Panel = uipanel('Parent',figH,'Units',units,'Position',pos);
            obj.createApp();
        end
        
        function update(obj, track, targets, found, located,pcam,lcam,robotheta)
            
            set(obj.Track, 'XData',track(:,1),'YData',track(:,2));
            set(obj.TargetsFound,'XData',targets(found,1),'YData',targets(found,2));
            set(obj.TargetsRemaining,'XData',targets(~found,1),'YData',targets(~found,2));
            set(obj.TargetsLocated,'XData',located(:,1),'YData',located(:,2));

            %update labels            
            ntargets = max(size(targets));
            update_labels = @(lh, x, y, num) set(lh, 'Position', [x, y]-1,'String',num2str(num), 'Color',[0.8 0 0],'FontWeight','bold');
            arrayfun(update_labels, obj.TargetsLabel(1:ntargets), targets(:,1), targets(:,2),(1:ntargets)');
            
            %update visibility trapez
            %1. In robot PoV
            xTrapezRobot = [pcam(1) pcam(2) pcam(2) pcam(1)] ;
            yTrapezRobot = [-lcam(1)/2 -lcam(2)/2 lcam(2)/2 pcam(1)/2] ;
            
            %2. In absolute PoV
            xyRobotAbsolute = [cosd(robotheta) -sind(robotheta) ; ...
                sind(robotheta) cosd(robotheta)] * ...
                [xTrapezRobot;yTrapezRobot];
            set(obj.VisibilityPatch,...
                'XData',xyRobotAbsolute(1,:)+track(end,1),...
                'YData',xyRobotAbsolute(2,:)+track(end,2));
            
            %update robot image position
            
            if isempty(track) || isnan(track(end,1))
                Mx = makehgtform('translate',[-10 -10 0]); %Move out of view
            else
                pos = track(end,:);
                Mx = makehgtform('translate',[pos(1), pos(2), 0]);
                %if size(track,1)>=2 && sum((pos-track(end-1,:)).^2) >= 0.015^2 % O.Dufour (08/04/2014): Commented to update robot direction everytime
                    obj.Theta = robotheta / 180*pi;
                %end
                Rx = makehgtform('zrotate',obj.Theta);
                %Mx = Mx*Rx;
                Mx = Mx*Rx*makehgtform('scale',1.3);
            end
            set(obj.Robot,'Matrix',Mx);
            drawnow()

            % adjust hilight icon
            if ~isempty(obj.Highlight)
                if all(~found)
                    delete(obj.Highlight(ishghandle(obj.Highlight)));
                    obj.Highlight = [];
                    return
                end
                
                s = get(obj.Highlight,{'MarkerSize'});
                s = [s{:}];
                for i = 1:length(obj.Highlight)
                    set(obj.Highlight(i),'MarkerSize' , max(s(i)-1, 15))
                end
                
            end
        end
        
        function  highlightFoundTarget(obj, target)
            obj.Highlight(end+1) = line(target(1),target(2),...
                'Color',[0 0.6 0],'LineStyle','none',...
                'lineWidth',2,'Marker','o','MarkerSize',21,...
                'MarkerFaceColor',[0 0.95 0],'Parent',obj.Axes);
        end
    end
    
    methods (Access = private)
        function createApp(obj)
            lengthArena = 300 ;
            imageFilename = 'BackGround.jpg' ;
            % view
            obj.Axes = axes('Parent',obj.Panel,'Box','on',...
                'OuterPosition',[0 0 0.98 0.98]); 
            axis(obj.Axes,[0 lengthArena 0 lengthArena]);
            axis(obj.Axes,'square');
            if exist(imageFilename,'file')
                im=imread(imageFilename);
                obj.Image = image(linspace(0,lengthArena,size(im,1)),...
                    linspace(0,lengthArena,size(im,2)),im,'Parent',obj.Axes);
            end
            set(obj.Axes,'YDir','normal'); % the origin should be in SouthWest corner
            % display the grid in the robot tracker figure
            grid(obj.Axes);
            
            obj.Track = line(NaN,NaN,'Color','b','LineStyle','--',...
                'LineWidth',2,'Parent',obj.Axes);            
            obj.TargetsFound = line(NaN,NaN,'Color',[0 0.6 0],'LineStyle','none',...
                'lineWidth',2,'Marker','o','MarkerSize',15,...
                'MarkerFaceColor',[0 0.95 0],'Parent',obj.Axes);
            obj.TargetsLabel = text(nan(20,1),nan(20,1),cell(20,1),'Parent',obj.Axes);
            obj.TargetsRemaining = line(NaN,NaN,'Color',[0.8 0 0],'LineStyle','none',...
                'LineWidth',1,'Marker','o','MarkerSize',15,...
                'MarkerFaceColor',[0.95 0.95 0.95],'Parent',obj.Axes);            
            obj.TargetsLocated = line(NaN,NaN,'Color',[0 0 0.8],'LineStyle','none',...
                'LineWidth',3,'Marker','+','MarkerSize',18,'Parent',obj.Axes);            
            obj.Robot = hgtransform('Parent',obj.Axes);
            obj.VisibilityPatch = patch(NaN,NaN,[0 0 1],'FaceAlpha',0.5,'Parent',obj.Axes);
            % scale image and centre ball at [0 0]
            
            robot_length = 24; % Previous value = 10
            robot_width = 24; % Previous value = 9
            surf(linspace(0,robot_length,191)-robot_length, linspace(0,robot_width,231)-robot_width/2, zeros(231,191),...
               im2double(imread('robot_dessus.jpg')),'EdgeColor','none','Parent',obj.Robot);
        end
    end
    
end
