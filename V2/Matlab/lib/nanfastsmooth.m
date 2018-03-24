function SmoothY = nanfastsmooth(Y,w,type,tol)
% nanfastsmooth(Y,w,type,tol) smooths vector Y with moving  
% average of width w ignoring NaNs in data.. 
%
% Y is input signal.
% w is the window width.
%
% The argument "type" determines the smooth type:
%   If type=1, rectangular (sliding-average or boxcar) 
%   If type=2, triangular (2 passes of sliding-average)
%   If type=3, pseudo-Gaussian (3 passes of sliding-average)
%
% The argument "tol" controls the amount of tolerance to NaNs allowed 
% between 0 and 1. A value of zero means that if the window has any NaNs 
% in it then the output is set as NaN. A value of 1 allows any number of 
% NaNs in the window and will still give an answer for the smoothed signal. 
% A value of 0.5 means that there must be at least half
% real values in the window for the output to be valid.
%
% The start and end of the file are treated as if there are NaNs beyond the
% dataset. As such the behaviour depends on the value of 'tol' as above.
% With 'tol' set at 0.5 the smoothed signal will start and end at the same
% time as the orgional signal. However it's accuracy will be reduced and
% the moving average will become more and more one-sided as the beginning 
% and end is approached.
%
% fastsmooth(Y,w,type) smooths with tol = 0.5.
% fastsmooth(Y,w) smooths with type = 1 and tol = 0.5
% 
% Version 1.0, 26th August 2015. G.M.Pittam
%   - First Version
% Version 1.1, 5th October 2015. G.M.Pittam
%   - Updated to correctly smooth both even and uneven window length. 
%   - Issue identified by Erik Benkler 5th September 2015.
% Modified from fastsmooth by T. C. O'Haver, May, 2008.

if nargin == 2, tol = 0.5; type = 1; end
if nargin == 3, tol = 0.5; end
switch type
case 1
   SmoothY = sa(Y,w,tol);
case 2
   SmoothY = sa(sa(Y,w,tol),w,tol);
case 3
   SmoothY = sa(sa(sa(Y,w,tol),w,tol),w,tol);
end

function SmoothY = sa(Y,smoothwidth,tol)
if smoothwidth == 1
    SmoothY = Y;
    return
end

% Bound Tollerance
if tol<0, tol=0; end
if tol>1, tol=1; end

w = round(smoothwidth);
halfw = floor(w/2);
L = length(Y);

% Make empty arrays to store data
n = size(Y);
s = zeros(n);
np = zeros(n);

if mod(w,2)
    % Initialise Sums and counts
    SumPoints = NaNsum(Y(1:halfw+1));
    NumPoints = sum(~isnan(Y(1:halfw+1)));

    % Loop through producing sum and count
    s(1) = SumPoints;
    np(1) = NumPoints;
    for k=2:L
        if k > halfw+1 && ~isnan(Y(k-halfw-1))
            SumPoints = SumPoints-Y(k-halfw-1);
            NumPoints = NumPoints-1;
        end
        if k <= L-halfw && ~isnan(Y(k+halfw))
            SumPoints = SumPoints+Y(k+halfw);
            NumPoints = NumPoints+1;
        end
        s(k) = SumPoints;
        np(k) = NumPoints;
    end
else
    % Initialise Sums and counts
    SumPoints = NaNsum(Y(1:halfw))+0.5*Y(halfw+1);
    NumPoints = sum(~isnan(Y(1:halfw)))+0.5;

    % Loop through producing sum and count
    s(1) = SumPoints;
    np(1) = NumPoints;
    for k=2:L
        if k > halfw+1 && ~isnan(Y(k-halfw-1))
            SumPoints = SumPoints - 0.5*Y(k-halfw-1);
            NumPoints = NumPoints - 0.5;
        end
        if k > halfw && ~isnan(Y(k-halfw))
            SumPoints = SumPoints - 0.5*Y(k-halfw);
            NumPoints = NumPoints - 0.5;
        end
        if k <= L-halfw && ~isnan(Y(k+halfw))
            SumPoints = SumPoints + 0.5*Y(k+halfw);
            NumPoints = NumPoints+1;
        end
        s(k) = SumPoints;
        np(k) = NumPoints;
    end
else
    % Initialise Sums and counts
    SumPoints = NaNsum(Y(1:halfw))+0.5*Y(halfw+1);
    NumPoints = sum(~isnan(Y(1:halfw)))+0.5;

    % Loop through producing sum and count
    s(1) = SumPoints;
    np(1) = NumPoints;
    for k=2:L
        if k > halfw+1 && ~isnan(Y(k-halfw-1))
            SumPoints = SumPoints - 0.5*Y(k-halfw-1);
            NumPoints = NumPoints - 0.5;
        end
        if k > halfw && ~isnan(Y(k-halfw))
            SumPoints = SumPoints - 0.5*Y(k-halfw);
            NumPoints = NumPoints - 0.5;
        end
        if k <= L-halfw && ~isnan(Y(k+halfw))
            SumPoints = SumPoints + 0.5*Y(k+halfw);
            NumPoints = NumPoints + 0.5;
        end
        if k <= L-halfw+1 && ~isnan(Y(k+halfw-1))
            SumPoints = SumPoints + 0.5*Y(k+halfw-1);
            NumPoints = NumPoints + 0.5;
        end
        s(k) = SumPoints;
        np(k) = NumPoints;
    end
end

% Remove the amount of interpolated datapoints desired
np(np<max((w*(1-tol)),1)) = NaN;

% Calculate Smoothed Signal
SmoothY=s./np;

function y = NaNsum(x)
y = sum(x(~isnan(x)));            
            
