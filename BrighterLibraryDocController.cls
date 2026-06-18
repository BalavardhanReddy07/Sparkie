/**
 * BrighterLibraryDocController
 *
 * Fetches Document_Detail__c records that are linked via Topic_Document_Mapping__c
 * where Topic__c = 'Brighter Library' AND Additional_Document__c != null.
 *
 * Used by the brighterLibraryDocSelector LWC, which is registered as an
 * Agentforce custom input component via the BrighterLibraryDocInput Lightning Type.
 */
public with sharing class BrighterLibraryDocController {

    // ─── Inner DTOs ───────────────────────────────────────────────────────────

    public class DocumentOption {
        @AuraEnabled public String  recordId          { get; set; }
        @AuraEnabled public String  documentName      { get; set; }
        @AuraEnabled public String  dataCloudFilePath { get; set; }
        @AuraEnabled public String  documentUrl       { get; set; }
        @AuraEnabled public Boolean hasWarning        { get; set; }
        @AuraEnabled public String  warningText       { get; set; }
    }

    public class DocumentResponse {
        @AuraEnabled public List<DocumentOption> documents { get; set; }
        @AuraEnabled public String               errorMessage { get; set; }

        public DocumentResponse() {
            this.documents = new List<DocumentOption>();
        }
    }

    // ─── Invocable / AuraEnabled entry point ─────────────────────────────────

    /**
     * Returns all Document_Detail__c records that appear as Additional_Document__c
     * on an active (or open-dated) Topic_Document_Mapping__c row where
     * Topic__c = 'Brighter Library'.
     *
     * Called directly from the LWC via @wire or imperative call.
     */
    @AuraEnabled(cacheable=true)
    public static DocumentResponse getBrighterLibraryDocuments() {

        DocumentResponse response = new DocumentResponse();

        try {
            // ── Step 1: collect qualifying Document_Detail__c Ids via the mapping ──
            Date today = Date.today();

            List<Topic_Document_Mapping__c> mappings = [
                SELECT Additional_Document__c
                FROM   Topic_Document_Mapping__c
                WHERE  Topic__c                = 'Brighter Library'
                AND    Additional_Document__c != null
                AND    Active__c               = true
                AND    (Valid_From__c          = null OR Valid_From__c <= :today)
                AND    (Valid_To__c            = null OR Valid_To__c   >= :today)
                WITH   SECURITY_ENFORCED
            ];

            if (mappings.isEmpty()) {
                return response; // empty list – no matching mappings
            }

            Set<Id> docIds = new Set<Id>();
            for (Topic_Document_Mapping__c m : mappings) {
                docIds.add(m.Additional_Document__c);
            }

            // ── Step 2: fetch the actual Document_Detail__c records ──────────────
            for (Document_Detail__c d : [
                SELECT Id,
                       Name,
                       Data_Cloud_File_Path__c,
                       Document_URL__c,
                       Warning_for_L2_document__c
                FROM   Document_Detail__c
                WHERE  Id IN :docIds
                WITH   SECURITY_ENFORCED
                ORDER  BY Name ASC
            ]) {
                DocumentOption opt = new DocumentOption();
                opt.recordId          = d.Id;
                opt.documentName      = d.Name;
                opt.dataCloudFilePath = d.Data_Cloud_File_Path__c;
                opt.documentUrl       = d.Document_URL__c;
                opt.hasWarning        = String.isNotBlank(d.Warning_for_L2_document__c);
                opt.warningText       = d.Warning_for_L2_document__c;
                response.documents.add(opt);
            }

        } catch (QueryException qe) {
            response.errorMessage = 'Insufficient privileges to read document data.';
            System.debug(LoggingLevel.ERROR,
                'BrighterLibraryDocController.getBrighterLibraryDocuments QueryException: ' + qe.getMessage());
        } catch (Exception e) {
            response.errorMessage = 'An unexpected error occurred: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR,
                'BrighterLibraryDocController.getBrighterLibraryDocuments Exception: ' + e.getMessage());
        }

        return response;
    }
}