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
