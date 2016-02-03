function [  ] = addimagebasedstructuresegmentation( varargin )

% addimagebasedstructuresegmentation is an @Session function. It adds a imagebased segmentation of a dataset to the
% SessionObject.
%   Dataset =
%   SessionObject.addimagebasedstructuresegmentation(label,opacity,color,threshold,thresholdtype,
%   blurenabled, boundingbox, includeseeds, excludeseeds
%   

if nargin==1
    disp('input arguments should be: [object], label,opacity,color,threshold,thresholdtype,blurenabled, boundingbox, includeseeds, excludeseeds,parent')
    R = [];
    return
end

obj= varargin{1};
label = varargin{2};
opacity = varargin{3};
threshold = varargin{4};
thresholdType = varargin{5};
blurEnabled = varargin{6};
boundingbox = varargin{7};
includeSeeds = varargin{8};
excludeSeeds = varargin{9};
parent = varargin{10};

warning('Build a check for unique names')
%determine XML path
genericPath = 'obj.sessionData.SureTune2Sessions.Session.structureSegmentations.Array.ImageBasedStructureSegmentation';
try
    index = numel(eval(genericPath)) +1;
catch
    index =1;
end
path = [genericPath,'{',num2str(index),'}'];

if ischar(parent)
    %replace parent char with its object
    namelist = obj.registerables.names;
    parentindex = find(ismember(namelist,parent));

    if isempty(parentindex)
        warning('Parent is not known. Mesh is added without correct reference')
    else
        parent = obj.registerables.list{parentindex};
    end
end



T = eye(4);
component_args = {path,obj};
registerable_args = {parent,T,0,label}; %set accepted to true


%Make dummy elements in XML

A.parent.ref.Text = '';
A.parent.ref.Attributes.id = parent.matlabId;

A.transform.Matrix3D.Text = '';


A.label.Text = '';
A.label.Attributes.type = 'String';
A.label.Attributes.value = label;

A.opacity.Text = '';
A.opacity.Attributes.type = 'Double';
A.opacity.Attributes.value = opacity;

A.color.Text = '';
A.color.Attributes.type = 'Int';
A.color.Attributes.value = 8;

A.threshold.Text = '';
A.threshold.Attributes.type = 'Double';
A.threshold.Attributes.value = 5000;

A.thresholdType.Enum.Text = '';
A.thresholdType.Enum.Attribues.type = 'ThresholdType';
A.thresholdType.Enum.Attribues.value = 'Light';

A.blurEnabled.Text = '';
A.blurEnabled.Attributes.type = 'Bool';
A.blurEnabled.Attributes.value = blurEnabled;

A.boundingBox.BoundingBox.leftDown.Point3D.Text = '';
A.boundingBox.BoundingBox.leftDown.Point3D.Attributes.x = boundingbox.leftDown(1);
A.boundingBox.BoundingBox.leftDown.Point3D.Attributes.y = boundingbox.leftDown(2);
A.boundingBox.BoundingBox.leftDown.Point3D.Attributes.z = boundingbox.leftDown(3);
A.boundingBox.BoundingBox.rightUp.Point3D.Attributes.x = boundingbox.rightUp(1);
A.boundingBox.BoundingBox.rightUp.Point3D.Attributes.y = boundingbox.rightUp(2);
A.boundingBox.BoundingBox.rightUp.Point3D.Attributes.z = boundingbox.rightUp(3);

A.includeSeeds.Array.Text = '';
A.excludeSeeds.Array.Text = '';



%add dummy elements
eval([path,' = A'])



R = ImageBasedStructureSegmentation(component_args,registerable_args,label, opacity, color, threshold, thresholdType, blurEnabled,boundingBox, includeSeeds, excludeSeeds);

%Add to registerable list
obj.registerables.names{end+1} = label;
obj.registerables.list{end+1} = R;








end


