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
    }

    /** Output wrapper returned to the agent and rendered by the Output CLT. */
    public class L2DocumentResult {
        @AuraEnabled
        @InvocableVariable(label='Has Documents' description='True if any documents were found.')
        public Boolean hasDocuments;

        @AuraEnabled
        @InvocableVariable(label='Document Options' description='The list of documents found for the category and topic.')
        public List<DocumentOption> documentOptions;
    }

    /** Lightweight shape to pass label/value pairs to the LWC. */
    public class DocumentOption {
        @AuraEnabled @InvocableVariable public String label;
        @AuraEnabled @InvocableVariable public String value;
    }

    /**
     * The Agent Action entry point. The agent passes the scheme category and topic,
     * we query the documents, and return the list to be rendered by the Output CLT.
     *
     * Data model:
     *   Topic_Document_Mapping__c  (topic + scheme category -> document lookup)
     *     └─ Additional_Document__c  (Lookup -> Document_Detail__c, i.e. the L2 doc)
     *   Document_Detail__c  (Name, Data_Cloud_File_Path__c, Document_URL__c)
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
            
            if (String.isBlank(req.schemeCategory) || String.isBlank(req.selectedTopic)) {
                res.hasDocuments = false;
                results.add(res);
                continue;
            }

            for (Topic_Document_Mapping__c mapping : [
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
            ]) {
                DocumentOption opt = new DocumentOption();
                opt.label = mapping.Additional_Document__r.Name;
                opt.value = mapping.Additional_Document__r.Data_Cloud_File_Path__c;
                res.documentOptions.add(opt);
            }

            res.hasDocuments = !res.documentOptions.isEmpty();
            results.add(res);
        }

        return results;
    }
}
