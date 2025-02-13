% Specify the target directory (modify the path as needed)
folder = '/opt/seizmo';

% Define the function names to be replaced (old names and new names, in corresponding order)
oldNames = {'isstring', 'vecnorm'};
newNames = {'isstring_local', 'vecnorm_local'};

% Specify the file to be excluded from processing
excludeFile = 'rename_old_funcs.m';

% Get all .m files in the folder and its subdirectories (requires MATLAB R2016b or later)
fileList = dir(fullfile(folder, '**', '*.m'));

for i = 1:length(fileList)
    % Skip the excluded file
    if strcmpi(fileList(i).name, excludeFile)
        continue;
    end
    
    % Construct the full file path using the folder field
    filePath = fullfile(fileList(i).folder, fileList(i).name);
    
    % Read the file content
    text = fileread(filePath);
    
    % Process each function name replacement in the file content
    for j = 1:length(oldNames)
        % Construct the regular expression to ensure only whole words are replaced
        pattern = ['\<', oldNames{j}, '\>'];
        text = regexprep(text, pattern, newNames{j});
    end
    
    % Write the modified content back to the file
    fid = fopen(filePath, 'w');
    if fid == -1
        warning('Unable to open file: %s', filePath);
    else
        fwrite(fid, text);
        fclose(fid);
        fprintf('Updated file content: %s\n', filePath);
    end
    
    % Check if the file name itself needs to be renamed
    [~, baseName, ext] = fileparts(fileList(i).name);
    for j = 1:length(oldNames)
        if strcmp(baseName, oldNames{j})
            newFileName = [newNames{j}, ext];
            newFilePath = fullfile(fileList(i).folder, newFileName);
            % Rename the file
            status = movefile(filePath, newFilePath);
            if status
                fprintf('Renamed file: %s -> %s\n', fileList(i).name, newFileName);
            else
                warning('Failed to rename file: %s', filePath);
            end
            break;  % Exit the loop once a match is found
        end
    end
end