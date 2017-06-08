function [Polyline] = SDK_generatepolylinesegment(lin,lcin,rcin,rin)
Accuracy = 1e-3;
Polyline = {};
queue = {};
queue{end+1} = {lin lcin rcin rin};

while numel(queue)>0
    elem = queue{1};
    queue(1) = [];
    
    l = elem{1};
    lc = elem{2};
    rc = elem{3};
    r = elem{4};
    
    lCross = [];
    rCross = [];
    
    lCross.X = ...
        ((lc(2) - l(2))*(r(3) - l(3))) - ...
        ((lc(3) - l(3))*(r(2) - l(2)));
    lCross.Y =...
        ((lc(3) - l(3))*(r(1) - l(1))) -...
        ((lc(1) - l(1))*(r(3) - l(3)));
    lCross.Z =...
        ((lc(1) - l(1))*(r(2) - l(2))) -...
        ((lc(2) - l(2))*(r(1) - l(1)));
    rCross.X =...
        ((rc(2) - r(2))*(l(3) - r(3))) -...
        ((rc(3) - r(3))*(l(2) - r(2)));
    rCross.Y =...
        ((rc(3) - r(3))*(l(1) - r(1))) -...
        ((rc(1) - r(1))*(l(3) - r(3)));
    rCross.Z =...
        ((rc(1) - r(1))*(l(2) - r(2))) -...
        ((rc(2) - r(2))*(l(1) - r(1)));
    
    %Test for small cross-products by testing individual components...
    if (...
        (-Accuracy < lCross.X) && (lCross.X < Accuracy) &&...
        (-Accuracy < lCross.Y) && (lCross.Y < Accuracy) &&...
        (-Accuracy < lCross.Z) && (lCross.Z < Accuracy) &&...
        (-Accuracy < rCross.X) && (rCross.X < Accuracy) &&...
        (-Accuracy < rCross.Y) && (rCross.Y < Accuracy) &&...
        (-Accuracy < rCross.Z) && (rCross.Z < Accuracy)...
        )
        Polyline{end+1} = elem{4};
    else
        % Segment requires further refinement, split segment into
        % two smaller parts and generate recursively for each part...
        rlc = (lc + 2*rc + r)*0.25;
        rrc = (rc + r)*0.5;
        llc = (l + lc)*0.5;
        lrc = (l + 2*lc + rc)*0.25;
        s = (l + 3*lc + 3*rc + r)*0.125;
        
        elem1 = {l,llc,lrc,s};
        elem2 = {s,rlc,rrc,r};
        
        % Segment is split into two pieces. Make sure piece from l -> s is
        % handled before s-> r
        
        queue = {elem1,elem2,queue{:}};
    end
        
end
end