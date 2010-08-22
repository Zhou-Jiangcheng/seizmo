function [data]=synchronize(data,field,option,iztype,timing,varargin)
%SYNCHRONIZE    Synchronizes the reference times of SEIZMO records
%
%    Usage:    data=synchronize(data)
%              data=synchronize(data,field)
%              data=synchronize(data,field,option)
%              data=synchronize(data,field,option,iztype)
%              data=synchronize(data,field,option,iztype,timing)
%              data=synchronize(data,field,option,iztype,timing,...
%                               field1,...,fieldN)
%
%    Description: SYNCHRONIZE(DATA) synchronizes the reference times for
%     all records in DATA.  It sets the unified reference time to the
%     starting time of the latest starting record.  All timing fields (A,
%     B, E, F, O, Tn) are correspondingly shifted so that their timing is
%     preserved.  This is particularly useful when combined with CUT to get
%     a time window corresponding to a specific absolute time range.
%
%     SYNCHRONIZE(DATA,FIELD) changes the header field that the
%     synchronization is based on.  FIELD may be any header field that
%     returns one numeric value per record.  By default, FIELD is 'b'.  If
%     FIELD is not a recognized timing field (A, B, E, F, O, Tn), it will
%     not be shifted in the resulting output unless it is also supplied as
%     a user field (see final usage description).  Field may also be 'Z'
%     to align on a reference time.  Field can be a 1x5 or 1x6 numeric
%     vector or a KZDTTM string to directly set the absolute time to
%     synchronize on.
%
%     SYNCHRONIZE(DATA,FIELD,OPTION) sets whether reference times are
%     synced to the first or last occuring FIELD (in absolute time sense).
%     OPTION may be either 'FIRST' or 'LAST' (default).
%
%     SYNCHRONIZE(DATA,FIELD,OPTION,IZTYPE) changes the output records'
%     header field 'iztype' to IZTYPE.  This value is passed directly to
%     CHANGEHEADER as 'changeheader(DATA,'iztype',IZTYPE)'.  The default
%     IZTYPE is 'iunkn'.
%
%     SYNCHRONIZE(DATA,FIELD,OPTION,IZTYPE,TIMING) sets the absolute timing
%     standard to TIMING.  TIMING must be either 'UTC' or 'TAI'.  The
%     default is 'UTC' and takes UTC leap seconds into account.
%
%     SYNCHRONIZE(DATA,FIELD,OPTION,IZTYPE,TIMING,FIELD1,...,FIELDN) shifts
%     the user-defined timing fields FIELD1 thru FIELDN so their timing is
%     also preserved in the sync.  If a non-standard timing field is used
%     for syncing (FIELD parameter), then that field must be included in
%     this list as well.  See the examples below for further clarity.
%
%    Notes:
%     - Due to the reference time resolution of 1 millisecond, the field
%       being aligned on may not be zero but will be within a millisecond.
%
%    Header changes: NZYEAR, NZJDAY, NZHOUR, NZMIN, NZSEC, NZMSEC,
%                    A, B, E, F, O, Tn, and any user-defined field
%
%    Examples:
%     Just like SAC:
%      data=synchronize(data);
%
%     Sync to the first occurance of USER2, making sure to update USERN:
%      data=synchronize(data,'user2','first',[],[],'user');
%
%    See also: TIMESHIFT, CUT

%     Version History:
%        June 24, 2009 - initial version
%        Sep. 24, 2009 - added iztype field parameter
%        Sep. 25, 2009 - better fix for reftime millisec limit, true sync
%        Oct. 17, 2009 - added direct absolute time input
%        Feb.  3, 2010 - proper SEIZMO handling, seizmoverbose support, fix
%                        xy datatype bug, fix checking order bug
%        Aug. 21, 2010 - nargchk fix, better checkheader usage, update
%                        undef checking, drop versioninfo caching
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Aug. 21, 2010 at 16:20 GMT

% todo:

% check nargin
error(nargchk(1,inf,nargin));

% check headers
data=checkheader(data,...
    'NONTIME_IFTYPE','ERROR');

% turn off struct checking
oldseizmocheckstate=seizmocheck_state(false);

% attempt time synchronization
try
    % verbosity
    verbose=seizmoverbose;

    % number of records
    nrecs=numel(data);
    
    % detail message
    if(verbose)
        disp('Sychronizing Record(s)');
        print_time_left(0,nrecs);
    end

    % valid option values
    valid.TIMING={'UTC' 'TAI'};
    valid.OPTION={'LAST' 'FIRST'};

    % default/check field (catching warnings)
    abstime=false;
    if(nargin>1 && iscell(field) && isscalar(field)); field=field{1}; end
    if(nargin<2 || isempty(field))
        field='b';
        values=getheader(data,field);
    elseif(isnumeric(field))
        if((~isequal(size(field),[1 5]) && ~isequal(size(field),[1 6])) ...
                || any(isnan(field) | isinf(field)) ...
                || ~isequal(field(1:end-1),round(field(1:end-1))))
            error('seizmo:synchronize:badField',...
                'Numeric FIELD must be 1x5 or 1x6 and not be NaN or Inf!');
        end
        abstime=true;
    elseif(~ischar(field) || size(field,1)~=1)
        error('seizmo:synchronize:badField',...
            'FIELD must be a character string!');
    else
        if(isequal(size(field),[1 29]))
            num=true(1,29);
            num(1,[5 8 11 12 16 17 20 23 26])=false;
            if(~strcmp(field(~num),'-- () ::.') ...
                    || ~all(isstrprop(field(num),'digit')))
                error('seizmo:synchronize:badField',...
                    'FIELD kzdttm-style string improperly formatted!');
            end
            field=str2double([cellstr(field(1:4)) cellstr(field(13:15)) ...
                cellstr(field(18:19)) cellstr(field(21:22)) ...
                cellstr(field(24:25)) cellstr(field(27:29))]);
            abstime=true;
        elseif(strcmpi(field,'z'))
            values=zeros(nrecs,1);
        else
            warning('off','seizmo:getheader:fieldInvalid')
            values=getheader(data,field);
            warning('on','seizmo:getheader:fieldInvalid')
            if(any(isnan(values)) || ~isnumeric(values) || size(values,2)>1)
                error('seizmo:synchronize:badOption',...
                    'FIELD must be a valid numeric header field string!');
            end
        end
    end

    % force values to nearest millisecond
    if(~abstime); values=round(values*1000)/1000; end

    % default/check option
    if(nargin<3 || isempty(option))
        option='last';
    elseif(~ischar(option) || size(option,1)~=1 ...
            || ~any(strcmpi(option,valid.OPTION)))
        error('seizmo:synchronize:badOption',...
            ['OPTION must be a string of one of the following:\n'...
            sprintf('%s ',valid.OPTION{:})]);
    end

    % default iztype
    if(nargin<4 || isempty(iztype))
        iztype='iunkn';
    end

    % default/check timing
    if(nargin<5 || isempty(timing))
        timing='utc';
    elseif(~ischar(timing) || size(timing,1)~=1 ...
            || ~any(strcmpi(timing,valid.TIMING)))
        error('seizmo:synchronize:badTiming',...
            ['TIMING must be a string of one of the following:\n'...
            sprintf('%s ',valid.TIMING{:})]);
    end

    % get header fields
    nvararg=numel(varargin);
    user=cell(1,nvararg);
    [a,b,e,f,o,t,nzyear,nzjday,nzhour,nzmin,nzsec,nzmsec,user{:}]=...
        getheader(data,'a','b','e','f','o','t',...
        'nzyear','nzjday','nzhour','nzmin','nzsec','nzmsec',varargin{:});

    % get shift
    reftimes=[nzyear nzjday nzhour nzmin nzsec+nzmsec/1000];
    if(abstime)
        synctime=fixtimes(field,timing);
        if(strcmpi(timing,'tai'))
            reftimes=fixtimes(reftimes);
        end
    else
        times=sortrows(fixtimes(...
            [reftimes(:,1:4) reftimes(:,5)+values],timing));
        times(:,5)=fix(1000*(times(:,5)+1e-9))/1000; % handle msec limit
        switch lower(option)
            case 'last'
                synctime=times(end,:);
            case 'first'
                synctime=times(1,:);
        end
    end

    % get shift
    shift=timediff(synctime,reftimes,timing);

    % shift user fields, but not undefined user fields
    for i=1:nvararg
        if(~isnumeric(user{i}))
            error('seizmo:synchronize:badUserField',...
                'User given fields must return numeric arrays!');
        end
        sz=size(user{i},2);
        user{i}=user{i}+shift(:,ones(sz,1));
    end

    % combine field and values for changeheader call
    user=[varargin; user];

    % change header fields
    data=changeheader(data,'iztype',iztype,...
        'nzyear',synctime(1),'nzjday',synctime(2),...
        'nzhour',synctime(3),'nzmin',synctime(4),...
        'nzsec',fix(synctime(5)+1e-9),...
        'nzmsec',fix(1000*mod(synctime(5)+1e-9,1)),...
        'a',a+shift,'b',b+shift,'e',e+shift,'f',f+shift,...
        'o',o+shift,'t',t+shift(:,ones(10,1)),user{:});
    
    % detail message
    if(verbose); print_time_left(nrecs,nrecs); end

    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
catch
    % toggle checking back
    seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

end
