classdef Session < handle_hidden
    % SESSION   A session object relates to exactly one SureTune2 session.
    % A Session contains the raw SureTune data:
    %   - Session Data (XML)
    %   - Meshes (OBJ)
    %   - Volumes (bin)
    %
    % This toolbox processes the raw Session Data into:
    % A tree of Registerables, containing:
    %   - DATASET
    %       > Refers to a Volume instance describing the imagevolume
    %   - Path
    %   - ACPCIH
    %   - Lead
    %   - ImageBasedStructureSegmentation
    %   - ManualStructureSegmentation
    %   - ImportedStructure (with ImportedMeshPart)
    %       > MeshPart refers to an OBJ instance describing the mesh
    %   - Stf
    %   - StimPlan
    %       > Refers to a Volume Instance describing the VTA
    %
    %
    
    
    
    % * Hidden = private? --> private still shows up in methods list
    % *
    % * fullfile ipv [   \   ]
    %  * 7zip niet hardcoded
    
    properties (Hidden = true)  %These properties are hidden to not bother the user.
        originalSessionData %The original XML file
        directory %Directory of the loaded XML file
        log %Changes are logged
        %         ActiveSession = 1;
        activeDataset = 1;
        registerables %List of all Registerables
        master %Registerable tree starts with this dataset
        echoLog = 1; %Flag: 1/0: do/don't echo logging to command window.
        updateXml = 0;
        sureTune = 'C:\GIT\SureSuite\Output\'; %'C:\GIT\SureSuite\Output\';% Folder where SureTune is installed 'C:\Suresuit\Blue3\' %
        exportFolder = 'C:\MATLAB-Addons\Export\'; % Folder were sessions are exported.
        
    end
    
    properties
        sessionData %Imported SureTune2Session.xm
        volumeStorage %list that contains all Volume Objects (the actual voxeldata)
        meshStorage %list that contains all Mesh Objects (the actual faces and vertices)
        therapyPlanStorage %TBD
        patient
    end
    
    %     methods(Hidden = true)  %These methods are hidden because they are called from within.
    methods (Hidden = true)
        
        function addtolog(obj,varargin)
            % varargin should be a cell array with strings
            
            obj.log{end+1,1} = datestr(datetime);
            obj.log{end,2} = sprintf(varargin{:});
            
            if ~obj.echoLog;return;end;
            fprintf([sprintf(varargin{:}),'\n']);
        end
        
        
        function ok = checkinputarguments(obj,nargin,n,type)
            % Check if the number of input arguments is correct
            switch type
                case 'Registerable'
                    if nargin ~= n+1 %+1 = objectt
                        warningtxt = ['Specifiy ',num2str(n),sprintf(' Registerable(s): \n\t  - '),strjoin(obj.listregisterables,'\n\t  - ')];
                        ok = 0;  %#ok<NASGU>
                        error(warningtxt)
                    else ok = 1;
                    end
            end
        end
        
        
    end
    
    methods
        
        
        function obj = Session(varargin)
            % Constructor. No input is required. Creates an empty Session
            % Instance
            
            if nargin > 0
                warning('No input arguments are required. Run ''myFirstSession.m'' for examples.')
            end
            
            % Add empty cells:
            obj.volumeStorage.list = {};
            obj.volumeStorage.names = {};
            obj.therapyPlanStorage = {};
            obj.meshStorage.list = {};
            obj.meshStorage.names = {};
            obj.registerables.names = {};
            obj.registerables.list = {};
            
            % Make export dir of not already exist:
            if ~exist(obj.exportFolder,'dir')
                mkdir(obj.exportFolder);
            end
        end
        
        
        
        function loadxml(obj,pathName,fileName)
            % Input should be pathname and filename, otherwise a dialog
            % appears.
            
            if nargin == 1 %No input -> therefore dialog box
                [fileName,pathName] = uigetfile('.xml');
                if ~fileName
                    disp('Aborted by user');return
                end
            elseif nargin~=3
                error('Invalid Input')
            end
            
            %load xml
            loadedXml = SDK_xml2struct([pathName,fileName]);
            
            % Check for any comments (they may obstruct XML parsing)
            if SDK_removecomments(pathName,fileName);
                
                % Comments have been removed. Load session:
                fileName = [fileName(1:end-4),'_nocomments',fileName(end-3:end)];
                loadedXml = SDK_xml2struct([pathName,fileName]);
            end
            
            % Check if there is only one Session. Otherwise throw warning.
            [loadedXml,abort] = SDK_hasmultiplesessions(loadedXml, pathName,fileName);
            if abort;return;end
            
            
            %add properties to object
            obj.originalSessionData = loadedXml;
            obj.sessionData = loadedXml;
            obj.log = {datestr(datetime),['Load file:',pathName,fileName]};
            obj.directory = pathName;
            
            %print session Info
            obj.sessioninfo();
            
            %set flag
            obj.activeDataset = 1;
            
            %find registerables
            %             obj.noLog = 1;
            obj.registerables = SDK_findregistrables(obj);
            obj.patient = Patient('obj.sessionData.SureTune2Sessions.Session.patient.Patient',obj,...
                obj.sessionData.SureTune2Sessions.Session.patient.Patient.name.Attributes.value,...
                obj.sessionData.SureTune2Sessions.Session.patient.Patient.patientID.Attributes.value,...
                obj.sessionData.SureTune2Sessions.Session.patient.Patient.dateOfBirth.Attributes.value,...
                obj.sessionData.SureTune2Sessions.Session.patient.Patient.gender.Enum.Attributes.value);
            %             obj.noLog = 0;
            %             O.Master = O.SessionData.
            
            
        end
        
        
        
        
        
        
        
        
        function loadtherapyplans(obj,sessiondir)
            thisdir = pwd;
            
            % Browse to therapy folders:
            cd(sessiondir)
            cd('Sessions')
            
            if exist(obj.getsessionname(),'dir')
                cd(obj.getsessionname());
            else
                disp('No TherapyPlans for this session')
                cd(thisdir)
                return;
            end
            
            if exist([pwd,'/Leads'],'dir')
                cd('Leads')
            else
                disp('No TherapyPlans for this session');
                cd(thisdir)
                return;
            end
            
            
            
            
            leadFolders = SDK_subfolders('');
            
            % For all leads find the therapy plans:
            for iSubFolder = 1:numel(leadFolders)
                thisLead = leadFolders{iSubFolder};
                
                %find thislead in the sessiondata
                [names,types] = obj.listregisterables;
                leadNames = names(ismember(types,'Lead'));
                
                %Find Lead Object
                leadObject = obj.getregisterable(leadNames{~cellfun(@isempty,strfind(leadNames,thisLead))});
                
                
                therapyPlanFolders = SDK_subfolders(thisLead);
                
                %For all therapy plans make a Therapy Object.
                for iTherapyPlanFolder = 1:numel(therapyPlanFolders)
                    thisPlan = therapyPlanFolders{iTherapyPlanFolder};
                    
                    %Find the corresponding SessionData, using the lead
                    %name and therapyplanname
                    obj = leadObject.session;
                    xmlPath = leadObject.path;
                    therapyXml = eval(xmlPath);
                    
                    %there may be multiple stimplans in the session data,
                    %find the correct one.
                    stimPlanIndex = 0;
                    for iStimPlan = 1:numel(therapyXml.stimPlans.Array.StimPlan)
                        if strcmp(therapyXml.stimPlans.Array.StimPlan{iStimPlan}.label.Attributes.value,thisPlan)
                            stimPlanIndex = iStimPlan;
                            continue;
                        end
                    end
                    if stimPlanIndex==0;warning(['No matching stimplan in SessionData for ',thisPlan]);return;end
                    
                    
                    % Get the Stimplan data from therapyXML:
                    VTA = obj.loadvta([thisLead,'\',thisPlan]);
                    label = thisPlan;
                    voltageBasedStimulation = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.voltageBasedStimulation.Attributes.value;
                    stimulationValue = str2double(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.stimulationValue.Attributes.value);
                    pulseWidth = str2double(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.pulseWidth.Attributes.value);
                    pulseFrequency =str2double(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.pulseFrequency.Attributes.value);
                    activeRings = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.activeRings.BoolArray.Text;
                    contactsGrounded = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.contactsGrounded.BoolArray.Text;
                    annotation = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.annotation.Attributes.value;
                    
                    % Make a StimPlan Instance:
                    stimPlanObject = StimPlan(VTA,leadObject,label,voltageBasedStimulation,stimulationValue,pulseWidth,pulseFrequency,activeRings,contactsGrounded,annotation);
                    
                    %Add the therapy object to Lead.StimPlan{end+1}
                    stimPlanObject.linktolead(leadObject)
                    
                end
            end
            
            % Revert to original directory:
            cd(thisdir)
        end
        
        function vta = loadvta(obj,folder)
            thisDir = pwd;
            cd(folder)
            volumeFolders = SDK_subfolders();
            
            for iVolumeFolder = 1:numel(volumeFolders)
                %Add an Volume instance to the list.
                volumeObject = Volume();
                volumeObject.loadvolume(volumeFolders{iVolumeFolder})
                vta.(volumeFolders{iVolumeFolder}) = volumeObject;
                
                
            end
            % Revert to original directory
            cd(thisDir)
            
        end
        
        
        
        function loadmeshes(thisSession,folder)
            thisdir = pwd;
            cd(folder)
            
            
            
            % Get a list with all obj filenames:
            objFiles = dir('*.obj');
            objNames ={objFiles.name};
            
            
            for iObjName = 1:numel(objNames)
                if ~iscell(objNames)
                    fileName = objNames;
                else
                    fileName = objNames{iObjName};
                end
                
                %Read the OBJ file
                [V,F] = SDK_obj2fv(fileName);
                
                
                %Add an Obj instance to the list.
                objInstance = Obj(V,F,fileName);
                objInstance.linktosession(thisSession);
                
                
                if ~iscell(objNames)
                    break
                end
                
            end
            
            % Revert to original directory
            cd(thisdir)
            
        end
        
        function loadvolumes(thisSession,folder)
            thisDir = pwd;
            cd(folder)
            
            
            volumeFolders = SDK_subfolders();
            
            for iVolumeFolder = 1:numel(volumeFolders)
                %Add an Volume instance to the list.
                volumeObject = Volume();
                volumeObject.loadvolume(volumeFolders{iVolumeFolder});
                volumeObject.linktosession(thisSession);
                
            end
            % Revert to original directory
            cd(thisDir)
            
        end
        
        
        
        
        
        
        
        
        
        
        %% Logging
        
        
        
        
        
        %% Sessions
        
        
        
        
        %
        %         function obj = setActiveSession(obj,sessionnr)
        %             if sessionnr > numel(obj.sessionData.SureTune2Sessions.Session) || sessionnr <=0
        %                 disp('Session does not exist')
        %                 return
        %             end
        %
        %             obj.ActiveSession = sessionnr;
        %             obj.getSessions
        %         end
        
        %% Datasets
        
        %             function listdatasets(obj)
        %             % Function may be obselete.
        %                 fprintf('\n\nDatasets for %s:\n',obj.getpatientname)
        %
        %                 for i = 1:numel(obj.sessionData.SureTune2Sessions.Session.datasets.Array.Dataset)
        %                     if obj.ativeDataset(obj.activeSession) == i
        %                         arrow = '-> ';
        %                     else
        %                         arrow = '   ';
        %                     end
        %
        %                     label = obj.sessionData.SureTune2Sessions.Session.datasets.Array.Dataset{i}.label.Attributes.value;
        %
        %                     fprintf('%s%1.0f - %s\n',arrow,i, label);
        %                 end
        %             end
        %
        
        
        %% Set/Get
        
        %Name
        %             function setpatientname(obj,val)
        %                 if nargin == 1
        %                     val = input('Patient name: ','s');
        %                 end
        %
        %                 old = obj.sessionData.SureTune2Sessions.Session.patient.Patient.name.Attributes.value;
        %                 obj.sessionData.SureTune2Sessions.Session.patient.Patient.name.Attributes.value = val;
        %                 obj.addtolog('Changed patient name from %s to %s',old,val);
        %
        %             end
        %
        %             function val = getpatientname(obj)
        %                 val = obj.sessionData.SureTune2Sessions.Session.patient.Patient.name.Attributes.value;
        %             end
        
        %             %SessionName
        %             function setsessionname(obj,val)
        %                 if nargin == 1
        %                     val = input('Session name: ','s');
        %                 end
        %
        %                 old = obj.sessionData.SureTune2Sessions.Session.id.Attributes.value;
        %                 obj.sessionData.SureTune2Sessions.Session.id.Attributes.value = val;
        %                 obj.addtolog('Changed session name from %s to %s',old,val);
        %
        %             end
        
        %             function val = getsessionname(obj)
        %                 val = obj.sessionData.SureTune2Sessions.Session.id.Attributes.value;
        %             end
        
        
        %             %PatientID
        %             function setpatientid(obj,val)
        %                 if nargin == 1
        %                     val = input('Patient ID: ','s');
        %                 end
        %
        %                 old = obj.sessionData.SureTune2Sessions.Session.patient.Patient.patientID.Attributes.value;
        %                 obj.sessionData.SureTune2Sessions.Session.patient.Patient.patientID.Attributes.value = val;
        %                 obj.addtolog('Changed patient ID from %s to %s',old,val);
        %
        %             end
        %
        %             function val = getpatientid(obj)
        %                 val = obj.sessionData.SureTune2Sessions.Session.patient.Patient.patientID.Attributes.value;
        %             end
        
        %
        %             %DateOfBirth
        %             function setdateofbirth(obj,val)
        %                 old = obj.sessionData.SureTune2Sessions.Session.patient.Patient.patientID.Attributes.value;
        %                 obj.sessionData.SureTune2Sessions.Session.patient.Patient.dateOfBirth.Attributes.value = val;
        %                 obj.addtolog('Changed date of birth from %s to %s',old,val);
        %             end
        %
        %             function val = getdateofbirth(obj)
        %                 val = obj.sessionData.SureTune2Sessions.Session.patient.Patient.dateOfBirth.Attributes.value;
        %             end
        
        %             %Gender
        %             function setgender(obj,val)
        %                 old = obj.sessionData.SureTune2Sessions.Session.patient.Patient.gender.Enum.Attributes.value;
        %                 obj.sessionData.SureTune2Sessions.Session.patient.Patient.gender.Enum.Attributes.value = val;
        %                 obj.addtolog('Changed gender from %s to %s',old,val);
        %             end
        %
        %             function val = getgender(obj)
        %                 val = obj.sessionData.SureTune2Sessions.Session.patient.Patient.gender.Enum.Attributes.value;
        %             end
        
        
        
        %Dataset
        
        %             function setactivedataset(obj,val)
        %                 %Function may be obsolete.
        %                 if nargin==1
        %                     obj.listdatasets;
        %                     val = input('Select dataset number: ');
        %                     if isempty(val)
        %                         return
        %                     end
        %                 end
        %
        %                 %check input
        %
        %                 if val > 0 && val <= numel(obj.sessionData.SureTune2Sessions.Session.datasets.Array.Dataset)
        %                     old = obj.ActiveDataset(obj.ActiveSession);
        %                     obj.ActiveDataset(obj.ActiveSession) = val;
        %                 else
        %                     error('Out of bounds')
        %                 end
        %
        %
        %                 obj.addtolog('Changed activeDataset from %1.0f to %1.0f',old,val);
        %             end
        %
        %             function val = getactivedataset(obj)
        %                 val = obj.ActiveDataset;
        %             end
        %
        
        
        %Registerables
        
        
        
        
        
        
        
        
        
        %leads
        
        
        
        
        
        
        %Add New elements
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
    end
    
end
