if ~exist('Session','class')
    try
        loadSDK
    catch
        error('Please add the SDK to your path, then try again.')
    end
end
    
%go to the installation directory    
installationDirSession = Session;
current_dir = pwd;
cd(installationDirSession.homeFolder);


button = questdlg(sprintf('You are about to reclone the lastest version of the SDK.\n Do you wish to keep your local changes? \n(If you press no, all local changes are deleted) '),'Do you want to proceed?','Cancel') ;
    switch button
        case 'Yes'
            !git stash
            !git fetch
            !git merge -Xignore-space-change origin/master 
            !git stash pop
        case 'No'
            button2 = questdlg(sprintf('Are you really sure you want a clean version?'),'Are you Sure?','Cancel') ;
            switch button2
                case 'Yes'
                    !git reset --hard
                    !git fetch
                    !git merge -Xignore-space-change origin/master 
                otherwise
                    error('Script aborted - User was not sure.')
            end
                    
        case 'Cancel'
            error('Script aborted - User pressed cancel.')
        case ''
           error('Script aborted - User pressed cancel.')
    end
    
    
%% write hash for version control
fileID = fopen(fullfile('@Session','version.txt'), 'w+');

[~,hash] = system('git rev-list --max-count=1 HEAD');
hash = strrep(hash,sprintf('\n'),'');
%any changes after last commit?
if system('git diff --no-ext-diff --quiet')
    hash = [hash,'-dirty'];
end

fprintf(fileID, '%s', hash);
fclose(fileID);

%% get SureTune installation directory

if ~exist(fullfile('@Session','SureTuneInstallationDirectory.txt'),'file')
    pathname = uigetdir('C:\','One time only: where is your SureTune.exe?');
    fileID = fopen(fullfile('@Session','SureTuneInstallationDirectory.txt'), 'w+');
    fprintf(fileID, '%s', pathname);
    fclose(fileID);
end
    

    
    
%return to previous folder
cd(current_dir);