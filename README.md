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



        <template>
    <lightning-card>
        <div class="slds-p-horizontal_medium slds-p-vertical_medium">

            <!-- Step 1: Member Specific Button -->
            <lightning-button-stateful
                label-when-off="Member Specific"
                label-when-on="Member Specific"
                icon-name-when-on="utility:check"
                selected={isSelected}
                disabled={readOnly}
                onclick={handleExistingMemberChange}>
            </lightning-button-stateful>

            <!-- Step 2: Member ID Input -->
            <template if:true={isExistingMember}>
                <div class="slds-m-top_medium">
                    <lightning-input
                        label="Enter Member Id"
                        name="memberId"
                        value={memberId}
                        type="text"
                        onchange={handleInputChange}
                        read-only={readOnly}>
                    </lightning-input>

                    <!-- Fetch Summary Button -->
                    <div class="slds-m-top_small">
                        <lightning-button
                            label="Get Member Summary"
                            variant="brand"
                            disabled={isFetchDisabled}
                            onclick={handleGetSummary}>
                        </lightning-button>
                    </div>
                </div>
            </template>

            <!-- Loading Spinner -->
            <template if:true={isLoading}>
                <div class="slds-m-top_medium slds-align_absolute-center">
                    <lightning-spinner alternative-text="Loading member summary..." size="small"></lightning-spinner>
                </div>
            </template>

            <!-- Error Message -->
            <template if:true={errorMessage}>
                <div class="slds-m-top_medium">
                    <p class="slds-text-color_error">{errorMessage}</p>
                </div>
            </template>

            <!-- Step 3: Flow (hidden, used to fetch member summary) -->
            <template if:true={runFlow}>
                <div class="slds-hide">
                    <lightning-flow
                        flow-api-name="Sparkie_Get_Member_Summary"
                        flow-input-variables={flowInputVariables}
                        onstatuschange={handleFlowStatusChange}>
                    </lightning-flow>
                </div>
            </template>

            <!-- Step 4: Member Summary Display + Product Selection -->
            <template if:true={hasMemberSummary}>
                <div class="slds-m-top_large">
                    <div class="slds-box slds-theme_shade slds-m-bottom_medium">
                        <h2 class="slds-text-heading_small slds-m-bottom_small">Member Summary</h2>
                        <lightning-formatted-rich-text value={memberSummary}></lightning-formatted-rich-text>
                    </div>

                    <!-- Product Selection via Radio Buttons -->
                    <template if:true={hasProducts}>
                        <lightning-radio-group
                            label="Select a product for your questions."
                            name="productSelection"
                            options={productOptions}
                            value={selectedSchemeCategory}
                            type="radio"
                            onchange={handleProductChange}
                            disabled={readOnly}>
                        </lightning-radio-group>
                    </template>
                </div>
            </template>

        </div>
    </lightning-card>
</template>

import { api, LightningElement, track } from "lwc";

export default class MenuFilter extends LightningElement {

    // ─── API: readOnly ───────────────────────────────────────────────────────
    @api
    get readOnly() {
        return this._readOnly;
    }
    set readOnly(value) {
        this._readOnly = value;
    }
    _readOnly = false;

    // ─── API: value (used by Agentforce to read/set component state) ─────────
    @api
    get value() {
        return this._value;
    }
    set value(value) {
        this._value = value;
        if (value) {
            this.existingMember = value.existingMember || false;
            this.isSelected     = value.existingMember || false;
            this.memberId       = value.memberId       || "";
            this.selectedSchemeCategory = value.selectedSchemeCategory || "";
            this.memberSummary = value.memberSummary || "";
            this.products = value.products || [];
        }
    }
    _value;

    // ─── Internal State ──────────────────────────────────────────────────────
    existingMember  = false;
    memberId        = "";
    isSelected      = false;

    @track memberSummary  = "";      // plain-text summary returned by flow
    @track products       = [];      // array of product name strings
    @track selectedSchemeCategory = "";

    isLoading    = false;
    runFlow      = false;
    errorMessage = "";

    // ─── Flow input variables ────────────────────────────────────────────────
    get flowInputVariables() {
        return [
            { name: "memberId", type: "String", value: this.memberId }
        ];
    }

    // ─── Computed helpers ────────────────────────────────────────────────────
    get isExistingMember() {
        return this.existingMember === true;
    }

    get isFetchDisabled() {
        return !this.memberId || this.memberId.trim() === "" || this.isLoading || this.readOnly;
    }

    get hasMemberSummary() {
        return !!this.memberSummary;
    }

    get hasProducts() {
        return this.products && this.products.length > 0;
    }

    /** Map products array → radio-group options */
    get productOptions() {
        return this.products.map((name) => ({ label: name, value: name }));
    }

    // ─── Step 1: Toggle member-specific button ───────────────────────────────
    handleExistingMemberChange() {
        this.isSelected     = !this.isSelected;
        this.existingMember = this.isSelected;

        // Reset downstream state when toggled off
        if (!this.existingMember) {
            this.memberId        = "";
            this.memberSummary   = "";
            this.products        = [];
            this.selectedSchemeCategory = "";
            this.runFlow         = false;
            this.errorMessage    = "";
        }

        this.dispatchValueChangeEvent();
    }

    // ─── Step 2: Member ID input change ─────────────────────────────────────
    handleInputChange(event) {
        event.stopPropagation();
        const { name, value } = event.target;
        this[name] = value;

        // Clear stale summary when member ID changes
        this.memberSummary   = "";
        this.products        = [];
        this.selectedSchemeCategory = "";
        this.runFlow         = false;
        this.errorMessage    = "";

        this.dispatchValueChangeEvent();
    }

    // ─── Step 3: Launch the flow to fetch member summary ────────────────────
    handleGetSummary() {
        if (!this.memberId || this.memberId.trim() === "") return;

        this.isLoading    = true;
        this.errorMessage = "";
        this.memberSummary   = "";
        this.products        = [];
        this.selectedSchemeCategory = "";
        this.runFlow         = false;   // reset so flow rerenders fresh

        // Use a micro-task delay to allow the DOM to clear the old flow first
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.runFlow = true;
        }, 0);
    }

    // ─── Step 3b: Handle flow completion ────────────────────────────────────
    /**
     * The flow must have two output variables:
     *   - MemberSummary  (String) – human-readable summary text
     *   - ProductNames   (String) – comma-separated product names
     *                               e.g. "Plan A,Plan B,Plan C"
     */
    handleFlowStatusChange(event) {
        const { status, outputVariables } = event.detail;

        if (status === "FINISHED" || status === "FINISHED_SCREEN") {
            this.isLoading = false;
            this.runFlow   = false;

            if (outputVariables && outputVariables.length > 0) {
                const summaryVar  = outputVariables.find((v) => v.name === "memberSummaryResponse");
                const productsVar = outputVariables.find((v) => v.name === "schemeCategoryList");

                this.memberSummary = summaryVar  ? summaryVar.value  : "Summary not available.";

                if (productsVar && productsVar.value) {
                    // Accept either a comma-separated string or an array
                    this.products = Array.isArray(productsVar.value)
                        ? productsVar.value
                        : productsVar.value.split(",").map((p) => p.trim()).filter(Boolean);
                }
            } else {
                this.memberSummary = "No summary returned by the flow.";
            }

        } else if (status === "ERROR") {
            this.isLoading    = false;
            this.runFlow      = false;
            this.errorMessage = "Failed to retrieve member summary. Please try again.";
        }
    }

    // ─── Step 4: Product selection ───────────────────────────────────────────
    handleProductChange(event) {
        this.selectedSchemeCategory = event.detail.value;
        this.dispatchValueChangeEvent();
    }

    // ─── Dispatch value back to Agentforce (same pattern as original) ────────
    dispatchValueChangeEvent() {
        const currentValue = {
            existingMember:  this.existingMember,
            memberId:        this.memberId,
            memberSummary:   this.memberSummary,
            selectedSchemeCategory: this.selectedSchemeCategory,
            products: this.products,
        }
        this._value = currentValue;
        this.dispatchEvent(
            new CustomEvent("valuechange", {
                detail: {
                    value: {
                        existingMember:  this.existingMember,
                        memberId:        this.memberId,
                        memberSummary:   this.memberSummary,
                        selectedSchemeCategory: this.selectedSchemeCategory,
                    },
                },
            })
        );
    }
}


    }

}
