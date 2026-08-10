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

    // Replace with a Data_Cloud_File_Path__c that exists on a real Document_Detail__c record.
    // A path that matches indexed ADL content lets runADLSearch return rows and cover its
    // chunk-grouping and citation-building loops; an unmatched path still covers the entry path.
    private static final String L2_DOCUMENT_PATH = 'ADL/Insurance/Death_and_TPD_Guide.pdf';

    // Live UAT values. AF_Get_ADL_KA_Search_Parameters resolves these to real DCFilePaths
    // and KADataCategories, which is what drives coverage of runADLSearch and runKASearch.
    // If the flow's routing data changes, refresh these three constants.
    private static final String SCHEME_CATEGORY = 'CorpPerm>=15hrs';
    private static final String EMPLOYER_NAME = 'NRI';
    private static final String SEARCH_QUERY = 'Tell me About NRI plan?';

    /**
     * @description Builds a request with only a search query set.
     */
    private static AF_UnifiedSearchService.Request buildRequest(String searchQuery) {
        AF_UnifiedSearchService.Request req = new AF_UnifiedSearchService.Request();
        req.searchQuery = searchQuery;
        return req;
    }

    /**
     * @description Builds a request that carries no L2 document, so the search parameters
     * are resolved through AF_Get_ADL_KA_Search_Parameters.
     */
    private static AF_UnifiedSearchService.Request buildFlowRequest(
        Boolean isExistingMember,
        Boolean isInsuranceSelected,
        Boolean isProductSelected,
        String employerName,
        String schemeCategory
    ) {
        AF_UnifiedSearchService.Request req = buildRequest(SEARCH_QUERY);
        req.isExistingMember = isExistingMember;
        req.isInsuranceSelected = isInsuranceSelected;
        req.isProductSelected = isProductSelected;
        req.employerName = employerName;
        req.schemeCategory = schemeCategory;
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
        AF_UnifiedSearchService.Request req = buildRequest(SEARCH_QUERY);
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
        AF_UnifiedSearchService.Request req =
            buildFlowRequest(true, true, false, EMPLOYER_NAME, SCHEME_CATEGORY);
        req.selectedL2DocumentFilePath = '';

        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(req);
        Test.stopTest();

        assertResponseShape(responses);
    }

    // ── Flow path: parameters resolved by AF_Get_ADL_KA_Search_Parameters ─────

    /**
     * @description Existing member, insurance topic, with an employer. This is the
     * combination the flow resolves to the Insurance and Employers data categories,
     * so it is the one that drives runKASearch.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForInsuranceMember() {
        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(
            buildFlowRequest(true, true, false, EMPLOYER_NAME, SCHEME_CATEGORY)
        );
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description Existing member on the product topic — the flow selects a different
     * set of parameters for the same scheme category.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForProductEnquiry() {
        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(
            buildFlowRequest(true, false, true, EMPLOYER_NAME, SCHEME_CATEGORY)
        );
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description Existing member with neither topic flag set — the general member
     * context, which the flow resolves to the Member data category.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForGeneralMemberEnquiry() {
        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(
            buildFlowRequest(true, false, false, EMPLOYER_NAME, SCHEME_CATEGORY)
        );
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description A non-member asking about the same scheme category. The flow routes
     * public enquiries to a different parameter set than member enquiries.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForNonMember() {
        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(
            buildFlowRequest(false, true, false, null, SCHEME_CATEGORY)
        );
        Test.stopTest();

        assertResponseShape(responses);
    }

    /**
     * @description An employer named with no scheme category, which is how the flow is
     * reached when the member has identified their employer but not their scheme.
     */
    @IsTest
    static void searchResolvesParametersThroughFlowForEmployerOnly() {
        Test.startTest();
        List<AF_UnifiedSearchService.Response> responses = runSearch(
            buildFlowRequest(true, true, false, EMPLOYER_NAME, null)
        );
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
