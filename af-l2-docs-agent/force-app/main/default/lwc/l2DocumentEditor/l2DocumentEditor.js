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
        // correct (and possibly MORE current - e.g. the user clicked again
        // since we dispatched). Skip re-hydrating so we don't clobber it.
        if (this.isEchoOfLastDispatch(incoming)) {
            return;
        }

        // Genuine external update (first load, conversation reset, etc.)
        this.existingMember = incoming.existingMember || false;
        this.isSelected     = this.existingMember;
        this.memberId       = incoming.memberId || "";
        this.memberSummary  = incoming.memberSummary || "";
        this.selectedSchemeCategory = incoming.selectedSchemeCategory || "";
        this.selectedEmployer       = incoming.selectedEmployer || "";

        // products isn't part of the outbound contract, so only adopt it
        // when explicitly provided - otherwise keep what we fetched locally.
        if (incoming.products && incoming.products.length) {
            this.products = incoming.products;
        }
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
    @track selectedSchemeCategory = "";

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
            const schemeCategory = mainParts[1] ? mainParts[1].trim() : "";
            return { label: displayPart, value: schemeCategory };
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

            // Pre-fetch employers for ALL categories in one query (fast path
            // for the common case). Any category not covered here just falls
            // back to an on-demand fetch in handleProductChange below.
            if (this.hasProducts) {
                this.isEmployerLoading = true;
                try {
                    const categoriesToFetch = this.productOptions.map(opt => opt.value).filter(Boolean);
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

    // ─── Step 4: Product/category selection - free switching, cache + on-demand fetch ──
    async handleProductChange(event) {
        const newCategory = event.detail.value;

        // Always clear the old employer selection first so a stale employer
        // from the previous category can never linger on screen.
        this.selectedSchemeCategory = newCategory;
        this.selectedEmployer = "";
        this.employerOptions = [];

        if (!newCategory) {
            this.dispatchValueChangeEvent(true);
            return;
        }

        if (Object.prototype.hasOwnProperty.call(this.employerMap, newCategory)) {
            // Already cached (from the pre-fetch, or a previous visit to this
            // category) - apply instantly, no server round trip.
            this.applyEmployerOptions(this.employerMap[newCategory]);
        } else {
            // Not cached yet - fetch just this category on demand and cache
            // the result so re-selecting it later is instant too.
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

    // ─── Step 5: Employer Selection handler ─────────────────────────────────
    handleEmployerSelection(event) {
        const selectedVal = event.target.dataset.value;
        this.selectedEmployer = selectedVal;

        this.employerOptions = this.employerOptions.map(emp => ({
            ...emp,
            selected: emp.value === selectedVal
        }));

        this.dispatchValueChangeEvent(true); // discrete click -> dispatch immediately
    }

    // ─── Helper: is this incoming `value` push just Agentforce echoing back
    // what we ourselves last dispatched? ──────────────────────────────────────
    isEchoOfLastDispatch(incoming) {
        if (!this._lastDispatchedValue) return false;
        const fields = ['existingMember', 'memberId', 'memberSummary', 'selectedSchemeCategory', 'selectedEmployer'];
        return fields.every(f => (incoming[f] ?? '') === (this._lastDispatchedValue[f] ?? ''));
    }

    // ─── Core: Dispatch value back to Agentforce ─────────────────────────────
    // immediate = true  -> discrete clicks (radio/button toggles). Fires
    //                      synchronously so there's no window for a stale
    //                      external push to land before the new selection
    //                      is recorded.
    // immediate = false -> free-text typing. Keeps a short debounce so we
    //                      don't dispatch on every keystroke.
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
