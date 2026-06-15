get productOptions() {
    return this.products.map((item) => {
        const parts = item.split(" -- ");
        const schemeCategory = parts[0] ? parts[0].trim() : item;
        const accountNumber  = parts[1] ? parts[1].trim() : "";
        const label = accountNumber
            ? `${schemeCategory} -- ${accountNumber}`
            : schemeCategory;
        return { label: label, value: schemeCategory };
    });
}




=======================================================================
How the Interview Started
How the Interview Started
Bala Reddy (0059j00000QLTDM) started the flow interview.
API Version for Running the Flow: 66
Some of this flow's variables were set when the interview started.
memberId = 210062539
Flow start time: <b>15 June 2026 at 8:01 pm</b>.


Get Records: Get Account Record
One or more  Account  records were retrieved.
Find all Account records where:
Client_ID__c Equals {!memberId} (210062539)
AND Record_Type_Name__c Equals Member
AND Staff_Account__c Equals false
Store the values of these fields in Get_Account_Record: Age__c, First_Nation_Postcode__c, Id, Name
Result
Successfully found records.
SOQL queries: 1 out of 100
,SOQL query rows: 1 out of 50000


Decision: Account Exists
" Member_Found " outcome was executed.
$$:OutcomeExecuted:Member_Found
Outcome executed: Member_Found
Outcome conditions: 
1. {!Get_Account_Record} (Account (0018v0000054Z7tAAE)) Is null false
2. {!Get_Account_Record} (Account (0018v0000054Z7tAAE)) Is Blank false
Logic: All conditions must be true (AND)


Get Records: Get Case Record Types
One or more  RecordType  records were retrieved.
Find all RecordType records where:
SobjectType Equals Case
AND IsActive Equals true
AND Name Does not equal Enquiry
AND Name Does not equal Partner
AND Name Does not equal Return Mail
Store the values of these fields in Get_Case_Record_Types: Id, DeveloperName, Name
Result
Successfully found records.
SOQL queries: 1 out of 100
,SOQL query rows: 6 out of 50000


Loop: Loop Over Case Record Types
Iteration  0  of the loop through the  Get_Case_Record_Types  collection occurred.
$$:LoopNext:
Loop Through: [0125K0000004JjbQAE,0127F000000QEn0QAG,0127F000000QEn3QAG,012Ol000000bgJdIAI,012Ol000003SjOfIAK,012Ol000004VWvlIAG]
Iteration: 0
Current iteration item: 0125K0000004JjbQAE


Assignment: Record Type Name List
1 variable was updated.
{!caseRecordTypeNameList} Add {!Loop_Over_Case_Record_Types.Name}
Result
{!caseRecordTypeNameList} = "[Disability and Terminal Claim]"


Loop: Loop Over Case Record Types
Iteration  1  of the loop through the  Get_Case_Record_Types  collection occurred.
$$:LoopNext:
Loop Through: [0125K0000004JjbQAE,0127F000000QEn0QAG,0127F000000QEn3QAG,012Ol000000bgJdIAI,012Ol000003SjOfIAK,012Ol000004VWvlIAG]
Iteration: 1
Current iteration item: 0127F000000QEn0QAG


Assignment: Record Type Name List
1 variable was updated.
{!caseRecordTypeNameList} Add {!Loop_Over_Case_Record_Types.Name}
Result
{!caseRecordTypeNameList} = "[Disability and Terminal Claim,Complaint]"


Loop: Loop Over Case Record Types
Iteration  2  of the loop through the  Get_Case_Record_Types  collection occurred.
$$:LoopNext:
Loop Through: [0125K0000004JjbQAE,0127F000000QEn0QAG,0127F000000QEn3QAG,012Ol000000bgJdIAI,012Ol000003SjOfIAK,012Ol000004VWvlIAG]
Iteration: 2
Current iteration item: 0127F000000QEn3QAG


Assignment: Record Type Name List
1 variable was updated.
{!caseRecordTypeNameList} Add {!Loop_Over_Case_Record_Types.Name}
Result
{!caseRecordTypeNameList} = "[Disability and Terminal Claim,Complaint,Third Party Authority]"


Loop: Loop Over Case Record Types
Iteration  3  of the loop through the  Get_Case_Record_Types  collection occurred.
$$:LoopNext:
Loop Through: [0125K0000004JjbQAE,0127F000000QEn0QAG,0127F000000QEn3QAG,012Ol000000bgJdIAI,012Ol000003SjOfIAK,012Ol000004VWvlIAG]
Iteration: 3
Current iteration item: 012Ol000000bgJdIAI


Assignment: Record Type Name List
1 variable was updated.
{!caseRecordTypeNameList} Add {!Loop_Over_Case_Record_Types.Name}
Result
{!caseRecordTypeNameList} = "[Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim]"


Loop: Loop Over Case Record Types
Iteration  4  of the loop through the  Get_Case_Record_Types  collection occurred.
$$:LoopNext:
Loop Through: [0125K0000004JjbQAE,0127F000000QEn0QAG,0127F000000QEn3QAG,012Ol000000bgJdIAI,012Ol000003SjOfIAK,012Ol000004VWvlIAG]
Iteration: 4
Current iteration item: 012Ol000003SjOfIAK


Assignment: Record Type Name List
1 variable was updated.
{!caseRecordTypeNameList} Add {!Loop_Over_Case_Record_Types.Name}
Result
{!caseRecordTypeNameList} = "[Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim]"


Loop: Loop Over Case Record Types
Iteration  5  of the loop through the  Get_Case_Record_Types  collection occurred.
$$:LoopNext:
Loop Through: [0125K0000004JjbQAE,0127F000000QEn0QAG,0127F000000QEn3QAG,012Ol000000bgJdIAI,012Ol000003SjOfIAK,012Ol000004VWvlIAG]
Iteration: 5
Current iteration item: 012Ol000004VWvlIAG


Assignment: Record Type Name List
1 variable was updated.
{!caseRecordTypeNameList} Add {!Loop_Over_Case_Record_Types.Name}
Result
{!caseRecordTypeNameList} = "[Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]"


Loop: Loop Over Case Record Types
Loop was completed.
$$:LoopEnd:
End Loop.


Collection Filter: Filter Enquiry Record Type
Source collection: Get_Case_Record_Types
Create a collection, applying these filter conditions: 
One condition must be true (OR)
1. {!currentItem_Filter_Enquiry_Record_Type.DeveloperName} Equals Enquiry
2. {!currentItem_Filter_Enquiry_Record_Type.DeveloperName} Equals Partner
3. {!currentItem_Filter_Enquiry_Record_Type.DeveloperName} Equals Return Mail
Items in source collection: 6
Items in filtered target collection: 0
Result
None.


Get Records: Get Case Records
We couldn't retrieve any records.
Find all Case records where:
AccountId Equals {!Get_Account_Record.Id} (0018v0000054Z7tAAE)
AND Status Equals Open
AND RecordTypeId Equals {!currentItem_Filter_Enquiry_Record_Type.Id} (null)
Store the values of these fields in Get_Case_Records: RecordTypeId, Id
Result
Failed to find records.
SOQL queries: 1 out of 100


Decision: Case Record Found?
The  default  outcome was executed.
$$:OutcomeNotExecuted:Found
Skipped this outcome because its conditions weren't met: Found
Outcome conditions: 
1. {!Get_Case_Records} (null) Is null false
2. {!Get_Case_Records} (null) Is Empty false
Logic: All conditions must be true (AND)
$$:DefaultOutcomeExecuted:
Default outcome executed.


Loop: Loop through Case Record Type Names
Iteration  0  of the loop through the  caseRecordTypeNameList  collection occurred.
$$:LoopNext:
Loop Through: [Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]
Iteration: 0
Current iteration item: Disability and Terminal Claim


Assignment: Assign Current Case Record Type
1 variable was updated.
{!currentCaseRecordTypeName} Equals {!Loop_through_Case_Record_Type_Names_nocases}
Result
{!currentCaseRecordTypeName} = "Disability and Terminal Claim"


Assignment: Assign Case Status
2 variables were updated.
{!caseExists} Equals No <br>
{!caseStatusList} Add {!caseStatusDetails}
Result
{!caseExists} = "No <br>"
{!caseStatusList} = "<ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul>"


Loop: Loop through Case Record Type Names
Iteration  1  of the loop through the  caseRecordTypeNameList  collection occurred.
$$:LoopNext:
Loop Through: [Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]
Iteration: 1
Current iteration item: Complaint


Assignment: Assign Current Case Record Type
1 variable was updated.
{!currentCaseRecordTypeName} Equals {!Loop_through_Case_Record_Type_Names_nocases}
Result
{!currentCaseRecordTypeName} = "Complaint"


Assignment: Assign Case Status
2 variables were updated.
{!caseExists} Equals No <br>
{!caseStatusList} Add {!caseStatusDetails}
Result
{!caseExists} = "No <br>"
{!caseStatusList} = "<ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul><ul><li><strong>Complaint</strong>: No <br></li></ul>"


Loop: Loop through Case Record Type Names
Iteration  2  of the loop through the  caseRecordTypeNameList  collection occurred.
$$:LoopNext:
Loop Through: [Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]
Iteration: 2
Current iteration item: Third Party Authority


Assignment: Assign Current Case Record Type
1 variable was updated.
{!currentCaseRecordTypeName} Equals {!Loop_through_Case_Record_Type_Names_nocases}
Result
{!currentCaseRecordTypeName} = "Third Party Authority"


Assignment: Assign Case Status
2 variables were updated.
{!caseExists} Equals No <br>
{!caseStatusList} Add {!caseStatusDetails}
Result
{!caseExists} = "No <br>"
{!caseStatusList} = "<ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul><ul><li><strong>Complaint</strong>: No <br></li></ul><ul><li><strong>Third Party Authority</strong>: No <br></li></ul>"


Loop: Loop through Case Record Type Names
Iteration  3  of the loop through the  caseRecordTypeNameList  collection occurred.
$$:LoopNext:
Loop Through: [Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]
Iteration: 3
Current iteration item: Total and Permanent Disability Claim


Assignment: Assign Current Case Record Type
1 variable was updated.
{!currentCaseRecordTypeName} Equals {!Loop_through_Case_Record_Type_Names_nocases}
Result
{!currentCaseRecordTypeName} = "Total and Permanent Disability Claim"


Assignment: Assign Case Status
2 variables were updated.
{!caseExists} Equals No <br>
{!caseStatusList} Add {!caseStatusDetails}
Result
{!caseExists} = "No <br>"
{!caseStatusList} = "<ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul><ul><li><strong>Complaint</strong>: No <br></li></ul><ul><li><strong>Third Party Authority</strong>: No <br></li></ul><ul><li><strong>Total and Permanent Disability Claim</strong>: No <br></li></ul>"


Loop: Loop through Case Record Type Names
Iteration  4  of the loop through the  caseRecordTypeNameList  collection occurred.
$$:LoopNext:
Loop Through: [Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]
Iteration: 4
Current iteration item: Death Benefit Claim


Assignment: Assign Current Case Record Type
1 variable was updated.
{!currentCaseRecordTypeName} Equals {!Loop_through_Case_Record_Type_Names_nocases}
Result
{!currentCaseRecordTypeName} = "Death Benefit Claim"


Assignment: Assign Case Status
2 variables were updated.
{!caseExists} Equals No <br>
{!caseStatusList} Add {!caseStatusDetails}
Result
{!caseExists} = "No <br>"
{!caseStatusList} = "<ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul><ul><li><strong>Complaint</strong>: No <br></li></ul><ul><li><strong>Third Party Authority</strong>: No <br></li></ul><ul><li><strong>Total and Permanent Disability Claim</strong>: No <br></li></ul><ul><li><strong>Death Benefit Claim</strong>: No <br></li></ul>"


Loop: Loop through Case Record Type Names
Iteration  5  of the loop through the  caseRecordTypeNameList  collection occurred.
$$:LoopNext:
Loop Through: [Disability and Terminal Claim,Complaint,Third Party Authority,Total and Permanent Disability Claim,Death Benefit Claim,Terminal Illness Claim]
Iteration: 5
Current iteration item: Terminal Illness Claim


Assignment: Assign Current Case Record Type
1 variable was updated.
{!currentCaseRecordTypeName} Equals {!Loop_through_Case_Record_Type_Names_nocases}
Result
{!currentCaseRecordTypeName} = "Terminal Illness Claim"


Assignment: Assign Case Status
2 variables were updated.
{!caseExists} Equals No <br>
{!caseStatusList} Add {!caseStatusDetails}
Result
{!caseExists} = "No <br>"
{!caseStatusList} = "<ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul><ul><li><strong>Complaint</strong>: No <br></li></ul><ul><li><strong>Third Party Authority</strong>: No <br></li></ul><ul><li><strong>Total and Permanent Disability Claim</strong>: No <br></li></ul><ul><li><strong>Death Benefit Claim</strong>: No <br></li></ul><ul><li><strong>Terminal Illness Claim</strong>: No <br></li></ul>"


Loop: Loop through Case Record Type Names
Loop was completed.
$$:LoopEnd:
End Loop.


Get Records: Get Relationships
One or more  Relationship__c  records were retrieved.
Find all Relationship__c records where:
Account__c Equals {!Get_Account_Record.Id} (0018v0000054Z7tAAE)
AND Type__c Equals Owner
Store the values of these fields in Get_Relationships: Products__c, Id
Result
Successfully found records.
SOQL queries: 1 out of 100
,SOQL query rows: 2 out of 50000


Loop: Loop Through Relationship Records
Iteration  0  of the loop through the  Get_Relationships  collection occurred.
$$:LoopNext:
Loop Through: [a0GOl000004obZjMAI,a0GOl000004obZkMAI]
Iteration: 0
Current iteration item: a0GOl000004obZjMAI


Assignment: Assign Scheme Category List
1 variable was updated.
{!schemeCategoryList} Add Kiwisaver R/Os -- 435870436
Result
{!schemeCategoryList} = "[Kiwisaver R/Os -- 435870436]"


Get Records: Get Product Record
One or more  Product__c  records were retrieved.
Find all Product__c records where:
Id Equals {!Loop_Through_Relationship_Records.Products__c} (a0F8v000000EzB7EAK)
Store the values of these fields in Get_Product_Record: Id
Result
Successfully found records.
SOQL queries: 1 out of 100
,SOQL query rows: 1 out of 50000


Decision: Check Product List
" First_Product " outcome was executed.
$$:OutcomeExecuted:First_Product
Outcome executed: First_Product
Outcome conditions: 
{!productList} () Is Blank true
All conditions must be true (AND)


Assignment: Add First Product
1 variable was updated.
{!productList} Add {!productDetail}
Result
{!productList} = "<p><strong>Account Name</strong>: LGIAsuper Accumulation</p><p><strong>Account Number:</strong> 435870436</p><p><strong>Scheme Category:</strong> Kiwisaver R/Os</p><p><strong>Designation</strong>: Accumulation</p><p><strong>Status</strong>: Closed</p>"


Loop: Loop Through Relationship Records
Iteration  1  of the loop through the  Get_Relationships  collection occurred.
$$:LoopNext:
Loop Through: [a0GOl000004obZjMAI,a0GOl000004obZkMAI]
Iteration: 1
Current iteration item: a0GOl000004obZkMAI


Assignment: Assign Scheme Category List
1 variable was updated.
{!schemeCategoryList} Add ES Public Offer -- 435863187
Result
{!schemeCategoryList} = "[Kiwisaver R/Os -- 435870436,ES Public Offer -- 435863187]"


Get Records: Get Product Record
One or more  Product__c  records were retrieved.
Find all Product__c records where:
Id Equals {!Loop_Through_Relationship_Records.Products__c} (a0F8v000000EzbOEAS)
Store the values of these fields in Get_Product_Record: Id
Result
Successfully found records.
SOQL queries: 1 out of 100
,SOQL query rows: 1 out of 50000


Decision: Check Product List
The  default  outcome was executed.
$$:OutcomeNotExecuted:First_Product
Skipped this outcome because its conditions weren't met: First_Product
Outcome conditions: 
{!productList} (<p><strong>Account Name</strong>: LGIAsuper Accumulation</p><p><strong>Account Number:</strong> 435870436</p><p><strong>Scheme Category:</strong> Kiwisaver R/Os</p><p><strong>Designation</strong>: Accumulation</p><p><strong>Status</strong>: Closed</p>) Is Blank true
All conditions must be true (AND)
$$:DefaultOutcomeExecuted:
Default outcome executed.


Assignment: Add Next Product
2 variables were updated.
{!productList} Add <br>
{!productList} Add {!productDetail}
Result
{!productList} = "<p><strong>Account Name</strong>: LGIAsuper Accumulation</p><p><strong>Account Number:</strong> 435870436</p><p><strong>Scheme Category:</strong> Kiwisaver R/Os</p><p><strong>Designation</strong>: Accumulation</p><p><strong>Status</strong>: Closed</p><br><p><strong>Account Name</strong>: LGIAsuper Accumulation</p><p><strong>Account Number:</strong> 435863187</p><p><strong>Scheme Category:</strong> ES Public Offer</p><p><strong>Designation</strong>: Accumulation</p><p><strong>Status</strong>: Active</p>"


Loop: Loop Through Relationship Records
Loop was completed.
$$:LoopEnd:
End Loop.


Assignment: Assign Output
1 variable was updated.
{!memberSummaryResponse} Equals {!memberSummary}
Result
{!memberSummaryResponse} = "<p><strong>Member Name</strong>: Aaira Farina</p><p><strong>Age</strong>: 37</p><p><strong>First Nation Post Code: </strong>false</p><p><br></p><p><strong>Product(s) List</strong>:</p><p><p><strong>Account Name</strong>: LGIAsuper Accumulation</p><p><strong>Account Number:</strong> 435870436</p><p><strong>Scheme Category:</strong> Kiwisaver R/Os</p><p><strong>Designation</strong>: Accumulation</p><p><strong>Status</strong>: Closed</p><br><p><strong>Account Name</strong>: LGIAsuper Accumulation</p><p><strong>Account Number:</strong> 435863187</p><p><strong>Scheme Category:</strong> ES Public Offer</p><p><strong>Designation</strong>: Accumulation</p><p><strong>Status</strong>: Active</p></p><p><br></p><p><strong>Open Case Summary:</strong></p><p><ul><li><strong>Disability and Terminal Claim</strong>: No</li></ul><ul><li><strong>Complaint</strong>: No <br></li></ul><ul><li><strong>Third Party Authority</strong>: No <br></li></ul><ul><li><strong>Total and Permanent Disability Claim</strong>: No <br></li></ul><ul><li><strong>Death Benefit Claim</strong>: No <br></li></ul><ul><li><strong>Terminal Illness Claim</strong>: No <br></li></ul></p>"


Transaction Committed
Any records that the flow was ready to create, update, or delete were committed to the database.


How the Interview Finished
The flow interview ran for 1.38 seconds and finished on 15 June 2026 at 8:01 pm.
