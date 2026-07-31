public with sharing class AF_ADLHybridSearchService {

    private static final String ADL_SEARCH_PROMPT_TEMPLATE_API_NAME = 'AF_ADL_KA_Search_Template';
	private static final String GET_JSON_FILEPATHS_FLOW_API_NAME = 'AF_Get_ADL_JSON_File_Paths';

    public class Request {
		
		@InvocableVariable(required=false)
        public String employerName;
		
		@InvocableVariable(required=false)
		public String searchQuery;
		
		@InvocableVariable(required=false)
		public Boolean isEmployerSelected;

		@InvocableVariable(required=false)
		public Boolean isExistingMember;

		@InvocableVariable(required=false)
		public Boolean isInsuranceSelected;

		@InvocableVariable(required=false)
		public Boolean isProductSelected;

		@InvocableVariable(required=false)
		public String schemeCategory;

    }

    public class Response {
        @InvocableVariable(description='Resolved prompt passed to Agentforce reasoning engine')
        public String Data;

        // @InvocableVariable(description='Citation sources for inline references')
        // public AiCopilot.GenAiCitationInput sources;
    }

	public static String GetJsonFilePaths(List<Request> requests){
		Map<String, Object> flowInputs = new Map<String, Object>{
			'EmployerName' => requests[0].employerName,
			'IsEmployerSelected' => requests[0].isEmployerSelected,
			'IsExistingMember' => requests[0].isExistingMember,
			'IsInsuranceSelected' => requests[0].isInsuranceSelected,
			'IsProductSelected' => requests[0].isProductSelected,
			'SchemeCategory' => requests[0].schemeCategory

		};
		Flow.Interview flowInterview = Flow.Interview.createInterview(GET_JSON_FILEPATHS_FLOW_API_NAME, flowInputs);
		flowInterview.start();
		system.debug('flowInterview.getVariableValue(DCFilePaths)'+ flowInterview.getVariableValue('DCFilePaths'));
		return JSON.serialize(flowInterview.getVariableValue('DCFilePaths'));
	}

    @InvocableMethod(label='Agentforce Data Library Search Service')
    public static List<Response> SearchRetriever(List<Request> requests) {
		List<String> paths = (List<String>) JSON.deserialize(GetJsonFilePaths(requests), List<String>.class);
        System.debug('paths: ' + paths);
        String preFilterConditions = buildFilePathFilter(paths);
        System.debug('preFilterConditions: ' + preFilterConditions);
        List<Response> responses = new List<Response>();
        responses.add(ExecuteSearch(requests[0].searchQuery, preFilterConditions));
        return responses;
    }

    public static Response ExecuteSearch(String searchQuery, String preFilterConditions) {
        Response executionResponse = new Response();

        String sqlQuery =
            'SELECT c.Chunk__c, d.FilePath__c, h.hybrid_score__c, h.keyword_score__c, h.vector_score__c FROM ' +
            'hybrid_search(table(ADL_All_Documents_Custom_index__dlm), \'' + searchQuery + '\',' + preFilterConditions + ', 20) AS h ' +
            'JOIN ADL_All_Documents_Custom_chunk__dlm AS c ON h.SourceRecordId__c = c.RecordId__c ' +
            'JOIN ADL_All_Documents_L__dlm AS d ON c.SourceRecordId__c = d.FilePath__c ' +
            'ORDER BY h.hybrid_score__c DESC';

        ConnectApi.CdpQueryInput cdpInput = new ConnectApi.CdpQueryInput();
        cdpInput.sql = sqlQuery;
        ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(cdpInput);

        Set<String> filePathSet    = new Set<String>();
        List<List<Object>> rawRows = new List<List<Object>>();

        if (output.data != null && !output.data.isEmpty()) {
            for (ConnectApi.CdpQueryV2Row rowObj : output.data) {
                List<Object> row = rowObj.rowData;
                rawRows.add(row);
                if (row[1] != null) filePathSet.add((String) row[1]);
            }
        }

        // Id added so sourceObjectRecordId shows the document Name in Agentforce citations
        Map<String, Document_Detail__c> filePathToDocMap = new Map<String, Document_Detail__c>();
        if (!filePathSet.isEmpty()) {
            for (Document_Detail__c doc : [
                SELECT Id, Name, Document_URL__c, Data_Cloud_File_Path__c
                FROM Document_Detail__c
                WHERE Data_Cloud_File_Path__c IN :filePathSet
            ]) {
                filePathToDocMap.put(doc.Data_Cloud_File_Path__c, doc);
            }
        }

        Map<String, List<String>> filePathToChunks = new Map<String, List<String>>();
        List<String> orderedFilePaths = new List<String>();
        String formattedContext = '';

        // Build context as JSON array - one entry per chunk
        List<Map<String, Object>> contextList = new List<Map<String, Object>>();

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
            contextList.add(new Map<String, Object>{
                'Name'    => doc != null ? doc.Name : filePath,
                'URL'     => doc != null ? doc.Document_URL__c : '',
                'Content' => chunk
            });
        }

        formattedContext = JSON.serialize(contextList);

        // One source reference per document, ALL its chunks as contents
        List<AiCopilot.GenAiSourceReference> sourceRefs = new List<AiCopilot.GenAiSourceReference>();

        for (String filePath : orderedFilePaths) {
            Document_Detail__c doc = filePathToDocMap.get(filePath);
            String docUrl   = doc != null ? doc.Document_URL__c : null;
            String docLabel = doc != null ? doc.Name : filePath;

            List<AiCopilot.GenAiSourceContentInfo> contents = new List<AiCopilot.GenAiSourceContentInfo>();
            for (String chunk : filePathToChunks.get(filePath)) {
                contents.add(new AiCopilot.GenAiSourceContentInfo(null, 'ADL_All_Documents_L__dlm', chunk));
            }

            List<AiCopilot.GenAiSourceReferenceInfo> metadata =
                new List<AiCopilot.GenAiSourceReferenceInfo>{
                    new AiCopilot.GenAiSourceReferenceInfo(docUrl, null, 'ADL_All_Documents_L__dlm', docLabel)
                };

            sourceRefs.add(new AiCopilot.GenAiSourceReference(null, contents, metadata));
        }

        // Agentforce reasoning engine generates a response from this, citation engine adds [1][2] markers
        String resolvedPrompt = invokePromptTemplate(searchQuery, formattedContext);

        executionResponse.Data    = resolvedPrompt;
        // executionResponse.sources = new AiCopilot.GenAiCitationInput(resolvedPrompt, sourceRefs);

        return executionResponse;
    }

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
        promptInput.isPreview                        = false;
        promptInput.additionalConfig                 = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        promptInput.additionalConfig.numGenerations  = 1;
        promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        System.debug('################ '+promptInput);
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation result =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                ADL_SEARCH_PROMPT_TEMPLATE_API_NAME,
                promptInput
            );
        System.debug('################ '+result.prompt);
        return result.prompt;

    }

    public static String buildFilePathFilter(List<String> filePaths) {
        if (filePaths == null || filePaths.isEmpty()) return '\'1=1\'';
        List<String> escaped = new List<String>();
        for (String fp : filePaths) {
            escaped.add('\'\'' + fp.replace('\'', '\'\'') + '\'\'');
        }
        return '\'' + 'FilePath__c IN (' + String.join(escaped, ', ') + ')' + '\'';
    }
}



This is my Agent Action Code , 
When I am asking this Questions to Agent it is giving the response well "Members SFH application has not been processed what can I do?
"

When I ask the same Question like this 
"Members SFH application hasn't been processed what can I do?
"

It is throwing this Error Execution Error: [{"statusCode":"UNKNOWN_EXCEPTION","message":"An Apex error occurred: ConnectApi.ConnectApiException: {"timestamp":"2026-07-31T04:55:04.658Z","error":"400 BAD_REQUEST","message":"mismatched input 't'. Expecting: ')', ',', 'COPARTITION'","path":"uri=/query/v2/queries","tenantId":"a360/prod4/12741320f6514fc4899683ece2eff7f2","internalErrorCode":"COMMON_ERROR_GENERIC","details":{}}","fields":null}]


What's the issue

