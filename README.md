Active	Active__c	Checkbox		False	
Additional Document	Additional_Document__c	Lookup(Document Detail)		True	
Created By	CreatedById	Lookup(User)		False	
Key Field API Name	Key_Field_API_Name__c	Text(255)		False	
Key Field Value	Key_Field_Value__c	Text(255)		False	
Last Modified By	LastModifiedById	Lookup(User)		False	
Mapping Number	Name	Auto Number		True	
Object API Name	Object_API_Name__c	Text(255)		False	
Owner	OwnerId	Lookup(User,Group)		True	
Primary Document	Primary_Document__c	Lookup(Document Detail)		True	
Sub Topic	Sub_Topic__c	Text(255)		False	
Topic	Topic__c	Text(255)		False	
Valid From	Valid_From__c	Date		False	
Valid To	Valid_To__c	Date
                    
                    
                    
                    
                                        {
                                "description": "Used in Sparkie for showing asking the existing member question and getting the Member ID",
                                "lightning:type": "@apexClassType/c__AF_MemberQuestionService$MemberInput",
                                "title": "Existing Member Question and Member ID"
                            }


                                            <?xml version="1.0" encoding="UTF-8"?>
                <LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
                    <apiVersion>62.0</apiVersion>
                    <isExposed>true</isExposed>
                    <targets>
                        <target>lightning__AgentforceInput</target>
                    </targets>
                    <targetConfigs>
                        <targetConfig targets="lightning__AgentforceInput">
                            <targetType name="c__memberInput"/>
                        </targetConfig>
                    </targetConfigs>
                </LightningComponentBundle>
