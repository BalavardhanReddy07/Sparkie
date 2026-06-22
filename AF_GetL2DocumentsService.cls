/**
 * AF_GetL2DocumentsService
 * --------------------------------------------------------------------------
 * Backs the "AF_GetL2Documents" Agentforce action.
 *
 * Design notes (read this before wiring up Agent Builder):
 *  - This single action does double duty:
 *      1. It is the action the agent calls when the user types "Show L2
 *         Documents". Its complex input (L2DocumentRequest) is rendered by
 *         a custom Editor CLT (the l2DocumentEditor LWC), so the agent
 *         shows a searchable combobox + Submit button right in the chat
 *         instead of asking the user to type a document name.
 *      2. Because schemeCategory / selectedTopic are NOT marked as
 *         "Collect data from user" in Agent Builder, the agent fills them
 *         in automatically from your existing conversation variables
 *         (IsTopicSelected / SelectedSchemeCategory). The editor LWC
 *         receives those pre-filled values and uses them to look up the
 *         matching documents (via the searchDocuments Apex method below)
 *         to populate the combobox.
 *      3. When the user picks a document and clicks Submit, the editor LWC
 *         dispatches a `valuechange` event with the full object (including
 *         selectedDocumentName / selectedFilePath). THAT is what runs this
 *         invocable method.
 *      4. In Agent Builder, map this action's `selectedFilePath` output to
 *         your `dataCloudL2FilePath` conversation variable (Action ->
 *         Output -> Map to Variable). That is what makes the value
 *         available to the "Find L2 Answers" subagent later.
 *
 *  - Data model:
 *      Topic_Document_Mapping__c  (topic + scheme category -> L2 doc lookup)
 *        └─ Additional_Document__c  (Lookup -> Document_Detail__c)
 *      Document_Detail__c  (Name, Data_Cloud_File_Path__c, Document_URL__c)
 *
 *      searchDocuments() queries Topic_Document_Mapping__c filtered by
 *      Topic__c and Key_Field_Value__c, traversing Additional_Document__r
 *      to pull the document name and Data Cloud file path from
 *      Document_Detail__c.
 */
public with sharing class AF_GetL2DocumentsService {

    /**
     * Input wrapper. This is the type the l2DocumentRequest Custom
     * Lightning Type schema.json points to via:
     *   "lightning:type": "@apexClassType/c__AF_GetL2DocumentsService$L2DocumentRequest"
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

        @AuraEnabled
        @InvocableVariable(label='Selected Document Name'
            description='Name of the L2 document the user picked from the combobox.'
            required=false)
        public String selectedDocumentName;

        @AuraEnabled
        @InvocableVariable(label='Selected Document File Path'
            description='File path (or Content/Document Id) of the L2 document the user picked.'
            required=false)
        public String selectedFilePath;
    }

    /** Output wrapper returned to the agent / mapped to conversation variables. */
    public class L2DocumentResult {
        @AuraEnabled
        @InvocableVariable(label='Selected Document Name')
        public String selectedDocumentName;

        @AuraEnabled
        @InvocableVariable(label='Selected Document File Path')
        public String selectedFilePath;

        @AuraEnabled
        @InvocableVariable(label='Confirmation Message')
        public String confirmationMessage;
    }

    /** Lightweight shape returned to the LWC for populating the combobox. Not used by the agent itself. */
    public class DocumentOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    /**
     * The Agent Action entry point. Runs once the editor CLT has collected
     * the user's selection and dispatched valuechange.
     */
    @InvocableMethod(
        label='AF Get L2 Documents'
        description='Captures the L2 document the user selected for the current scheme category and topic, and returns its file path for downstream use.'
        category='L2 Documents'
    )
    public static List<L2DocumentResult> getSelectedDocument(List<L2DocumentRequest> requests) {
        List<L2DocumentResult> results = new List<L2DocumentResult>();

        for (L2DocumentRequest req : requests) {
            L2DocumentResult res = new L2DocumentResult();

            if (String.isBlank(req.selectedFilePath)) {
                res.selectedDocumentName = null;
                res.selectedFilePath = null;
                res.confirmationMessage = 'No document was selected yet.';
            } else {
                res.selectedDocumentName = req.selectedDocumentName;
                res.selectedFilePath = req.selectedFilePath;
                res.confirmationMessage = 'Loaded "' + req.selectedDocumentName + '". Please ask your question.';
            }

            results.add(res);
        }

        return results;
    }

    /**
     * Imperative method called DIRECTLY by the l2DocumentEditor LWC
     * (via @salesforce/apex) to populate the combobox. This never runs
     * through the agent's reasoning loop -- it's plain LWC -> Apex.
     *
     * Data model:
     *   Topic_Document_Mapping__c  (topic + scheme category -> document lookup)
     *     └─ Additional_Document__c  (Lookup -> Document_Detail__c, i.e. the L2 doc)
     *   Document_Detail__c  (Name, Data_Cloud_File_Path__c, Document_URL__c)
     */
    @AuraEnabled(cacheable=false)
    public static List<DocumentOption> searchDocuments(String schemeCategory, String selectedTopic) {
        List<DocumentOption> options = new List<DocumentOption>();

        if (String.isBlank(schemeCategory) || String.isBlank(selectedTopic)) {
            return options;
        }

        for (Topic_Document_Mapping__c mapping : [
            SELECT Additional_Document__c,
                   Additional_Document__r.Name,
                   Additional_Document__r.Data_Cloud_File_Path__c
            FROM Topic_Document_Mapping__c
            WHERE Topic__c = :selectedTopic
              AND Key_Field_Value__c = :schemeCategory
              AND Additional_Document__c != null
              AND Active__c = true
            ORDER BY Additional_Document__r.Name ASC
            LIMIT 200
        ]) {
            DocumentOption opt = new DocumentOption();
            opt.label = mapping.Additional_Document__r.Name;
            opt.value = mapping.Additional_Document__r.Data_Cloud_File_Path__c;
            options.add(opt);
        }

        return options;
    }
}
