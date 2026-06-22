import { LightningElement, api } from 'lwc';

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

    _value = {};

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val || {};
    }

    get documentOptions() {
        if (!this._value.documentOptions) return [];
        return this._value.documentOptions.map(opt => ({
            label: opt.label,
            value: opt.value
        }));
    }

    get hasNoDocuments() {
        return !this._value.hasDocuments;
    }

    get isSubmitDisabled() {
        return !this.selectedFilePath;
    }

    handleSelect(event) {
        this.selectedFilePath = event.detail.value;
        const match = this.documentOptions.find((o) => o.value === this.selectedFilePath);
        this.selectedDocumentName = match ? match.label : '';
    }

    handleSubmit() {
        // TODO: Execute your Flow or dispatch agent message here.
        // Example logic to invoke a flow if you embed lightning-flow:
        // const flowParams = [
        //     { name: 'dataCloudL2FilePath', type: 'String', value: this.selectedFilePath }
        // ];
        // this.template.querySelector('lightning-flow').startFlow('Your_Flow_Api_Name', flowParams);
        
        console.log('User submitted document:', this.selectedDocumentName, this.selectedFilePath);
        
        // Note: For Output CLTs, standard agent platform flow does not inherently wait for 
        // a valuechange event from an output component. You must use Flow, standard platform 
        // events, or send a message back to the conversation.
    }
}
