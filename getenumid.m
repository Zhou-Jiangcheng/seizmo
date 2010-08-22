function [varargout]=getenumid(data,varargin)
%GETENUMID    Get enum string id from SEIZMO data header enum field
%
%    Usage: cellstr=getenumid(data,'field')
%           [cellstr1,...,cellstrN]=getenumid(data,'field1',...,'fieldN')
%
%    Description: GETENUMID(DATA,FIELD) returns a cellstring array
%    containing the enum id strings associated with the values of the enum
%     header field FIELD stored in the SEIZMO structure DATA.  This offers
%     useful & readible output compared to the raw magic number returned by
%     GETHEADER.
%
%     GETENUMID(DATA,FIELD1,...,FIELDN) returns a cellstring array for each
%     field supplied.
%
%    Notes:
%     - Numeric header fields not defined to be enum fields can be used as 
%       if they were enum fields with GETENUMID.  This gives the user the 
%       ability to have more enum fields if needed.  Character fields are
%       NOT able to be treated as enum fields.
%     - Nonexistant header fields and undefined/invalid enum values return
%       'NaN'.
%
%    Examples:
%     To check if all records are timeseries data:
%      if(all(strcmp(getenumid(data,'iftype'),'itime')))
%          disp('timeseries dataset')
%      end
%
%     Interpret resp0 as an enum field:
%      my_enum_id=getenumid(data,'resp0')   
%
%    See also: GETHEADER, GETLGC, GETENUMDESC

%     Version History:
%        Feb. 23, 2008 - initial version
%        Feb. 28, 2008 - minor code clean
%        Feb. 29, 2008 - handle undefined
%        Mar.  4, 2008 - minor doc update
%        June 13, 2008 - doc update, compat fixes, handle values out of
%                        range or non-whole, avoid name conflict
%        Oct. 17, 2008 - added VINFO support
%        Nov. 16, 2008 - history fix, doc update, code cleaning, rename
%                        from GENUM to GETENUMID
%        Apr. 23, 2009 - move usage up
%        Oct.  6, 2009 - change special output to work with CHANGEHEADER
%        Jan. 29, 2010 - elimate extra VERSIONINFO call
%        Aug. 21, 2010 - all unknown fields/values return 'NaN', doc update
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Aug. 21, 2010 at 00:25 GMT

% require at least two inputs
if(nargin<2)
    error('seizmo:getenumid:notEnoughInputs',...
        'Not enough input arguments.')
end

% preallocate output
varnargin=length(varargin);
nvarargout=cell(1,varnargin);
varargout=nvarargout;
[varargout{:}]=deal(cell(numel(data),1));

% get header info
[nvarargout{:}]=getheader(data,varargin{:});

% pull header setup
global SEIZMO
h=SEIZMO.VERSIONINFO.H;
idx=SEIZMO.VERSIONINFO.IDX;

% loop over versions
for i=1:numel(h)
    % indexing of data with this header version
    ind=find(idx==i);
    
    % loop over fields
    for j=1:numel(varargin)
        % check for cell output (char field)
        if(iscell(nvarargout{j}(ind)))
            error('seizmo:getenumid:badField',...
                'String fields are not supported!');
        end
        
        % compare
        bad=isnan(nvarargout{j}(ind)) ...
            | nvarargout{j}(ind)<h(i).enum(1).minval...
            | nvarargout{j}(ind)>h(i).enum(1).maxval ...
            | fix(nvarargout{j}(ind))~=nvarargout{j}(ind);
        good=~bad;
        
        % assign enum descriptions
        if(any(bad))
            varargout{j}(ind(bad))={'NaN'};
        end
        if(any(good))
            varargout{j}(ind(good))=...
                h(i).enum(1).id(nvarargout{j}(ind(good))+1);
        end
    end
end

end
