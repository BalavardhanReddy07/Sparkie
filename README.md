Hi Beatrix,
Summary details are presented in the LWC Component which will show the details only when the end user will click "Get Member Summary" button. 
There are only two options on the button click:
Option 1: Agent gets the member summary details when button clicked and we found the member details in Salesforce
Option 2: Agent gets "Sorry, I am unable to find the member information" message when button clicked and we don't found the member details in Salesforce
Once end user will click on "Submit", then the controls are passed to Agentforce to set the member Id in the context variables to move to next steps.
Looking at the snapshot in the ticket, it seems like the "Get Member Summary" button was not clicked. 
We have tried multiple times and everytime, when "Get Member Summary" button is clicked we get the summary.

Regarding the session Logs: 
LWC/UI component interactions are not logged in Session Logs but they are available in the Standard Debug logs which are enabled only on-demand basis. 
GIven this issue is not reproducable, are you happy to retest and confirm the next steps?
