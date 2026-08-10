/**
 * @description Test class for AFA_ProcessTopicSelection.
 * Covers both branches of processTopicSelection (populated inputs and null inputs),
 * the null-safe boolean coercion, and bulk request handling.
 */
@IsTest
private class AFA_ProcessTopicSelection_Test {

    /**
     * @description Builds a TopicSelectionInput with the three routing flags.
     */
    private static AFA_ProcessTopicSelection.InputRequest buildRequest(
        Boolean isProductSelected,
        Boolean isInsuranceSelected,
        Boolean isTopicSubmitted
    ) {
        AFA_ProcessTopicSelection.TopicSelectionInput selection = new AFA_ProcessTopicSelection.TopicSelectionInput();
        selection.IsProductSelected = isProductSelected;
        selection.IsInsuranceSelected = isInsuranceSelected;
        selection.IsTopicSubmitted = isTopicSubmitted;

        AFA_ProcessTopicSelection.InputRequest request = new AFA_ProcessTopicSelection.InputRequest();
        request.inputs = selection;
        return request;
    }

    /**
     * @description All flags true — the Agent Script should receive all three as true.
     */
    @IsTest
    static void processTopicSelectionReturnsAllFlagsTrue() {
        Test.startTest();
        List<AFA_ProcessTopicSelection.ActionOutput> results =
            AFA_ProcessTopicSelection.processTopicSelection(
                new List<AFA_ProcessTopicSelection.InputRequest>{ buildRequest(true, true, true) }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One output is expected for one request.');
        Assert.areEqual(true, results[0].IsProductSelected, 'IsProductSelected should be true.');
        Assert.areEqual(true, results[0].IsInsuranceSelected, 'IsInsuranceSelected should be true.');
        Assert.areEqual(true, results[0].IsTopicSubmitted, 'IsTopicSubmitted should be true.');
    }

    /**
     * @description Insurance selected only — the other two flags must stay false so the
     * Agent Script routes to the insurance subagent.
     */
    @IsTest
    static void processTopicSelectionRoutesInsuranceOnly() {
        Test.startTest();
        List<AFA_ProcessTopicSelection.ActionOutput> results =
            AFA_ProcessTopicSelection.processTopicSelection(
                new List<AFA_ProcessTopicSelection.InputRequest>{ buildRequest(false, true, true) }
            );
        Test.stopTest();

        Assert.areEqual(false, results[0].IsProductSelected, 'IsProductSelected should be false.');
        Assert.areEqual(true, results[0].IsInsuranceSelected, 'IsInsuranceSelected should be true.');
        Assert.areEqual(true, results[0].IsTopicSubmitted, 'IsTopicSubmitted should be true.');
    }

    /**
     * @description Null booleans on the input must be coerced to false by the `== true` comparison,
     * never returned as null to the Agent Script.
     */
    @IsTest
    static void processTopicSelectionCoercesNullBooleansToFalse() {
        Test.startTest();
        List<AFA_ProcessTopicSelection.ActionOutput> results =
            AFA_ProcessTopicSelection.processTopicSelection(
                new List<AFA_ProcessTopicSelection.InputRequest>{ buildRequest(null, null, null) }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One output is expected for one request.');
        Assert.areEqual(false, results[0].IsProductSelected, 'A null IsProductSelected should become false.');
        Assert.areEqual(false, results[0].IsInsuranceSelected, 'A null IsInsuranceSelected should become false.');
        Assert.areEqual(false, results[0].IsTopicSubmitted, 'A null IsTopicSubmitted should become false.');
    }

    /**
     * @description A request with no inputs at all takes the else branch and returns all false.
     */
    @IsTest
    static void processTopicSelectionReturnsAllFalseWhenInputsAreNull() {
        AFA_ProcessTopicSelection.InputRequest request = new AFA_ProcessTopicSelection.InputRequest();
        request.inputs = null;

        Test.startTest();
        List<AFA_ProcessTopicSelection.ActionOutput> results =
            AFA_ProcessTopicSelection.processTopicSelection(
                new List<AFA_ProcessTopicSelection.InputRequest>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One output is expected even without inputs.');
        Assert.areEqual(false, results[0].IsProductSelected, 'IsProductSelected should default to false.');
        Assert.areEqual(false, results[0].IsInsuranceSelected, 'IsInsuranceSelected should default to false.');
        Assert.areEqual(false, results[0].IsTopicSubmitted, 'IsTopicSubmitted should default to false.');
    }

    /**
     * @description Several requests in one invocation — each must produce its own output,
     * in order, mixing the populated and null-inputs branches.
     */
    @IsTest
    static void processTopicSelectionHandlesBulkRequests() {
        AFA_ProcessTopicSelection.InputRequest emptyRequest = new AFA_ProcessTopicSelection.InputRequest();
        emptyRequest.inputs = null;

        List<AFA_ProcessTopicSelection.InputRequest> requests = new List<AFA_ProcessTopicSelection.InputRequest>{
            buildRequest(true, false, true),
            buildRequest(false, true, false),
            emptyRequest
        };

        Test.startTest();
        List<AFA_ProcessTopicSelection.ActionOutput> results =
            AFA_ProcessTopicSelection.processTopicSelection(requests);
        Test.stopTest();

        Assert.areEqual(3, results.size(), 'Every request should produce one output.');
        Assert.areEqual(true, results[0].IsProductSelected, 'First request selected a product.');
        Assert.areEqual(false, results[0].IsInsuranceSelected, 'First request did not select insurance.');
        Assert.areEqual(true, results[1].IsInsuranceSelected, 'Second request selected insurance.');
        Assert.areEqual(false, results[1].IsTopicSubmitted, 'Second request had not submitted the topic.');
        Assert.areEqual(false, results[2].IsProductSelected, 'Third request had no inputs.');
        Assert.areEqual(false, results[2].IsTopicSubmitted, 'Third request had no inputs.');
    }

    /**
     * @description An empty request list must return an empty output list without error.
     */
    @IsTest
    static void processTopicSelectionHandlesEmptyRequestList() {
        Test.startTest();
        List<AFA_ProcessTopicSelection.ActionOutput> results =
            AFA_ProcessTopicSelection.processTopicSelection(
                new List<AFA_ProcessTopicSelection.InputRequest>()
            );
        Test.stopTest();

        Assert.isNotNull(results, 'A list should still be returned.');
        Assert.isTrue(results.isEmpty(), 'No outputs should be produced for no requests.');
    }
}
