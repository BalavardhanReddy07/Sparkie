public with sharing class AF_GetL2DocumentsService {

    public class L2DocumentRequest {
        @AuraEnabled @InvocableVariable(label='Scheme Category' required=true)
        public String schemeCategory;

        @AuraEnabled @InvocableVariable(label='Selected Topic' required=true)
        public String selectedTopic;

        @AuraEnabled @InvocableVariable(label='Agent Session ID' required=false)
        public String agentSessionId;
    }

    public class L2DocumentResult {
        @AuraEnabled @InvocableVariable(label='Has Documents')
        public Boolean hasDocuments;

        @AuraEnabled @InvocableVariable(label='Document Options')
        public List<DocumentOption> documentOptions;
    }

    public class DocumentOption {
        @AuraEnabled @InvocableVariable public String label;
        @AuraEnabled @InvocableVariable public String value;
    }

    @InvocableMethod(label='AF Get L2 Documents' category='L2 Documents')
    public static List<L2DocumentResult> getSelectedDocument(List<L2DocumentRequest> requests) {
        List<L2DocumentResult> results = new List<L2DocumentResult>();

        for (L2DocumentRequest req : requests) {
            L2DocumentResult res = new L2DocumentResult();
            res.documentOptions = new List<DocumentOption>();
            
            Boolean isBrighterLibrary = (req.selectedTopic == 'Brighter Library');

            if (String.isBlank(req.selectedTopic) || (!isBrighterLibrary && String.isBlank(req.schemeCategory))) {
                res.hasDocuments = false;
                results.add(res);
                continue;
            }

            List<Topic_Document_Mapping__c> mappings;
            
            if (isBrighterLibrary) {
                mappings = [SELECT Additional_Document__c, Additional_Document__r.Name, Additional_Document__r.Data_Cloud_File_Path__c FROM Topic_Document_Mapping__c WHERE Topic__c = :req.selectedTopic AND Additional_Document__c != null AND Active__c = true ORDER BY Additional_Document__r.Name ASC LIMIT 200];
            } else {
                mappings = [SELECT Additional_Document__c, Additional_Document__r.Name, Additional_Document__r.Data_Cloud_File_Path__c FROM Topic_Document_Mapping__c WHERE Topic__c = :req.selectedTopic AND Key_Field_Value__c = :req.schemeCategory AND Additional_Document__c != null AND Active__c = true ORDER BY Additional_Document__r.Name ASC LIMIT 200];
            }

            for (Topic_Document_Mapping__c mapping : mappings) {
                DocumentOption opt = new DocumentOption();
                opt.label = mapping.Additional_Document__r.Name;
                opt.value = mapping.Additional_Document__r.Data_Cloud_File_Path__c;
                res.documentOptions.add(opt);
            }

            res.hasDocuments = !res.documentOptions.isEmpty();

            // The Smuggler: Hide the active session ID for the LWC to grab
            if (String.isNotBlank(req.agentSessionId)) {
                DocumentOption sessionOpt = new DocumentOption();
                sessionOpt.label = 'HIDDEN_SESSION_ID';
                sessionOpt.value = req.agentSessionId;
                res.documentOptions.add(sessionOpt);
            }

            results.add(res);
        }

        return results;
    }

    @AuraEnabled
    public static String runL2SearchFlow(String documentFilePath, String sessionId) {
        if (String.isBlank(documentFilePath)) {
            return null;
        }

        try {
            Map<String, Object> flowParams = new Map<String, Object>();
            flowParams.put('document_File_Paths', documentFilePath);
            flowParams.put('SessionId', sessionId);

            Flow.Interview myFlow = Flow.Interview.createInterview('Flow_L2_Documents_Search', flowParams);
            myFlow.start();

            // Returns the exact string from your Flow's Assignment variable
            return (String) myFlow.getVariableValue('Output_Message');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
