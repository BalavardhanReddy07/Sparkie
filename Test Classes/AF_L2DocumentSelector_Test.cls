/**
 * @description Test class for AF_L2DocumentSelector.
 * Covers the happy path plus both ways the invocable method can throw internally
 * (null selectorData and an empty request list), which the service catches.
 */
@IsTest
private class AF_L2DocumentSelector_Test {

    /**
     * @description The selected file path supplied by the Input Rendering Component
     * must be returned unchanged.
     */
    @IsTest
    static void getSelectedDocumentReturnsSuppliedPath() {
        AF_L2DocumentSelector.SelectorInput input = new AF_L2DocumentSelector.SelectorInput();
        input.selectedL2Document = 'ADL/Insurance/Death_and_TPD_Guide.pdf';

        AF_L2DocumentSelector.SelectorRequestInput request = new AF_L2DocumentSelector.SelectorRequestInput();
        request.selectorData = input;

        Test.startTest();
        List<AF_L2DocumentSelector.SelectorResult> results =
            AF_L2DocumentSelector.getSelectedDocument(
                new List<AF_L2DocumentSelector.SelectorRequestInput>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One result is expected for one request.');
        Assert.areEqual(
            'ADL/Insurance/Death_and_TPD_Guide.pdf',
            results[0].selectedL2Document,
            'The selected L2 document path should be returned unchanged.'
        );
    }

    /**
     * @description A null selectorData dereferences inside the try block.
     * The service catches it and returns an empty list instead of failing the agent action.
     */
    @IsTest
    static void getSelectedDocumentSwallowsExceptionWhenSelectorDataIsNull() {
        AF_L2DocumentSelector.SelectorRequestInput request = new AF_L2DocumentSelector.SelectorRequestInput();
        request.selectorData = null;

        Test.startTest();
        List<AF_L2DocumentSelector.SelectorResult> results =
            AF_L2DocumentSelector.getSelectedDocument(
                new List<AF_L2DocumentSelector.SelectorRequestInput>{ request }
            );
        Test.stopTest();

        Assert.isNotNull(results, 'The service should still return a list.');
        Assert.isTrue(results.isEmpty(), 'No result should be added when selectorData is null.');
    }

    /**
     * @description An empty request list makes requests[0] throw a ListException,
     * which is caught the same way.
     */
    @IsTest
    static void getSelectedDocumentSwallowsExceptionForEmptyRequestList() {
        Test.startTest();
        List<AF_L2DocumentSelector.SelectorResult> results =
            AF_L2DocumentSelector.getSelectedDocument(
                new List<AF_L2DocumentSelector.SelectorRequestInput>()
            );
        Test.stopTest();

        Assert.isNotNull(results, 'The service should still return a list.');
        Assert.isTrue(results.isEmpty(), 'No result should be added when the request list is empty.');
    }

    /**
     * @description An empty string is a legitimate selection value and must not be
     * confused with the failure paths above.
     */
    @IsTest
    static void getSelectedDocumentHandlesBlankPath() {
        AF_L2DocumentSelector.SelectorInput input = new AF_L2DocumentSelector.SelectorInput();
        input.selectedL2Document = '';

        AF_L2DocumentSelector.SelectorRequestInput request = new AF_L2DocumentSelector.SelectorRequestInput();
        request.selectorData = input;

        Test.startTest();
        List<AF_L2DocumentSelector.SelectorResult> results =
            AF_L2DocumentSelector.getSelectedDocument(
                new List<AF_L2DocumentSelector.SelectorRequestInput>{ request }
            );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'A blank selection is still a successful result.');
        Assert.areEqual('', results[0].selectedL2Document, 'A blank path should be returned as-is.');
    }
}
