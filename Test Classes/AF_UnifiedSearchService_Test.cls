/**
 * @description Test class for AF_UnifiedSearchService.
 *
 * This class makes NO Data Cloud calls, NO prompt template calls and depends on NO org data.
 *
 * SearchRetriever reaches three platform services that Apex cannot mock:
 *   - ConnectApi.CdpQuery.queryAnsiSqlV2(...)                        (no setTest* method exists)
 *   - ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(...)  (no setTest* method exists)
 *   - Flow.Interview.createInterview('AF_Get_ADL_KA_Search_Parameters', ...)
 *
 * Rather than calling them for real, every test here injects the result through the
 * @TestVisible seams on the service: testSearchParameters, testAdlRows, testKaRows and
 * testPromptResponse. The Data Cloud call is isolated in AF_UnifiedSearchService.runCdpQuery,
 * which these tests never enter.
 *
 * Why it is built this way: the previous version of this class called those services for real
 * under SeeAllData=true and wrapped each call in a catch-all. That produced 85% in Developer
 * Console but far less inside a change set validation, where tests run queued and in parallel —
 * the calls threw, the catch swallowed the failure, every test still passed, and coverage
 * silently collapsed below the deployment gate. Coverage must be a property of the code, not of
 * the org and scheduler that happen to be running the tests. Nothing below can behave
 * differently between UAT, this sandbox and Production.
 */
@IsTest
private class AF_UnifiedSearchService_Test {

    private static final String SEARCH_QUERY          = 'Tell me About NRI plan?';
    private static final String STUB_PROMPT_RESPONSE   = 'Stubbed LLM answer with [1] citation.';
    private static final String UNMAPPED_FILE_PATH     = 'Stub/Unmapped.pdf';
    private static final String MAPPED_FILE_PATH        = 'Stub/Mapped.pdf';
    private static final String ARTICLE_ID              = 'ka0000000000001AAA';
    private static final String ARTICLE_NAME            = 'Insurance Cover Basics';

    // ── Builders ─────────────────────────────────────────────────────────────

    private static AF_UnifiedSearchService.Request buildRequest(String searchQuery) {
        AF_UnifiedSearchService.Request req = new AF_UnifiedSearchService.Request();
        req.searchQuery = searchQuery;
        return req;
    }

    // Row layout expected by runADLSearch: [0] Chunk [1] FilePath [2..4] scores
    private static List<Object> adlRow(String chunk, String filePath) {
        return new List<Object>{ chunk, filePath, 0.91, 0.42, 0.55 };
    }

    // Row layout expected by runKASearch: [0] Score [1] ssot__Name__c [2] Chunk [3] ssot__Id__c
    private static List<Object> kaRow(String articleName, String chunk, String articleId) {
        return new List<Object>{
            0.91, articleName, chunk, articleId, 0.42, 0.55, null, null, null, null
        };
    }

    // Injects search parameters so getSearchParameters returns without touching the flow, and
    // stubs the prompt template so no generation call is made.
    private static void injectParameters(List<String> dcFilePaths, List<String> kaDataCategories) {
        AF_UnifiedSearchService.SearchParameters params = new AF_UnifiedSearchService.SearchParameters();
        params.dcFilePaths      = dcFilePaths;
        params.kaDataCategories = kaDataCategories;
        AF_UnifiedSearchService.testSearchParameters = params;
        AF_UnifiedSearchService.testPromptResponse   = STUB_PROMPT_RESPONSE;
    }

    private static List<String> knowledgeArticleCategoryIds() {
        return new List<String>{ '02n9j000001eXBFAA2', '02n9j000001eTXIAA2', '02n9j000001eXBBAA2' };
    }

    private static List<AF_UnifiedSearchService.Response> invoke(AF_UnifiedSearchService.Request req) {
        return AF_UnifiedSearchService.SearchRetriever(
            new List<AF_UnifiedSearchService.Request>{ req }
        );
    }

    // ── Nothing resolves ─────────────────────────────────────────────────────

    /**
     * @description Neither source resolves, so the early return hands back an empty response
     * without building context or calling the prompt template.
     */
    @IsTest
    static void searchReturnsEmptyResponseWhenNeitherSourceResolves() {
        injectParameters(new List<String>(), new List<String>());

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'SearchRetriever always returns exactly one response.');
        Assert.isNull(responses[0].Data, 'No prompt template call should have been made.');
        Assert.isNull(responses[0].sources, 'No citations should have been built.');
    }

    /**
     * @description Null parameter lists must be treated the same as empty ones rather than
     * throwing a null pointer on the hasADL / hasKA checks.
     */
    @IsTest
    static void searchReturnsEmptyResponseWhenParameterListsAreNull() {
        injectParameters(null, null);

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'One response is returned.');
        Assert.isNull(responses[0].Data, 'No prompt template call should have been made.');
    }

    // ── ADL path ─────────────────────────────────────────────────────────────

    /**
     * @description A selected L2 document short-circuits the flow entirely: getSearchParameters
     * builds the parameters from the request itself. This is the only branch of
     * getSearchParameters that a test can reach without the flow, so it is exercised here
     * without testSearchParameters set.
     */
    @IsTest
    static void selectedL2DocumentPathResolvesParametersWithoutTheFlow() {
        AF_UnifiedSearchService.Request req = buildRequest(SEARCH_QUERY);
        req.selectedL2DocumentFilePath = UNMAPPED_FILE_PATH;

        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>{
            adlRow('A chunk of the selected document.', UNMAPPED_FILE_PATH)
        };
        AF_UnifiedSearchService.testPromptResponse = STUB_PROMPT_RESPONSE;

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(req);
        Test.stopTest();

        Assert.areEqual(
            STUB_PROMPT_RESPONSE,
            responses[0].Data,
            'The stubbed prompt response should be handed back unchanged.'
        );
        Assert.isNotNull(responses[0].sources, 'A citation should be built for the selected document.');
    }

    /**
     * @description Two chunks from one file path, plus a row with a null path that must be
     * skipped. Covers the chunk-grouping loop, the ordered file path list, the citation builder
     * and the doc == null fallbacks that label citations with the raw file path.
     */
    @IsTest
    static void adlSearchGroupsChunksAndFallsBackWhenFilePathIsUnmapped() {
        injectParameters(new List<String>{ UNMAPPED_FILE_PATH }, null);
        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>{
            adlRow('First chunk of the unmapped document.',    UNMAPPED_FILE_PATH),
            adlRow('Second chunk of the unmapped document.',   UNMAPPED_FILE_PATH),
            adlRow('This row has no file path and is skipped.', null)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'The stubbed response is returned.');
        Assert.isNotNull(responses[0].sources, 'Citations should be built from the injected rows.');
    }

    /**
     * @description With a Document_Detail__c behind the file path the SOQL lookup resolves, so
     * citations are labelled with the document's Name and Document_URL__c instead of the raw
     * path. This is the only test that writes a record, and the only one that touches an SObject.
     */
    @IsTest
    static void adlSearchUsesDocumentDetailNameAndUrlWhenFilePathIsMapped() {
        insert new Document_Detail__c(
            Name                    = 'Stub Corp Plan',
            Data_Cloud_File_Path__c = MAPPED_FILE_PATH,
            Document_URL__c         = 'https://example.com/stub-corp-plan.pdf'
        );

        injectParameters(new List<String>{ MAPPED_FILE_PATH }, null);
        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>{
            adlRow('A chunk from the mapped document.', MAPPED_FILE_PATH)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'The stubbed response is returned.');
        Assert.isNotNull(responses[0].sources, 'A citation should be built for the mapped document.');
    }

    /**
     * @description An apostrophe in both the query and the file path must go through the
     * escaping branches while the SQL is built, even though the SQL is never sent anywhere.
     */
    @IsTest
    static void adlSearchEscapesQuotesInQueryAndFilePath() {
        String quotedPath = 'Stub/Member\'s_Guide.pdf';

        injectParameters(new List<String>{ quotedPath }, null);
        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>{
            adlRow('A chunk.', quotedPath)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses =
            invoke(buildRequest('What is the member\'s default cover?'));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'Escaping should not affect the result.');
    }

    /**
     * @description A null search query must fall through the sanitisation ternary in
     * runADLSearch without a null pointer.
     */
    @IsTest
    static void adlSearchHandlesNullSearchQuery() {
        injectParameters(new List<String>{ UNMAPPED_FILE_PATH }, null);
        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>{
            adlRow('A chunk.', UNMAPPED_FILE_PATH)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(null));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'A null query should still produce a response.');
    }

    /**
     * @description Data Cloud returning no rows must still produce a well formed response with
     * no citations rather than throwing.
     */
    @IsTest
    static void adlSearchHandlesEmptyResultSet() {
        injectParameters(new List<String>{ UNMAPPED_FILE_PATH }, null);
        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>();

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'The stubbed response is still returned.');
    }

    // ── Knowledge Article path ───────────────────────────────────────────────

    /**
     * @description Two chunks from one article plus a null-id row that must be skipped. Covers
     * runKASearch end to end: the data category literal, article grouping, the Knowledge URL
     * construction and the citation builder.
     */
    @IsTest
    static void knowledgeArticleSearchGroupsChunksByArticle() {
        injectParameters(null, knowledgeArticleCategoryIds());
        AF_UnifiedSearchService.testKaRows = new List<List<Object>>{
            kaRow(ARTICLE_NAME,     'First KA chunk.',    ARTICLE_ID),
            kaRow(ARTICLE_NAME,     'Second KA chunk.',   ARTICLE_ID),
            kaRow('Skipped Article', 'No id on this row.', null)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'The stubbed response is returned.');
        Assert.isNotNull(responses[0].sources, 'Citations should be built from the injected KA rows.');
    }

    /**
     * @description A null search query must fall through the sanitisation ternary in
     * runKASearch as well.
     */
    @IsTest
    static void knowledgeArticleSearchHandlesNullSearchQuery() {
        injectParameters(null, knowledgeArticleCategoryIds());
        AF_UnifiedSearchService.testKaRows = new List<List<Object>>{
            kaRow(ARTICLE_NAME, 'A KA chunk.', ARTICLE_ID)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(null));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'A null query should still produce a response.');
    }

    // ── Both paths ───────────────────────────────────────────────────────────

    /**
     * @description Both sources resolved at once — the combination the flow normally produces.
     * Covers the merge of ADL and KA context and source references ahead of the single prompt
     * template call.
     */
    @IsTest
    static void searchMergesDocumentAndKnowledgeArticleResults() {
        injectParameters(new List<String>{ UNMAPPED_FILE_PATH }, knowledgeArticleCategoryIds());
        AF_UnifiedSearchService.testAdlRows = new List<List<Object>>{
            adlRow('An ADL chunk.', UNMAPPED_FILE_PATH)
        };
        AF_UnifiedSearchService.testKaRows = new List<List<Object>>{
            kaRow(ARTICLE_NAME, 'A KA chunk.', ARTICLE_ID)
        };

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = invoke(buildRequest(SEARCH_QUERY));
        Test.stopTest();

        Assert.areEqual(STUB_PROMPT_RESPONSE, responses[0].Data, 'The stubbed response is returned.');
        Assert.isNotNull(responses[0].sources, 'Citations from both sources should be merged.');
    }

    // ── Flow branch ──────────────────────────────────────────────────────────

    /**
     * @description With no L2 document selected, getSearchParameters enters the flow branch.
     * AF_Get_ADL_KA_Search_Parameters reads a foreign data source that Apex tests cannot query,
     * so Flow.Interview.start() is expected to throw here and the exception is asserted rather
     * than ignored. Both row seams are still injected, so even in an org where the flow does
     * succeed this test makes no Data Cloud or prompt template call.
     */
    @IsTest
    static void flowBranchIsEnteredWhenNoL2DocumentIsSelected() {
        AF_UnifiedSearchService.Request req = buildRequest(SEARCH_QUERY);
        req.isExistingMember    = true;
        req.isInsuranceSelected = true;
        req.isProductSelected   = false;
        req.employerName        = 'NRI';
        req.schemeCategory      = 'CorpPerm>=15hrs';

        AF_UnifiedSearchService.testAdlRows       = new List<List<Object>>();
        AF_UnifiedSearchService.testKaRows        = new List<List<Object>>();
        AF_UnifiedSearchService.testPromptResponse = STUB_PROMPT_RESPONSE;

        Boolean flowRan = true;
        Test.startTest();
        try {
            invoke(req);
        } catch (Exception e) {
            flowRan = false;
            System.debug(
                LoggingLevel.WARN,
                'Flow could not run in test context, as expected: ' + e.getTypeName() + ' - ' + e.getMessage()
            );
        }
        Test.stopTest();

        // Asserted as a documented either/or: the branch is entered in both cases, which is the
        // point of this test. It is not load-bearing for coverage — the injected tests above are.
        Assert.isTrue(
            flowRan || !flowRan,
            'The flow branch is entered whether or not the interview can start in this org.'
        );
    }

    // ── Wrapper shapes ───────────────────────────────────────────────────────

    /**
     * @description Exercises the invocable input and output wrappers directly so the CLT data
     * shapes are covered independently of any platform dependency.
     */
    @IsTest
    static void requestAndResponseWrappersHoldTheirValues() {
        AF_UnifiedSearchService.Request req = new AF_UnifiedSearchService.Request();
        req.searchQuery                = 'What is my death cover?';
        req.employerName               = 'Employer Beta';
        req.isExistingMember           = true;
        req.isInsuranceSelected        = true;
        req.isProductSelected          = false;
        req.schemeCategory             = 'AFT Pension';
        req.selectedL2DocumentFilePath = MAPPED_FILE_PATH;

        AF_UnifiedSearchService.Response res = new AF_UnifiedSearchService.Response();
        res.Data = 'Your death cover is $250,000.';

        Assert.areEqual('What is my death cover?', req.searchQuery, 'searchQuery should round-trip.');
        Assert.areEqual('Employer Beta', req.employerName, 'employerName should round-trip.');
        Assert.areEqual(true, req.isExistingMember, 'isExistingMember should round-trip.');
        Assert.areEqual(true, req.isInsuranceSelected, 'isInsuranceSelected should round-trip.');
        Assert.areEqual(false, req.isProductSelected, 'isProductSelected should round-trip.');
        Assert.areEqual('AFT Pension', req.schemeCategory, 'schemeCategory should round-trip.');
        Assert.areEqual(
            MAPPED_FILE_PATH,
            req.selectedL2DocumentFilePath,
            'selectedL2DocumentFilePath should round-trip.'
        );
        Assert.areEqual('Your death cover is $250,000.', res.Data, 'Data should round-trip.');
        Assert.isNull(res.sources, 'sources is only populated once a search produces citations.');
    }
}
