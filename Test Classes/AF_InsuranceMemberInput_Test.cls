/**
 * @description Test class for AF_InsuranceMemberInput.
 * Covers the invocable getInsuranceMemberId (populated, null memberData, catch path)
 * and getAllEmployers, including every exclusion in its SOQL filter.
 */
@IsTest
private class AF_InsuranceMemberInput_Test {

    private static final String CATEGORY_ONE = 'AFT Corporate Super';
    private static final String CATEGORY_TWO = 'AFT Personal Super';
    private static final String CATEGORY_THREE = 'AFT Pension';

    /**
     * @description Mapping data covering rows that must be returned and every row the
     * query is expected to filter out: the two reserved sub-topics, a null sub-topic,
     * a non-Insurance topic, and a duplicate that must be de-duplicated by the Set.
     */
    @TestSetup
    static void makeData() {
        List<Topic_Document_Mapping__c> mappings = new List<Topic_Document_Mapping__c>{
            // Category one — two distinct employers, one of them duplicated.
            buildMapping(CATEGORY_ONE, 'Insurance', 'Employer Alpha'),
            buildMapping(CATEGORY_ONE, 'Insurance', 'Employer Beta'),
            buildMapping(CATEGORY_ONE, 'Insurance', 'Employer Alpha'),
            // Category one — rows the filter must exclude.
            buildMapping(CATEGORY_ONE, 'Insurance', 'General Insurance'),
            buildMapping(CATEGORY_ONE, 'Insurance', 'Member Specific Products'),
            buildMapping(CATEGORY_ONE, 'Insurance', null),
            // Category two — a single employer.
            buildMapping(CATEGORY_TWO, 'Insurance', 'Employer Gamma'),
            // Category three — right category, wrong topic, so it must not appear at all.
            buildMapping(CATEGORY_THREE, 'Products', 'Employer Delta')
        };
        insert mappings;
    }

    private static Topic_Document_Mapping__c buildMapping(String keyFieldValue, String topic, String subTopic) {
        return new Topic_Document_Mapping__c(
            Key_field_value__c = keyFieldValue,
            Topic__c = topic,
            Sub_Topic__c = subTopic
        );
    }

    // ── getInsuranceMemberId ──────────────────────────────────────────────────

    /**
     * @description memberData fully populated — every value must flow through to the result.
     */
    @IsTest
    static void getInsuranceMemberIdReturnsSuppliedValues() {
        AF_InsuranceMemberInput.InsuranceMemberInput input = new AF_InsuranceMemberInput.InsuranceMemberInput();
        input.existingMember = true;
        input.memberId = 'M-778812';
        input.memberSummary = 'Existing member with death and TPD cover.';
        input.selectedSchemeCategory = CATEGORY_ONE;
        input.selectedEmployer = 'Employer Alpha';

        AF_InsuranceMemberInput.InsuranceMemberRequestInput request =
            new AF_InsuranceMemberInput.InsuranceMemberRequestInput();
        request.memberData = input;

        Test.startTest();
        List<AF_InsuranceMemberInput.InsuranceMemberResult> results =
            AF_InsuranceMemberInput.getInsuranceMemberId(
                new List<AF_InsuranceMemberInput.InsuranceMemberRequestInput>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result is expected for one request.');
        AF_InsuranceMemberInput.InsuranceMemberResult result = results[0];
        Assert.areEqual(true, result.existingMember, 'existingMember should be carried across.');
        Assert.areEqual('M-778812', result.memberId, 'memberId should be carried across.');
        Assert.areEqual(
            'Existing member with death and TPD cover.',
            result.memberSummary,
            'memberSummary should be carried across.'
        );
        Assert.areEqual(CATEGORY_ONE, result.selectedSchemeCategory, 'selectedSchemeCategory should be carried across.');
        Assert.areEqual('Employer Alpha', result.selectedEmployer, 'selectedEmployer should be carried across.');
    }

    /**
     * @description memberData omitted — the service must fall back to its initialised defaults.
     */
    @IsTest
    static void getInsuranceMemberIdReturnsDefaultsWhenMemberDataIsNull() {
        AF_InsuranceMemberInput.InsuranceMemberRequestInput request =
            new AF_InsuranceMemberInput.InsuranceMemberRequestInput();
        request.memberData = null;

        Test.startTest();
        List<AF_InsuranceMemberInput.InsuranceMemberResult> results =
            AF_InsuranceMemberInput.getInsuranceMemberId(
                new List<AF_InsuranceMemberInput.InsuranceMemberRequestInput>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result is expected even without member data.');
        AF_InsuranceMemberInput.InsuranceMemberResult result = results[0];
        Assert.areEqual(false, result.existingMember, 'existingMember should default to false.');
        Assert.areEqual('', result.memberId, 'memberId should default to an empty string.');
        Assert.areEqual('', result.memberSummary, 'memberSummary should default to an empty string.');
        Assert.areEqual('', result.selectedSchemeCategory, 'selectedSchemeCategory should default to an empty string.');
        Assert.areEqual('', result.selectedEmployer, 'selectedEmployer should default to an empty string.');
    }

    /**
     * @description An empty request list makes requests[0] throw, which the service swallows.
     * Exercises the catch block.
     */
    @IsTest
    static void getInsuranceMemberIdSwallowsExceptionForEmptyRequestList() {
        Test.startTest();
        List<AF_InsuranceMemberInput.InsuranceMemberResult> results =
            AF_InsuranceMemberInput.getInsuranceMemberId(
                new List<AF_InsuranceMemberInput.InsuranceMemberRequestInput>()
            );
        Test.stopTest();

        Assert.isNotNull(results, 'The service should still return a list.');
        Assert.isTrue(results.isEmpty(), 'No result should be added when the request list is empty.');
    }

    // ── getAllEmployers ───────────────────────────────────────────────────────

    /**
     * @description The core query path: employers grouped per scheme category, reserved
     * sub-topics excluded, and duplicates collapsed by the Set.
     */
    @IsTest
    static void getAllEmployersGroupsEmployersByCategory() {
        Test.startTest();
        Map<String, List<String>> result = AF_InsuranceMemberInput.getAllEmployers(
            new List<String>{ CATEGORY_ONE, CATEGORY_TWO, CATEGORY_THREE }
        );
        Test.stopTest();

        Assert.isNotNull(result, 'A map should always be returned.');
        Assert.areEqual(2, result.size(), 'Only the two categories with Insurance sub-topics should appear.');

        Assert.isTrue(result.containsKey(CATEGORY_ONE), 'The first category should be present.');
        Assert.areEqual(
            new Set<String>{ 'Employer Alpha', 'Employer Beta' },
            new Set<String>(result.get(CATEGORY_ONE)),
            'Only the two real employers should be returned for the first category.'
        );
        Assert.areEqual(
            2,
            result.get(CATEGORY_ONE).size(),
            'The duplicated employer should be collapsed to a single entry.'
        );

        Assert.areEqual(
            new List<String>{ 'Employer Gamma' },
            result.get(CATEGORY_TWO),
            'The second category should return its single employer.'
        );

        Assert.isFalse(
            result.containsKey(CATEGORY_THREE),
            'A category whose only mapping has a non-Insurance topic should be absent.'
        );
    }

    /**
     * @description The reserved sub-topics must never be offered to the user as employers.
     */
    @IsTest
    static void getAllEmployersExcludesReservedSubTopics() {
        Test.startTest();
        Map<String, List<String>> result = AF_InsuranceMemberInput.getAllEmployers(
            new List<String>{ CATEGORY_ONE }
        );
        Test.stopTest();

        Set<String> employers = new Set<String>(result.get(CATEGORY_ONE));
        Assert.isFalse(employers.contains('General Insurance'), 'General Insurance should be filtered out.');
        Assert.isFalse(
            employers.contains('Member Specific Products'),
            'Member Specific Products should be filtered out.'
        );
        Assert.isFalse(employers.contains(null), 'A null sub-topic should be filtered out.');
    }

    /**
     * @description A category with no matching mappings simply yields no entry.
     */
    @IsTest
    static void getAllEmployersReturnsEmptyMapForUnknownCategory() {
        Test.startTest();
        Map<String, List<String>> result = AF_InsuranceMemberInput.getAllEmployers(
            new List<String>{ 'Category That Does Not Exist' }
        );
        Test.stopTest();

        Assert.isNotNull(result, 'A map should always be returned.');
        Assert.isTrue(result.isEmpty(), 'An unmatched category should produce no entries.');
    }

    /**
     * @description A null input list short-circuits before the query.
     */
    @IsTest
    static void getAllEmployersReturnsEmptyMapForNullInput() {
        Test.startTest();
        Map<String, List<String>> result = AF_InsuranceMemberInput.getAllEmployers(null);
        Test.stopTest();

        Assert.isNotNull(result, 'A map should always be returned.');
        Assert.isTrue(result.isEmpty(), 'A null input should produce no entries.');
    }

    /**
     * @description An empty input list also short-circuits before the query.
     */
    @IsTest
    static void getAllEmployersReturnsEmptyMapForEmptyInput() {
        Test.startTest();
        Map<String, List<String>> result = AF_InsuranceMemberInput.getAllEmployers(new List<String>());
        Test.stopTest();

        Assert.isNotNull(result, 'A map should always be returned.');
        Assert.isTrue(result.isEmpty(), 'An empty input should produce no entries.');
    }
}
