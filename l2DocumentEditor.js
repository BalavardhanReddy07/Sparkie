import { LightningElement, api } from 'lwc';
import runL2SearchFlow from '@salesforce/apex/AF_GetL2DocumentsService.runL2SearchFlow';

/**
 * Output CLT Renderer for the AF_GetL2Documents action.
 * Registered under sourceType: c__documentResult
 */
export default class L2DocumentEditor extends LightningElement {

    // --- Internal state ---
    selectedFilePath  = null;
    selectedDocumentName = null;
    isSubmitting      = false;
    flowOutputMessage = null;
    hiddenSessionId   = null;   // Smuggled session ID intercepted from Apex options array

    _value           = {};
    _documentOptions = [];      // Filtered display options (HIDDEN_SESSION_ID stripped out)

    // ─── @api value ──────────────────────────────────────────────────────────
    // Agentforce injects the action output here. We parse it once in the setter
    // so hiddenSessionId and _documentOptions are always ready before handleSubmit.
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val ? JSON.parse(JSON.stringify(val)) : {};

        // Accept either a direct array (Agentforce injects the list directly)
        // or a wrapper object with a documentOptions field.
        let rawOptions = [];
        if (Array.isArray(this._value)) {
            rawOptions = this._value;
        } else if (this._value && Array.isArray(this._value.documentOptions)) {
            rawOptions = this._value.documentOptions;
        }

        const displayOptions = [];
        this.hiddenSessionId = null; // reset on each new injection

        rawOptions.forEach(opt => {
            if (opt && opt.label === 'HIDDEN_SESSION_ID') {
                // Intercept the smuggled session ID — never surface it in the combobox
                this.hiddenSessionId = opt.value;
            } else if (opt && opt.label && opt.value) {
                displayOptions.push({ label: opt.label, value: opt.value });
            }
        });

        this._documentOptions = displayOptions;

        // Reset selection whenever new options arrive
        this.selectedFilePath    = null;
        this.selectedDocumentName = null;
        this.flowOutputMessage   = null;
    }

    // ─── Computed getters ────────────────────────────────────────────────────
    get documentOptions() {
        return this._documentOptions;
    }

    get hasNoDocuments() {
        return this._documentOptions.length === 0;
    }

    get isSubmitDisabled() {
        return !this.selectedFilePath || this.isSubmitting;
    }

    get selectedWarningMessage() {
        // Show a warning if the user hasn't picked anything yet after opening
        return null; // reserved for future validation messages
    }

    // ─── Handlers ────────────────────────────────────────────────────────────
    handleSelect(event) {
        this.selectedFilePath = event.detail.value;
        const match = this._documentOptions.find(o => o.value === this.selectedFilePath);
        this.selectedDocumentName = match ? match.label : '';
        this.flowOutputMessage = null;
    }

    async handleSubmit() {
        if (!this.selectedFilePath) return;

        this.isSubmitting      = true;
        this.flowOutputMessage = null;

        try {
            // 1. Call the Flow via Apex — updates SelectedL2Document agent variable
            //    using the session ID that was smuggled in through the options array.
            const outputMessage = await runL2SearchFlow({
                documentFilePath: this.selectedFilePath,
                sessionId: this.hiddenSessionId
            });

            this.flowOutputMessage =
                outputMessage || "Success! I've loaded the document. Please ask your questions.";

            // 2. Nudge the agent forward so it picks up the updated variable.
            this.dispatchEvent(
                new CustomEvent('sendmessage', {
                    detail: {
                        message: `I have selected the document: ${this.selectedDocumentName}. Please proceed.`
                    }
                })
            );

        } catch (error) {
            console.error('L2DocumentEditor — Flow error:', error);
            this.flowOutputMessage =
                'Error loading document: ' + (error.body ? error.body.message : error.message);
        } finally {
            this.isSubmitting = false;
        }
    }
}
