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
 * 5. NEW: To support dynamic Flow interactions, the active Session ID is 
 * captured from Agent Builder via `agentSessionId`, passed to the LWC, 
 * and then injected into the Flow's Send Session Message action.
 *
 * - Data model:
 * Topic_Document_Mapping__c  (topic + scheme category -> L2 doc lookup)
 * └─ Additional_Document__c  (Lookup -> Document_Detail__c)
 * Document_Detail__c  (Name, Data_Cloud_File_Path__c, Document_URL__c)
 *
 * searchDocuments() queries Topic_Document_Mapping__c filtered by
 * Topic__c and Key_Field_Value__c, traversing Additional_Document__r
 * to pull the document name and Data Cloud file path from
 * Document_Detail__c.
 */
public with sharing class AF_GetL2DocumentsService {

    /**
     * Input wrapper. This is the type the l2DocumentRequest Custom
     * Lightning Type schema.json points to via:
     * "lightning:type": "@apexClassType/c__AF_GetL2DocumentsService$L2DocumentRequest"
     */
    public class L2DocumentRequest {
        @AuraEnabled
        @InvocableVariable(label='Scheme Category'
            description='The scheme category already captured earlier in the conversation.'
            required=true)
        public String schemeCategory;

        @AuraEnabled
        @InvocableVariable(label='Selected Topic'
            description='The L1 topic already captured earlier in the conversation.'
            required=true)
        public String selectedTopic;

        // 1. New input to capture the session ID from Agent Builder
        @AuraEnabled
        @InvocableVariable(label='Agent Session ID' 
            description='The active V6 Session ID from Agent Builder used to map messages back to the chat.' 
            required=false)
        public String agentSessionId;
    }

    /** Output wrapper returned to the agent and rendered by the Output CLT. */
    public class L2DocumentResult {
        @AuraEnabled
        @InvocableVariable(label='Has Documents' description='True if any documents were found.')
        public Boolean hasDocuments;

        @AuraEnabled
        @InvocableVariable(label='Document Options' description='The list of documents found for the category and topic.')
        public List<DocumentOption> documentOptions;

        // 2. New output to pass the session ID to the LWC
        @AuraEnabled
        @InvocableVariable(label='Agent Session ID' description='Passes the active Session ID to the LWC context.')
        public String agentSessionId;
    }

    /** Lightweight shape to pass label/value pairs to the LWC. */
    public class DocumentOption {
        @AuraEnabled @InvocableVariable public String label;
        @AuraEnabled @InvocableVariable public String value;
        @AuraEnabled @InvocableVariable public String warningMessage;
    }

    /**
     * The Agent Action entry point. The agent passes the scheme category and topic,
     * we query the documents, and return the list to be rendered by the Output CLT.
     *
     * Data model:
     * Topic_Document_Mapping__c  (topic + scheme category -> document lookup)
     * └─ Additional_Document__c  (Lookup -> Document_Detail__c, i.e. the L2 doc)
     * Document_Detail__c  (Name, Data_Cloud_File_Path__c, Document_URL__c)
     */
    @InvocableMethod(
        label='AF Get L2 Documents'
        description='Fetches the available L2 documents for the current scheme category and topic, to be displayed for selection.'
        category='L2 Documents'
    )
    public static List<L2DocumentResult> getSelectedDocument(List<L2DocumentRequest> requests) {
        List<L2DocumentResult> results = new List<L2DocumentResult>();

        for (L2DocumentRequest req : requests) {
            L2DocumentResult res = new L2DocumentResult();
            res.documentOptions = new List<DocumentOption>();
            
            // 3. Pass the session ID from the request down to the result so the LWC can access it
            res.agentSessionId = req.agentSessionId;
            
            // If the topic is Brighter Library, we don't need a scheme category
            Boolean isBrighterLibrary = (req.selectedTopic == 'Brighter Library');

            if (String.isBlank(req.selectedTopic) || (!isBrighterLibrary && String.isBlank(req.schemeCategory))) {
                res.hasDocuments = false;
                results.add(res);
                continue;
            }

            List<Topic_Document_Mapping__c> mappings;
            
            if (isBrighterLibrary) {
                // Ignore Key_Field_Value__c for Brighter Library
                mappings = [
                    SELECT Additional_Document__c,
                           Additional_Document__r.Name,
                           Additional_Document__r.Data_Cloud_File_Path__c,
                           Additional_Document__r.Warning_for_L2_document__c
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
                           Additional_Document__r.Data_Cloud_File_Path__c,
                           Additional_Document__r.Warning_for_L2_document__c
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
                opt.warningMessage = mapping.Additional_Document__r.Warning_for_L2_document__c;
                res.documentOptions.add(opt);
            }

            res.hasDocuments = !res.documentOptions.isEmpty();
            results.add(res);
        }

        return results;
    }

    /**
     * Imperative method called directly by the l2DocumentEditor LWC upon Submit.
     * Invokes the Flow_L2_Documents_Search flow and returns the Output_Message.
     * Now accepts the active sessionId to dynamically route the Send Message action.
     */
    @AuraEnabled
    public static String runL2SearchFlow(String documentFilePath, String sessionId) {
        if (String.isBlank(documentFilePath)) {
            return null;
        }

        try {
            // Set the input variables for the flow
            Map<String, Object> flowParams = new Map<String, Object>();
            flowParams.put('document_File_Paths', documentFilePath);
            
            // 4. Pass the dynamic session ID into the Flow's input variable
            flowParams.put('SessionId', sessionId);

            // Create and start the flow interview
            Flow.Interview myFlow = Flow.Interview.createInterview('Flow_L2_Documents_Search', flowParams);
            myFlow.start();

            // Retrieve the output variable
            String outputMessage = (String) myFlow.getVariableValue('Output_Message');
            return outputMessage;
            
        } catch (Exception e) {
            System.debug('Error invoking flow: ' + e.getMessage());
            throw new AuraHandledException('Error executing the search flow: ' + e.getMessage());
        }
    }
}
