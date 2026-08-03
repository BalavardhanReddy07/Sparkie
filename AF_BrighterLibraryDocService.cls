/**
* @description Service for getting the Insurance Member ID via Agentforce Custom Lightning Types.
* Contains wrappers for CLT data shapes and methods for fetching Employer Names.
*/
public with sharing class AF_InsuranceMemberInput {
    
    public class InsuranceMemberInput {
        @InvocableVariable(label='Existing Member')
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
        @InvocableVariable(label='Existing Member')
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
        @InvocableVariable(required=false)
        public InsuranceMemberInput memberData;
    }
    
    @InvocableMethod(label='Get Insurance Member ID' description='Ask if Existing Member and Get Member ID with optional Employer')
    public static List<InsuranceMemberResult> getInsuranceMemberId(List<InsuranceMemberRequestInput> requests) {
        List<InsuranceMemberResult> responses = new List<InsuranceMemberResult>();
        
        try {
            InsuranceMemberResult res = new InsuranceMemberResult();
            
            res.existingMember = false;
            res.memberId = '';
            res.memberSummary = '';
            res.selectedSchemeCategory = '';
            res.selectedEmployer = '';
            if (requests[0].memberData != null){
                res.existingMember = requests[0].memberData.existingMember;
                res.memberId = requests[0].memberData.memberId;
                res.memberSummary = requests[0].memberData.memberSummary;
                res.selectedSchemeCategory = requests[0].memberData.selectedSchemeCategory;
                res.selectedEmployer = requests[0].memberData.selectedEmployer;
            }                
            responses.add(res);
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
                    AND Sub_Topic__c != 'Member Specific Products'
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


LWC/////////////////////////////////////////////////
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

            <!-- Loading Spinner for Flow -->
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

            <!-- Step 3: Flow (hidden, runs same flow as existing) -->
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
                            label="Select the account to ask questions."
                            name="productSelection"
                            options={productOptions}
                            value={selectedAccountNumber}
                            type="radio"
                            onchange={handleProductChange}
                            disabled={readOnly}>
                        </lightning-radio-group>
                    </template>
                </div>
            </template>

            <!-- NEW: Loading Spinner for Employer Query -->
            <template if:true={isEmployerLoading}>
                <div class="slds-m-top_medium slds-align_absolute-center">
                    <lightning-spinner alternative-text="Initializing Options..." size="small"></lightning-spinner>
                </div>
            </template>

            <!-- NEW: Employer Selection UI -->
            <template if:true={hasEmployers}>
                <div class="slds-m-top_large">
                    <h2 class="slds-text-heading_small slds-m-bottom_small">Select Employer</h2>
                        <p class="slds-text-body_x-small slds-text-color_weak slds-m-bottom_small">
                            You must select an employer to get the relevant response
                        </p>
                    <div class="slds-grid slds-wrap slds-gutters_x-small">
                        <template for:each={employerOptions} for:item="emp">
                            <div key={emp.value} class="slds-col slds-m-bottom_small">
                                <lightning-button-stateful
                                    label-when-off={emp.label}
                                    label-when-on={emp.label}
                                    icon-name-when-on="utility:check"
                                    selected={emp.selected}
                                    data-value={emp.value}
                                    onclick={handleEmployerSelection}
                                    disabled={readOnly}>
                                </lightning-button-stateful>
                            </div>
                        </template>
                    </div>
                </div>
            </template>

        </div>
    </lightning-card>
</template>


import { api, LightningElement, track } from "lwc";
import getAllEmployers from '@salesforce/apex/AF_InsuranceMemberInput.getAllEmployers';

export default class InsuranceMemberInput extends LightningElement {

    // ─── API: readOnly ───────────────────────────────────────────────────────
    @api
    get readOnly() { return this._readOnly; }
    set readOnly(value) { this._readOnly = value; }
    _readOnly = false;

    // ─── API: value (Agentforce state management) ────────────────────────────
    @api
    get value() { return this._value; }
    set value(value) {
        this._value = value;
        if (value) {
            this.existingMember = value.existingMember || false;
            this.isSelected     = value.existingMember || false;
            this.memberId       = value.memberId       || "";
            this.selectedSchemeCategory = value.selectedSchemeCategory || "";
            this.selectedAccountNumber  = value.selectedAccountNumber  || "";
            this.selectedEmployer = value.selectedEmployer || "";
            this.memberSummary = value.memberSummary || "";
            this.products = value.products || [];
        }
    }
    _value;
    _dispatchDelay; // Tracks the debounce timeout to prevent Agentforce race conditions

    // ─── Internal State ──────────────────────────────────────────────────────
    existingMember  = false;
    memberId        = "";
    isSelected      = false;

    @track memberSummary  = "";      
    @track products       = [];      
    @track selectedSchemeCategory = "";
    @track selectedAccountNumber = ""; // Unique radio value — the account identifier
    
    @track selectedEmployer = "";
    @track employerOptions = [];
    
    // Store the pre-fetched employers mapped by category
    employerMap = {}; 
    
    isEmployerLoading = false;
    isLoading    = false;
    runFlow      = false;
    errorMessage = "";

    // ─── Computed helpers ────────────────────────────────────────────────────
    get flowInputVariables() {
        return [{ name: "memberId", type: "String", value: this.memberId }];
    }

    get isExistingMember() { return this.existingMember === true; }
    get isFetchDisabled() { return !this.memberId || this.memberId.trim() === "" || this.isLoading || this.readOnly; }
    get hasMemberSummary() { return !!this.memberSummary; }
    get hasProducts() { return this.products && this.products.length > 0; }
    get hasEmployers() { return this.employerOptions && this.employerOptions.length > 0; }

    get productOptions() {
        return this.products.map((item) => {
            const mainParts = item.split(" -- ");
            const displayPart = mainParts[0] ? mainParts[0].trim() : item;
            const schemeCategory = mainParts[1] ? mainParts[1].trim() : "";
            // Use the account identifier (displayPart) as the unique radio value
            // so that two accounts sharing the same scheme category stay independently selectable.
            return { label: displayPart, value: displayPart, schemeCategory: schemeCategory };
        });
    }   

    // ─── Step 1: Toggle member-specific button ───────────────────────────────
    handleExistingMemberChange() {
        this.isSelected     = !this.isSelected;
        this.existingMember = this.isSelected;

        if (!this.existingMember) {
            this.resetState();
        }
        this.dispatchValueChangeEvent();
    }

    // ─── Step 2: Member ID input change ─────────────────────────────────────
    handleInputChange(event) {
        event.stopPropagation();
        this[event.target.name] = event.target.value;
        this.resetState();
        this.dispatchValueChangeEvent();
    }
    
    // Helper to clear out child state when ID or Member toggle changes
    resetState() {
        this.memberSummary   = "";
        this.products        = [];
        this.selectedSchemeCategory = "";
        this.selectedAccountNumber  = "";
        this.selectedEmployer = "";
        this.employerOptions = [];
        this.employerMap     = {};
        this.runFlow         = false;
        this.errorMessage    = "";
    }

    // ─── Step 3: Launch the flow to fetch member summary ────────────────────
    handleGetSummary() {
        if (!this.memberId || this.memberId.trim() === "") return;

        this.isLoading    = true;
        this.resetState();

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => { this.runFlow = true; }, 0);
    }

    // ─── Step 3b: Handle flow completion & PRE-FETCH EMPLOYERS ───────────────
    async handleFlowStatusChange(event) {
        const { status, outputVariables } = event.detail;

        if (status === "FINISHED" || status === "FINISHED_SCREEN") {
            this.isLoading = false;
            this.runFlow   = false;

            // 1. Process standard flow outputs
            if (outputVariables && outputVariables.length > 0) {
                const summaryVar  = outputVariables.find((v) => v.name === "memberSummaryResponse");
                const productsVar = outputVariables.find((v) => v.name === "schemeCategoryList");

                this.memberSummary = summaryVar ? summaryVar.value : "Summary not available.";

                if (productsVar && productsVar.value) {
                    let rawValue = productsVar.value;
                    if (Array.isArray(rawValue)) {
                        this.products = rawValue;
                    } else {
                        rawValue = rawValue.replace(/^\[|\]$/g, "");
                        this.products = rawValue.split(",").map((p) => p.trim()).filter(Boolean);
                    }
                }
            } else {
                this.memberSummary = "No summary returned by the flow.";
            }
            
            // 2. Pre-Fetch Employers immediately after flow finishes
            if (this.hasProducts) {
                this.isEmployerLoading = true;
                try {
                    // Extract unique Scheme Category values (NOT the radio value which is now the account number)
                    const categoriesToFetch = [...new Set(this.productOptions.map(opt => opt.schemeCategory).filter(Boolean))];
                    
                    if(categoriesToFetch.length > 0) {
                        this.employerMap = await getAllEmployers({ schemeCategories: categoriesToFetch });
                    }
                } catch (error) {
                    console.error('Error pre-fetching employers:', error);
                } finally {
                    this.isEmployerLoading = false;
                }
            }

            this.dispatchValueChangeEvent();

        } else if (status === "ERROR") {
            this.isLoading    = false;
            this.runFlow      = false;
            this.errorMessage = "Failed to retrieve member summary. Please try again.";
        }
    }

    // ─── Step 4: Product selection (Sync UI update) ─────────────────────────
    handleProductChange(event) {
        // event.detail.value is now the unique account identifier (displayPart)
        this.selectedAccountNumber = event.detail.value;

        // Resolve the Scheme Category from the selected account number
        const matchedOption = this.productOptions.find(opt => opt.value === this.selectedAccountNumber);
        this.selectedSchemeCategory = matchedOption ? matchedOption.schemeCategory : "";

        this.selectedEmployer = ""; 
        this.employerOptions = [];
        
        // Render employer buttons instantly using the pre-fetched map (keyed by Scheme Category)
        const employers = this.employerMap[this.selectedSchemeCategory] || [];
        
        if (employers.length > 0) {
            this.employerOptions = employers.map(emp => ({
                label: emp,
                value: emp,
                selected: false
            }));
        }

        this.dispatchValueChangeEvent();
    }

    // ─── Step 5: Employer Selection handler ─────────────────────────────────
    handleEmployerSelection(event) {
        const selectedVal = event.target.dataset.value;
        this.selectedEmployer = selectedVal;

        // Toggle state visually so only one employer shows as selected
        this.employerOptions = this.employerOptions.map(emp => ({
            ...emp,
            selected: emp.value === selectedVal
        }));
        
        this.dispatchValueChangeEvent();
    }

    // ─── Core: Dispatch value back to Agentforce (DEBOUNCED) ────────────────
    dispatchValueChangeEvent() {
        // Clear the previous timeout if the user rapidly clicks
        if (this._dispatchDelay) {
            clearTimeout(this._dispatchDelay);
        }

        // Wait 150ms before firing to prevent Agentforce state from flickering
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._dispatchDelay = setTimeout(() => {
            // Keep selectedAccountNumber in _value for internal UI state (radio binding)
            // but do NOT dispatch it — the Apex InsuranceMemberInput class has no such field.
            const currentValue = {
                existingMember:  this.existingMember,
                memberId:        this.memberId,
                memberSummary:   this.memberSummary,
                selectedSchemeCategory: this.selectedSchemeCategory,
                selectedAccountNumber:  this.selectedAccountNumber, // internal only
                selectedEmployer: this.selectedEmployer,
                products: this.products,
            };
            this._value = currentValue;
            
            // Only dispatch fields that exist in the Agentforce Flow/Apex Invocable variables
            this.dispatchEvent(
                new CustomEvent("valuechange", {
                    detail: {
                        value: {
                            existingMember:  this.existingMember,
                            memberId:        this.memberId,
                            memberSummary:   this.memberSummary,
                            selectedSchemeCategory: this.selectedSchemeCategory,
                            selectedEmployer: this.selectedEmployer
                        },
                    },
                })
            );
        }, 150);
    }
}

