How the Interview Started
How the Interview Started
Bala Reddy (0059j00000QLTDM) started the flow interview.
API Version for Running the Flow: 67
Some of this flow's variables were set when the interview started.
SessionId = 96d806a3-a561-4c37-8893-4e71a8cb87eb
document_File_Paths = 1JD9j000001btWPGAY/Brighter Super Member Guide.pdf
Flow start time: <b>23 June 2026 at 7:02 pm</b>.


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
We couldn't run action  AIAgentAPIV1.sendMessage  because something went wrong.
Inputs:
session-id = {!SessionId} (96d806a3-a561-4c37-8893-4e71a8cb87eb)
x-sfdc-tenant-id = {!$Organization.Id} (00D9j0000090JYX)
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
404Exc
{
  "timestamp_set": true,
  "timestamp": 1782205327698,
  "status_set": true,
  "status": 404,
  "requestId_set": true,
  "requestId": "14b1d0f2-5775-411d-ac0b-c1cdd3e899c5",
  "path_set": true,
  "path": "v6.0.0/sessions/96d806a3-a561-4c37-8893-4e71a8cb87eb/messages",
  "message_set": true,
  "message": "V6Session not found for sessionId: 96d806a3-a561-4c37-8893-4e71a8cb87eb",
  "error_set": true,
  "error": "NotFoundException"
}
responseCode (404)
$$:Fault:
Error Occurred: Not Found



Transaction Rolled Back
Because an error occurred, any records that the flow was ready to create, update, or delete weren’t committed to the database.


An Error Occurred
The flow interview failed on 23 June 2026 at 7:02 pm. It ran for 6.21 seconds.
