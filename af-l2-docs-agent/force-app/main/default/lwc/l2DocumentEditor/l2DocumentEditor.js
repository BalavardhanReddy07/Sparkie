import { LightningElement, api } from 'lwc';
import runL2SearchFlow from '@salesforce/apex/AF_GetL2DocumentsService.runL2SearchFlow';

/**
 * Output CLT Renderer for the AF_GetL2Documents action.
 *
 * The agent runs the Apex action, which queries the documents and returns
 * the L2DocumentResult. This component receives that result via `@api value`
 * and renders the combobox for the user to select.
 */
export default class L2DocumentEditor extends LightningElement {
    selectedFilePath;
    selectedDocumentName;
    isSubmitting = false;
    flowOutputMessage;

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
        // If Agentforce injects the array directly
        if (Array.isArray(this._value)) {
            return this._value.map(opt => ({
                label: opt.label,
                value: opt.value
            }));
        }
        // If Agentforce injects the wrapper object
        if (this._value && this._value.documentOptions) {
            return this._value.documentOptions.map(opt => ({
                label: opt.label,
                value: opt.value
            }));
        }
        return [];
    }

    get hasNoDocuments() {
        if (Array.isArray(this._value)) {
            return this._value.length === 0;
        }
        return !this._value || !this._value.hasDocuments;
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
            const outputMessage = await runL2SearchFlow({ 
                documentFilePath: this.selectedFilePath 
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
