classdef RpiController < handle
    %RpiController App for interacting with the Robot Tracking System 
    
    properties (Access = private) %data
        Targets = zeros(0,2);
        TargetsFound = false(0,1);
        Track = zeros(0,2);
        Time = zeros(0,1);;
        ElapsedTime = 0;
        TimeLastFound = 0;
    end
    properties %sounds
        Yahoo
        Finished
        Fs = 44100;
        PlaySound = false
    end
    properties (Access = private)
        Poller
        Listeners = []
        PiGoState = 0;
        PrevCalibState = false
        Calibrate = false
    end    
    properties (Access = private) %graphical components
        Fig
        StartStopPB
        CalibPanel
        RobotPanel
        RedThreshEdit
        GreenThreshEdit
        AutoCalibPB
        AdjustCalibPB
        CalibNoteTxt
        PositionTxt
        VideoView
        TrackView
        ProgressView
    end
    
    methods (Access = private)%constructor
        function obj  = RpiController()
            if ~ispref('RobotTracker')
                addpref('RobotTracker','RedThresh','30')
                addpref('RobotTracker','GreenThresh','30')
            end
            
            d = fileparts(mfilename('fullpath'));
            
            %obj.Finished = audioread(fullfile(d,'sounds','82481__benboncan__meeb-meeb.wav'));
            obj.Finished = audioread(fullfile(d,'sounds','Hehehe.wav'));
            
            obj.createApp()
            obj.updateTargetPos();
            obj.pollTargetPositionChanges();
            obj.sendStatesToPI();
            um = UdpManager_Mex.getInstance();
            l = event.listener(um,'NewData',@(s,e)obj.getNewData);
            l(2) = event.listener(um,'NewVideo',@(s,e)obj.getNewVideo);
            obj.Listeners = l;
        end
    end
    
    methods %open API
        
        function reset(obj)
            stop(obj);
            obj.Track = zeros(0,2);
            obj.TargetsFound = false(size(obj.Targets,1),1);
            obj.Time = zeros(0,1);
            obj.ElapsedTime = 0;
            obj.TimeLastFound = 0;
        end
        
        function [xLog, yLog, tLog] = getLog(obj)
            %GETLOG Return logged data from the Robot scoring system
            % Returns 3 column vectors xLog, yLog, tLog
            xLog = obj.Track(:,1);
            yLog = obj.Track(:,2);
            tLog = obj.Time;
        end
        
        function delete(obj)
            setpref('RobotTracker', 'RedThresh', get(obj.RedThreshEdit,'String'))
            setpref('RobotTracker', 'GreenThresh', get(obj.GreenThreshEdit,'String'))
            if isa(obj.Poller,'Timer')
                stop(obj.Poller)
                obj.Poller.TimerFcn = '';
            end
            if ishghandle(obj.Fig)
                delete(obj.Fig);
            end
        end
    end
    
    methods (Access = private)%Updating TargetsPosition changes
        function pollTargetPositionChanges(obj)
           obj.Poller =  Timer('Tag','TargetPositionPoller', 'ExecutionMode','fixedRate', ...
                'Period', 2, 'StartDelay', 2, 'TimerFcn', @(s,e)updateTargetPos(obj));
            start(obj.Poller);
        end
        
        function updateTargetPos(obj)
            varExists = evalin('base','exist(''TargetPositions'',''var'')');
            if varExists
                targets = evalin('base','TargetPositions');
                if  size(targets,2)~=2 || size(targets,1)>9 || ~isnumeric(targets) 
                    stop(obj.Poller);
                    errordlg({'The variable "TargetPositions" must be a 2 column matrix of xy values, with at most 9 rows','',...
                        'You will need to redefine the variable!'},'','modal');
                    targets = obj.Targets;
                    if isempty(targets)
                        targets = zeros(9,2);
                    end
                    assignin('base','TargetPositions',targets)
                    evalin('base','TargetPositions')
                    start(obj.Poller);
                    return
                end
            else
                warning(['TargetPositions variable not found in workspace.\n',...
                    'Using a default value: TargetPositions = zeros(9,2)']);
                targets = zeros(9,2);
                assignin('base','TargetPositions',targets)
            end
            
            if ~isequal(obj.Targets, targets)
                updateTargets(obj, targets);
            end
        end
        
        function updateTargets(obj, targets)
            stop(obj);
            
            disp('Updating Targets')
            
            obj.Targets = targets;
            obj.TargetsFound = false(size(targets,1),1);
            obj.ElapsedTime = 0;
            obj.TimeLastFound = 0;
            %update views
            updateTrackView(obj)
            updateProgressView(obj);
            updateTargetChecksum(obj);
            %update Rpi
            sendStatesToPI(obj);
        end
    end
    
    methods (Access = private) %App creation and layout control
        function createApp(obj)
            sz = get(0,'ScreenSize');
            obj.Fig = figure('Name','Robot Tracker',...
                'NumberTitle','off','Toolbar','none','MenuBar','none',...
                'Color',[0.9412, 0.9412, 0.9412],...
                'DeleteFcn',@(s,e)obj.delete(),...
                'Units','pixels','Position',[1 1 floor(sz(3:4)*0.75) ],...
                'HandleVisibility','off');
            centerfig(obj.Fig);
            
            hm = uimenu('Parent',obj.Fig,'Label','File');
            uimenu('Parent',hm,'Label','Refresh Connection',...
                'Callback',@(s,e)i_refreshTracker() )
            uimenu('Parent',hm,'Label','Screen Shot',...
                'Callback',@(s,e)filemenufcn(obj.Fig,'FileSaveAs') )
            uimenu('Parent',hm,'Label','Set Team Name',...
                'Separator','on',...
                'Callback', @(s,e)obj.onChangeTeamName() );
            hms = uimenu('Parent',hm,'Label','Play Sounds...',...
                'Separator','on','checked','off');
                
            nosound = uimenu('Parent',hms,'Label','None',...
                'Callback',@(s,e)obj.onSelectSound(s,0));
            uimenu('Parent',hms,'Label','Yahoo',...
                'Callback',@(s,e)obj.onSelectSound(s,1));
            uimenu('Parent',hms,'Label','Ye Ha',...
                'Callback',@(s,e)obj.onSelectSound(s,2));
            uimenu('Parent',hms,'Label','Woo Hoo',...
                'Callback',@(s,e)obj.onSelectSound(s,3));
            obj.onSelectSound(nosound,0);
            
                
            hm2 = uimenu('Parent',obj.Fig,'Label','Layout');
            uimenu('Parent',hm2,'Label','Normal',...
                'Callback',@(s,e)obj.onChooseLayout1() )
            uimenu('Parent',hm2,'Label','Widescreen',...
                'Callback',@(s,e)obj.onChooseLayout2() )
            uimenu('Parent',hm2,'Label','Widescreen Mirrored',...
                'Callback',@(s,e)obj.onChooseLayout3() )
%             uimenu('Parent',hm2,'Label','4',...
%                 'Callback',@(s,e)obj.adjustLayout4() )
            
            robotPanel = uipanel('Parent',obj.Fig,'Units','norm',...
                'Position',[0.6 0 0.4 0.21],'Title','Robot');
            calibPanel = uipanel('Parent',obj.Fig,'Units','norm',...
                'Position',[0.6 0.21 0.4 0.19],'Title','Arena Calibration');
            
            obj.VideoView = VideoViewer(obj.Fig,'norm',[0.6 0.4 0.4 0.6]);
            obj.TrackView = TrackViewer(obj.Fig,'norm',[0 0 0.6 0.85]);
            obj.ProgressView = ProgressViewer(obj.Fig,'norm',[0 0.85 0.6 0.15]);
            
            obj.CalibPanel = calibPanel;
            obj.RobotPanel = robotPanel;
            
                       
            % Calibration Controls
            we = 40;  %edit component width
            h = 20;  %component height
            b = 10;  %buffer
            
            % Arena Calibration Panel components
            obj.AutoCalibPB = uicontrol('Parent',calibPanel,'Style','pushbutton', ...
                'String', 'Calibrate Arena',  ...
                'Units','pixel', 'Position', [b h+3*b 120 30],...
                'Callback',@(s,e)obj.autoCalib(),...
                'TooltipString','Calibrate the Arena');
            
            obj.AdjustCalibPB = uicontrol('Parent',calibPanel,'Style','pushbutton', ...
                'String', 'Adjust Calibration',  ...
                'Units','pixel', 'Position', [b h+3*b 120 30],...
                'Callback',@(s,e)obj.adjustCalib(),...
                'Visible','off',...
                'TooltipString','Calibrate the Arena');
            
            obj.CalibNoteTxt = uicontrol('Parent',calibPanel,'Style','edit', ...
                'String', 'Not Calibrated!','Enable','inactive',...
                'ForegroundColor',[0.8 0 0],'FontWeight','bold',...
                'Units','pixel', 'Position', [110 b 150 30]);
            
            redthresh = getpref('RobotTracker','RedThresh');
            uicontrol('Parent', calibPanel, 'Style', 'text', ...
                'String', 'Red Threshold:', ...
                'HorizontalAlignment','right',...
                'Units','pixel', 'Position', [120+3*b h+3.5*b-2 100 h]);
            obj.RedThreshEdit = uicontrol('Parent', calibPanel, 'Style', 'edit', ...
                'String', redthresh,  'BackgroundColor', 'w',...
                'Units','pixel', 'Position', [220+3.5*b h+3.5*b we h],...
                'Callback', @(s,e)obj.sendStatesToPI(),...
                'KeyPressFcn', @i_defocusOnReturn,...
                'TooltipString','Thereshold value used for identifying red/orange objects');
            
            
            % Robot Panel
            greenthresh = getpref('RobotTracker','GreenThresh');
            uicontrol('Parent', robotPanel, 'Style', 'text', ...
                'String', 'Green Threshold:', ...
                'HorizontalAlignment','right',...
                'Units','pixel', 'Position', [120+3*b 3*h+b-2 100 h]);
            obj.GreenThreshEdit = uicontrol('Parent', robotPanel, 'Style', 'edit', ...
                'String', greenthresh, 'BackgroundColor', 'w',...
                'Enable','off',...
                'Units','pixel', 'Position', [220+3.5*b 3*h+b we h],...
                'Callback', @(s,e)obj.sendStatesToPI(),...
                'KeyPressFcn', @i_defocusOnReturn,...
                'TooltipString','Thereshold value used for identifying green objects');
            
            uicontrol('Parent',robotPanel,'Style','text', ...
                'String', 'Robot Position:',...
                'HorizontalAlignment','right',...
                'Enable','inactive','FontWeight','normal',...
                'Units','pixel', 'Position', [100+3*b 2*b 100 h]);
            obj.PositionTxt = uicontrol('Parent',robotPanel,'Style','edit', ...
                'String', '','Enable','inactive',...
                'ForegroundColor',[0 0 0],'FontWeight','bold',...
                'Units','pixel', 'Position', [200+3.5*b 2*b 82 1.5*h],...
                'TooltipString','Current position of the robot');
            
            obj.StartStopPB = uicontrol('Style','pushbutton','Parent',robotPanel,...
                'Units','pixel','Position',[7 7 96 96],'Enable','off',...
                'CData',imread('start.png'),...
                'String','Start','BackgroundColor',[0 0.6 0],...
                'ForegroundColor',[0 0 0],'FontSize',16,...
                'FontWeight','bold','Callback',@(s,e)obj.startstop());
            
            
            % Resize functionality
            set(obj.Fig, 'ResizeFcn',@(s,e)obj.adjustLayout1)
            adjustLayout1(obj)
        end
        
        function adjustLayout1(obj)
            ppf = getpixelposition(obj.Fig);
            set(obj.RobotPanel,'Units','norm','Position',[0.6 0 0.4 0.21]);
            set(obj.CalibPanel,'Units','norm','Position',[0.6 0.21 0.4 0.19]);
            set(obj.VideoView.Panel,'Units','norm','Position',[0.6 0.4 0.4 0.6]);
            set(obj.TrackView.Panel,'Units','norm','Position',[0 0 0.6 0.85]);
            set(obj.ProgressView.Panel,'Units','norm','Position',[0 0.85 0.6 0.15]);
            
            %set height of progress bar and trackview
            ppp = getpixelposition(obj.ProgressView.Panel);
            setpixelposition(obj.ProgressView.Panel,[ppp(1) ppf(4)-110 ppp(3) 110])
            ppt = getpixelposition(obj.TrackView.Panel);
            setpixelposition(obj.TrackView.Panel,[ppt(1) ppt(2) ppt(3) ppf(4)-110])
            
            %set location of calibration panel and propergate
            ppr = getpixelposition(obj.RobotPanel);
            if 0.4*ppf(3) < 333
                ppr(3) = 333;
                ppp = getpixelposition(obj.ProgressView.Panel);
                setpixelposition(obj.ProgressView.Panel,[ppp(1:2) ppf(3)-ppr(3) ppp(4)])
                ppt = getpixelposition(obj.TrackView.Panel);
                setpixelposition(obj.TrackView.Panel,[ppt(1:2) ppf(3)-ppr(3) ppt(4)])
            end
            setpixelposition(obj.RobotPanel, [ppf(3)-ppr(3) ppr(2) ppr(3) 120]);
            setpixelposition(obj.CalibPanel, [ppf(3)-ppr(3) ppr(2)+120 ppr(3) 100]);
            rp = get(obj.CalibPanel,'Position');
            pos = [rp(1) rp(2)+rp(4) rp(3) 1-rp(4)-rp(2)];
            set(obj.VideoView.Panel,'Position',pos);
            
        end
        
        function adjustLayout2(obj)
            ppf = getpixelposition(obj.Fig);
            set(obj.RobotPanel,'Units','norm','Position',[0.6 0 0.2 0.2]);
            set(obj.CalibPanel,'Units','norm','Position',[0.8 0 0.2 0.2]);
            set(obj.VideoView.Panel,'Units','norm','Position',[0.6 0.2 0.4 0.8]);
            set(obj.TrackView.Panel,'Units','norm','Position',[0 0 0.6 0.85]);
            set(obj.ProgressView.Panel,'Units','norm','Position',[0 0.85 0.6 0.15]);
            
            %set height of progress bar and trackview
            ppp = getpixelposition(obj.ProgressView.Panel);
            setpixelposition(obj.ProgressView.Panel,[ppp(1) ppf(4)-110 ppp(3) 110])
            ppt = getpixelposition(obj.TrackView.Panel);
            setpixelposition(obj.TrackView.Panel,[ppt(1) ppt(2) ppt(3) ppf(4)-110])
            
            %set location of calibration panel and propergate
            ppr = getpixelposition(obj.RobotPanel);
            ppc = getpixelposition(obj.CalibPanel);
            if 0.2*ppf(3) < 326
               ppr(3) = 326;
               ppc(3) = 326;
               ppp = getpixelposition(obj.ProgressView.Panel);
                setpixelposition(obj.ProgressView.Panel,[ppp(1:2) ppf(3)-ppr(3)-ppc(3) ppp(4)])
                ppt = getpixelposition(obj.TrackView.Panel);
                setpixelposition(obj.TrackView.Panel,[ppt(1:2) ppf(3)-ppr(3)-ppc(3) ppt(4)])
            end
            setpixelposition(obj.RobotPanel, [ppf(3)-ppr(3)-ppc(3) ppr(2:3) 120]);
            setpixelposition(obj.CalibPanel, [ppf(3)-ppc(3) ppc(2:3) 120]);
            
            rp = get(obj.RobotPanel,'Position');
            cp = get(obj.CalibPanel,'Position');
            pos = [rp(1) rp(2)+rp(4) rp(3)+cp(3) 1-rp(4)-rp(2)];
            set(obj.VideoView.Panel,'Position',pos);
        end
        
         function adjustLayout3(obj)
            ppf = getpixelposition(obj.Fig);
            set(obj.RobotPanel,'Units','norm','Position',[0.2 0 0.2 0.2]);
            set(obj.CalibPanel,'Units','norm','Position',[0 0 0.2 0.2]);
            set(obj.VideoView.Panel,'Units','norm','Position',[0 0.2 0.4 0.8]);
            set(obj.TrackView.Panel,'Units','norm','Position',[0.4 0 0.6 0.85]);
            set(obj.ProgressView.Panel,'Units','norm','Position',[0.4 0.85 0.6 0.15]);
            
            %set height of progress bar and trackview
            ppp = getpixelposition(obj.ProgressView.Panel);
            setpixelposition(obj.ProgressView.Panel,[ppp(1) ppf(4)-110 ppp(3) 110])
            ppt = getpixelposition(obj.TrackView.Panel);
            setpixelposition(obj.TrackView.Panel,[ppt(1) ppt(2) ppt(3) ppf(4)-110])
            
            %set location of calibration panel and propergate
            ppr = getpixelposition(obj.RobotPanel);
            ppc = getpixelposition(obj.CalibPanel);
            if 0.2*ppf(3) < 326
               ppr(3) = 326;
               ppc(3) = 326;
            end
            setpixelposition(obj.CalibPanel, [ppc(1:3) 120]);
            setpixelposition(obj.RobotPanel, [ppc(1)+ppc(3) ppr(2:3) 120]);
            rp = get(obj.RobotPanel,'Position');
            cp = get(obj.CalibPanel,'Position');
            
            pos = [cp(1) cp(2)+cp(4) cp(3)+rp(3) 1-cp(4)-cp(2)];
            set(obj.VideoView.Panel,'Position',pos);
            
            pp = get(obj.ProgressView.Panel,'Position');
            pos = [cp(3)+rp(3) pp(2) 1-cp(3)-rp(3) pp(4)];
            set(obj.ProgressView.Panel,'Position',pos);
            
            tp = get(obj.TrackView.Panel,'Position');
            pos = [cp(3)+rp(3) tp(2) 1-cp(3)-rp(3) tp(4)];
            set(obj.TrackView.Panel,'Position',pos)
            
         end
    end
    
    methods (Access = private) %callbacks
        function onChangeTeamName(obj)
            name = inputdlg('Enter your teams name', 'Set Team Name', 1, {''}, ...
                struct('WindowStyle','modal'));
            if ~isempty(name)
                title(obj.TrackView.Axes, name, 'FontSize',30,'FontWeight','bold',...
                    'Color',[18 86 135]/255)
            end
        end
        
        function onSelectSound(obj,src,val)
            menuitems = get(get(src,'Parent'),'Children');
            d = fileparts(mfilename('fullpath'));
            obj.PlaySound = true;
            switch val
                case 0
                    obj.Yahoo = [];
                    obj.PlaySound = false;
                case 1
                    obj.Yahoo = audioread(fullfile(d,'sounds','yahoo1.wav'));
                case 2
                    obj.Yahoo = audioread(fullfile(d,'sounds','yahoo2.wav'));
                case 3
                    obj.Yahoo = audioread(fullfile(d,'sounds','yahoo3.wav'));
            end
            sound(obj.Yahoo, obj.Fs)
            set(menuitems,'checked','off');
            set(src,'checked','on');
        end
        
        function getNewData(obj, ~, ~)
            um = UdpManager_Mex.getInstance();
            data = um.Data;
            update(obj, data.calib, data.go, data.position, data.targets, data.targetsFound,...
                data.timeLastFound, data.timeElapsed);
        end
        
        function getNewVideo(obj, ~, ~)
            um = UdpManager_Mex.getInstance();
            updateVideo(obj, um.VideoRed, um.VideoGreen, um.VideoBlue);
        end
        
        function autoCalib(obj)
            set(obj.RedThreshEdit,'Enable','off')
            set(obj.GreenThreshEdit,'Enable','on')
            set(obj.CalibNoteTxt,'String','Attempting to Calibrate..',...
                'ForegroundColor',[0.8,0.4,0])
            set(obj.AutoCalibPB,'Visible','off')
            set(obj.AdjustCalibPB,'Visible','on')
            obj.Calibrate = true;
            sendStatesToPI(obj)
        end
        
        function adjustCalib(obj)
            stop(obj)
            set(obj.RedThreshEdit,'Enable','on')
            set(obj.GreenThreshEdit,'Enable','off')
            set(obj.CalibNoteTxt,'String','Not Calibrated!',...
                'ForegroundColor',[0.8 0 0])
            set(obj.AdjustCalibPB,'Visible','off')
            set(obj.AutoCalibPB,'Visible','on')
            obj.Calibrate = false;
            sendStatesToPI(obj)
        end
 
        function startstop(obj)
            if strcmpi(get(obj.StartStopPB,'String'),'Start')
                start(obj)
            else
                stop(obj)
            end
        end
        
        function onChooseLayout1(obj)
            set(obj.Fig, 'ResizeFcn',@(s,e)obj.adjustLayout1)
            adjustLayout1(obj)    
        end
        
        function onChooseLayout2(obj)
            set(obj.Fig, 'ResizeFcn',@(s,e)obj.adjustLayout2)
            adjustLayout2(obj)    
        end
        
        function onChooseLayout3(obj)
            set(obj.Fig, 'ResizeFcn',@(s,e)obj.adjustLayout3)
            adjustLayout3(obj)    
        end
        
    end
    
    methods (Access = private) %start stop methods
        function start(obj)
            set(obj.StartStopPB,'String','Stop','BackgroundColor',[0.6 0 0],...
                'CData',imread('cancel.png'));
            obj.Track = zeros(0,2);
            obj.TargetsFound = false(size(obj.Targets,1),1);
            obj.Time = zeros(0,1);
            obj.ElapsedTime = 0;
            obj.TimeLastFound = 0;
            
            %update views
            updateTrackView(obj);
            updateProgressView(obj);
            %startPI
            obj.PiGoState = 1;
            obj.sendStatesToPI();
        end
        
        function stop(obj)
            obj.PiGoState = 0;
            obj.sendStatesToPI();
            set(obj.StartStopPB,'String','Start','BackgroundColor',[0 0.6 0],...
                'CData',imread('start.png') );
        end
    end
    
    methods (Access = private) %update methods
        
        function update(obj, calib, go, pos, T, T_found, t_last, t)
            persistent count
            
            % Check calibration state
            if calib && ~obj.PrevCalibState 
                % calibration just found
                set(obj.CalibNoteTxt,'String','Calibrated',...
                    'ForegroundColor',[0,0.8,0])
                set(obj.StartStopPB,'Enable','on')
            elseif ~calib && obj.PrevCalibState
                set(obj.StartStopPB,'Enable','off')
            end
            obj.PrevCalibState = calib;
            
            % Prevent haning in case where it is not possible to sync the
            % target positions with the Rpi
            if isempty(count), count = 0; end
            if count > 10
                stop(UdpManager_Mex.getInstance());
                errordlg({'Could sync TargetPositions with Rpi. Please call one of the Technical Support',...
                    'Full refresh of Robot Tracker Required!!'})
                count = 0;
                warning(['Could not sync TargetPositions with Rpi. Please call one of the Technical Coaches!',...
                    'Receiving TargetPositions from Rpi, but these are not the same those sent to the Rpi'])
            end
            % check targets
            if ~isequal(size(T),size(obj.Targets)) || any(any(abs(T-obj.Targets)>1e-5))
                stop(obj)
                fprintf('TargetPositions are not synchronised with Raspberry Pi\n')
                fprintf('  Synching TargetPositions between MATLAB and Raspberry Pi')
                sendStatesToPI(obj); %send the targets to the Rpi again
                for i = 1:10, fprintf('.'); pause(0.1); end
                fprintf('\n')
                count = count + 1;
                return
            end
            count = 0;
            
                
            % update other information
            updatePosDisplay(obj,pos);
            
            nfound = nnz(T_found);
            ntargets = size(obj.Targets,1);
            newTargetFound = T_found & (T_found ~= obj.TargetsFound);
            
            if go
                obj.Track(end+1, :) = pos;
                obj.Time(end+1) = t;
                obj.TargetsFound = T_found;
                obj.TimeLastFound = t_last;
                obj.ElapsedTime = t;
                % update views
                updateTrackView(obj);
                updateProgressView(obj);
            end
            
            if obj.PlaySound && any(newTargetFound)
                if nfound < ntargets
                    % sound in 5dB interval
                    GdB = (nfound-ntargets)*5;
                    sound(obj.Yahoo*10^(GdB/20), obj.Fs)
                else
                    sound(obj.Finished, obj.Fs)
                end
                highlightFoundTarget(obj.TrackView, obj.Targets(newTargetFound,:))
            end
            
            if ntargets == nfound
                %all targets found so stop
                stop(obj)
            end
            
        end
        
        function updateVideo(obj, r, g, b)
            updateImage(obj.VideoView, cat(3, r, g, b))
        end
        
        function updateTrackView(obj)
            update(obj.TrackView, obj.Track, obj.Targets, obj.TargetsFound)
        end
        
        function updatePosDisplay(obj,pos)
            txt = sprintf('[ %0.2f , %0.2f ]', pos);
            set(obj.PositionTxt,'String', txt)
            
        end
        
        function updateProgressView(obj)
            update(obj.ProgressView, size(obj.Targets,1), nnz(obj.TargetsFound),...
                obj.TimeLastFound, obj.ElapsedTime)
        end
        
        function updateTargetChecksum(obj)
            chksum = sum(typecast(sum(obj.Targets(:,1).^2 + obj.Targets(:,2).^3), 'uint16'));
            str = sprintf('Target checksum: %g',chksum);
            xlabel(obj.TrackView.Axes, str)
        end
    end
    
    methods (Access = private) %comms to PI
        function sendStatesToPI(obj)
            GO = obj.PiGoState;
            TargetPositions = obj.Targets;
            rth_str = get(obj.RedThreshEdit,'String');
            gth_str = get(obj.GreenThreshEdit,'String');
            RedThreshold = str2double(rth_str);
            GreenThreshold = str2double(gth_str);
            calibrate = double(obj.Calibrate);
            % send to PI
            um = UdpManager_Mex.getInstance();
            UdpSendToPi(um, GO, TargetPositions, RedThreshold, GreenThreshold, calibrate);
        end
    end
    
    methods (Static)
        function obj = getInstance()
            persistent app_singleton
            if isempty(app_singleton) || ~isvalid(app_singleton)
                app_singleton = RpiController();
            end
            obj = app_singleton;
        end
        
        function forceClose()
            r = RpiController.getInstance();
            delete(r);
            r = []; %#ok<NASGU>
            close all force;
        end
    end
    
end

function i_defocusOnReturn(s,e)
if strcmp(e.Key,'return')
   set(s,'Enable','off')
   set(s,'Enable','on')
end
end

function i_refreshTracker()
resetConnections(UdpManager.getInstance())
end
