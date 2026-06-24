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
                    _documentOptions = [];
                
                    @api
                    get value() {
                        return this._value;
                    }
                    set value(val) {
                        this._value = val ? JSON.parse(JSON.stringify(val)) : {};

                    // --- Extract options and session ID eagerly in the setter (runs once on data arrival) ---
                    let rawOptions = [];
                    if (Array.isArray(this._value)) {
                        rawOptions = this._value;
                    } else if (this._value && this._value.documentOptions) {
                        rawOptions = this._value.documentOptions;
                    }
            
                    const displayOptions = [];
                    this.hiddenSessionId = null; // reset each time value changes
            
                    rawOptions.forEach(opt => {
                        if (opt.label === 'HIDDEN_SESSION_ID') {
                            // Intercept and stash — never show in the combobox
                            this.hiddenSessionId = opt.value;
                        } else {
                            displayOptions.push({ label: opt.label, value: opt.value });
                        }
                    });
            
                    this._documentOptions = displayOptions;
                }
            
                get debugData() {
                    return JSON.stringify(this._value);
                }
            
                get documentOptions() {
                    return this._documentOptions;
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
                        // 1. BACKEND UPDATE: Pass the selected path and the smuggled Session ID to the Flow
                        // This firmly injects the selected document into the Agent's backend memory.
                        const outputMessage = await runL2SearchFlow({ 
                            documentFilePath: this.selectedFilePath,
                            sessionId: this.hiddenSessionId
                        });
                        
                        this.flowOutputMessage = outputMessage || "Success! I've loaded the document. Please ask your questions.";
            
                        // 2. FRONTEND UPDATE: Dispatch a standard chat message event
                        // This seamlessly nudges the Agent forward, completes the turn, and forces
                        // the Agentforce Context Variables panel to fetch the newly updated backend memory.
                        const messageEvent = new CustomEvent('sendmessage', {
                            detail: { 
                                message: `I have selected the document: ${this.selectedDocumentName}. Please proceed.` 
                            }
                        });
                        this.dispatchEvent(messageEvent);
                        
                    } catch (error) {
                        console.error('Error invoking flow:', error);
                        this.flowOutputMessage = 'Error invoking flow: ' + (error.body ? error.body.message : error.message);
                    } finally {
                        this.isSubmitting = false;
                    }
                }
            }
