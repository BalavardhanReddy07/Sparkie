import { api, LightningElement, track, wire } from "lwc";
import getBrighterLibraryDocuments from "@salesforce/apex/BrighterLibraryDocController.getBrighterLibraryDocuments";

export default class BrighterLibraryDocSelector extends LightningElement {

    // ─── API: readOnly (set by Agentforce when conversation is read-only) ─────
    @api
    get readOnly() {
        return this._readOnly;
    }
    set readOnly(val) {
        this._readOnly = val === true || val === "true";
    }
    _readOnly = false;

    // ─── API: value  (Agentforce reads + writes this property) ───────────────
    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._value = val;
        if (val) {
            // Restore persisted selection when Agentforce replays state
            this._selectedIds = new Set(val.selectedIds || []);
            this._syncCheckboxState();
        }
    }
    _value = null;

    // ─── Internal state ───────────────────────────────────────────────────────
    @track _documents        = [];   // [{recordId, documentName, dataCloudFilePath, hasWarning, warningText, checked}]
    @track _isLoading        = true;
    @track _errorMessage     = "";
    @track _activeWarning    = "";   // warning text for the currently-checked doc
    @track _showWarningModal = false;
    @track _pendingDocId     = null; // doc being "checked" that triggered a warning

    _selectedIds = new Set();        // Set of currently selected recordIds

    // ─── Wire: load documents once on connect ────────────────────────────────
    @wire(getBrighterLibraryDocuments)
    wiredDocs({ data, error }) {
        this._isLoading = false;
        if (data) {
            if (data.errorMessage) {
                this._errorMessage = data.errorMessage;
                return;
            }
            this._documents = (data.documents || []).map((d) => ({
                recordId:          d.recordId,
                documentName:      d.documentName,
                dataCloudFilePath: d.dataCloudFilePath,
                documentUrl:       d.documentUrl,
                hasWarning:        d.hasWarning,
                warningText:       d.warningText,
                checked:           this._selectedIds.has(d.recordId)
            }));
        } else if (error) {
            this._errorMessage =
                (error.body && error.body.message) || "Failed to load documents.";
        }
    }

    // ─── Computed helpers ─────────────────────────────────────────────────────
    get hasDocuments() {
        return this._documents && this._documents.length > 0;
    }

    get hasError() {
        return !!this._errorMessage;
    }

    get selectAllChecked() {
        return (
            this._documents.length > 0 &&
            this._documents.every((d) => d.checked)
        );
    }

    get selectAllIndeterminate() {
        const checkedCount = this._documents.filter((d) => d.checked).length;
        return checkedCount > 0 && checkedCount < this._documents.length;
    }

    get selectedCount() {
        return this._selectedIds.size;
    }

    get hasSelection() {
        return this._selectedIds.size > 0;
    }

    get isReadOnly() {
        return this._readOnly;
    }

    // ─── Select All ───────────────────────────────────────────────────────────
    handleSelectAll(event) {
        if (this._readOnly) return;

        const checked = event.target.checked;
        this._documents = this._documents.map((d) => ({ ...d, checked }));

        if (checked) {
            this._documents.forEach((d) => this._selectedIds.add(d.recordId));
        } else {
            this._selectedIds.clear();
        }

        this._dispatchValueChange();
    }

    // ─── Individual checkbox ──────────────────────────────────────────────────
    handleDocCheck(event) {
        if (this._readOnly) return;

        const recordId = event.target.dataset.id;
        const checked  = event.target.checked;

        // If checking a document that carries a warning → intercept & show modal
        if (checked) {
            const doc = this._documents.find((d) => d.recordId === recordId);
            if (doc && doc.hasWarning) {
                this._pendingDocId    = recordId;
                this._activeWarning   = doc.warningText;
                this._showWarningModal = true;
                // Visually un-check until user confirms
                event.target.checked = false;
                return;
            }
        }

        this._applyCheckChange(recordId, checked);
    }

    // ─── Warning modal handlers ───────────────────────────────────────────────
    handleWarningConfirm() {
        if (this._pendingDocId) {
            this._applyCheckChange(this._pendingDocId, true);
        }
        this._closeWarningModal();
    }

    handleWarningCancel() {
        this._closeWarningModal();
    }

    _closeWarningModal() {
        this._showWarningModal = false;
        this._pendingDocId    = null;
        this._activeWarning   = "";
    }

    // ─── Core check toggle ────────────────────────────────────────────────────
    _applyCheckChange(recordId, checked) {
        this._documents = this._documents.map((d) =>
            d.recordId === recordId ? { ...d, checked } : d
        );

        if (checked) {
            this._selectedIds.add(recordId);
        } else {
            this._selectedIds.delete(recordId);
        }

        this._dispatchValueChange();
    }

    // ─── Sync checkbox visuals when value is set from outside ────────────────
    _syncCheckboxState() {
        if (!this._documents.length) return;
        this._documents = this._documents.map((d) => ({
            ...d,
            checked: this._selectedIds.has(d.recordId)
        }));
    }

    // ─── Dispatch value back to Agentforce ───────────────────────────────────
    /**
     * The Agentforce Custom Input component contract:
     *   - listen for "valuechange" CustomEvent
     *   - event.detail.value  = the serialisable payload
     *
     * We return:
     *   selectedIds          – array of selected Document_Detail__c record Ids
     *   selectedFilePaths    – array of Data_Cloud_File_Path__c values (the
     *                          primary output consumed by the agent action)
     *   selectedDocumentNames – human-readable names for agent reasoning
     */
    _dispatchValueChange() {
        const selected = this._documents.filter((d) => d.checked);

        const payload = {
            selectedIds:           selected.map((d) => d.recordId),
            selectedFilePaths:     selected.map((d) => d.dataCloudFilePath).filter(Boolean),
            selectedDocumentNames: selected.map((d) => d.documentName)
        };

        this._value = payload;

        this.dispatchEvent(
            new CustomEvent("valuechange", {
                detail: { value: payload },
                bubbles: false
            })
        );
    }
}