function response = REDCap(varargin)

% %%%%%%%%%%%%%%%%%%%%%%%% REDCap interface %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  General notes:
%  ==============
%
%  (1) The user needs an API token to communicate with REDCap server.
%  Inquire with your administrator about obtaining a token.
%
%  (2) The user needs to have proper User Rights within the Project, such
%  as 'Data Export Tool' ('Full Data Set'), 'API' ('Export', 'Import')
%
%  (3) The user may have to be on the database network or via VPN
%
%  (4) Read the examples provided, the REDCap manual and use the API
%      playground.  REDCap is very useful but under reported via google etc
%
%
%  REDCap.m INPUTS:
%  ================
%
% 'arm' - cell array list of all arms available
%
% 'event' - cell array list of all events available, per arm
%
% 'exportfieldnames' - provides a table with fieldnames used for export
%
% 'filename' - returns the filename of a file associated with a field
%
% 'generateNextRecordName' - number of next record (when generated)
%
% 'init' - sets up token, url, etc.
%
% 'read' -  reads records, fields, files, etc. Reading a field provides
%           the field content.  Reading a file requires a pathname under
%           which the file is to be stored
%           On macOS the path can be for example: '~/Downloads'
%           On Windows 10 the path can for exmaple be: 'C:\Users\--username--\Downloads'
%
% 'report' - cell array list of specified report, very useful way to
%            extract large data amount
% 'write' - writes records, fields, files, etc. to REDCap.  The maximum
%           file size may vary.  In the present setup it is ~35 MB per
%           file. Writing a field requires the field content in exactly 
%           the format specified within REDCap! Writing a file requires
%           a pathname from which the file is read from.
%           Successful write replies with a '{"count": 1}', indicating
%           that one content was written.
%
%  REDCap.m OUTPUTS:
%  =================
%
%  Errors within REDCap.m are reported as:
%
%   0  : normal execution, no error
%  -1.2: malformed input arguments to REDCap.m
%  -1.3: too few arguments
%  -1.4: unknown command
%  -1.5: URL for REDCap server not declared
%  -1.6: token not declared
%
%  Errors within redcap server/database are reported as:
%
%  '{"error":"....error description ...."}'
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Oliver D. Kripfgans, University of Michigan, 2019-2021
%  Version 1.0.0
%
%  Acknowledgement:
%  REDCap Database software
%  (https://redcap.vanderbilt.edu).  
%  Currently REDCap 11.4.3 - © 2021 Vanderbilt University.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global redcap_url
global redcap_token
            
WRITE_OR_NOT = 1;
response = 0;

if nargin>0
    switch varargin{1}
        
        case 'init'
%             if mod(nargin,2)~=1 && nargin>3 %odd(nargin) && nargin>3
                for qwe=2:2:(nargin-1)
                    switch varargin{qwe}
                        case 'url'
                            redcap_url = varargin{qwe+1};
                        case 'token'
                            redcap_token = varargin{qwe+1};
                        otherwise
                            fprintf(2, 'REDCap:init: Unknown input argument %s!\n', varargin{qwe});
                            response = -1.1;
                            return
                    end
                end
%             else
%                 fprintf(2, 'REDCap:Init: Malformed input arguments!\n');
%                 response = -1.2;
%                 return
%             end

        case 'read'
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    ops = weboptions('CertificateFilename', '', 'Debug', false);
                    record_num = sprintf('%d', varargin{2});
                    response = webwrite(redcap_url, 'token', redcap_token, 'content','record', 'format','csv', 'type','flat', ...
                                'records', record_num, 'fields', varargin{4}, 'events', varargin{3}, ...
                                'rawOrLabel','raw', 'rawOrLabelHeaders','raw', 'exportCheckboxLabel','false', 'exportSurveyFields','false', ...
                                'exportDataAccessGroups','false', 'returnFormat','csv', ops);
                    response = table2array(response);
                    if iscell(response)
                        if contains(response{1}, '[document]') || (prod(response{1}((end-2):(end))=='DCM')==1) || (prod(response{1}((end-2):(end))=='png')==1)
                            dToken = [  '-d "token=', redcap_token, '&', ...
                            'content=file&action=export&record=', record_num, '&returnFormat=csv&field=', varargin{4}, '&event=', varargin{3},'"', ...
                            ' -o ', varargin{5}, '/output.dat'];

                            hCmd1 = '-H "Content-Type: application/x-www-form-urlencoded"';
                            hCmd2 = '-H "Accept: application/json"';
                            unixCmd = sprintf('curl  -v %s  %s   -X POST  %s  %s ', hCmd1, hCmd2, dToken, redcap_url);
                            if WRITE_OR_NOT
                                if ispc
                                    [~, uResultFile] = system( unixCmd );
                                else
                                    [~, uResultFile] = unix( unixCmd );
                                end
                                response = uResultFile((strfind(uResultFile, 'name="')+6)+(0:(find(uResultFile((strfind(uResultFile, 'name="')+6):end)=='"')-2)));
                                % rename file to proper name
                                unixCmd = ['mv ', varargin{5}, '/output.dat ', varargin{5}, '/', response];
                                if ispc
                                    movefile([varargin{5}, '/output.dat '],[varargin{5}, '/', response], 'f'); 
                                else
                                    unix( unixCmd );
                                end
                            else
                                fprintf(1, 'UNIX: >>%s<<\n', unixCmd);  uState=0;  response = 'simulate write';   %#ok<UNRCH>
                            end
                        end
                    end
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end

        case 'filename'
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    ops = weboptions('CertificateFilename', '', 'Debug', false);
                    record_num = sprintf('%d', varargin{2});
                    response = webwrite(redcap_url, 'token', redcap_token, 'content','record', 'format','csv', 'type','flat', ...
                                'records[0]', record_num, 'fields[0]', varargin{4}, 'events[0]', varargin{3}, ...
                                'rawOrLabel','label', 'rawOrLabelHeaders','LabelHeaders', 'exportCheckboxLabel','false', 'exportSurveyFields','false', ...
                                'exportDataAccessGroups','false', 'returnFormat','csv', ops);
                    response = table2array(response);
                    if iscell(response)
                        bracketResults = strfind(response{1}, '[document]');
                        if bracketResults>0
                            dToken = [  '-d "token=', redcap_token, '&', ...
                            'content=record&action=export&record=', record_num, '&returnFormat=csv&field=', varargin{4}, '&event=', varargin{3},'"'];
                            hCmd1 = '-H "Content-Type: application/x-www-form-urlencoded"';
                            hCmd2 = '-H "Accept: application/json"';
                            unixCmd = sprintf('curl  -v %s  %s   -X POST  %s  %s ', hCmd1, hCmd2, dToken, redcap_url);
                            if WRITE_OR_NOT
                                if ispc
                                    [~, uResultFile] = system( unixCmd );
                                else
                                    [~, uResultFile] = unix( unixCmd );
                                end
                                response = uResultFile((strfind(uResultFile, 'name="')+6)+(0:(find(uResultFile((strfind(uResultFile, 'name="')+6):end)=='"')-2)));
                            else
                                fprintf(1, 'UNIX: >>%s<<\n', unixCmd);  uState=0;  response = 'simulate write';   %#ok<UNRCH>
                            end
                        end
                    end
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end
            
        case {'arm', 'event','fieldnames'}
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    ops = weboptions('CertificateFilename', '', 'Debug', false);
                    response = webwrite(redcap_url, 'token', redcap_token, ...
                        'content',varargin{1}, 'format','csv', 'type','flat', ...
                        'rawOrLabel','raw', 'rawOrLabelHeaders','raw', 'exportCheckboxLabel','false', ...
                        'exportSurveyFields','false', 'exportDataAccessGroups','false', 'returnFormat','csv', ops);
                    response = table2cell(response);
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end
            
        case 'exportfieldnames'
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    ops = weboptions('CertificateFilename', '', 'Debug', false);
                    response = webwrite(redcap_url, 'token', redcap_token, 'content','exportFieldNames', 'format','csv', 'type','flat', ...
                                'rawOrLabel','raw', 'rawOrLabelHeaders','raw', 'exportCheckboxLabel','false', 'exportSurveyFields','false', ...
                                'exportDataAccessGroups','false', 'returnFormat','csv', ops);
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end
            
        case 'generateNextRecordName'
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    ops = weboptions('CertificateFilename', '', 'Debug', false);
                    response = webwrite(redcap_url, 'token', redcap_token, ...
                        'content',varargin{1}, 'format','csv', 'type','flat', ...
                        'rawOrLabel','raw', 'rawOrLabelHeaders','raw', 'exportCheckboxLabel','false', ...
                        'exportSurveyFields','false', 'exportDataAccessGroups','false', 'returnFormat','csv', ops);
                    response = table2array(response);
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end
            
        case 'write'
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    record_num = varargin{2};%sprintf('%d', varargin{2});
                    hCmd1 = '-H "Content-Type: application/x-www-form-urlencoded"';
                    hCmd2 = '-H "Accept: application/json"';

                    % check if what we upload is a record entry or a file
                    if ~isfile(varargin{5})
                        dToken = [  '-d "token=', redcap_token, '&', ...
                        'content=record&format=json&type=flat&overwriteBehavior=overwrite&', ...  % overwrite
                        'forceAutoNumber=false&', ...
                        ['data=[{', ...
                            '\"id_redcap\":\"', record_num, '\",', ...
                            '\"', varargin{4}, '\":\"', varargin{5}, '\",', ...
                            '\"redcap_event_name\":\"', varargin{3}, '\",', ...
                            '\"redcap_repeat_instrument\":\"', '', '\",', ...
                            '\"redcap_repeat_instance\":\"', varargin{6}, '\"}]&'], ...
                        'returnContent=count&returnFormat=json"'  ];
                   
                        unixCmd = sprintf('curl  %s  %s   -X POST  %s  %s ', hCmd1, hCmd2, dToken, redcap_url);
                        if WRITE_OR_NOT
                            if ispc
                                [uState, response] = system( unixCmd );
                            else
                                [uState, response] = unix( unixCmd );
                            end
                        else
                            fprintf(1, 'UNIX: >>%s<<\n', unixCmd);  uState=0;  response = 'simulate write';  %#ok<UNRCH>
                        end
                        if uState % any error occur?
                            fprintf(2, 'REDCap/system response: %s\n', response);
                            fprintf(2, '>> %s\n', unixCmd(228:end));
                        end
                    else
                        % we upload a file              
                        [~, this_name, this_ext] = fileparts(varargin{5});
                        if ispc
                            temp = [app.this_app_path, '\', this_name, this_ext];
                            movefile(varargin{5}, temp,'f');
                        else
                            temp = ['/tmp/', this_name, this_ext];
                            unix(['cp "', varargin{5}, '" /tmp/', [this_name, this_ext]]);
                        end                                    
                        dToken = [  ...
                            '-F "token=', redcap_token, '"', ...
                            ' -F "content=file"', ...
                            ' -F "action=import"', ...
                            ' -F "record=', record_num, '"', ...
                            ' -F "event=', varargin{3}, '"', ...
                            ' -F "field=', varargin{4}, '"', ...
                            ' -F "filename=', [this_name, this_ext], '"', ...
                            ' -F "file=@', temp, '"'];
                        
                        unixCmd = ['curl  ', hCmd2, '  -X POST  ', hCmd2, '  ', dToken, '  ', app.redcap_url];
                        if ispc
                            [uState, uResultUpload] = system( unixCmd );
                            delete(temp);
                        else
                            [uState, uResultUpload] = unix( unixCmd );
                            unix(['rm ', temp]);
                        end
                        if uState
                            response = fprintf(2, 'Error Up: %d, %s\n', uState, uResultUpload);
                        else
                            response = 'upload succeeded';
                        end                        
                    end
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end
            
        case 'report'
            if ~isempty(redcap_url)
                if ~isempty(redcap_token)
                    % ready to contact REDCap
                    ops = weboptions('CertificateFilename', '', 'Debug', false);
                    response = webwrite(redcap_url, 'token', redcap_token, 'content', varargin{1}, ...
                        'report_id', varargin{2}, 'format','csv', 'returnFormat','csv', ops);
                    % obtain record ID, event, pig#, tooth#
                    response = table2cell(response);
                else
                    fprintf(2, 'REDCap:read: Declare token first!\n');
                    response = -1.6;
                end
            else
                fprintf(2, 'REDCap:read: Declare URL first!\n');            
                response = -1.5;
            end
            
        otherwise
            fprintf(2, 'REDCap: Unknown command!\n');
            response = -1.4;
    end
else
    fprintf(2, 'REDCap: Too few input arguments!\n');
    response = -1.3;
    return

end

