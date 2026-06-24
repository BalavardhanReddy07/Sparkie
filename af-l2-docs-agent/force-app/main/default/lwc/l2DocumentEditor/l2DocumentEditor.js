import { LightningElement, api } from 'lwc';
import runL2SearchFlow from '@salesforce/apex/AF_GetL2DocumentsService.runL2SearchFlow';

export default class L2DocumentEditor extends LightningElement {
    selectedFilePath;
    selectedDocumentName;
    
    // State management flags
    isSubmitting = false;
    isSuccessfullySubmitted = false;
    
    flowOutputMessage;
    hiddenSessionId = null;

    _value = {};

    @api
    get value() { return this._value; }
    set value(val) { this._value = val ? JSON.parse(JSON.stringify(val)) : {}; }

    get documentOptions() {
        let rawOptions = Array.isArray(this._value) ? this._value : (this._value?.documentOptions || []);
        const displayOptions = [];
        
        rawOptions.forEach(opt => {
            if (opt.label === 'HIDDEN_SESSION_ID') {
                this.hiddenSessionId = opt.value;
            } else {
                displayOptions.push({ label: opt.label, value: opt.value });
            }
        });
        
        return displayOptions;
    }

    get hasNoDocuments() {
        return this.documentOptions.length === 0;
    }

    // Permanently disable if successful, or temporarily disable during load/empty state
    get isSubmitDisabled() {
        return !this.selectedFilePath || this.isSubmitting || this.isSuccessfullySubmitted;
    }

    get submitButtonLabel() {
        if (this.isSuccessfullySubmitted) return 'Submitted';
        if (this.isSubmitting) return 'Submitting...';
        return 'Submit';
    }

    handleSelect(event) {
        this.selectedFilePath = event.detail.value;
        const match = this.documentOptions.find((o) => o.value === this.selectedFilePath);
        this.selectedDocumentName = match ? match.label : '';
        
        // Only clear the message if they haven't locked it in yet
        if (!this.isSuccessfullySubmitted) {
            this.flowOutputMessage = null;
        }
    }

    async handleSubmit() {
        this.isSubmitting = true;
        this.flowOutputMessage = null;

        try {
            // Trigger the Flow 
            const outputMessage = await runL2SearchFlow({ 
                documentFilePath: this.selectedFilePath,
                sessionId: this.hiddenSessionId
            });
            
            // Set the exact message passed back from the Flow
            this.flowOutputMessage = outputMessage;
            
            // Permanently lock the component since the Flow took over
            this.isSuccessfullySubmitted = true;
            
        } catch (error) {
            console.error('Error invoking flow:', error);
            this.flowOutputMessage = 'Error invoking flow: ' + (error.body ? error.body.message : error.message);
        } finally {
            this.isSubmitting = false;
        }
    }
}
