public static Response ExecuteSearch(String searchQuery, String preFilterConditions) {
    Response executionResponse = new Response();

    String safeSearchQuery = searchQuery != null ? searchQuery.replace('\'', '\'\'') : searchQuery;

    String sqlQuery =
        'SELECT c.Chunk__c, d.FilePath__c, h.hybrid_score__c, h.keyword_score__c, h.vector_score__c FROM ' +
        'hybrid_search(table(ADL_All_Documents_Custom_index__dlm), \'' + safeSearchQuery + '\',' + preFilterConditions + ', 20) AS h ' +
        'JOIN ADL_All_Documents_Custom_chunk__dlm AS c ON h.SourceRecordId__c = c.RecordId__c ' +
        'JOIN ADL_All_Documents_L__dlm AS d ON c.SourceRecordId__c = d.FilePath__c ' +
        'ORDER BY h.hybrid_score__c DESC';
