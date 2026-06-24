    import { LightningElement, api } from 'lwc';
    
    /**
     * Output CLT Renderer for the AF_GetL2Documents action.
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
    
        get documentOptions() {
            let rawOptions = [];
        
        if (Array.isArray(this._value)) {
            rawOptions = this._value;
        } else if (this._value && this._value.documentOptions) {
            rawOptions = this._value.documentOptions;
        }

        const displayOptions = [];
        rawOptions.forEach(opt => {
            // Filter out any smuggled IDs if you left them in Apex, otherwise just map normally
            if (opt.label !== 'HIDDEN_SESSION_ID') {
                displayOptions.push({
                    label: opt.label,
                    value: opt.value
                });
            }
        });
        
        return displayOptions;
    }

    get hasNoDocuments() {
        return this.documentOptions.length === 0;
    }

    get isSubmitDisabled() {
        return !this.selectedFilePath || this.isSubmitting;
    }

    handleSelect(event) {
        this.selectedFilePath = event.detail.value;
        const match = this.documentOptions.find((o) => o.value === this.selectedFilePath);
        this.selectedDocumentName = match ? match.label : '';
        this.flowOutputMessage = null;
    }

    handleSubmit() {
        this.isSubmitting = true;

        try {
            // 1. Package the exact properties mapped in your AgentScript YAML
            const payload = {
                selectedFilePath: this.selectedFilePath,
                selectedDocumentName: this.selectedDocumentName
            };

            // 2. Dispatch the native event back to the Agent container
            // This triggers Agentforce to automatically set @variables.SelectedL2Document = @outputs.selectedFilePath
            this.dispatchEvent(new CustomEvent('valuechange', {
                detail: { 
                    value: payload 
                }
            }));

            // 3. Optional: Trigger a message to nudge the LLM forward
            this.dispatchEvent(new CustomEvent('sendmessage', {
                detail: { 
                    message: `I have selected the document: ${this.selectedDocumentName}. Please proceed.` 
                }
            }));
            
            this.flowOutputMessage = "Success! Document loaded. Please ask your questions.";
        } catch (error) {
            console.error('Error selecting document:', error);
            this.flowOutputMessage = 'An error occurred while selecting the document.';
        } finally {
            this.isSubmitting = false;
        }
    }
    }
