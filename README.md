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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
        /**
     * Supports the Level 2 (Additional Document) checkbox UI in Agentforce.
     * Does NOT modify AF_CollectionToJson or AF_HybridSearchService —
     * it only prepares input for them and consumes their output via Flow.
     */
    public with sharing class AF_L2DocumentSelectionService {
    
        // =====================================================================
        // ACTION 1: Return Additional Documents for the checkbox CLT
        // =====================================================================
        public class ListRequest {
            @InvocableVariable(required=true)
            public List<String> documentIds; // Additional_Document__c Ids resolved by Flow #2A
        }
    
        public class ListResponse {
            @InvocableVariable
            public List<DocumentOption> documents;
        }
    
        @JsonAccess(serializable='always' deserializable='always')
        public class DocumentOption {
            @InvocableVariable public String recordId;
            @InvocableVariable public String documentName;
            @InvocableVariable public String dataCloudFilePath;
            @InvocableVariable public String documentUrl;
            @InvocableVariable public Boolean hasWarning;
            @InvocableVariable public String warningText;
        }
    
        @InvocableMethod(
            label='Get Additional (L2) Document List'
            description='Returns Additional Documents with warning flags for the L2 checkbox selector.'
        )
        public static List<ListResponse> getAdditionalDocuments(List<ListRequest> requests) {
            ListRequest req = requests[0];
            ListResponse out = new ListResponse();
            out.documents = new List<DocumentOption>();
    
            if (req.documentIds == null || req.documentIds.isEmpty()) {
                return new List<ListResponse>{ out };
            }
    
            for (Document_Detail__c d : [
                SELECT Id, Name, Data_Cloud_File_Path__c, Document_URL__c, Warning_for_L2_document__c
                FROM Document_Detail__c
                WHERE Id IN :req.documentIds
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
            ]) {
                DocumentOption opt = new DocumentOption();
                opt.recordId           = d.Id;
                opt.documentName       = d.Name;
                opt.dataCloudFilePath  = d.Data_Cloud_File_Path__c;
                opt.documentUrl        = d.Document_URL__c;
                opt.hasWarning         = String.isNotBlank(d.Warning_for_L2_document__c);
                opt.warningText        = d.Warning_for_L2_document__c;
                out.documents.add(opt);
            }
    
            return new List<ListResponse>{ out };
        }
    
        // =====================================================================
        // ACTION 2: Take the user's selected docs, re-validate, hand off
        // =====================================================================
        public class SelectionRequest {
            @InvocableVariable(required=true)
            public List<String> selectedRecordIds; // Document_Detail__c Ids the user checked
            @InvocableVariable(required=true)
            public String inputQuestion; // original user question, passed through for the prompt
        }
    
        public class SelectionResponse {
            @InvocableVariable
            public String promptAnswer; // final text for the chat panel
            @InvocableVariable
            public List<String> activeWarnings; // non-empty warnings for the selected docs, if any
        }
    
        @InvocableMethod(
            label='Process L2 Document Selection'
            description='Validates selected Additional Documents and runs the existing CollectionToJson/HybridSearch pipeline via Flow.'
        )
        public static List<SelectionResponse> processSelection(List<SelectionRequest> requests) {
            SelectionRequest req = requests[0];
            SelectionResponse out = new SelectionResponse();
            out.activeWarnings = new List<String>();
    
            if (req.selectedRecordIds == null || req.selectedRecordIds.isEmpty()) {
                out.promptAnswer = 'No documents were selected. Please select at least one document.';
                return new List<SelectionResponse>{ out };
            }
    
            Map<Id, Document_Detail__c> docMap = new Map<Id, Document_Detail__c>(
                [SELECT Id, Name, Data_Cloud_File_Path__c, Warning_for_L2_document__c
                 FROM Document_Detail__c
                 WHERE Id IN :req.selectedRecordIds
                 WITH SECURITY_ENFORCED]
            );
    
            List<String> filePaths = new List<String>();
            for (Document_Detail__c d : docMap.values()) {
                if (String.isNotBlank(d.Data_Cloud_File_Path__c)) {
                    filePaths.add(d.Data_Cloud_File_Path__c);
                }
                if (String.isNotBlank(d.Warning_for_L2_document__c)) {
                    out.activeWarnings.add(d.Name + ': ' + d.Warning_for_L2_document__c);
                }
            }
    
            // Hand off to a flow that calls your UNCHANGED AF_CollectionToJson
            // and AF_HybridSearchService actions exactly as the Primary Documents flow does.
            Map<String, Object> flowInputs = new Map<String, Object>{
                'DCFilePaths'    => filePaths,
                'Input_Question' => req.inputQuestion
            };
    
            Flow.Interview interview = Flow.Interview.createInterview(
                'L2_Additional_Document_Retriever', flowInputs
            );
            interview.start();
    
            Object answer = interview.getVariableValue('Output_Answer');
            out.promptAnswer = answer != null ? String.valueOf(answer) : 'No response generated.';
    
            return new List<SelectionResponse>{ out };
        }
    }
