    <template>
        <div class="slds-box slds-theme_default l2-doc-selector">
            <lightning-input
                type="checkbox"
                label="Select All"
                checked={allSelected}
                indeterminate={someSelectedButNotAll}
                onchange={handleSelectAllChange}
            ></lightning-input>

        <ul class="slds-list_vertical slds-m-top_small">
            <template for:each={items} for:item="item">
                <li key={item.recordId} class="slds-p-vertical_x-small">
                    <lightning-input
                        type="checkbox"
                        label={item.documentName}
                        checked={item.checked}
                        data-id={item.recordId}
                        onchange={handleItemChange}
                    ></lightning-input>

                    <template if:true={item.checked}>
                        <template if:true={item.hasWarning}>
                            <div class="slds-text-color_error slds-text-body_small slds-p-left_large slds-p-top_xx-small">
                                ⚠ {item.warningText}
                            </div>
                        </template>
                    </template>
                </li>
            </template>
        </ul>
    </div>
    </template>
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    import { LightningElement, api } from 'lwc';

    export default class L2DocumentChecklistEditor extends LightningElement {
        _value = { documents: [] };
        items = [];
        selectedIds = new Set();

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val || { documents: [] };
        this.items = (this._value.documents || []).map((d) => ({
            ...d,
            checked: false
        }));
        this.selectedIds = new Set();
    }

    get allSelected() {
        return this.items.length > 0 && this.selectedIds.size === this.items.length;
    }

    get someSelectedButNotAll() {
        return this.selectedIds.size > 0 && this.selectedIds.size < this.items.length;
    }

    get visibleWarnings() {
        return this.items.filter((i) => i.checked && i.hasWarning);
    }

    handleSelectAllChange(event) {
        const checked = event.target.checked;
        this.selectedIds = checked
            ? new Set(this.items.map((i) => i.recordId))
            : new Set();
        this.items = this.items.map((i) => ({ ...i, checked }));
        this.emitChange();
    }

    handleItemChange(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;

        if (checked) {
            this.selectedIds.add(id);
        } else {
            this.selectedIds.delete(id);
        }

        this.items = this.items.map((i) =>
            i.recordId === id ? { ...i, checked } : i
        );
        this.emitChange();
    }

    emitChange() {
        // Field name MUST match AF_L2DocumentSelectionService.SelectionRequest.selectedRecordIds
        const selectedRecordIds = this.items
            .filter((i) => this.selectedIds.has(i.recordId))
            .map((i) => i.recordId);

        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { value: { selectedRecordIds } }
            })
        );
    }
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    <?xml version="1.0" encoding="UTF-8"?>
    <LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
        <apiVersion>62.0</apiVersion>
        <isExposed>true</isExposed>
        <targets>
            <target>lightning__AgentforceInput</target>
        </targets>
        <targetConfigs>
            <targetConfig targets="lightning__AgentforceInput">
                <property name="targetType" type="String" default="c__l2DocumentChecklist" />
            </targetConfig>
        </targetConfigs>
    </LightningComponentBundle>
