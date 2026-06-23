import { LightningElement, api } from 'lwc';
import runL2SearchFlow from '@salesforce/apex/AF_GetL2DocumentsService.runL2SearchFlow';

/**
 * Output CLT Renderer for the AF_GetL2Documents action.
 */
export default class L2DocumentEditor extends LightningElement {
    selectedFilePath;
    selectedDocumentName;
    isSubmitting = false;
    flowOutputMessage;
    
    // Holds the active V6 Session ID intercepted from the Apex array
    hiddenSessionId = null;

    _value = {};

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val ? JSON.parse(JSON.stringify(val)) : {};
    }

    get debugData() {
        return JSON.stringify(this._value);
    }

    get documentOptions() {
        let rawOptions = [];
        
        // Handle Agentforce direct array vs wrapper object injection
        if (Array.isArray(this._value)) {
            rawOptions = this._value;
        } else if (this._value && this._value.documentOptions) {
            rawOptions = this._value.documentOptions;
        }

        const displayOptions = [];
        
        // --- INTERCEPTOR LOGIC ---
        // Strip out the hidden session ID so it never shows in the UI combobox
        rawOptions.forEach(opt => {
            if (opt.label === 'HIDDEN_SESSION_ID') {
                this.hiddenSessionId = opt.value;
            } else {
                displayOptions.push({
                    label: opt.label,
                    value: opt.value
                });
            }
        });
        
        return displayOptions;
    }

    get hasNoDocuments() {
        // Evaluate based on the filtered options, not the raw array
        return this.documentOptions.length === 0;
    }

    get isSubmitDisabled() {
        return !this.selectedFilePath || this.isSubmitting;
    }

    handleSelect(event) {
        this.selectedFilePath = event.detail.value;
        const match = this.documentOptions.find((o) => o.value === this.selectedFilePath);
        this.selectedDocumentName = match ? match.label : '';
        
        // Clear previous message if user changes selection
        this.flowOutputMessage = null;
    }

    async handleSubmit() {
        this.isSubmitting = true;
        this.flowOutputMessage = null;

        try {
            // Pass both the selected path and the smuggled Session ID to the Flow
            const outputMessage = await runL2SearchFlow({ 
                documentFilePath: this.selectedFilePath,
                sessionId: this.hiddenSessionId
            });
            this.flowOutputMessage = outputMessage || 'Success! Please ask your questions.';
            
        } catch (error) {
            console.error('Error invoking flow:', error);
            this.flowOutputMessage = 'Error invoking flow: ' + (error.body ? error.body.message : error.message);
        } finally {
            this.isSubmitting = false;
        }
    }
}
