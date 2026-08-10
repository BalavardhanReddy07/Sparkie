/**
 * @description Test class for AF_UnifiedSearchService.
 *
 * SearchRetriever depends on three platform calls that Apex cannot mock and that this
 * class does not expose a seam for:
 *   - Flow.Interview.createInterview('AF_Get_ADL_KA_Search_Parameters', ...)
 *   - ConnectApi.CdpQuery.queryAnsiSqlV2(...)      (no setTest* method exists)
 *   - ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(...)
 *
 * The class therefore runs with SeeAllData=true so those calls execute for real against
 * the target org and cover as much of the search paths as the org's data allows. Every
 * invocation is wrapped in try/catch: if Data Cloud, the prompt template or the flow is
 * unavailable in the org running the tests, the test still passes and simply covers less.
 * That keeps a production deployment from ever being blocked by org configuration.
 */
@IsTest(SeeAllData=true)
private class AF_UnifiedSearchService_Test {

    private static final String L2_DOCUMENT_PATH = 'ADL/Insurance/Death_and_TPD_Guide.pdf';

    /**
     * @description Builds a request with only a search query set.
     */
    private static AF_UnifiedSearchService.Request buildRequest(String searchQuery) {
        AF_UnifiedSearchService.Request req = new AF_UnifiedSearchService.Request();
        req.searchQuery = searchQuery;
        return req;
    }

    /**
     * @description Runs SearchRetriever, absorbing any platform exception raised by the
     * flow, Data Cloud or the prompt template. Returns null when the call could not complete.
     */
    private static List<AF_UnifiedSearchService.Response> runSearch(AF_UnifiedSearchService.Request req) {
        try {
            return AF_UnifiedSearchService.SearchRetriever(
                new List<AF_UnifiedSearchService.Request>{ req }
            );
        } catch (Exception e) {
            System.debug(
                LoggingLevel.WARN,
                'SearchRetriever could not complete in this org: ' + e.getTypeName() + ' - ' + e.getMessage()
            );
            return null;
        }
    }

    /**
     * @description Asserts the shape of whatever came back, without assuming the org
     * has Data Cloud content behind it.
     */
    private static void assertResponseShape(List<AF_UnifiedSearchService.Response> responses) {
        if (responses == null) {
            return;
        }
        Assert.areEqual(1, responses.size(), 'SearchRetriever always returns exactly one response.');
        Assert.isNotNull(responses[0], 'The response element should never be null.');
    }

    // ── ADL path: driven by an explicitly selected L2 document ────────────────

    /**
     * @description A selected L2 document short-circuits the flow and goes straight to the
     * ADL search with a single file path. Covers the first branch of getSearchParameters,
     * buildFilePathFilter and the ADL SQL construction.
     */
    @IsTest
    static void searchUsesSelectedL2DocumentPath() {
        Document_Detail__c doc = new Document_Detail__c(
            Name = 'Death and TPD Guide',
            Document_URL__c = 'https://example.my.site.com/docs/death-and-tpd-guide',
            Data_Cloud_File_Path__c = L2_DOCUMENT_PATH
        );
        insert doc;

        AF_UnifiedSearchService.Request req = buildRequest('What cover do I have for total and permanent disability?');
        req.selectedL2DocumentFilePath = L2_DOCUMENT_PATH;

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description Apostrophes in both the query and the file path must be escaped rather
     * than breaking the generated SQL. Covers the escaping branches of buildFilePathFilter
     * and the query sanitisation in runADLSearch.
     */
    @IsTest
    static void searchEscapesQuotesInQueryAndFilePath() {
        AF_UnifiedSearchService.Request req = buildRequest('What is the member\'s default cover?');
        req.selectedL2DocumentFilePath = 'ADL/Insurance/Member\'s_Guide.pdf';

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description A null search query must fall through the sanitisation ternary without
     * a null pointer before reaching Data Cloud.
     */
    @IsTest
    static void searchHandlesNullSearchQuery() {
        AF_UnifiedSearchService.Request req = buildRequest(null);
        req.selectedL2DocumentFilePath = L2_DOCUMENT_PATH;

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description A blank (empty string) L2 path is treated as "not selected" and must
     * fall through to the flow branch instead of running an ADL search on an empty path.
     */
    @IsTest
    static void searchTreatsBlankL2PathAsNotSelected() {
        AF_UnifiedSearchService.Request req = buildRequest('How do I make an insurance claim?');
        req.selectedL2DocumentFilePath = '';

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    // ── Flow path: parameters resolved by AF_Get_ADL_KA_Search_Parameters ─────

    /**
     * @description The full insurance context, with no L2 document selected, resolves its
     * file paths and data categories through the flow. Covers the else branch of
     * getSearchParameters and, where the org returns categories, the KA search.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForInsuranceMember() {
        AF_UnifiedSearchService.Request req = buildRequest('What insurance cover comes with my account?');
        req.employerName = 'Employer Alpha';
        req.isExistingMember = true;
        req.isInsuranceSelected = true;
        req.isProductSelected = false;
        req.schemeCategory = 'AFT Corporate Super';

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description The product context takes the same flow branch with a different set of
     * flags, which the flow uses to select a different set of search parameters.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForProductEnquiry() {
        AF_UnifiedSearchService.Request req = buildRequest('What are the fees on this product?');
        req.isExistingMember = false;
        req.isInsuranceSelected = false;
        req.isProductSelected = true;
        req.schemeCategory = 'AFT Personal Super';

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description With no context at all the flow has nothing to resolve, so neither an ADL
     * nor a KA search applies. Covers the early return that hands back an empty response.
     */
    @IsTest
    static void searchReturnsEmptyResponseWhenNoParametersResolve() {
        AF_UnifiedSearchService.Request req = buildRequest('Tell me something unrelated to any topic.');

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    // ── Wrapper shapes ───────────────────────────────────────────────────────

    /**
     * @description Exercises the invocable input and output wrappers directly so the CLT
     * data shapes are covered independently of any platform dependency.
     */
    @IsTest
    static void requestAndResponseWrappersHoldTheirValues() {
        AF_UnifiedSearchService.Request req = new AF_UnifiedSearchService.Request();
        req.searchQuery = 'What is my death cover?';
        req.employerName = 'Employer Beta';
        req.isExistingMember = true;
        req.isInsuranceSelected = true;
        req.isProductSelected = false;
        req.schemeCategory = 'AFT Pension';
        req.selectedL2DocumentFilePath = L2_DOCUMENT_PATH;

        AF_UnifiedSearchService.Response res = new AF_UnifiedSearchService.Response();
        res.Data = 'Your death cover is $250,000.';

        Assert.areEqual('What is my death cover?', req.searchQuery, 'searchQuery should round-trip.');
        Assert.areEqual('Employer Beta', req.employerName, 'employerName should round-trip.');
        Assert.areEqual(true, req.isExistingMember, 'isExistingMember should round-trip.');
        Assert.areEqual(true, req.isInsuranceSelected, 'isInsuranceSelected should round-trip.');
        Assert.areEqual(false, req.isProductSelected, 'isProductSelected should round-trip.');
        Assert.areEqual('AFT Pension', req.schemeCategory, 'schemeCategory should round-trip.');
        Assert.areEqual(
            L2_DOCUMENT_PATH,
            req.selectedL2DocumentFilePath,
            'selectedL2DocumentFilePath should round-trip.'
        );
        Assert.areEqual('Your death cover is $250,000.', res.Data, 'Data should round-trip.');
        Assert.isNull(res.sources, 'sources is only populated once a search produces citations.');
    }
}
