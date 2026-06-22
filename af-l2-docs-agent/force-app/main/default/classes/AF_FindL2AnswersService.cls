/**
 * AF_FindL2AnswersService
 * --------------------------------------------------------------------------
 * Backs the "AF_FindL2Answers" action used by the "Find L2 Answers"
 * subagent. Takes the user's freeform question plus the L2 document file
 * path (resolved automatically from the dataCloudL2FilePath conversation
 * variable -- this input is NOT "Collect data from user" in Agent Builder)
 * and returns a grounded answer.
 *
 * The retrieval/answering logic below is a placeholder. Wire in whichever
 * of these fits your org:
 *   - A Prompt Template (Prompt Builder) grounded on the file content
 *   - A Data Cloud vector / semantic search scoped to the file path
 *   - A direct text-extraction + search over the document content
 */
public class AF_FindL2AnswersService {

    public class L2AnswerRequest {
        @InvocableVariable(label='User Question'
            description='The question the user asked about the selected L2 document.'
            required=true)
        public String userQuestion;

        @InvocableVariable(label='L2 Document File Path'
            description='File path of the L2 document selected earlier in the conversation (dataCloudL2FilePath).'
            required=true)
        public String l2DocumentFilePath;
    }

    public class L2AnswerResult {
        @InvocableVariable(label='Answer')
        public String answer;
    }

    @InvocableMethod(
        label='AF Find L2 Answers'
        description='Answers a user question by grounding on the previously selected L2 document file path.'
        category='L2 Documents'
    )
    public static List<L2AnswerResult> findAnswers(List<L2AnswerRequest> requests) {
        List<L2AnswerResult> results = new List<L2AnswerResult>();

        for (L2AnswerRequest req : requests) {
            L2AnswerResult res = new L2AnswerResult();
            res.answer = buildAnswer(req.userQuestion, req.l2DocumentFilePath);
            results.add(res);
        }

        return results;
    }

    private static String buildAnswer(String question, String filePath) {
        if (String.isBlank(filePath)) {
            return 'I don\'t have a document selected yet. Please run "Show L2 Documents" and pick one first.';
        }

        // TODO: replace with real grounding logic (Prompt Template / Data
        // Cloud vector search / document text extraction + search).
        return 'Based on the document at ' + filePath + ', here is what I found ' +
            'regarding your question: "' + question + '". ' +
            '(Replace AF_FindL2AnswersService.buildAnswer with your real retrieval logic.)';
    }
}
