import { api, LightningElement, track } from "lwc";
import getEmployers from '@salesforce/apex/AF_InsuranceMemberInput.getEmployers';

export default class InsuranceMemberInput extends LightningElement {

    // ─── API: readOnly ───────────────────────────────────────────────────────
    @api
    get readOnly() {
        return this._readOnly;
    }
    set readOnly(value) {
        this._readOnly = value;
    }
    _readOnly = false;

    // ─── API: value (Agentforce state management) ────────────────────────────
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
            this.selectedEmployer = value.selectedEmployer || "";
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
    
    // NEW State Trackers
    @track selectedEmployer = "";
    @track employerOptions = [];
    isEmployerLoading = false;

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

    get hasEmployers() {
        return this.employerOptions && this.employerOptions.length > 0;
    }

    /** Map products array → radio-group options */
    get productOptions() {
        return this.products.map((item) => {
            const mainParts = item.split(" -- ");
            const displayPart = mainParts[0] ? mainParts[0].trim() : item;
            const schemeCategory = mainParts[1] ? mainParts[1].trim() : "";

            return {
                label: displayPart,
                value: schemeCategory
            };
        });
    }   

    // ─── Step 1: Toggle member-specific button ───────────────────────────────
    handleExistingMemberChange() {
        this.isSelected     = !this.isSelected;
        this.existingMember = this.isSelected;

        if (!this.existingMember) {
            this.memberId        = "";
            this.memberSummary   = "";
            this.products        = [];
            this.selectedSchemeCategory = "";
            this.selectedEmployer = "";
            this.employerOptions = [];
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

        this.memberSummary   = "";
        this.products        = [];
        this.selectedSchemeCategory = "";
        this.selectedEmployer = "";
        this.employerOptions = [];
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
        this.selectedEmployer = "";
        this.employerOptions = [];
        this.runFlow         = false;  

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.runFlow = true;
        }, 0);
    }

    // ─── Step 3b: Handle flow completion ────────────────────────────────────
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
                    let rawValue = productsVar.value;

                    if (Array.isArray(rawValue)) {
                        this.products = rawValue;
                    } else {
                        rawValue = rawValue.replace(/^\[|\]$/g, "");
                        this.products = rawValue
                            .split(",")
                            .map((p) => p.trim())
                            .filter(Boolean);
                    }
                }
            } else {
                this.memberSummary = "No summary returned by the flow.";
            }
            
            // Sync up the summary and products back to the CLT framework
            this.dispatchValueChangeEvent();

        } else if (status === "ERROR") {
            this.isLoading    = false;
            this.runFlow      = false;
            this.errorMessage = "Failed to retrieve member summary. Please try again.";
        }
    }

    // ─── NEW: Step 4: Product selection (Onchange event fires query) ────────
    async handleProductChange(event) {
        this.selectedSchemeCategory = event.detail.value;
        this.selectedEmployer = ""; // Reset employer if scheme changes
        this.employerOptions = [];
        
        // Immediately dispatch so Agentforce has the Scheme Category even if they don't select an employer
        this.dispatchValueChangeEvent();

        // Show spinner during Apex fetch
        this.isEmployerLoading = true;

        try {
            // Call Apex to get employers mapped to this Scheme Category
            const employers = await getEmployers({ schemeCategory: this.selectedSchemeCategory });
            
            if (employers && employers.length > 0) {
                // Map to stateful button structure
                this.employerOptions = employers.map(emp => ({
                    label: emp,
                    value: emp,
                    selected: false
                }));
            }
        } catch (error) {
            console.error('Error fetching employers:', error);
        } finally {
            this.isEmployerLoading = false;
        }
    }

    // ─── NEW: Employer Selection handler ────────────────────────────────────
    handleEmployerSelection(event) {
        const selectedVal = event.target.dataset.value;
        this.selectedEmployer = selectedVal;

        // Toggle state visually so only one employer shows as selected
        this.employerOptions = this.employerOptions.map(emp => ({
            ...emp,
            selected: emp.value === selectedVal
        }));
        
        // Dispatch updated employer selection to Agentforce
        this.dispatchValueChangeEvent();
    }

    // ─── Core: Dispatch value back to Agentforce ────────────────────────────
    dispatchValueChangeEvent() {
        const currentValue = {
            existingMember:  this.existingMember,
            memberId:        this.memberId,
            memberSummary:   this.memberSummary,
            selectedSchemeCategory: this.selectedSchemeCategory,
            selectedEmployer: this.selectedEmployer,
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
                        selectedEmployer: this.selectedEmployer
                    },
                },
            })
        );
    }
}
