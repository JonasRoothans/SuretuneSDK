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
    
    
    %% properties
    properties (Hidden = true)  %These properties are hidden to not bother the user.
        originalSessionData %The original XML file
        directory %Directory of the loaded XML file
        log
        activeDataset = 1;
        registerables %List of all Registerables
        master %Registerable tree starts with this dataset
        updateXml = 0;
        sureTune = ''; %'C:\Suresuit\Blue5\';%'C:\GIT\SureSuite\Output\'; %'C:\Suresuit\Blue4(Bill)';% ' %'C:\Suresuit\Blue4(Bill)' 'C:\GIT\SureSuite\Output\';% Folder where SureTune is installed 'C:\Suresuit\Blue3\' %
        exportFolder = fullfile(fileparts(fileparts(mfilename('fullpath'))),'Export'); % Folder were sessions are exported.
        homeFolder;
        developerFlags %See line 115
        ver
        settings
        
        
        
    end
    
    properties
        sessionData %Imported SureTune2Session.xm
        volumeStorage %list that contains all Volume Objects (the actual voxeldata)
        meshStorage %list that contains all Mesh Objects (the actual faces and vertices)
        therapyPlanStorage %TBD
        merTableStorage
        patient
 
    end
    
    %% methods hidden
    methods (Hidden = true)
        
        function addtolog(obj,varargin)
            % varargin should be a cell array with strings
            try
            obj.log{end+1,1} = datestr(datetime);
            obj.log{end,2} = sprintf('%s ',varargin{:});
            catch
                warning('Could not log')
            end
            
            if ~obj.developerFlags.echoLog;return;end;
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
    
    %% methods visible
    
    methods
        
        function obj = Session(varargin)
            % Constructor. No input is required. Creates an empty Session
            % Instance
            
            %Check if Settings exist (aka, tool is installed)
            if not(exist('SDKsettings.mat','file'))
                obj.install()
            end
            
        load('SDKsettings.mat')
        obj.settings.unzipdir = settings.unzipdir;
            
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
            obj.merTableStorage.list = {};
            obj.merTableStorage.names = {};
            
            
            % Make export dir of not already exist:
            if ~exist(obj.exportFolder,'dir')
                mkdir(obj.exportFolder);
            end
            
            %add home folder
            fullpath = mfilename('fullpath');
            obj.homeFolder = fullpath(1:findstr(fullpath,'@Session')-2);
            
            
            %try to add suretunefolder
            if exist(fullfile(obj.homeFolder,'@Session','SureTuneInstallationDirectory.txt'),'file')
                [suretunepath] = textread(fullfile(obj.homeFolder,'@Session','SureTuneInstallationDirectory.txt'),'%s');
                obj.sureTune = suretunepath{1};
            end
            
            %developerFlags
            obj.developerFlags.readable = 1;
            obj.developerFlags.echoLog = 1; %Flag: 1/0: do/don't echo logging to command window.
            obj.developerFlags.loadVolumes = 1;
            obj.developerFlags.skipWarning = 0;
            obj.developerFlags.upgrade = 1;
            
            

        end
        
        
        function update(obj)
            currentpath = pwd;
            cd(fileparts(mfilename('fullpath')))
            try
                disp('does not work yet')
            %!git pull
            
            catch
                cd(currentpath)
            end
            
            cd(currentpath)
        end
        
        %% loading functions
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
            fullFileName = fullfile(pathName,fileName);
            
            %load xml
            % Check for any comments (they may obstruct XML parsing
            if SDK_removecomments(fullFileName);
                % Reading with new file
                fullFileName = [fullFileName(1:end-4),'_nocomments.xml'];
                loadedXml = SDK_xml2struct(fullFileName);
                disp('removed comments')
            else
                loadedXml = SDK_xml2struct(fullFileName);
            end
            
            % Check if there is only one Session. Otherwise throw warning.
            [loadedXml,abort] = SDK_hasmultiplesessions(loadedXml, pathName,fileName);
            if abort;return;end
            
            
            %add properties to object
            obj.originalSessionData = loadedXml;
            obj.sessionData = loadedXml;
            obj.log = {datestr(datetime),['Load file:',fullFileName]};
            obj.directory = pathName;
            
            %add SDK version
            %[version] = textread('@Session/version.txt','%s');
%             obj.sessionData.(obj.ver).Attributes.version = [obj.sessionData.(obj.ver).Attributes.version,'(SDK: ',version{1},')'];
            
            
            
            
            %print session Info
            obj.sessioninfo();
            
            %set flag
            obj.activeDataset = 1;
            obj.developerFlags.upgrade =0;
            
            %find merTables
%             obj.loadmertables()
            warning('do not load MER')
            
            %find registerables
            %             obj.noLog = 1;
            obj.registerables = SDK_findregistrables(obj);
            obj.patient = Patient(['obj.sessionData.',obj.ver,'.Session.patient.Patient'],obj);%removed redundant input arguments
            
            %             obj.noLog = 0;
            %             O.Master = O.SessionData.
            
            
        end
        
        
        
        
        
        
        function loadmertables(obj)
            
            %Return if no merTables are found
            if ~isfield(obj.sessionData.(obj.ver).Session,'merTables')
                disp('This session contains no MER data')
                return
            end
            
            if ~isfield(obj.sessionData.(obj.ver).Session.merTables.Array,'MerTable')
                disp('This session contains no MER data')
                return
            end
            
            
            
            
            for iMerTable = 1:numel(obj.sessionData.(obj.ver).Session.merTables.Array.MerTable)
                obj.merTableStorage.names{end+1} = obj.sessionData.(obj.ver).Session.merTables.Array.MerTable{iMerTable}.Attributes.id;
                
                XML = obj.sessionData.(obj.ver).Session.merTables.Array.MerTable{iMerTable};
                component_args = {['obj.sessionData.',obj.ver,'.Session.merTables.Array.MerTable{iMerTable}'],obj};
                
                label = XML.label.Attributes.value;
                isBensGunAlignedWithOrientationReference = XML.isBensGunAlignedWithOrientationReference.Attributes.value;
                targetSide = XML.targetSide.Enum.Attributes.value;
                middleC0ChannelDepth = XML.middleC0ChannelDepth;
                targetChannelDepth = XML.targetChannelDepth;
                merDepths = XML.merDepths.Array;
                id = XML.Attributes.id;
                
                
                obj.merTableStorage.list{end+1} = merTable(component_args,label,isBensGunAlignedWithOrientationReference,targetSide,middleC0ChannelDepth,targetChannelDepth,merDepths,id);
            end
            
            
            
            
            
            
        end
        
        function loadtherapyplans(obj,sessiondir)
            thisdir = pwd;
            
            % Browse to therapy folders:
            try
                cd(sessiondir)
                cd('Sessions')
            catch
                disp('could not find a Session directory')
            end
            
            
            if exist(fullfile(pwd,obj.getsessionname()),'dir')
                cd(obj.getsessionname());
            else
                disp('No TherapyPlans for this session')
                cd(thisdir)
                return;
            end
            
            if exist(fullfile(pwd,'Leads'),'dir')
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
                
                %%NEW SURETUNE3.0 FIX
                if ~isnan(str2double(thisLead))
                    STUversion = 3;
                else
                    STUversion = 2.99;
                end
                
                %find thislead in the sessiondata
                [names,types] = obj.listregisterables;
                leadIds = names(ismember(types,'Lead'));
                
                leadNames = {};
                for leadId = 1:numel(leadIds)
                    leadNames{leadId} = obj.getregisterable(leadIds{leadId}).label;
                end
                
                if numel(leadNames)==0
                    return
                end
                
                %Find Lead Object
                try
                    thisLead = strrep(thisLead,'%28','(');
                    thisLead = strrep(thisLead,'%29',')');
                    thisLead = strrep(thisLead,'%2e','.');
                    
                    %%NEW STU FIX
                    if STUversion==3 %in this case the folders do not have a name but index number
                        thisLead = str2double(thisLead); %index starts at 0
                        leadObject = obj.getregisterable(leadIds{thisLead+1});
                    else
                        leadObject = obj.getregisterable(leadIds{~cellfun(@isempty,strfind(leadNames,thisLead))});
                        
                        
                        if isempty(leadIds{~cellfun(@isempty,strfind(leadNames,thisLead))})
                            warning('no matching lead names?')
                        end
                    end
                catch
                    warning('?')
                end
                
                if STUversion==3
                    therapyPlanFolders = SDK_subfolders(num2str(thisLead));
                else
                    therapyPlanFolders = SDK_subfolders(thisLead);
                end
                
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
                    
                    %%STU3fix
                    if STUversion == 3
                        stimPlanIndex = str2double(thisPlan)+1;
                    else
                        
                        stimPlanIndex = 0;
                        for iStimPlan = 1:numel(therapyXml.stimPlans.Array.StimPlan)
                            if strcmp(strrep(therapyXml.stimPlans.Array.StimPlan{iStimPlan}.label.Attributes.value,'.','_'),thisPlan)
                                stimPlanIndex = iStimPlan;
                                continue;
                            end
                        end
                        if stimPlanIndex==0;warning(['No matching stimplan in SessionData for ',thisPlan]);return;end
                    end
                    
                    
                    %get stimplan_path:
                    %determine XML path
                    genericPath = [leadObject.path,'.stimPlans.Array.StimPlan'];
                    try
                        index = numel(eval(genericPath)) +1;
                    catch
                        index =1;
                    end
                    path = [genericPath,'{',num2str(index),'}'];
                    
                    
                    % Get the Stimplan data from therapyXML:
                    if STUversion==3
                        VTA = obj.loadvta(fullfile(num2str(thisLead),thisPlan));
                        label = strrep(therapyXml.stimPlans.Array.StimPlan{str2double(thisPlan)+1}.label.Attributes.value,'.','_');
                    else
                        VTA = obj.loadvta(fullfile(thisLead,thisPlan));
                                            label = thisPlan;
                    end

                    voltageBasedStimulation = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.voltageBasedStimulation.Attributes.value;
                    stimulationValue = str2double(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.stimulationValue.Attributes.value);
                    pulseWidth = str2double(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.pulseWidth.Attributes.value);
                    pulseFrequency =str2double(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.pulseFrequency.Attributes.value);
                    activeRings = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.activeRings.BoolArray.Text;
                    contactsGrounded = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.contactsGrounded.BoolArray.Text;
                    annotation = therapyXml.stimPlans.Array.StimPlan{stimPlanIndex}.annotation.Attributes.value;
                    StrucAnnotation = SDK_getStructuredAnnotation(therapyXml.stimPlans.Array.StimPlan{stimPlanIndex});
                    component_args = {path,obj};
                    % Make a StimPlan Instance:
                    stimPlanObject = StimPlan(component_args,VTA,leadObject,label,voltageBasedStimulation,stimulationValue,pulseWidth,pulseFrequency,activeRings,contactsGrounded,annotation,StrucAnnotation);
                    
                    %                     %Add the therapy object to Lead.StimPlan{end+1}
                    %                     stimPlanObject.linktolead(leadObject)
                    
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
            try cd(folder);
            catch;return
            end
            
            
            
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
            if ~exist(folder)
                error('Volumes folder could not be found. Most likely something went wrong with unpacking the session file.')
            end
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
        
        
        
        
        
        
        
        
        
        
        %% deleted functions
        
        
        
        
        
        
        
        
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
        
        function val = getsessionname(obj)
            val = obj.sessionData.(obj.ver).Session.id.Attributes.value;
        end
        
        
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
        
        
        
    end
    
end

