/**
 * AF_BrighterLibraryDocService
 *
 * Invocable Apex action for the Brighter Library Document selector.
 *
 * When wired to an Agent Action, set the input rendering component to
 * the Lightning Type backed by BrighterLibraryDocInputSchema and the
 * brighterlibrarydocselector LWC.
 *
 * The LWC lets the user pick documents; on submit the Lightning Type
 * passes BrighterLibraryDocInputSchema into this action. This class
 * extracts the selected Data Cloud file paths and returns them as the
 * action output so the agent can consume them downstream.
 */
@JsonAccess(serializable='always' deserializable='always')
global class AF_BrighterLibraryDocService {

    // ─── Input wrapper (references the Lightning Type schema) ────────────────
    @JsonAccess(serializable='always' deserializable='always')
    global class InputRequest {
        @InvocableVariable(label='Document Selection Input' required=true)
        global BrighterLibraryDocInputSchema inputs;
    }

    // ─── Output wrapper ─────────────────────────────────────────────────────
    @JsonAccess(serializable='always' deserializable='always')
    global class ActionOutput {
        @InvocableVariable(label='Selected File Paths' description='Comma-separated Data Cloud file paths of the selected documents')
        global String selectedFilePaths;

        @InvocableVariable(label='Selected Document Names' description='Comma-separated names of the selected documents')
        global String selectedDocumentNames;

        @InvocableVariable(label='Is Success')
        global Boolean isSuccess;
    }

    // ─── Invocable entry point ───────────────────────────────────────────────
    @InvocableMethod(label='Process Brighter Library Document Selection'
                     description='Receives the user document selection from the Brighter Library LWC and returns the selected Data Cloud file paths.')
    global static List<ActionOutput> processDocumentSelection(List<InputRequest> requests) {
        List<ActionOutput> results = new List<ActionOutput>();

        for (InputRequest req : requests) {
            ActionOutput out = new ActionOutput();
            out.isSuccess = true;

            if (req.inputs != null) {
                // Join file paths into a single comma-separated string
                if (req.inputs.selectedFilePaths != null && !req.inputs.selectedFilePaths.isEmpty()) {
                    out.selectedFilePaths = String.join(req.inputs.selectedFilePaths, ',');
                }
                // Join document names for agent reasoning / display
                if (req.inputs.selectedDocumentNames != null && !req.inputs.selectedDocumentNames.isEmpty()) {
                    out.selectedDocumentNames = String.join(req.inputs.selectedDocumentNames, ',');
                }
            }

            results.add(out);
        }
        return results;
    }
}
