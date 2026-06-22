import { LightningElement, api } from 'lwc';
import searchDocuments from '@salesforce/apex/AF_GetL2DocumentsService.searchDocuments';

/**
 * Editor CLT for the AF_GetL2Documents action's L2DocumentRequest input.
 *
 * The agent pre-fills `value.schemeCategory` and `value.selectedTopic` from
 * conversation context before this component ever renders (those two
 * fields are NOT marked "Collect data from user" on the action). This
 * component uses them to fetch the matching documents directly via Apex,
 * then lets the user pick one and submit -- which sends the COMPLETE
 * object (including the user's selection) back to the agent via
 * `valuechange`, which is what the platform listens for to run the action.
 */
export default class L2DocumentEditor extends LightningElement {
    documentOptions = [];
    selectedFilePath;
    selectedDocumentName;
    isLoading = true;

    _value = {};

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val || {};
        this.loadDocuments();
    }

    async loadDocuments() {
        this.isLoading = true;
        try {
            const options = await searchDocuments({
                schemeCategory: this._value.schemeCategory,
                selectedTopic: this._value.selectedTopic
            });
            this.documentOptions = (options || []).map((o) => ({
                label: o.label,
                value: o.value
            }));
        } catch (e) {
            this.documentOptions = [];
            // eslint-disable-next-line no-console
            console.error('Error loading L2 documents', e);
        } finally {
            this.isLoading = false;
        }
    }

    get hasNoDocuments() {
        return !this.isLoading && this.documentOptions.length === 0;
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
        const updatedValue = {
            ...this._value,
            selectedDocumentName: this.selectedDocumentName,
            selectedFilePath: this.selectedFilePath
        };

        // The platform listens for this event to capture the form data
        // and forward it as the input to the AF_GetL2Documents action.
        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: updatedValue }
            })
        );
    }
}
