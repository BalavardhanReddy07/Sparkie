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
        if (!value) return;

        // If this push is just Agentforce echoing back the exact value we
        // ourselves just dispatched, our local state is already correct -
        // skip re-hydrating so a stale echo can't overwrite a selection the
        // user just made (this was causing the "selects the last option
        // first" bug).
        if (this.isEchoOfLastDispatch(value)) {
            return;
        }

        this.existingMember = value.existingMember || false;
        this.isSelected     = value.existingMember || false;
        this.memberId       = value.memberId       || "";
        this.selectedSchemeCategory = value.selectedSchemeCategory || "";
        this.selectedAccountNumber  = value.selectedAccountNumber  || "";
        this.memberSummary = value.memberSummary || "";
        this.products = value.products || [];
    }
    _value;
    _lastDispatchedValue; // snapshot of the last payload WE dispatched, used to detect echoes

    // ─── Internal State ──────────────────────────────────────────────────────
    existingMember  = false;
    memberId        = "";
    isSelected      = false;

    @track memberSummary  = "";      // plain-text summary returned by flow
    @track products       = [];      // array of product name strings
    @track selectedSchemeCategory = "";
    @track selectedAccountNumber = ""; // Unique radio value — the account identifier

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
        return this.products.map((item) => {
            // Step 1: Split off the Scheme Category (after " -- ")
            const mainParts = item.split(" -- ");
            const displayPart = mainParts[0] ? mainParts[0].trim() : item;
            const schemeCategory = mainParts[1] ? mainParts[1].trim() : "";

            // Step 2: Use the account identifier (displayPart) as the unique radio value
            // so that two accounts sharing the same scheme category stay independently selectable.
            return {
                label: displayPart,
                value: displayPart,
                schemeCategory: schemeCategory
            };
        });
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
            this.selectedAccountNumber  = "";
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
        this.selectedAccountNumber  = "";
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

                    let rawValue = productsVar.value;

                    if (Array.isArray(rawValue)) {
                        this.products = rawValue;
                    } else {
                        // ✅ Remove enclosing brackets [ ]
                        rawValue = rawValue.replace(/^\[|\]$/g, "");

                        // ✅ Split and trim safely
                        this.products = rawValue
                            .split(",")
                            .map((p) => p.trim())
                            .filter(Boolean);
                    }
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
        // event.detail.value is now the unique account identifier (displayPart)
        this.selectedAccountNumber = event.detail.value;

        // Resolve the Scheme Category from the selected account number
        const matchedOption = this.productOptions.find(opt => opt.value === this.selectedAccountNumber);
        this.selectedSchemeCategory = matchedOption ? matchedOption.schemeCategory : "";

        this.dispatchValueChangeEvent();
    }

    // ─── Helper: is this incoming `value` push just Agentforce echoing back
    // what we ourselves last dispatched? ──────────────────────────────────────
    isEchoOfLastDispatch(incoming) {
        if (!this._lastDispatchedValue) return false;
        const fields = ['existingMember', 'memberId', 'memberSummary', 'selectedSchemeCategory', 'selectedAccountNumber'];
        return fields.every(f => (incoming[f] ?? '') === (this._lastDispatchedValue[f] ?? ''));
    }

    // ─── Dispatch value back to Agentforce (same pattern as original) ────────
    dispatchValueChangeEvent() {
        const currentValue = {
            existingMember:  this.existingMember,
            memberId:        this.memberId,
            memberSummary:   this.memberSummary,
            selectedSchemeCategory: this.selectedSchemeCategory,
            selectedAccountNumber:  this.selectedAccountNumber,
            products: this.products,
        };
        this._value = currentValue;

        const dispatchedPayload = {
            existingMember:  this.existingMember,
            memberId:        this.memberId,
            memberSummary:   this.memberSummary,
            selectedSchemeCategory: this.selectedSchemeCategory,
            selectedAccountNumber:  this.selectedAccountNumber,
        };
        this._lastDispatchedValue = dispatchedPayload;

        this.dispatchEvent(
            new CustomEvent("valuechange", {
                detail: {
                    value: dispatchedPayload,
                },
            })
        );
    }
}
