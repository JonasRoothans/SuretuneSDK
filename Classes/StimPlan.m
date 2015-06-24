classdef StimPlan
    %STIMPLAN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        vta
        lead
        label
        voltageBasedStimulation
        stimulationValue
        pulseWidth
        pulseFrequency
        activeRings
        contactsGrounded
        annotation
        
    end
    
    methods
        function obj = StimPlan(VTA,Lead,label,voltageBasedStimulation,stimulationValue,pulseWidth,pulseFrequency,activeRings,contactsGrounded,annotation)
            obj.vta = VTA;
            obj.lead = Lead;
            obj.label = label;
            obj.voltageBasedStimulation = voltageBasedStimulation;
            obj.stimulationValue = stimulationValue;
            obj.pulseWidth = pulseWidth;
            obj.pulseFrequency = pulseFrequency;
            obj.activeRings = activeRings;
            obj.contactsGrounded = contactsGrounded;
            obj.annotation = annotation;
        end
        
    end
    
end

