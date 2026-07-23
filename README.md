SELECT 

  GenAIGatewayRequest__dlm.prompt__c,

  GenAIGeneration__dlm.responseText__c,

  GenAIFeedback__dlm.action__c,

  GenAIFeedback__dlm.feedbackId__c,

  GenAIFeedbackDetail__dlm.feedbackText__c,

  ssot__AiAgentInteractionMessage__dlm.ssot__AiAgentInteractionMessageType__c,

  ssot__AiAgentInteractionMessage__dlm.ssot__ContentText__c
 
FROM

  GenAIGatewayRequest__dlm,

  GenAIGatewayResponse__dlm,

  GenAIGeneration__dlm, 

  GenAIFeedback__dlm,

  GenAIFeedbackDetail__dlm,

  ssot__AiAgentInteractionMessage__dlm

WHERE 

  GenAIGeneration__dlm.generationResponseId__c = GenAIGatewayResponse__dlm.generationResponseId__c

  AND GenAIGatewayResponse__dlm.generationRequestId__c = GenAIGatewayRequest__dlm.gatewayRequestId__c

  AND GenAIGatewayRequest__dlm.generationGroupId__c = GenAIFeedback__dlm.generationGroupId__c 

  AND GenAIFeedback__dlm.feedbackId__c = GenAIFeedbackDetail__dlm.parent__c
 
