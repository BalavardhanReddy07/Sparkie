@JsonAccess(serializable='always' deserializable='always')
global class AFA_ProcessTopicSelection {

    @JsonAccess(serializable='always' deserializable='always')
    global class TopicSelectionInput {
        @AuraEnabled
        global Boolean IsProductSelected;

        @AuraEnabled
        global Boolean IsInsuranceSelected;

        @AuraEnabled
        global Boolean IsTopicSubmitted;        // ← added here
    }

    @JsonAccess(serializable='always' deserializable='always')
    global class InputRequest {
        @InvocableVariable(label='Topic Selection Input' required=true)
        global TopicSelectionInput inputs;
    }

    @JsonAccess(serializable='always' deserializable='always')
    global class ActionOutput {
        @InvocableVariable(label='Is Product Selected')
        global Boolean IsProductSelected;

        @InvocableVariable(label='Is Insurance Selected')
        global Boolean IsInsuranceSelected;

        @InvocableVariable(label='Is Topic Submitted')  // ← added here
        global Boolean IsTopicSubmitted;
    }

    @InvocableMethod(label='Topic Selection Process' description='Receives the user topic selection from the LWC and returns boolean flags so the Agent Script can route to the correct subagent.')
    global static List<ActionOutput> processTopicSelection(List<InputRequest> requests) {
        List<ActionOutput> results = new List<ActionOutput>();

        for (InputRequest req : requests) {
            ActionOutput out = new ActionOutput();

            if (req.inputs != null) {
                out.IsProductSelected   = req.inputs.IsProductSelected  == true;
                out.IsInsuranceSelected = req.inputs.IsInsuranceSelected == true;
                out.IsTopicSubmitted    = req.inputs.IsTopicSubmitted    == true;
            } else {
                out.IsProductSelected   = false;
                out.IsInsuranceSelected = false;
                out.IsTopicSubmitted    = false; // ← added here
            }

            results.add(out);
        }
        return results;
    }
}
