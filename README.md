How the Interview Started
How the Interview Started
Bala Reddy (0059j00000QLTDM) started the flow interview.
API Version for Running the Flow: 67
Some of this flow's variables were set when the interview started.
SessionId = c15ee348-4ee8-46c1-bd1d-75324ad9fbf7
document_File_Paths = 1JD9j000001btWPGAY/Brighter Super Member Guide.pdf
Flow start time: <b>23 June 2026 at 6:45 pm</b>.


Assignment: Set Context Variable Data
3 variables were updated.
{!var_AgentVariable.TextVariable.name} Equals SelectedL2Document
{!var_AgentVariable.TextVariable.value} Equals {!document_File_Paths}
{!var_AgentVariable.TextVariable.z0type} Equals Text
Result
{!var_AgentVariable.TextVariable.z0type} = "Text"
{!var_AgentVariable.TextVariable.name} = "SelectedL2Document"
{!var_AgentVariable.TextVariable.value} = "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"


Assignment: Construct Message Body
5 variables were updated.
{!var_AgentVariableCollection} Add {!var_AgentVariable}
{!var_MessageBody.variables} Equals {!var_AgentVariableCollection}
{!var_MessageBody.message.TextMessage.text} Equals L2 Document Selected Successfully
{!var_MessageBody.message.TextMessage.z0type} Equals Text
{!var_MessageBody.message.TextMessage.sequenceId} Equals 1
Result
{!var_MessageBody.message.TextMessage.z0type} = "Text"
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
session-id = {!SessionId} (c15ee348-4ee8-46c1-bd1d-75324ad9fbf7)
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
404Exc
{
  "timestamp_set": true,
  "timestamp": 1782204344128,
  "status_set": true,
  "status": 404,
  "requestId_set": true,
  "requestId": "87764d50-fa3a-4029-b197-0ea7b19179da",
  "path_set": true,
  "path": "v6.0.0/sessions/c15ee348-4ee8-46c1-bd1d-75324ad9fbf7/messages",
  "message_set": true,
  "message": "V6Session not found for sessionId: c15ee348-4ee8-46c1-bd1d-75324ad9fbf7",
  "error_set": true,
  "error": "NotFoundException"
}
responseCode (404)
$$:Fault:
Error Occurred: Not Found



Transaction Rolled Back
Because an error occurred, any records that the flow was ready to create, update, or delete weren’t committed to the database.


An Error Occurred
The flow interview failed on 23 June 2026 at 6:45 pm. It ran for 10.65 seconds.
