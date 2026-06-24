/**
 * @description Service for getting the MemberId via Custom Lightning Types.
 * Inner classes MemberInput and MemberResult are the CLT data shapes referenced
 * by memberInput/schema.json and memberResult/schema.json respectively.
 */
public with sharing class AF_MemberQuestionService {

    /**
     * @description Data shape for CLT input — referenced by memberInput/schema.json
     */
    public class MemberInput {
        @InvocableVariable(label='Existing Member' description='This indicates if the user is an existing member.' required=true)
        public Boolean existingMember;

        @InvocableVariable(label='Member ID' description='If the user is an existing member then this variable stores the member id (also known as client id).')
        public String memberId;

        @InvocableVariable(label='Member Summary' description='This variable stores the summary of the membership details.')
        public String memberSummary;

        @InvocableVariable(label='Selected Scheme Category' description='This variable stores scheme category value about which user is going to ask their question.')
        public String selectedSchemeCategory;

    }

    /**
     * @description Data shape for CLT output — referenced by memberResult/schema.json
     */
    public class MemberResult {

        @InvocableVariable(label='Existing Member' description='This indicates if the user is an existing member.' required=true)
        public Boolean existingMember;

        @InvocableVariable(label='Member ID' description='If the user is an existing member then this variable stores the member id (also known as client id).')
        public String memberId;

        @InvocableVariable(label='Member Summary' description='This variable stores the summary of the membership details.')
        public String memberSummary;

        @InvocableVariable(label='Selected Scheme Category' description='This variable stores scheme category value about which user is going to ask their question.')
        public String selectedSchemeCategory;
    }

    /**
     * @description Invocable request wrapper — field names must match AgentScript action input names
     */
    public class MemberRequestInput {
        @InvocableVariable(required=true)
        public MemberInput memberData;
    }

    /**
     * @description returns the captured values from the user
     */
    @InvocableMethod(label='Get Member ID' description='Ask if Existing Member and Get Member ID')
    public static List<MemberResult> getMemberId(List<MemberRequestInput> requests) {
        

        List<MemberResult> responses = new List<MemberResult>();
        MemberResult response = new MemberResult();
        try{
            response.memberId= requests[0].memberData.memberId;
            response.existingMember = requests[0].memberData.existingMember;
            response.memberSummary = requests[0].memberData.memberSummary;
            response.selectedSchemeCategory = requests[0].memberData.selectedSchemeCategory;
            
        //     if(requests[0].memberData.memberId != null){
        //         response.memberId = requests[0].memberData.memberId;

        //         Map<String, Object> flowInputs = new Map<String, Object>{
        //             'memberId'=> requests[0].memberData.memberId
        //         };

        //         Flow.Interview flowInterview = Flow.Interview.createInterview(MEMBER_SUMMARY_FLOW_API_NAME, flowInputs);
        //         flowInterview.start();
        //         system.debug('flowInterview.getVariableValue(memberSummaryResponse)'+ flowInterview.getVariableValue('memberSummaryResponse'));
        //         MemberResult result = new MemberResult();
        //         result.memberSummary = (String)  flowInterview.getVariableValue('memberSummaryResponse');
        //         response.member_summary = result;
        //     }
            responses.add(response);
        }
        catch(Exception e){
            system.debug(e.getCause()+ ' '+ e.getLineNumber()+ ' '+ e.getStackTraceString() + ' '+ e.getMessage());
        }
        
        return responses;
    }

}
