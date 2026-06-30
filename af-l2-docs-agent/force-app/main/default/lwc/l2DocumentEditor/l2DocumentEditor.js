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
    set value(incoming) {
        this._value = incoming;
        if (!incoming) return;

        // If this push is just Agentforce echoing back the exact value we
        // ourselves dispatched a moment ago, our local state is already
        // correct - skip re-hydrating so a stale echo can't clobber it.
        if (this.isEchoOfLastDispatch(incoming)) {
            return;
        }

        this.existingMember = incoming.existingMember || false;
        this.isSelected     = this.existingMember;
        this.memberId       = incoming.memberId || "";
        this.memberSummary  = incoming.memberSummary || "";
        this.selectedEmployer = incoming.selectedEmployer || "";

        if (incoming.products && incoming.products.length) {
            this.products = incoming.products;
        }

        this.selectedSchemeCategory = incoming.selectedSchemeCategory || "";
        
        // FIX: Prioritize the exact, unique product key from Agentforce if it exists, 
        // otherwise fall back to guessing via the category code.
        this.selectedProductKey = incoming.selectedProductKey || this.findProductKeyForCategory(this.selectedSchemeCategory);
    }
    _value;
    _dispatchDelay;        // debounce timer, used only for free-text typing
    _lastDispatchedValue;  // snapshot of the last payload WE sent, to detect echoes

    // ─── Internal State ──────────────────────────────────────────────────────
    existingMember  = false;
    memberId        = "";
    isSelected      = false;

    @track memberSummary  = "";
    @track products       = [];
    @track selectedSchemeCategory = "";   // actual scheme category code - sent to Agentforce / used for Apex
    @track selectedProductKey     = "";   // unique per-row key bound to the radio group (account number embedded)

    @track selectedEmployer = "";
    @track employerOptions  = [];

    // Cache of already-fetched employers, keyed by scheme category
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
            return {
                label: displayPart,
                value: item,
                // FIX: Explicitly evaluate and attach the boolean selected state 
                // so standard HTML inputs know when they are active
                selected: item === this.selectedProductKey 
            };
        });
    }

    // ─── Step 1: Toggle member-specific button ───────────────────────────────
    handleExistingMemberChange() {
        this.isSelected     = !this.isSelected;
        this.existingMember = this.isSelected;

        if (!this.existingMember) {
            this.resetState();
        }
        this.dispatchValueChangeEvent(true); // discrete click -> dispatch immediately
    }

    // ─── Step 2: Member ID input change ─────────────────────────────────────
    handleInputChange(event) {
        event.stopPropagation();
        this[event.target.name] = event.target.value;
        this.resetState();
        this.dispatchValueChangeEvent(); // typing -> keep the debounce
    }

    // Helper to clear out child state when ID or Member toggle changes
    resetState() {
        this.memberSummary   = "";
        this.products        = [];
        this.selectedSchemeCategory = "";
        this.selectedProductKey    = "";
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

            // Pre-fetch employers for all DISTINCT categories in one query.
            if (this.hasProducts) {
                this.isEmployerLoading = true;
                try {
                    const categoriesToFetch = [...new Set(
                        this.productOptions
                            .map(opt => {
                                const parts = opt.value.split(" -- ");
                                return parts[1] ? parts[1].trim() : "";
                            })
                            .filter(Boolean)
                    )];
                    if (categoriesToFetch.length > 0) {
                        this.employerMap = await getAllEmployers({ schemeCategories: categoriesToFetch });
                    }
                } catch (error) {
                    console.error('Error pre-fetching employers:', error);
                } finally {
                    this.isEmployerLoading = false;
                }
            }

            this.dispatchValueChangeEvent(true);

        } else if (status === "ERROR") {
            this.isLoading    = false;
            this.runFlow      = false;
            this.errorMessage = "Failed to retrieve member summary. Please try again.";
        }
    }

    // ─── Step 4: Product/category selection - unique key in, real category out ──
    async handleProductChange(event) {
        const selectedKey = event.detail.value; // unique raw product string (includes account number)
        this.selectedProductKey = selectedKey;

        // Pull the real scheme category code back out for everything that
        // actually depends on the category itself.
        const mainParts = selectedKey ? selectedKey.split(" -- ") : [];
        const newCategory = mainParts[1] ? mainParts[1].trim() : "";
        this.selectedSchemeCategory = newCategory;

        this.selectedEmployer = "";
        this.employerOptions = [];

        if (!newCategory) {
            this.dispatchValueChangeEvent(true);
            return;
        }

        if (Object.prototype.hasOwnProperty.call(this.employerMap, newCategory)) {
            // Already cached - apply instantly
            this.applyEmployerOptions(this.employerMap[newCategory]);
        } else {
            // Not cached yet - fetch just this category on demand
            this.isEmployerLoading = true;
            try {
                const result = await getAllEmployers({ schemeCategories: [newCategory] });
                this.employerMap = { ...this.employerMap, ...result };
                this.applyEmployerOptions(this.employerMap[newCategory] || []);
            } catch (error) {
                console.error('Error fetching employers for category ' + newCategory, error);
            } finally {
                this.isEmployerLoading = false;
            }
        }

        this.dispatchValueChangeEvent(true); // discrete click -> dispatch immediately
    }

    applyEmployerOptions(employers) {
        this.employerOptions = (employers || []).map(emp => ({
            label: emp,
            value: emp,
            selected: false
        }));
    }

    // ─── Helper: best-effort match a scheme category back to one of its
    // product rows
    findProductKeyForCategory(category) {
        if (!category) return "";
        const match = this.products.find(item => {
            const parts = item.split(" -- ");
            const cat = parts[1] ? parts[1].trim() : "";
            return cat === category;
        });
        return match || "";
    }

    // ─── Helper: is this incoming `value` push just Agentforce echoing back
    // what we ourselves last dispatched?
    isEchoOfLastDispatch(incoming) {
        if (!this._lastDispatchedValue) return false;
        
        // FIX: Added 'selectedProductKey' to the fields array so we evaluate 
        // echoes accurately against the unique account string.
        const fields = [
            'existingMember', 
            'memberId', 
            'memberSummary', 
            'selectedSchemeCategory', 
            'selectedEmployer',
            'selectedProductKey' 
        ];
        return fields.every(f => (incoming[f] ?? '') === (this._lastDispatchedValue[f] ?? ''));
    }

    // ─── Core: Dispatch value back to Agentforce ─────────────────────────────
    dispatchValueChangeEvent(immediate = false) {
        if (this._dispatchDelay) {
            clearTimeout(this._dispatchDelay);
        }

        const fire = () => {
            const payload = {
                existingMember:  this.existingMember,
                memberId:        this.memberId,
                memberSummary:   this.memberSummary,
                selectedSchemeCategory: this.selectedSchemeCategory,
                selectedEmployer: this.selectedEmployer,
                // FIX: Passed the unique exact key to Agentforce so it won't drop it
                selectedProductKey: this.selectedProductKey 
            };

            this._lastDispatchedValue = payload;
            this._value = { ...payload, products: this.products };

            this.dispatchEvent(
                new CustomEvent("valuechange", { detail: { value: payload } })
            );
        };

        if (immediate) {
            fire();
        } else {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this._dispatchDelay = setTimeout(fire, 150);
        }
    }
}
