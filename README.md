How the Interview Started
How the Interview Started
Bala Reddy (0059j00000QLTDM) started the flow interview.
API Version for Running the Flow: 67
Some of this flow's variables were set when the interview started.
SessionId = 019ef83e-bb6f-7640-a47b-8614f75784a2
document_File_Paths = 1JD9j000001btWPGAY/Brighter Super Member Guide.pdf
Flow start time: <b>24 June 2026 at 4:19 pm</b>.


Assignment: Set Context Variable Data
2 variables were updated.
{!var_AgentVariable.TextVariable.name} Equals SelectedL2Document
{!var_AgentVariable.TextVariable.value} Equals {!document_File_Paths}
Result
{!var_AgentVariable.TextVariable.name} = "SelectedL2Document"
{!var_AgentVariable.TextVariable.value} = "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"


Assignment: Construct Message Body
4 variables were updated.
{!var_AgentVariableCollection} Add {!var_AgentVariable}
{!var_MessageBody.variables} Equals {!var_AgentVariableCollection}
{!var_MessageBody.message.TextMessage.text} Equals L2 Document Selected Successfully
{!var_MessageBody.message.TextMessage.sequenceId} Equals 1
Result
{!var_AgentVariableCollection} = "[AIAgentAPIV1_Variable_KT_PT : {
  "TextVariable_set" : true,
  "TextVariable" : {
    "z0type" : "Text",
    "value_set" : true,
    "value" : "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf",
    "name_set" : true,
    "name" : "SelectedL2Document"
  }
}]"
{!var_MessageBody.variables} = "[AIAgentAPIV1_Variable_KT_PT : {
  "TextVariable_set" : true,
  "TextVariable" : {
    "z0type" : "Text",
    "value_set" : true,
    "value" : "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf",
    "name_set" : true,
    "name" : "SelectedL2Document"
  }
}]"
{!var_MessageBody.message.TextMessage.sequenceId} = "1"
{!var_MessageBody.message.TextMessage.text} = "L2 Document Selected Successfully"


AIAgentAPIV1.sendMessage (API): Send Session Message Action 1
Action  AIAgentAPIV1.sendMessage  was run.
Inputs:
session-id = {!SessionId} (019ef83e-bb6f-7640-a47b-8614f75784a2)
x-sfdc-tenant-id = test
body = {!var_MessageBody}
{
  "variables_set": true,
  "variables": [
    {
      "TextVariable_set": true,
      "TextVariable": {
        "z0type": "Text",
        "value_set": true,
        "value": "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf",
        "name_set": true,
        "name": "SelectedL2Document"
      }
    }
  ],
  "message_set": true,
  "message": {
    "TextMessage_set": true,
    "TextMessage": {
      "z0type": "Text",
      "text_set": true,
      "text": "L2 Document Selected Successfully",
      "sequenceId_set": true,
      "sequenceId": 1
    }
  }
}
Outputs:
200
{
  "x5flinks_set": true,
  "x5flinks": {
    "z0end_set": true,
    "z0end": {
      "href_set": true,
      "href": "https://api.salesforce.com/einstein/ai-agent/v1/sessions/019ef83e-bb6f-7640-a47b-8614f75784a2"
    },
    "session_set": true,
    "session": {
      "href_set": true,
      "href": "https://api.salesforce.com/einstein/ai-agent/v1/agents/0Xx9j0000004MTNCA2/sessions"
    },
    "self_set": true,
    "messages_set": true,
    "messages": {
      "href_set": true,
      "href": "https://api.salesforce.com/einstein/ai-agent/v1/sessions/019ef83e-bb6f-7640-a47b-8614f75784a2/messages"
    }
  },
  "messages_set": true,
  "messages": [
    {
      "InformMessage_set": true,
      "InformMessage": {
        "z0type": "Inform",
        "result_set": true,
        "result": [],
        "planId_set": true,
        "planId": "35055968-fc23-467f-8ad6-ed74c0a8f0a3",
        "metrics_set": true,
        "metrics": {},
        "message_set": true,
        "message": "You have successfully selected an L2 document. Please specify which document you want to view:\\n\\n- Brighter Super Fund Business Rules\\n- Brighter Super Member Guide\\n\\nLet me know your choice, and I will provide information or guidance from the selected document.",
        "isContentSafe_set": true,
        "isContentSafe": true,
        "id_set": true,
        "id": "b1a137b5-1467-4bd7-b110-3507d2e6e43c",
        "feedbackId_set": true,
        "feedbackId": "35055968-fc23-467f-8ad6-ed74c0a8f0a3",
        "citedReferences_set": true,
        "citedReferences": []
      }
    }
  ]
}
responseCode (200)


Assignment: Assign Output Message
1 variable was updated.
{!Output_Message} Equals Success! I've loaded the document. Please ask your questions from the selected L2 document
Result
{!Output_Message} = "Success! I've loaded the document. Please ask your questions from the selected L2 document"


Transaction Committed
Any records that the flow was ready to create, update, or delete were committed to the database.


How the Interview Finished
The flow interview ran for 9.11 seconds and finished on 24 June 2026 at 4:19 pm.
