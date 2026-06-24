/**
 * @description Service for getting the Insurance Member ID via Agentforce Custom Lightning Types.
 * Contains wrappers for CLT data shapes and methods for fetching Employer Names.
 */
public with sharing class AF_InsuranceMemberInput {

    /**
     * @description Data shape for CLT input
     */
    public class InsuranceMemberInput {
        @InvocableVariable(label='Existing Member' required=true)
        public Boolean existingMember;

        @InvocableVariable(label='Member ID')
        public String memberId;

        @InvocableVariable(label='Member Summary')
        public String memberSummary;

        @InvocableVariable(label='Selected Scheme Category')
        public String selectedSchemeCategory;

        @InvocableVariable(label='Selected Employer')
        public String selectedEmployer;
    }

    /**
     * @description Data shape for CLT output
     */
    public class InsuranceMemberResult {
        @InvocableVariable(label='Existing Member' required=true)
        public Boolean existingMember;

        @InvocableVariable(label='Member ID')
        public String memberId;

        @InvocableVariable(label='Member Summary')
        public String memberSummary;

        @InvocableVariable(label='Selected Scheme Category')
        public String selectedSchemeCategory;

        @InvocableVariable(label='Selected Employer')
        public String selectedEmployer;
    }

    /**
     * @description Invocable request wrapper matching AgentScript action inputs
     */
    public class InsuranceMemberRequestInput {
        @InvocableVariable(required=true)
        public InsuranceMemberInput memberData;
    }

    /**
     * @description Returns the captured values from the user back to Agentforce
     */
    @InvocableMethod(label='Get Insurance Member ID' description='Ask if Existing Member and Get Member ID with optional Employer')
    public static List<InsuranceMemberResult> getInsuranceMemberId(List<InsuranceMemberRequestInput> requests) {
        List<InsuranceMemberResult> responses = new List<InsuranceMemberResult>();
        
        try {
            for(InsuranceMemberRequestInput req : requests) {
                InsuranceMemberResult res = new InsuranceMemberResult();
                res.existingMember = req.memberData.existingMember;
                res.memberId = req.memberData.memberId;
                res.memberSummary = req.memberData.memberSummary;
                res.selectedSchemeCategory = req.memberData.selectedSchemeCategory;
                res.selectedEmployer = req.memberData.selectedEmployer;
                
                responses.add(res);
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getInsuranceMemberId: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return responses;
    }

    /**
     * @description Fetches Employer names based on Scheme Category. Uses a Set to ensure distinct Sub_Topic__c values.
     * @param schemeCategory The selected Scheme Category key value.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getEmployers(String schemeCategory) {
        Set<String> uniqueEmployers = new Set<String>();
        
        try {
            if (String.isNotBlank(schemeCategory)) {
                // Querying mapped documents and filtering out nulls to extract Employer Names
                for (Topic_Document_Mapping__c tdm : [
                    SELECT Sub_Topic__c 
                    FROM Topic_Document_Mapping__c 
                    WHERE Key_field_value__c = :schemeCategory  AND Topic__c = 'Insurance'
                    AND Sub_Topic__c != null AND Sub_Topic__c != 'General Insurance'
                ]) {
                    uniqueEmployers.add(tdm.Sub_Topic__c);
                }
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching employers: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        // Return as List for LWC iteration
        return new List<String>(uniqueEmployers);
    }
}
