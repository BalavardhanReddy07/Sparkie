public with sharing class AF_UnifiedSearchService {

    private static final String PROMPT_TEMPLATE_API_NAME        = 'AF_ADL_KA_Search_Template';
    private static final String GET_SEARCH_PARAMS_FLOW_API_NAME = 'AF_Get_ADL_KA_Search_Parameters';

    // ===== INPUT =====
    public class Request {
        @InvocableVariable(required=true)
        public String searchQuery;

        @InvocableVariable(required=false)
        public String employerName;

        @InvocableVariable(required=false)
        public Boolean isExistingMember;

        @InvocableVariable(required=false)
        public Boolean isInsuranceSelected;

        @InvocableVariable(required=false)
        public Boolean isProductSelected;

        @InvocableVariable(required=false)
        public String schemeCategory;

        @InvocableVariable(required=false)
        public String selectedL2DocumentFilePath;
    }

    // ===== OUTPUT =====
    public class Response {
        @InvocableVariable(description='LLM response with inline citations')
        public String Data;

        @InvocableVariable(description='Citation sources for inline references')
        public AiCopilot.GenAiCitationInput sources;
    }

    // Holds DCFilePaths and KADataCategories returned from the unified flow
    @TestVisible
    private class SearchParameters {
        @TestVisible List<String> dcFilePaths;
        @TestVisible List<String> kaDataCategories;
    }

    // Test-only override. @TestVisible members cannot be set from non-test code, so this is
    // always null at runtime and getSearchParameters behaves exactly as before in UAT and Production.
    @TestVisible
    private static SearchParameters testSearchParameters;

    // Holds context and source references produced by each search
    private class SearchResults {
        List<Map<String, Object>>            contextList = new List<Map<String, Object>>();
        List<AiCopilot.GenAiSourceReference> sourceRefs  = new List<AiCopilot.GenAiSourceReference>();
    }

    @InvocableMethod(label='AF Unified ADL and KA Hybrid Search Service')
    public static List<Response> SearchRetriever(List<Request> requests) {
        Request req = requests[0];
        // Step 1: Call unified flow to get both ADL file paths and KA data categories
        SearchParameters params = getSearchParameters(req);

        Boolean hasADL = params.dcFilePaths     != null && !params.dcFilePaths.isEmpty();
        Boolean hasKA  = params.kaDataCategories != null && !params.kaDataCategories.isEmpty();

        if (!hasADL && !hasKA) {
            return new List<Response>{ new Response() };
        }

        // Step 2: Run applicable searches based on what the flow returned
        List<Map<String, Object>>            combinedContext    = new List<Map<String, Object>>();
        List<AiCopilot.GenAiSourceReference> combinedSourceRefs = new List<AiCopilot.GenAiSourceReference>();

        if (hasADL) {
            SearchResults adlResults = runADLSearch(req.searchQuery, params.dcFilePaths);
            combinedContext.addAll(adlResults.contextList);
            combinedSourceRefs.addAll(adlResults.sourceRefs);
        }

        if (hasKA) {
            SearchResults kaResults = runKASearch(req.searchQuery, params.kaDataCategories);
            combinedContext.addAll(kaResults.contextList);
            combinedSourceRefs.addAll(kaResults.sourceRefs);
        }

        // Step 3: Single PT call with all combined context
        String llmResponse = invokePromptTemplate(req.searchQuery, JSON.serialize(combinedContext));

        Response response = new Response();
        response.Data     = llmResponse;
        response.sources  = new AiCopilot.GenAiCitationInput(null, combinedSourceRefs);

        system.debug('output>>>'  + response);
        return new List<Response>{ response };
    }

    // ── Unified Flow ──────────────────────────────────────────────────────────

    private static SearchParameters getSearchParameters(Request req) {
        if (testSearchParameters != null) { return testSearchParameters; }

        if (req.selectedL2DocumentFilePath != null && !String.isEmpty(req.selectedL2DocumentFilePath)){
            SearchParameters params = new SearchParameters();
            params.dcFilePaths = new List<String> { req.selectedL2DocumentFilePath };
            System.debug('DCFilePaths: '      + params.dcFilePaths);
            return params;
        }
        else {
            Map<String, Object> flowInputs = new Map<String, Object>{
                'EmployerName'        => req.employerName,
                'IsExistingMember'    => req.isExistingMember,
                'IsInsuranceSelected' => req.isInsuranceSelected,
                'IsProductSelected'   => req.isProductSelected,
                'SchemeCategory'      => req.schemeCategory
            };

            Flow.Interview flowInterview = Flow.Interview.createInterview(GET_SEARCH_PARAMS_FLOW_API_NAME, flowInputs);
            flowInterview.start();

            SearchParameters params = new SearchParameters();

            params.dcFilePaths = (List<String>) JSON.deserialize(
                JSON.serialize(flowInterview.getVariableValue('DCFilePaths')), List<String>.class
            );
            params.kaDataCategories = (List<String>) JSON.deserialize(
                JSON.serialize(flowInterview.getVariableValue('KADataCategories')), List<String>.class
            );

            System.debug('DCFilePaths: '      + params.dcFilePaths);
            System.debug('KADataCategories: ' + params.kaDataCategories);

            return params;
        }
    }

    // ── ADL Search ────────────────────────────────────────────────────────────

    private static SearchResults runADLSearch(String searchQuery, List<String> filePaths) {
        SearchResults results = new SearchResults();
        String preFilterConditions = buildFilePathFilter(filePaths);
        String safeSearchQuery = searchQuery != null ? searchQuery.replace('\'', '\'\'') : searchQuery;

        // Row layout: [0] Chunk  [1] FilePath  [2] hybrid_score  [3] keyword_score  [4] vector_score
        String sqlQuery =
            'SELECT c.Chunk__c, d.FilePath__c, h.hybrid_score__c, h.keyword_score__c, h.vector_score__c FROM ' +
            'hybrid_search(table(ADL_All_Documents_Custom_index__dlm), \'' + safeSearchQuery + '\',' + preFilterConditions + ', 20) AS h ' +
            'JOIN ADL_All_Documents_Custom_chunk__dlm AS c ON h.SourceRecordId__c = c.RecordId__c ' +
            'JOIN ADL_All_Documents_L__dlm AS d ON c.SourceRecordId__c = d.FilePath__c ' +
            'ORDER BY h.hybrid_score__c DESC';

        ConnectApi.CdpQueryInput cdpInput = new ConnectApi.CdpQueryInput();
        cdpInput.sql = sqlQuery;
        ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(cdpInput);

        Set<String>        filePathSet = new Set<String>();
        List<List<Object>> rawRows     = new List<List<Object>>();

        if (output.data != null && !output.data.isEmpty()) {
            for (ConnectApi.CdpQueryV2Row rowObj : output.data) {
                List<Object> row = rowObj.rowData;
                rawRows.add(row);
                if (row[1] != null) filePathSet.add((String) row[1]);
            }
        }

        Map<String, Document_Detail__c> filePathToDocMap = new Map<String, Document_Detail__c>();
        if (!filePathSet.isEmpty()) {
            for (Document_Detail__c doc : [
                SELECT Name, Document_URL__c, Data_Cloud_File_Path__c
                FROM Document_Detail__c
                WHERE Data_Cloud_File_Path__c IN :filePathSet
            ]) {
                filePathToDocMap.put(doc.Data_Cloud_File_Path__c, doc);
            }
        }

        Map<String, List<String>> filePathToChunks = new Map<String, List<String>>();
        List<String>              orderedFilePaths  = new List<String>();

        for (List<Object> row : rawRows) {
            String chunk    = (String) row[0];
            String filePath = (String) row[1];
            if (filePath == null) continue;

            if (!filePathToChunks.containsKey(filePath)) {
                filePathToChunks.put(filePath, new List<String>());
                orderedFilePaths.add(filePath);
            }
            filePathToChunks.get(filePath).add(chunk);

            Document_Detail__c doc = filePathToDocMap.get(filePath);
            results.contextList.add(new Map<String, Object>{
                'Name'    => doc != null ? doc.Name : filePath,
                'URL'     => doc != null ? doc.Document_URL__c : '',
                'Content' => chunk
            });
        }

        for (String filePath : orderedFilePaths) {
            Document_Detail__c doc    = filePathToDocMap.get(filePath);
            String             docUrl = doc != null ? doc.Document_URL__c : null;
            String             label  = doc != null ? doc.Name : filePath;

            List<AiCopilot.GenAiSourceContentInfo> contents = new List<AiCopilot.GenAiSourceContentInfo>();
            for (String chunk : filePathToChunks.get(filePath)) {
                contents.add(new AiCopilot.GenAiSourceContentInfo(null, 'ADL_All_Documents_L__dlm', chunk));
            }

            results.sourceRefs.add(new AiCopilot.GenAiSourceReference(
                null, contents,
                new List<AiCopilot.GenAiSourceReferenceInfo>{
                    new AiCopilot.GenAiSourceReferenceInfo(docUrl, null, 'ADL_All_Documents_L__dlm', label)
                }
            ));
        }

        return results;
    }

    // ── KA Search ─────────────────────────────────────────────────────────────

    private static SearchResults runKASearch(String searchQuery, List<String> dataCategoryIds) {
        SearchResults results = new SearchResults();
        String safeSearchQuery = searchQuery != null ? searchQuery.replace('\'', '\'\'') : searchQuery;

        List<String> quoteIds = new List<String>();
        for (String id : dataCategoryIds) {
            quoteIds.add('\'' + String.escapeSingleQuotes(id) + '\'');
        }
        String dataCategoryIdsLiteral = String.join(quoteIds, ', ');

        // Row layout: [0] hybrid_score  [1] ssot__Name__c  [2] Chunk  [3] ssot__Id__c
        String sqlQuery =
            'SELECT v.hybrid_score__c AS Score, kav.ssot__Name__c, c.Chunk__c AS Chunk, kav.ssot__Id__c, v.keyword_score__c, v.vector_score__c, c.SourceRecordId__c AS SourceRecordId, c.RecordId__c AS RecordId, c.DataSource__c AS DataSource, c.DataSourceObject__c AS DataSourceObject FROM ' +
            'hybrid_search(TABLE(KA_Knowledge_Article_Data_Lib_index__dlm), \'' + safeSearchQuery + '\', \'\', 20) AS v ' +
            'INNER JOIN KA_Knowledge_Article_Data_Lib_chunk__dlm AS c ON c.RecordId__c = v.RecordId__c ' +
            'INNER JOIN ssot__KnowledgeArticleVersion__dlm AS kav ON c.SourceRecordId__c = kav.ssot__Id__c ' +
            'AND kav.ssot__KnowledgePublicationStatus__c = \'Online\' ' +
            'AND c.SourceRecordId__c IN (SELECT DISTINCT kds.ParentId__c FROM DataCategorySelectionCustom__dlm AS kds WHERE kds.DataCategoryId__c IN (' + dataCategoryIdsLiteral + ')) ' +
            'ORDER BY Score DESC LIMIT 20';

        ConnectApi.CdpQueryInput cdpInput = new ConnectApi.CdpQueryInput();
        cdpInput.sql = sqlQuery;
        ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(cdpInput);

        List<List<Object>> rawRows = new List<List<Object>>();
        if (output.data != null && !output.data.isEmpty()) {
            for (ConnectApi.CdpQueryV2Row rowObj : output.data) {
                rawRows.add(rowObj.rowData);
            }
        }

        Map<String, List<String>> articleIdToChunks = new Map<String, List<String>>();
        Map<String, String>       articleIdToNameMap = new Map<String, String>();
        List<String>              orderedArticleIds  = new List<String>();

        for (List<Object> row : rawRows) {
            String chunk       = (String) row[2];
            String articleId   = (String) row[3];
            String articleName = (String) row[1];
            if (articleId == null) continue;

            articleIdToNameMap.put(articleId, articleName);

            if (!articleIdToChunks.containsKey(articleId)) {
                articleIdToChunks.put(articleId, new List<String>());
                orderedArticleIds.add(articleId);
            }
            articleIdToChunks.get(articleId).add(chunk);

            results.contextList.add(new Map<String, Object>{
                'Name'    => articleName,
                'URL'     => System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Knowledge__kav/' + articleId + '/view',
                'Content' => chunk
            });
        }

        for (String articleId : orderedArticleIds) {
            String articleUrl   = System.Url.getOrgDomainUrl().toExternalForm() + '/lightning/r/Knowledge__kav/' + articleId + '/view';
            String articleLabel = articleIdToNameMap.get(articleId);

            List<AiCopilot.GenAiSourceContentInfo> contents = new List<AiCopilot.GenAiSourceContentInfo>();
            for (String chunk : articleIdToChunks.get(articleId)) {
                contents.add(new AiCopilot.GenAiSourceContentInfo(null, 'ssot__KnowledgeArticleVersion__dlm', chunk));
            }

            results.sourceRefs.add(new AiCopilot.GenAiSourceReference(
                null, contents,
                new List<AiCopilot.GenAiSourceReferenceInfo>{
                    new AiCopilot.GenAiSourceReferenceInfo(articleUrl, null, 'ssot__KnowledgeArticleVersion__dlm', articleLabel)
                }
            ));
        }

        return results;
    }

    // ── Shared: Prompt Template ───────────────────────────────────────────────

    private static String invokePromptTemplate(String searchQuery, String formattedContext) {
        ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
            new ConnectApi.EinsteinPromptTemplateGenerationsInput();

        Map<String, ConnectApi.WrappedValue> params = new Map<String, ConnectApi.WrappedValue>();

        ConnectApi.WrappedValue qVal = new ConnectApi.WrappedValue();
        qVal.value = searchQuery;
        params.put('Input:Question', qVal);

        ConnectApi.WrappedValue cVal = new ConnectApi.WrappedValue();
        cVal.value = formattedContext;
        params.put('Input:Context', cVal);

        promptInput.inputParams                      = params;
        promptInput.isPreview                        = true;
        promptInput.additionalConfig                 = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptInput.additionalConfig.numGenerations  = 1;
        promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                PROMPT_TEMPLATE_API_NAME, promptInput
            );
        return result.prompt;
    }

    // ── Shared: ADL File Path Filter ─────────────────────────────────────────

    private static String buildFilePathFilter(List<String> filePaths) {
        if (filePaths == null || filePaths.isEmpty()) return '\'1=1\'';
        List<String> escaped = new List<String>();
        for (String fp : filePaths) {
            escaped.add('\'\'' + fp.replace('\'', '\'\'') + '\'\'');
        }
        return '\'' + 'FilePath__c IN (' + String.join(escaped, ', ') + ')' + '\'';
    }
}
