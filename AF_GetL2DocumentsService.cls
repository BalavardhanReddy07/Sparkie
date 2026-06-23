/**
 * AF_GetL2DocumentsService
 * --------------------------------------------------------------------------
 * Backs the "AF_GetL2Documents" Agentforce action.
 *
 * Design notes (read this before wiring up Agent Builder):
 * - This single action does double duty:
 * 1. It is the action the agent calls when the user types "Show L2
 * Documents". Its complex input (L2DocumentRequest) is rendered by
 * a custom Editor CLT (the l2DocumentEditor LWC), so the agent
 * shows a searchable combobox + Submit button right in the chat
 * instead of asking the user to type a document name.
 * 2. Because schemeCategory / selectedTopic are NOT marked as
 * "Collect data from user" in Agent Builder, the agent fills them
 * in automatically from your existing conversation variables
 * (IsTopicSelected / SelectedSchemeCategory). The editor LWC
 * receives those pre-filled values and uses them to look up the
 * matching documents (via the searchDocuments Apex method below)
 * to populate the combobox.
 * 3. When the user picks a document and clicks Submit, the editor LWC
 * dispatches a `valuechange` event with the full object (including
 * selectedDocumentName / selectedFilePath). THAT is what runs this
 * invocable method.
 * 4. In Agent Builder, map this action's `selectedFilePath` output to
 * your `dataCloudL2FilePath` conversation variable (Action ->
 * Output -> Map to Variable). That is what makes the value
 * available to the "Find L2 Answers" subagent later.
 * 5. NEW [SMUGGLER APPROACH]: To support dynamic Flow interactions without
 * breaking the CLT schema, the `agentSessionId` is captured from the input, 
 * injected into the `documentOptions` array as a hidden option, and 
 * extracted by the LWC before rendering.
 *
 * - Data model:
 * Topic_Document_Mapping__c  (topic + scheme category -> L2 doc lookup)
 * └─ Additional_Document__c  (Lookup -> Document_Detail__c)
 * Document_Detail__c  (Name, Data_Cloud_File_Path__c, Document_URL__c)
 */
public with sharing class AF_GetL2DocumentsService {

    /** Input wrapper. */
    public class L2DocumentRequest {
        @AuraEnabled
        @InvocableVariable(label='Scheme Category' required=true)
        public String schemeCategory;

        @AuraEnabled
        @InvocableVariable(label='Selected Topic' required=true)
        public String selectedTopic;

        // Captured from Agent Builder/AgentScript to pass the active UUID
        @AuraEnabled
        @InvocableVariable(label='Agent Session ID' required=false)
        public String agentSessionId;
    }

    /** Output wrapper */
    public class L2DocumentResult {
        @AuraEnabled
        @InvocableVariable(label='Has Documents' description='True if any documents were found.')
        public Boolean hasDocuments;

        @AuraEnabled
        @InvocableVariable(label='Document Options' description='The list of documents found for the category and topic.')
        public List<DocumentOption> documentOptions;

        // --- NEW: Schema bridges for the LWC Return Payload ---
        @AuraEnabled
        @InvocableVariable(label='Selected File Path' description='Populated by the LWC on Submit')
        public String selectedFilePath;

        @AuraEnabled
        @InvocableVariable(label='Selected Document Name' description='Populated by the LWC on Submit')
        public String selectedDocumentName;
    }

    public class DocumentOption {
        @AuraEnabled @InvocableVariable public String label;
        @AuraEnabled @InvocableVariable public String value;
    }

    @InvocableMethod(
        label='AF Get L2 Documents'
        description='Fetches the available L2 documents for the current scheme category and topic.'
        category='L2 Documents'
    )
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
                mappings = [
                    SELECT Additional_Document__c,
                           Additional_Document__r.Name,
                           Additional_Document__r.Data_Cloud_File_Path__c
                    FROM Topic_Document_Mapping__c
                    WHERE Topic__c = :req.selectedTopic
                      AND Additional_Document__c != null
                      AND Active__c = true
                    ORDER BY Additional_Document__r.Name ASC
                    LIMIT 200
                ];
            } else {
                mappings = [
                    SELECT Additional_Document__c,
                           Additional_Document__r.Name,
                           Additional_Document__r.Data_Cloud_File_Path__c
                    FROM Topic_Document_Mapping__c
                    WHERE Topic__c = :req.selectedTopic
                      AND Key_Field_Value__c = :req.schemeCategory
                      AND Additional_Document__c != null
                      AND Active__c = true
                    ORDER BY Additional_Document__r.Name ASC
                    LIMIT 200
                ];
            }

            for (Topic_Document_Mapping__c mapping : mappings) {
                DocumentOption opt = new DocumentOption();
                opt.label = mapping.Additional_Document__r.Name;
                opt.value = mapping.Additional_Document__r.Data_Cloud_File_Path__c;
                res.documentOptions.add(opt);
            }

            // Set true ONLY if we have actual documents (ignore the smuggled session ID below)
            res.hasDocuments = !res.documentOptions.isEmpty();

            // --- THE SMUGGLER LOGIC ---
            // Hide the active session ID in the options array so the LWC can intercept it
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

    /** Imperative method to trigger the Flow manually. */
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

            String outputMessage = (String) myFlow.getVariableValue('Output_Message');
            return outputMessage;
            
        } catch (Exception e) {
            System.debug('Error invoking flow: ' + e.getMessage());
            throw new AuraHandledException('Error executing the search flow: ' + e.getMessage());
        }
    }
}
