function sessioninfo(obj)
sessionname = trytoget(['obj.sessionData.',obj.ver,'.Session.id.Attributes.value']);
patientname = trytoget(['obj.sessionData.',obj.ver,'.Session.patient.Patient.name.Attributes.value']);
dateofbirth = trytoget(['obj.sessionData.',obj.ver,'.Session.patient.Patient.dateOfBirth.Attributes.value']);
gender = trytoget(['obj.sessionData.',obj.ver,'.Session.patient.Patient.gender.Enum.Attributes.value']);
savedate = trytoget(['obj.sessionData.',obj.ver,'.Attributes.exportDate']);

fprintf('Session info\n-----------------\n')
fprintf('%15s: %s\n','Session name',sessionname)
fprintf('%15s: %s\n','Export date',savedate)
fprintf('%15s: %s\n','Patient name',patientname)
fprintf('%15s: %s\n','Date of birth',dateofbirth)
fprintf('%15s: %s\n','Gender',gender)

function output = trytoget(path)
    try
        output = eval(path);
    catch
        output = 'empty';
    end
end

end



    