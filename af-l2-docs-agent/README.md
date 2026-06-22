# L2 Documents — End-to-End Agentforce Implementation Guide

## 0. Architecture overview

User types **"Show L2 Documents"** → Agentforce routes to the **L2 Document
Lookup** subagent → triggers the `AF_GetL2Documents` action → the action's
Editor CLT renders a **searchable combobox + Submit button** inline in the
chat → user picks a document → `dataCloudL2FilePath` is set → agent says
"Please ask your question." → user asks a question → **Find L2 Answers**
subagent fires `AF_FindL2Answers` → answer is returned.

### Why one action with an Editor CLT (not a separate Flow)

The only supported way to write a value into an Agentforce conversation
variable is via an **action output mapped to that variable** in Agent
Builder (Action → Output → "Map to Variable"). This guide uses a single
`AF_GetL2Documents` action whose Editor CLT handles the combobox UI, and
whose `selectedFilePath` output is mapped to `dataCloudL2FilePath`.

### Data model

```
Topic_Document_Mapping__c
  ├─ Topic__c                  (Text — the selected topic)
  ├─ Key_Field_Value__c        (Text — the scheme category)
  ├─ Active__c                 (Checkbox)
  └─ Additional_Document__c    (Lookup → Document_Detail__c — the L2 doc)

Document_Detail__c
  ├─ Name                      (the document display name)
  ├─ Data_Cloud_File_Path__c   (the file path used by Data Cloud)
  └─ Document_URL__c           (URL)
```

`searchDocuments()` queries `Topic_Document_Mapping__c` filtered by
`Topic__c` and `Key_Field_Value__c`, traversing `Additional_Document__r` to
pull the document name and `Data_Cloud_File_Path__c` from
`Document_Detail__c`.

> **Terminology note:** As of April 2026, Salesforce renamed *Topics* to
> *Subagents* (same functionality, new name). This guide uses "subagent"
> throughout; your org may still show "topic" depending on rollout.

---

## 1. Files in this package

```
force-app/main/default/
├── classes/
│   ├── AF_GetL2DocumentsService.cls(+meta)      → AF_GetL2Documents action
│   ├── AF_FindL2AnswersService.cls(+meta)       → AF_FindL2Answers action
│   └── AF_L2DocumentsServiceTest.cls(+meta)     → test coverage
├── lwc/l2DocumentEditor/                         → the combobox+submit CLT editor
└── lightningTypes/l2DocumentRequest/             → the CLT bundle (schema.json + editor.json)
```

`AF_FindL2AnswersService.buildAnswer()` is a placeholder — plug in your
real grounding logic (Prompt Template, Data Cloud vector search, or direct
document search scoped to the file path).

> ⚠️ The exact JSON keys inside `editor.json`/`schema.json` for
> LightningTypeBundle have shifted slightly across releases. Cross-check
> against [Custom Lightning Types](https://developer.salesforce.com/docs/einstein/genai/guide/lightning-types-custom.html)
> and the [full editor/renderer example](https://developer.salesforce.com/docs/ai/agentforce/guide/lightning-types-example-full-editor-renderer.html)
> before deploying, and adjust if your org's metadata schema differs.

---

## 2. Deploy the metadata

```bash
sf project deploy start --source-dir force-app -o yourOrgAlias
sf apex run test --class-names AF_L2DocumentsServiceTest -o yourOrgAlias -r human
```

Ensure `Topic_Document_Mapping__c` and `Document_Detail__c` objects already
exist in your org with the field API names listed above.

---

## 3. Create the conversation variable

In **Agentforce Builder** (Setup → Agentforce Agents → your agent → Open in
Builder):

1. Go to the **Variables** tab.
2. Click **New → Conversation Variable**.
3. Name: `dataCloudL2FilePath`, Data Type: Text.
4. Save.

This sits alongside your existing `IsTopicSelected` and
`SelectedSchemeCategory` variables — conversation variables are visible to
every subagent on the same agent, which is what lets the later "Find L2
Answers" subagent read it.

---

## 4. Create the `AF_GetL2Documents` agent action

1. Setup → **Agentforce Assets** → **Actions** tab → **New Agent Action**.
2. Reference Action Type: **Apex**. Reference Action:
   `AF_GetL2DocumentsService.getSelectedDocument` (label "AF Get L2
   Documents").
3. Configure inputs:
   - The action exposes a single complex input (the `L2DocumentRequest`
     wrapper). Click **Edit** on it.
   - **Input Rendering** → select the custom Lightning Type
     `l2DocumentRequest`.
   - Check **Collect data from user** for this input as a whole (this is
     what tells the platform to render the editor CLT instead of asking a
     text question).
   - Within the wrapper, leave `schemeCategory` and `selectedTopic`
     *required* but do **not** mark them individually as user input —
     instruction text (step 6) is what tells the agent to resolve them from
     your existing context variables before rendering the form.
4. Configure outputs:
   - `selectedFilePath` → **Map to Variable** → `dataCloudL2FilePath`.
   - `selectedDocumentName` → check **Show in conversation** (optional, so
     the agent can confirm what was loaded) or leave it filtered if you'd
     rather the confirmation message handle that.
   - `confirmationMessage` → **Show in conversation**.
5. Save and **Activate** (you'll need to deactivate the agent first if it's
   already live, per the usual Agent Builder flow).

---

## 5. Create the "L2 Document Lookup" subagent

1. Open your agent in Builder → **Subagents** panel → **New → New
   Subagent**.
2. Classification description: *"Use this when the user wants to view or
   browse L2 documents for a scheme category and topic, e.g. when they say
   'Show L2 Documents'."*
3. Scope: *"Help the user pick a single L2 document for the scheme
   category and topic already established in this conversation, and load
   its file path for follow-up questions."*
4. Instructions (add these as plain-language rules):
   - *"If the user says 'Show L2 Documents' or asks to see L2 documents,
     run the {!@actions.AF_GetL2Documents} action. Populate its
     schemeCategory input from the SelectedSchemeCategory conversation
     variable and its selectedTopic input from the topic the user
     previously selected. Do not ask the user to retype these values."*
   - *"Only run this action if IsTopicSelected is true. If it isn't, tell
     the user to select a topic and scheme category first."*
   - *"After the action returns a selectedFilePath, say exactly: 'Please
     ask your question.' Do not add anything else."*
5. Add the `AF_GetL2Documents` action to **This Subagent's Actions**.
6. Save, then go back and **Activate** the agent.

---

## 6. Create the `AF_FindL2Answers` agent action

1. Setup → **Agentforce Assets** → **Actions** → **New Agent Action**.
2. Reference Action Type: **Apex**. Reference Action:
   `AF_FindL2AnswersService.findAnswers` (label "AF Find L2 Answers").
3. Inputs:
   - `userQuestion` → check **Collect data from user** (the agent fills
     this from whatever the user typed).
   - `l2DocumentFilePath` → do **not** mark as user input. Leave it
     required; instructions (step 8) tell the agent to pull it from
     `dataCloudL2FilePath`.
4. Output:
   - `answer` → **Show in conversation**.
5. Save and activate.

---

## 7. Create the "Find L2 Answers" subagent

1. **New Subagent** on the same agent.
2. Classification description: *"Use this once an L2 document has been
   selected (dataCloudL2FilePath is set) and the user asks a question about
   it."*
3. Scope: *"Answer the user's question using only the selected L2
   document's content."*
4. Instructions:
   - *"If dataCloudL2FilePath is blank, tell the user to run 'Show L2
     Documents' and select one first — don't call this action."*
   - *"Otherwise, run {!@actions.AF_FindL2Answers}, passing the user's
     latest message as userQuestion and dataCloudL2FilePath as
     l2DocumentFilePath. Return the answer output to the user as-is."*
5. Add `AF_FindL2Answers` to **This Subagent's Actions**.
6. Save and activate.

---

## 8. Test the whole flow

In **Agentforce Builder**'s Conversation Preview (or a deployed channel):

1. Run whatever existing actions set `IsTopicSelected = true` and
   `SelectedSchemeCategory` (per your note, these already exist elsewhere
   in your agent).
2. Type: `Show L2 Documents`
   → expect the L2 Document Lookup subagent to fire, the combobox+Submit
   card to render inline, populated from `searchDocuments()`.
3. Pick a document, click **Submit**
   → `AF_GetL2Documents` runs → `dataCloudL2FilePath` gets set → agent
   replies "Please ask your question."
4. Type a question about the document
   → Find L2 Answers subagent fires → `AF_FindL2Answers` runs with the
   stored file path → answer is returned.

Use **Conversation Preview → Plan/Inspector** at each step to confirm which
subagent and action actually ran, and check the **Variables** panel to
confirm `dataCloudL2FilePath` populated correctly before moving to step 4 —
this is the fastest way to catch a mapping mistake.

---

## 9. Common gotchas

- **CLTs render in Lightning Experience by default.** If this agent is also
  deployed to Enhanced Chat / Experience Cloud, add a matching
  `enhancedWebChat/editor.json` alongside `lightningDesktopGenAi/editor.json`
  inside the same Lightning Type bundle.
- **Field name mismatch breaks CLT silently.** The wrapper class field
  names (`schemeCategory`, `selectedTopic`, …) must exactly match what the
  editor's `valuechange` payload uses and what `schema.json` declares.
- **Agent must be deactivated** to add/edit subagents, actions, or
  variables — reactivate when done.
- **Conversation variables are agent-scoped, not subagent-scoped** — that's
  why `dataCloudL2FilePath` set in one subagent is visible in another on
  the same agent.
