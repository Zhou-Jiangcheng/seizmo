function [data]=amph2rlim(data)
%AMPH2RLIM    Convert SEIZMO spectral records from AMPH to RLIM
%
%    Usage:    data=amph2rlim(data)
%
%    Description: AMPH2RLIM(DATA) converts SEIZMO amplitude-phase records 
%     to real-imaginary records.  This is particularly useful when
%     performing basic operations on spectral records which would otherwise
%     require treating the amplitude and phase components separately.
%     Records in DATA must be of the spectral variety.  Real-imaginary
%     records are not altered.
%
%    Notes:
%
%    Header changes: IFTYPE, DEPMEN, DEPMIN, DEPMAX
%
%    Examples:
%     To simply multiply two records in the frequency domain, they must be
%     converted to real-imaginary first:
%      data=amph2rlim(data)
%      data=multiplyrecords(data(1),data(2))
%      data=rlim2amph(data)
%
%    See also: RLIM2AMPH, DFT, IDFT

%     Version History:
%        June 11, 2008 - initial version
%        June 20, 2008 - minor doc update
%        June 28, 2008 - fixed call to ch, removed option,
%                        doc update, .dep rather than .x
%        July 19, 2008 - dataless support, updates DEP* fields
%        Oct.  7, 2008 - minor code cleaning
%        Nov. 22, 2008 - update for new name schema
%        Apr. 23, 2009 - fix nargchk and seizmocheck for octave,
%                        move usage up
%        Oct. 21, 2009 - only touches amph (maybe a bit faster)
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Oct. 21, 2009 at 06:45 GMT

% todo:

% check nargin
msg=nargchk(1,1,nargin);
if(~isempty(msg)); error(msg); end

% check data structure
msg=seizmocheck(data,'dep');
if(~isempty(msg)); error(msg.identifier,msg.message); end

% turn off struct checking
oldseizmocheckstate=get_seizmocheck_state;
set_seizmocheck_state(false);

% attempt header check
try
    % check header
    data=checkheader(data);
catch
    % toggle checking back
    set_seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

% attempt conversion
try
    % retreive header info
    iftype=getenumdesc(data,'iftype');

    % find spectral
    amph=strcmpi(iftype,'iamph');
    rlim=strcmpi(iftype,'irlim');
    iamph=find(amph); namph=numel(iamph);

    % records must be spectral
    if(any(~amph & ~rlim))
        error('seizmo:amph2rlim:illegalOperation',...
            'Illegal operation on non-spectral file!');
    end

    % loop through records
    depmen=nan(namph,1); depmin=depmen; depmax=depmen;
    for i=1:namph
        k=iamph(i);

        % skip dataless
        if(isempty(data(k).dep)); continue; end

        % convert
        oclass=str2func(class(data(k).dep));
        data(i).dep=double(data(k).dep);
        temp=data(k).dep(:,1:2:end).*exp(j*data(k).dep(:,2:2:end));
        data(k).dep(:,1:2:end)=real(temp);
        data(k).dep(:,2:2:end)=imag(temp);
        data(k).dep=oclass(data(k).dep);

        % dep*
        depmen(i)=mean(data(k).dep(:));
        depmin(i)=min(data(k).dep(:));
        depmax(i)=max(data(k).dep(:));
    end

    % update filetype
    data(amph)=changeheader(data(amph),'iftype','irlim',...
        'depmax',depmax,'depmin',depmin,'depmen',depmen);

    % toggle checking back
    set_seizmocheck_state(oldseizmocheckstate);
catch
    % toggle checking back
    set_seizmocheck_state(oldseizmocheckstate);
    
    % rethrow error
    error(lasterror)
end

end
