    import { api, LightningElement, track } from "lwc";

        export default class MenuFilter extends LightningElement {
        
            // ─── API: readOnly ───────────────────────────────────────────────────────
            @api
            get readOnly() {
                return this._readOnly;
            }
            set readOnly(value) {
                this._readOnly = value;
            }
            _readOnly = false;
        
            // ─── API: value (used by Agentforce to read/set component state) ─────────
            @api
            get value() {
                return this._value;
            }
            set value(value) {
                this._value = value;
                if (value) {
                    this.existingMember = value.existingMember || false;
                    this.isSelected     = value.existingMember || false;
                    this.memberId       = value.memberId       || "";
                    this.selectedSchemeCategory = value.selectedSchemeCategory || "";
                    this.memberSummary = value.memberSummary || "";
                    this.products = value.products || [];
                }
            }
            _value;
        
            // ─── Internal State ──────────────────────────────────────────────────────
            existingMember  = false;
            memberId        = "";
            isSelected      = false;
        
            @track memberSummary  = "";      // plain-text summary returned by flow
            @track products       = [];      // array of product name strings
            @track selectedSchemeCategory = "";
        
            isLoading    = false;
            runFlow      = false;
            errorMessage = "";
        
            // ─── Flow input variables ────────────────────────────────────────────────
            get flowInputVariables() {
                return [
                    { name: "memberId", type: "String", value: this.memberId }
                ];
            }
        
            // ─── Computed helpers ────────────────────────────────────────────────────
            get isExistingMember() {
                return this.existingMember === true;
            }
        
            get isFetchDisabled() {
                return !this.memberId || this.memberId.trim() === "" || this.isLoading || this.readOnly;
            }
        
            get hasMemberSummary() {
                return !!this.memberSummary;
            }
        
            get hasProducts() {
                return this.products && this.products.length > 0;
            }
        
            /** Map products array → radio-group options */
            get productOptions() {
                return this.products.map((item) => {
                // Step 1: Split off the Scheme Category (after " -- ")
                const mainParts = item.split(" -- ");
                const displayPart = mainParts[0] ? mainParts[0].trim() : item;
                const schemeCategory = mainParts[1] ? mainParts[1].trim() : "";
        
                // Step 2: displayPart is "AccountNumber - Designation" — use as-is for label
                const label = displayPart;
        
                return {
                    label: label,
                    value: schemeCategory
                };
            });
            }   
        
        
            // ─── Step 1: Toggle member-specific button ───────────────────────────────
            handleExistingMemberChange() {
                this.isSelected     = !this.isSelected;
                this.existingMember = this.isSelected;
        
                // Reset downstream state when toggled off
                if (!this.existingMember) {
                    this.memberId        = "";
                    this.memberSummary   = "";
                    this.products        = [];
                    this.selectedSchemeCategory = "";
                    this.runFlow         = false;
                    this.errorMessage    = "";
                }
        
                this.dispatchValueChangeEvent();
            }
        
            // ─── Step 2: Member ID input change ─────────────────────────────────────
            handleInputChange(event) {
                event.stopPropagation();
                const { name, value } = event.target;
                this[name] = value;
        
                // Clear stale summary when member ID changes
                this.memberSummary   = "";
                this.products        = [];
                this.selectedSchemeCategory = "";
                this.runFlow         = false;
                this.errorMessage    = "";
        
                this.dispatchValueChangeEvent();
            }
        
            // ─── Step 3: Launch the flow to fetch member summary ────────────────────
            handleGetSummary() {
                if (!this.memberId || this.memberId.trim() === "") return;
        
                this.isLoading    = true;
                this.errorMessage = "";
                this.memberSummary   = "";
                this.products        = [];
                this.selectedSchemeCategory = "";
                this.runFlow         = false;   // reset so flow rerenders fresh
        
                // Use a micro-task delay to allow the DOM to clear the old flow first
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    this.runFlow = true;
                }, 0);
            }
        
            // ─── Step 3b: Handle flow completion ────────────────────────────────────
            /**
             * The flow must have two output variables:
             *   - MemberSummary  (String) – human-readable summary text
             *   - ProductNames   (String) – comma-separated product names
             *                               e.g. "Plan A,Plan B,Plan C"
             */
            handleFlowStatusChange(event) {
                const { status, outputVariables } = event.detail;
        
                if (status === "FINISHED" || status === "FINISHED_SCREEN") {
                    this.isLoading = false;
                    this.runFlow   = false;
        
                    if (outputVariables && outputVariables.length > 0) {
                        const summaryVar  = outputVariables.find((v) => v.name === "memberSummaryResponse");
                        const productsVar = outputVariables.find((v) => v.name === "schemeCategoryList");
        
                        this.memberSummary = summaryVar  ? summaryVar.value  : "Summary not available.";
        
                        if (productsVar && productsVar.value) {
        
                            let rawValue = productsVar.value;
        
                            if (Array.isArray(rawValue)) {
                                this.products = rawValue;
                            } else {
                                // ✅ Remove enclosing brackets [ ]
                                rawValue = rawValue.replace(/^\[|\]$/g, "");
        
                                // ✅ Split and trim safely
                                this.products = rawValue
                                    .split(",")
                                    .map((p) => p.trim())
                                    .filter(Boolean);
                            }
                        }
                    } else {
                        this.memberSummary = "No summary returned by the flow.";
                    }
        
                } else if (status === "ERROR") {
                    this.isLoading    = false;
                    this.runFlow      = false;
                    this.errorMessage = "Failed to retrieve member summary. Please try again.";
                }
            }
        
            // ─── Step 4: Product selection ───────────────────────────────────────────
            handleProductChange(event) {
                this.selectedSchemeCategory = event.detail.value;
                this.dispatchValueChangeEvent();
            }
        
            // ─── Dispatch value back to Agentforce (same pattern as original) ────────
            dispatchValueChangeEvent() {
                const currentValue = {
                    existingMember:  this.existingMember,
                    memberId:        this.memberId,
                    memberSummary:   this.memberSummary,
                    selectedSchemeCategory: this.selectedSchemeCategory,
                    products: this.products,
                }
                this._value = currentValue;
                this.dispatchEvent(
                    new CustomEvent("valuechange", {
                        detail: {
                            value: {
                                existingMember:  this.existingMember,
                                memberId:        this.memberId,
                                memberSummary:   this.memberSummary,
                                selectedSchemeCategory: this.selectedSchemeCategory,
                            },
                        },
                    })
                );
            }
        }


///////////////////////////////////////////////////////////////////////////////////////////////////////////
Topic_Document_Mapping__c Object
fields : 
Active	Active__c	Checkbox		False	
Additional Document	Additional_Document__c	Lookup(Document Detail)		True	
Created By	CreatedById	Lookup(User)		False	
Key Field API Name	Key_Field_API_Name__c	Text(255)		False	
Key Field Value	Key_Field_Value__c	Text(255)		False	
Last Modified By	LastModifiedById	Lookup(User)		False	
Mapping Number	Name	Auto Number		True	
Object API Name	Object_API_Name__c	Text(255)		False	
Owner	OwnerId	Lookup(User,Group)		True	
Primary Document	Primary_Document__c	Lookup(Document Detail)		True	
Sub Topic	Sub_Topic__c	Text(255)		False	
Topic	Topic__c	Text(255)		False	
Valid From	Valid_From__c	Date		False	
Valid To	Valid_To__c	Date
    
    
    
/////////////////////////////////////////////////////////////////////    
    public with sharing class AF_L2DocumentListService {

    public class ListRequest {
        @InvocableVariable(required=true)
        public List<String> documentIds;
    }

    public class ListResponse {
        @InvocableVariable
        public List<DocumentOption> documents;
    }

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
            opt.recordId          = d.Id;
            opt.documentName      = d.Name;
            opt.dataCloudFilePath = d.Data_Cloud_File_Path__c;
            opt.documentUrl       = d.Document_URL__c;
            opt.hasWarning        = String.isNotBlank(d.Warning_for_L2_document__c);
            opt.warningText       = d.Warning_for_L2_document__c;
            out.documents.add(opt);
        }

        return new List<ListResponse>{ out };
    }
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public with sharing class AF_L2DocumentSelectionService {

    public class SelectionRequest {
        @InvocableVariable(required=true)
        public List<String> selectedRecordIds;
        @InvocableVariable(required=true)
        public String inputQuestion;
    }

    public class SelectionResponse {
        @InvocableVariable public String promptAnswer;
        @InvocableVariable public List<String> activeWarnings;
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

        Map<String, Object> flowInputs = new Map<String, Object>{
            'SelectedFilePaths' => filePaths,
            'Input_Question'    => req.inputQuestion
        };

        Flow.Interview interview = Flow.Interview.createInterview(
            'L2_Additional_Document_Selection_Handler', flowInputs
        );
        interview.start();

        Object answer = interview.getVariableValue('Output_Answer');
        out.promptAnswer = answer != null ? String.valueOf(answer) : 'No response generated.';

        return new List<SelectionResponse>{ out };
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
