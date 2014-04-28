classdef SimDisplay < handle
    %SimDisplay Ui for displaying the simulation runs of the Robot tracking
    %system
    
   
    properties (Access = private) %logged data
        Targets = zeros(0,2);
        TargetsLocated = zeros(0,2);
        TargetsFound = false(0,1);
        Track = zeros(0,2);
        Time = zeros(0,1);
        ElapsedTime = 0;
        TimeLastFound = 0;
        Velocity = 0;
    end
    properties %App
        Fig
        TrackView
        ProgressView
    end
    
    methods (Access = private)%constructor
        function obj  = SimDisplay()
            obj.reset();
            obj.createApp();
        end
    end
    
    methods %open API
        function update(obj, position, targetPositions, targetsFound, ...
                timeLastTargetFound, time, targetLocated,pcam,lcam,robotheta)
            % update Update display with new data
            % This updates the track progress displays and updates the
            % logged data
            obj.Targets = targetPositions;
            obj.TargetsLocated = targetLocated;
            obj.Track(end+1, :) = position;
            obj.Time(end+1) = time;
            
            obj.TargetsFound = targetsFound;
            obj.TimeLastFound = timeLastTargetFound;
            obj.ElapsedTime = time;
            if length(obj.Time)>2
                obj.Velocity = sqrt( sum( diff( obj.Track(end-1:end,:) ).^2 ) ) / (obj.Time(end) - obj.Time(end-1));
            else
                obj.Velocity = 0;
            end
            
            % update views
            updateTrackView(obj,pcam,lcam,robotheta);
            updateProgressView(obj);
            updateTargetChecksum(obj);
        end
        
        function [xLog, yLog, tLog] = getLog(obj)
            %GETLOG Return logged data from the simulation of the Robot scoring system
            % Returns 3 column vectors xLog, yLog, tLog
            xLog = obj.Track(:,1);
            yLog = obj.Track(:,2);
            tLog = obj.Time;
        end
        
        function reset(obj)
            % Reset Reset the logged data
            obj.Targets = zeros(0,2);
            obj.TargetsLocated = zeros(0,2);
            obj.TargetsFound = false(0,1);
            obj.Track = zeros(0,2);
            obj.Time = zeros(0,1);
            obj.ElapsedTime = 0;
            obj.TimeLastFound = 0;
            obj.Velocity = 0;
        end
        
        function delete(obj)
            
            if ishghandle(obj.Fig)
                delete(obj.Fig);
            end
        end
    end
    
    methods (Access = private) %App
        function createApp(obj)
            sz = get(0,'ScreenSize');
            obj.Fig = figure('Name','Robot Tracker',...
                'NumberTitle','off','Toolbar','none','MenuBar','none',...
                'Color',[0.9412, 0.9412, 0.9412],...
                'DeleteFcn',@(s,e)obj.delete(),...
                'Units','pixels','Position',[1 1 0.45*sz(3) 0.75*sz(4) ],...
                'HandleVisibility','off', ...
                'CloseRequestFcn', @(s,e)obj.CloseRequestFcn());
            centerfig(obj.Fig);
            
            hm = uimenu('Parent',obj.Fig,'Label','File');
            uimenu('Parent',hm,'Label','Screen Shot',...
                'Callback',@(s,e)filemenufcn(obj.Fig,'FileSaveAs') )
            
            obj.TrackView = TrackViewer(obj.Fig,'norm',[0 0 1 0.85]);
            obj.ProgressView = ProgressViewer(obj.Fig,'norm',[0 0.85 1 0.15]);
        end
    end
    
    methods (Access = private) %update methods
        function updateTrackView(obj,pcam,lcam,bearing)
            update(obj.TrackView, obj.Track, obj.Targets, obj.TargetsFound, obj.TargetsLocated,pcam,lcam,bearing)
        end
        
        function updateProgressView(obj)
            update(obj.ProgressView, size(obj.Targets,1), nnz(obj.TargetsFound),...
                obj.TimeLastFound, obj.ElapsedTime,obj.Track(end,:),obj.Velocity)
        end
        
        function updateTargetChecksum(obj)
            %chksum = sum(typecast(sum(obj.Targets(:,1).^2 + obj.Targets(:,2).^3), 'uint16'));
            %str = sprintf('Target checksum: %g',chksum);
            %xlabel(obj.TrackView.Axes, str)
        end
               
        function CloseRequestFcn(obj)
            if strcmp(get_param(bdroot,'SimulationStatus'),'stopped')
                delete(obj);
            end
        end
        
    end
    
    methods (Static)
        function obj = getInstance()
            persistent app_singleton
            if isempty(app_singleton) || ~isvalid(app_singleton)
                app_singleton = SimDisplay();
            end
            obj = app_singleton;
        end
        
    end
    
end

