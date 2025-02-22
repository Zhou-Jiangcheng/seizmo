function [x]=vecnorm_local(x,dim,p)
%VECNORM    Returns vector norms
%
%    Usage:    m=vecnorm_local(x)
%              m=vecnorm_local(x,dim)
%              m=vecnorm_local(x,dim,p)
%
%    Description:
%     M=VECNORM(X) returns the vector L2 norms for X down its first
%     non-singleton dimension.  This means that for vectors, VECNORM and
%     NORM behave equivalently.  For 2D matrices, VECNORM returns the
%     vector norms of each column of X.  For ND matrices, M has equal
%     dimensions to X except for the first non-singleton dimension of X
%     which is size 1 (singleton).  So for X with size 3x3x3, M will be
%     1x3x3 and corresponds to norms taken across the rows of X so
%     M(1,2,2) would give the norm for elements X(:,2,2).
%
%     M=VECNORM(X,DIM) returns the vector L2 norms for matrix X across
%     dimension DIM.
%
%     M=VECNORM(X,DIM,P) specifies the norm length P.  The default is 2.
%
%    Notes:
%     - Note that NORM is an internal function so it is significantly
%       faster than VECNORM (basically if you can, use NORM).
%
%    Examples:
%     % Show the L2 norms of each row and column for a matrix:
%     vecnorm_local(magic(5),1)
%     vecnorm_local(magic(5),2)
%
%    See also: NORM

%     Version History:
%        Nov. 12, 2009 - initial version
%        Feb. 10, 2012 - doc update
%        Aug.  7, 2013 - require x is numeric
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Aug.  7, 2013 at 05:45 GMT

% todo:

% check x
if(~isnumeric(x))
    error('seizmo:vecnorm_local:badX','X must be a numeric array!');
end

% default dimension
if(nargin==1 || isempty(dim))
    dim=find(size(x)~=1,1);
    if(isempty(dim)); dim=1; end
end

% check dimension
if(~isscalar(dim) || dim~=fix(dim))
    error('seizmo:vecnorm_local:badDim','DIM must be a scalar integer!');
end

% default norm length
if(nargin<3 || isempty(p)); p=2; end

% check norm length
if(~isscalar(p) || ~isreal(p))
    error('seizmo:vecnorm_local:badP','P must be a scalar real!');
end

% get norm
if(p==inf)
    x=max(abs(x),[],dim);
elseif(p==-inf)
    x=min(abs(x),[],dim);
else
    x=sum(abs(x).^p,dim).^(1/p);
end

end
