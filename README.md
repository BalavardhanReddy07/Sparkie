How the Interview Started
How the Interview Started
Bala Reddy (0059j00000QLTDM) started the flow interview.
API Version for Running the Flow: 67
Some of this flow's variables were set when the interview started.
SessionId = c15ee348-4ee8-46c1-bd1d-75324ad9fbf7
document_File_Paths = 1JD9j000001btWPGAY/Brighter Super Member Guide.pdf
Flow start time: <b>23 June 2026 at 6:28 pm</b>.


Assignment: Set Context Variable Data
3 variables were updated.
{!var_AgentVariable.TextVariable.name} Equals {!document_File_Paths}
{!var_AgentVariable.TextVariable.value} Equals {!document_File_Paths}
{!var_AgentVariable.TextVariable.z0type} Equals Text
Result
{!var_AgentVariable.TextVariable.z0type} = "Text"
{!var_AgentVariable.TextVariable.name} = "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"
{!var_AgentVariable.TextVariable.value} = "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"


Assignment: Construct Message Body
2 variables were updated.
{!var_AgentVariableCollection} Add {!var_AgentVariable}
{!var_MessageBody.variables} Equals {!var_AgentVariableCollection}
Result
{!var_AgentVariableCollection} = "[AIAgentAPIV1_Variable_KT_PT : {
  "TextVariable_set" : true,
  "TextVariable" : {
    "z0type" : "Text",
    "value_set" : true,
    "value" : "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf",
    "name_set" : true,
    "name" : "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"
  }
}]"
{!var_MessageBody.variables} = "[AIAgentAPIV1_Variable_KT_PT : {
  "TextVariable_set" : true,
  "TextVariable" : {
    "z0type" : "Text",
    "value_set" : true,
    "value" : "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf",
    "name_set" : true,
    "name" : "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"
  }
}]"


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
        "name": "1JD9j000001btWPGAY/Brighter Super Member Guide.pdf"
      }
    }
  ]
}
$$:Fault:
Error Occurred: Callout failed for invocable action AIAgentAPIV1.sendMessage. Missing required input parameter property message declared in object AIAgentAPIV1.SendMessageRequest.



Transaction Rolled Back
Because an error occurred, any records that the flow was ready to create, update, or delete weren’t committed to the database.


An Error Occurred
The flow interview failed on 23 June 2026 at 6:28 pm. It ran for 4.85 seconds.
