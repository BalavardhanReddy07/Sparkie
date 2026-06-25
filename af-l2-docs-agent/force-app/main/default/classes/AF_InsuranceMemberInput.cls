/**
 * @description Service for getting the Insurance Member ID via Agentforce Custom Lightning Types.
 * Contains wrappers for CLT data shapes and methods for fetching Employer Names.
 */
public with sharing class AF_InsuranceMemberInput {

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

    public class InsuranceMemberRequestInput {
        @InvocableVariable(required=true)
        public InsuranceMemberInput memberData;
    }

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

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getAllEmployers(List<String> schemeCategories) {
        System.debug('--- getAllEmployers APEX STARTED ---');
        System.debug('Input schemeCategories received from LWC: ' + schemeCategories);
        
        Map<String, Set<String>> empSetMap = new Map<String, Set<String>>();
        Map<String, List<String>> resultMap = new Map<String, List<String>>();
        
        try {
            if (schemeCategories != null && !schemeCategories.isEmpty()) {
                
                // Store the query results so we can debug the size
                List<Topic_Document_Mapping__c> mappings = [
                    SELECT Key_field_value__c, Sub_Topic__c 
                    FROM Topic_Document_Mapping__c 
                    WHERE Key_field_value__c IN :schemeCategories 
                    AND Topic__c = 'Insurance'
                    AND Sub_Topic__c != null 
                    AND Sub_Topic__c != 'General Insurance'
                ];
                
                System.debug('SOQL Query returned ' + mappings.size() + ' records.');

                for (Topic_Document_Mapping__c tdm : mappings) {
                    if (!empSetMap.containsKey(tdm.Key_field_value__c)) {
                        empSetMap.put(tdm.Key_field_value__c, new Set<String>());
                    }
                    empSetMap.get(tdm.Key_field_value__c).add(tdm.Sub_Topic__c);
                }
                
                for (String key : empSetMap.keySet()) {
                    resultMap.put(key, new List<String>(empSetMap.get(key)));
                }
            }
        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching employers: ' + e.getMessage());
        }
        
        System.debug('Final resultMap returning to LWC: ' + resultMap);
        System.debug('--- getAllEmployers APEX ENDED ---');
        
        return resultMap;
    }
}
