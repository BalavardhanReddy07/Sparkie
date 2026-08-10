/**
 * @description Test class for AF_MemberQuestionService.
 * Covers the CLT wrapper shapes and every branch of getMemberId:
 * populated memberData, null memberData, and the catch block.
 */
@IsTest
private class AF_MemberQuestionService_Test {

    /**
     * @description memberData fully populated — every value must flow through to the result.
     */
    @IsTest
    static void getMemberIdReturnsSuppliedValues() {
        AF_MemberQuestionService.MemberInput input = new AF_MemberQuestionService.MemberInput();
        input.existingMember = true;
        input.memberId = 'M-100045';
        input.memberSummary = 'Active member since 2019 with two products.';
        input.selectedSchemeCategory = 'Corporate Super';

        AF_MemberQuestionService.MemberRequestInput request = new AF_MemberQuestionService.MemberRequestInput();
        request.memberData = input;

        Test.startTest();
        List<AF_MemberQuestionService.MemberResult> results =
            AF_MemberQuestionService.getMemberId(
                new List<AF_MemberQuestionService.MemberRequestInput>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result is expected for one request.');
        AF_MemberQuestionService.MemberResult result = results[0];
        Assert.areEqual(true, result.existingMember, 'existingMember should be carried across.');
        Assert.areEqual('M-100045', result.memberId, 'memberId should be carried across.');
        Assert.areEqual(
            'Active member since 2019 with two products.',
            result.memberSummary,
            'memberSummary should be carried across.'
        );
        Assert.areEqual(
            'Corporate Super',
            result.selectedSchemeCategory,
            'selectedSchemeCategory should be carried across.'
        );
    }

    /**
     * @description memberData omitted — the service must fall back to its initialised defaults.
     */
    @IsTest
    static void getMemberIdReturnsDefaultsWhenMemberDataIsNull() {
        AF_MemberQuestionService.MemberRequestInput request = new AF_MemberQuestionService.MemberRequestInput();
        request.memberData = null;

        Test.startTest();
        List<AF_MemberQuestionService.MemberResult> results =
            AF_MemberQuestionService.getMemberId(
                new List<AF_MemberQuestionService.MemberRequestInput>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result is expected even without member data.');
        AF_MemberQuestionService.MemberResult result = results[0];
        Assert.areEqual(false, result.existingMember, 'existingMember should default to false.');
        Assert.areEqual('', result.memberId, 'memberId should default to an empty string.');
        Assert.areEqual('', result.memberSummary, 'memberSummary should default to an empty string.');
        Assert.areEqual('', result.selectedSchemeCategory, 'selectedSchemeCategory should default to an empty string.');
    }

    /**
     * @description An empty request list makes requests[0] throw, which the service swallows.
     * Exercises the catch block and proves the action degrades quietly rather than erroring the agent.
     */
    @IsTest
    static void getMemberIdSwallowsExceptionForEmptyRequestList() {
        Test.startTest();
        List<AF_MemberQuestionService.MemberResult> results =
            AF_MemberQuestionService.getMemberId(
                new List<AF_MemberQuestionService.MemberRequestInput>()
            );
        Test.stopTest();

        Assert.isNotNull(results, 'The service should still return a list.');
        Assert.isTrue(results.isEmpty(), 'No result should be added when the request list is empty.');
    }

    /**
     * @description Directly exercises the CLT data shapes referenced by the schema.json files.
     */
    @IsTest
    static void wrapperShapesHoldTheirValues() {
        AF_MemberQuestionService.MemberInput input = new AF_MemberQuestionService.MemberInput();
        input.existingMember = false;
        input.memberId = 'M-000001';
        input.memberSummary = 'Prospective member.';
        input.selectedSchemeCategory = 'Personal Super';

        AF_MemberQuestionService.MemberResult result = new AF_MemberQuestionService.MemberResult();
        result.existingMember = input.existingMember;
        result.memberId = input.memberId;
        result.memberSummary = input.memberSummary;
        result.selectedSchemeCategory = input.selectedSchemeCategory;

        Assert.areEqual(false, result.existingMember, 'existingMember should round-trip.');
        Assert.areEqual('M-000001', result.memberId, 'memberId should round-trip.');
        Assert.areEqual('Prospective member.', result.memberSummary, 'memberSummary should round-trip.');
        Assert.areEqual('Personal Super', result.selectedSchemeCategory, 'selectedSchemeCategory should round-trip.');
    }
}
