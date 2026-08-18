system:
    instructions: |You are an AI Agent. Your role is to provide the answers to User's question by Strictly following the defined instructions and actions. NEVER use external Knowledge, NEVER assume anything which is not stated by the user.

                   NEVER display messages stating that Live Chat, Human Support, or Customer Service is unavailable.
                   If an issue cannot be resolved, state clearly what information is missing.


                   The user's current context is:
                   Current App Name: {!@variables.currentAppName}
                   Current Object Name: {!@variables.currentObjectApiName}
                   Current Page Type: {!@variables.currentPageType}
                   Current Record ID: {!@variables.currentRecordId}
    messages:
        welcome: "Welcome to Sparkie. I help you find policies, processes, FAQs and trusted links, with sources provided where available. I can make mistakes, so please verify information before sharing with members - final accountability always sits with you"
        error: "Something went wrong. Try again."
    recommended_prompts:
        in_conversation: False
        welcome_screen: False
    | NEVER show any recommendations in an active session. 

model_config:
    model: "model://sfdc_ai__DefaultVertexAIGemini35Flash"

config:
    agent_label: "Sparkie"
    agent_template: "EmployeeCopilot__AgentforceEmployeeAgent"
    developer_name: "Sparkie"
    agent_type: "AgentforceEmployeeAgent"
    description: "Automate common business tasks and assist users in their flow of work. Agentforce Employee Agent can search knowledge articles and other data sources. Customize it further to meet your employees' business needs."

    additional_parameter__enable_thought_chunks: True
language:
    default_locale: "en_US"
    additional_locales: "en_GB"
    all_additional_locales: False

variables:
    EndUserId: linked string
        source: @MessagingSession.MessagingEndUserId
        description: "This variable may also be referred to as MessagingEndUser Id"
    RoutableId: linked string
        source: @MessagingSession.Id
        description: "This variable may also be referred to as MessagingSession Id"
    ContactId: linked string
        source: @MessagingEndUser.ContactId
        description: "This variable may also be referred to as MessagingEndUser ContactId"
    EndUserLanguage: linked string
        source: @MessagingSession.EndUserLanguage
        description: "This variable may also be referred to as MessagingSession EndUserLanguage"
    ChannelType: linked string
        source: @MessagingSession.ChannelType
        description: "This variable may also be referred to as MessagingSession ChannelType"
    currentAppName: mutable string
        description: "Salesforce Application Name"
        visibility: "External"
    currentObjectApiName: mutable string
        description: "The API name of the current Salesforce object"
        visibility: "External"
    currentPageType: mutable string
        description: "Page type (record, list, home)"
        visibility: "External"
    currentRecordId: mutable string
        description: "The Salesforce ID of the current record"
        visibility: "External"
    VerifiedCustomerId: mutable string
        description: "This variable may also be referred to as VerifiedCustomerId"
        visibility: "Internal"
    isExistingMember: mutable boolean = False
        label: "isExistingMember"
        visibility: "External"
        description: "This variable indicated is the user is an existing member"
    MemberId: mutable string
        label: "Member Id"
        visibility: "External"
        description: "This variable stores the member id."
    SelectedSchemeCategory: mutable string = ""
        label: "Selected Scheme Category"
        visibility: "External"
        description: "This variable stores the value of scheme category selected by the user"
    MemberSummary: mutable string = ""
        description: "This is the summary of the member found after entering the memberId, this shows the Member Summary with list of products and related cases"
        label: "Member Summary"
        visibility: "External"
    IsInsuranceSelected: mutable boolean =
        label: "IsInsuranceSelected"
        visibility: "External"
        description: "This variable indicates if user selected the Insurance Topic"
    IsProductSelected: mutable boolean = 
        label: "IsProductSelected"
        visibility: "External"
        description: "This variable indicates if user selected the Product Topic"
    IsTopicSelected: mutable boolean = False
        label: "IsTopicSelected"
        visibility: "External"
        description: "This variable indicates if user selected any of the topics"
    ShowMainMenu: mutable boolean = True
        label: "ShowMainMenu"
        visibility: "External"
        description: "The boolean variable that indicates is the user needs to be shown the Topic Selection Menu in the Welcome Subagent"
    OutputAnswer: mutable object = ""
        label: "Output Answer"
        visibility: "External"
        description: "This is the search result for the user's question"
    InputQuestion: mutable string = ""
        label: "Input Question"
        visibility: "External"
        description: "This is the question asked by the user"
    SelectedL2Document: mutable string = ""
        label: "SelectedL2Document"
        visibility: "External"
        description: "This is the filepath of the Selected Level 2 document"
    SelectedEmployerName: mutable string = ""
        label: "Selected Employer Name"
        visibility: "External"
        description: "This variable stores the name of employer selected by the user in Insurance branch"

knowledge:
    rag_feature_config_id: ""
    citations_url: ""
    citations_enabled: False

start_agent agent_router:
    label: "Agent Router"
    description: |Welcome the user and determine the appropriate subagent based on user input
    model_config:
        model: "model://sfdc_ai__DefaultEinsteinHyperClassifier"
    reasoning:
        instructions: ->
                set @variables.InputQuestion = @system_variables.user_input
            if @variables.ShowMainMenu == True:
                |use {!@actions.go_to_Welcome_Menu} to route the user to Main Menu.
            else:
                |Route the user to appropriate subagent.
        actions:
            go_to_Welcome_Menu: @utils.transition to @subagent.Welcome_Menu
                description: "This subagent shows the Topic Selection Main Menu and routes the user to different subagents."
                available when @variables.ShowMainMenu == True
            go_to_Insurance: @utils.transition to @subagent.Insurance
                description: "This subagent handles user queries when Insurance Topic is selected in Welcome_Menu"
                available when @variables.IsInsuranceSelected == True
            go_to_Product: @utils.transition to @subagent.Product
                description: "This subagent handles user queries when Product Topic is selected in Welcome_Menu"
                available when @variables.IsProductSelected == True
            go_to_Find_Answers: @utils.transition to @subagent.Find_Answers
                description: "This subagent is responsible for finding answers to the questions asked by the user."
            go_to_Show_Menu: @utils.transition to @subagent.Show_Menu
                description: "This subagent is responsible for transitioning the user back to the top of Main Menu (Welcome_Menu Subagent) when user says 'Show Main Menu' OR 'Return to Main Menu' OR 'Show Menu'"
            go_to_Select_L2_Documents: @utils.transition to @subagent.Select_L2_Documents
                description: "This subagent is responsible for showing the Level 2 (L2) documents that are available for the user to search their queries"
            go_to_Change_Branch: @utils.transition to @subagent.Change_Branch
                description: "This subagent is responsible for transitioning the user back to the top of either Insurance Subagent or Product Subagent when user says 'Change Branch'. After going to the Insurance and Product Subagent, user must see the UI Component to enter a different Member Id. This transitioning path depends on the IsProductSelected and IsInsuranceSelected Variables, for example: if inside Insurance Subagent then 'change branch' will transition the user to the top of Insurance Suabagent, they should see the Member ID Component to enter a different MemberId. Same stands true for Product subagent"
                available when @variables.IsInsuranceSelected == True or @variables.IsProductSelected == True

subagent Welcome_Menu:
    label: "Welcome Menu"
    description: |This sub-agent serves as the primary routing and decision-making agent. It must first present the user with the Topic Selection UI component and capture the user's topic choice. Based on the selected topic, the sub-agent should determine the appropriate path, invoke the relevant workflow or sub-agent, and guide the user through the correct journey. The sub-agent is responsible for ensuring accurate topic selection, seamless routing, and a consistent user experience throughout the interaction.
                       Guardrail: This sub-agent must never generate free-form conversational responses, explanations, greetings, clarifications, or informational content. Its only responsibilities are to render the Topic Selection UI component when a topic selection is required, process the user's selected topic, and perform the appropriate routing or transition based on that selection. At no point should the sub-agent engage in general conversation. It must strictly function as a routing and navigation controller.
    reasoning:
        instructions: ->
            if @variables.ShowMainMenu == True:
                set @variables.ShowMainMenu = False
                |present the topic selection component by invoking the {!@actions.Topic_Selection_Process} action's user_input so they can choose a topic to get started.
            else:
                |There are 2 things the user can do at this stage, so analyse the activity and take the appropriate decisions. There is no scope for inaccuracy:
                |- 1. If the user selects a particular topic from the UI component and clicks on submit, then immediately run {!@actions.Topic_Selection_Process} action. This execution is MANDATORY.
                |- 2. If user doesn't interacts with UI component and directly asks a question, then transition the user to Find_Answers subagent.
            if @variables.IsProductSelected == True and @variables.IsInsuranceSelected == False:
                transition to @subagent.Product
            if @variables.IsInsuranceSelected == True and @variables.IsProductSelected == False:
                transition to @subagent.Insurance
      
        actions:
            Topic_Selection_Process: @actions.Topic_Selection_Process
                with inputs = ...
                set @variables.IsInsuranceSelected = @outputs.IsInsuranceSelected
                set @variables.IsProductSelected = @outputs.IsProductSelected
                set @variables.IsTopicSelected = @outputs.IsTopicSubmitted
            go_to_find_answers: @utils.transition to @subagent.Find_Answers
                available when @variables.IsTopicSelected == False and @variables.ShowMainMenu == False
            go_to_Insurance_subagent: @utils.transition to @subagent.Insurance
                available when @variables.IsInsuranceSelected == True and @variables.IsProductSelected == False and @variables.IsTopicSelected == True
            go_to_product_subagent: @utils.transition to @subagent.Product
                available when @variables.IsProductSelected == True and @variables.IsInsuranceSelected == False and @variables.IsTopicSelected == True
    actions:
        Topic_Selection_Process:
            description: |
                Renders the custom lightning topic-selection component and once the user submits, sets IsInsuranceSelected and IsProductSelected, and IsTopicSubmitted.
            label: "Topic Selection Process"
            require_user_confirmation: False
            include_in_progress_indicator: False
            source: "Topic_Selection_Process"
            target: "apex://AFA_ProcessTopicSelection"                                                                                         
            inputs:
                "inputs": object
                    description: |
                      Pass the input given by the user from the rendered component
                    label: "Topic Selection Input"
                    is_required: False
                    is_user_input: True
                    complex_data_type_name: "c__CLT_Process_Topic_Selection"
            outputs:
                "IsInsuranceSelected": boolean
                    description: |
                      This shows whether the Insurance Topic is selected or not
                    label: "Is Insurance Selected"
                    is_displayable: False
                    filter_from_agent: False
                "IsProductSelected": boolean
                    description: |
                      This shows whether the Product Topic is selected or not
                    label: "Is Product Selected"
                    is_displayable: False
                    filter_from_agent: False
                "IsTopicSubmitted": boolean
                    description: |
                      This Shows whether the Submit button selected or not
                    label: "Is Topic Submitted"
                    is_displayable: False
                    filter_from_agent: False

subagent Product:
    label: "Product"
    system:
        instructions: |If the user is transitioned to this Subagent after saying Change Branch, then it means you need to render {!@actions.Get_Member_ID} action's user_input component again to start and start this subagent from beginning
    description: |This Subagent is responsible to answer Product related queries. It will first give an option to get the Member Id and make decisions on where to route the user.
                  The agent MUST ALWAYS invoke the {!@actions.Get_Member_ID} action's user_input component,
    reasoning:
        instructions: ->
            if @variables.IsProductSelected == True:
                |Step 1: Always show {!@actions.Get_Member_ID} action's user_input to get the memberData. Use this memberData provided by the user and then run the action and set the output variables.
                |There are 2 things user can do at this stage, so analyse the activity and take the appropriate decisions. There is no scope for inaccuracy:
                |- 1. If user selects a particular Scheme Category Value from the UI component and clicks on submit, then immediately run {!@actions.Get_Member_ID} action. This execution is MANDATORY, after executing show the user the Member name and scheme category opted.
                |- 2. After showing the component, If user doesn't give any input with UI component and directly asks a question, then only you need to transition to the Find_Answers subagent.
        actions:
            Get_Member_ID: @actions.Get_Member_ID
                with memberData = ...
                set @variables.isExistingMember = @outputs.existingMember
                set @variables.MemberId = @outputs.memberId
                set @variables.MemberSummary = @outputs.memberSummary
                set @variables.SelectedSchemeCategory = @outputs.selectedSchemeCategory
            go_to_Find_Answers: @utils.transition to @subagent.Find_Answers
    actions:
        Get_Member_ID:
            description: |
                Ask if Existing Member and Get Member ID
            label: "Get Member ID"
            require_user_confirmation: False
            include_in_progress_indicator: False
            source: "Get_Member_ID"
            target: "apex://AF_MemberQuestionService"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            inputs:
                "memberData": object
                    description: |
                      This is an input component rendered using c__memberInput custom lightning type. Always render the input component before invoking the action.
                    label: "memberData"
                    is_required: True
                    is_user_input: True
                    complex_data_type_name: "c__memberInput"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
            outputs:
                "existingMember": boolean
                    description: |
                      This indicates if the user is an existing member.
                    label: "Existing Member"
                    is_displayable: False
                    filter_from_agent: False
                "memberId": string
                    description: |
                      If the user is an existing member then this variable stores the member id (also known as client id).
                    label: "Member ID"
                    is_displayable: False
                    filter_from_agent: False
                "memberSummary": string
                    description: |
                      This variable stores the summary of the membership details.
                    label: "Member Summary"
                    is_displayable: False
                    filter_from_agent: False
                "selectedSchemeCategory": string
                    description: |
                      This variable stores scheme category value about which user is going to ask their question.
                    label: "Selected Scheme Category"
                    is_displayable: False
                    filter_from_agent: False

subagent Insurance:
    label: "Insurance"
    system:
        instructions: "If the user is transitioned to this Subagent after saying 'Change Branch' then it means you need to render {!@actions.Get_Insurance_Member_ID} action's user_input component again to start this subagent from beginning by capturing the member id. Do not ask any follow up questions."
    description: |This Subagent is responsible to answer insurance related queries. It will first give an option to get the Member Id, then make decisions on where to route the user.
                  The agent MUST ALWAYS invoke the {!@actions.Get_Insurance_Member_ID} action's user_input component,
    reasoning:
        instructions: ->
            if @variables.IsInsuranceSelected == True:
                |Step 1: Always show  {!@actions.Get_Insurance_Member_ID}  action's user_input to get the memberData. Use this memberData provided by the user and then run the action and set the output variables.
                |There are 2 things the user can do at this stage, so analyse the activity and take the appropriate decisions. There is no scope for inaccuracy:
                |- 1. If user selects a particular Scheme Category value and Employer name from the UI component and clicks on submit, then immediately run {!@actions.Get_Insurance_Member_ID} action. This execution is MANDATORY. After executing show the user the Member name, Scheme category and Employer Name opted.
                |- 2. If user doesn't interact with UI component and directly asks a question, then transition the user to Find_Answers subagent.
        actions:
            Get_Insurance_Member_ID: @actions.Get_Insurance_Member_ID
                with memberData = ...
                set @variables.isExistingMember = @outputs.existingMember
                set @variables.MemberId = @outputs.memberId
                set @variables.MemberSummary = @outputs.memberSummary
                set @variables.SelectedEmployerName = @outputs.selectedEmployer
                set @variables.SelectedSchemeCategory = @outputs.selectedSchemeCategory
            go_to_Find_Answers: @utils.transition to @subagent.Find_Answers
    actions:
        Get_Insurance_Member_ID:
            description: |
                Ask if Existing Member and Get Member ID with optional Employer
            label: "Get Insurance Member ID"
            require_user_confirmation: False
            include_in_progress_indicator: False
            source: "Get_Insurance_Member_ID"
            target: "apex://AF_InsuranceMemberInput"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            inputs:
                "memberData": object
                    description: |
                      This is an input component rendered using c__insuranceMemberInput custom lightning type. Always render the input component before invoking the action.
                    label: "memberData"
                    is_required: True
                    is_user_input: True
                    complex_data_type_name: "c__insuranceMemberInput"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            outputs:
                "existingMember": boolean
                    description: |
                      This indicates if the user is an existing member.
                    label: "Existing Member"
                    is_displayable: False
                    filter_from_agent: False
                "memberId": string
                    description: |
                      If the user is an existing member, then this variable stores the member id (also known as client id).
                    label: "Member ID"
                    is_displayable: False
                    filter_from_agent: False
                "memberSummary": string
                    description: |
                      This variable stores the summary of the membership details.
                    label: "Member Summary"
                    is_displayable: False
                    filter_from_agent: False
                "selectedEmployer": string
                    description: |
                      This variable store scheme Employer name about which user is going to ask their question.
                    label: "Selected Employer"
                    is_displayable: False
                    filter_from_agent: False
                "selectedSchemeCategory": string
                    description: |
                      This variable store scheme category value about which user is going to ask their question.
                    label: "Selected Scheme Category"
                    is_displayable: False
                    filter_from_agent: False

subagent Find_Answers:
    label: "Find Answers"
    description: "This Subagent is responsible for searching user's question in the Data cloud and the knowledge articles"
    model_config:
        model: "model://sfdc_ai__DefaultVertexAIGemini35Flash"
    system:
        instructions: |After presenting the answer, do not ask the user any follow-up question - end the response with the answer itself.
                       When the response is based on content retrieved from the file search, always include a "Sources" section listing the file name(s) should be shown as the hyperlinks without any static URLs in the response.
                       If no relevant content is found in the retrieved files, state that clearly and do not fabricate a source or citation.
    reasoning:
        instructions: ->
            
            |Run  {!@actions.AF_Unified_ADL_and_KA_Hybrid_Search_Service}  and analyse the output to generate an answer for the user and display the answer.
             - if the answer is not found then display an apology message "Sorry, I am unable to find this information" and DO NOT ask for any clarifications/context/follow-up questions.
             -If the user asked anything regarding these following questions,
              -Generate/Publish/drafting a knowledge article
             - Draft/write/send an email
             - Export data in excel or csv
             - Generate a report
             - Create/Modify cases
             - Execute transactions
             - Update member data
             - create ,edit ,delete any records in the system
              then display a message "Sorry, I am unable to Answer" and DO NOT ask for any clarifications/context/follow-up questions.
             Make sure you add Sources for every response
        actions:
            AF_Unified_ADL_and_KA_Hybrid_Search_Service: @actions.AF_Unified_ADL_and_KA_Hybrid_Search_Service
                with employerName = @variables.SelectedEmployerName
                with isExistingMember = @variables.isExistingMember
                with isInsuranceSelected = @variables.IsInsuranceSelected
                with isProductSelected = @variables.IsProductSelected
                with schemeCategory = @variables.SelectedSchemeCategory
                with searchQuery = ...
                with selectedL2DocumentFilePath = @variables.SelectedL2Document
    actions:
        AF_Unified_ADL_and_KA_Hybrid_Search_Service:
            description: |
                This action is used for searching user's question in Agentforce Data Library and Knowledge Articles
            label: "AF Unified ADL and KA Hybrid Search Service"
            require_user_confirmation: False
            include_in_progress_indicator: True
            progress_indicator_message: "Please wait while I retrieve the information"
            target: "apex://AF_UnifiedSearchService"
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            inputs:
                "employerName": string
                    description: |
                      This variable stores the name of employer selected by user in Insurance Subagent.
                    label: "employerName"
                    is_required: False
                    is_user_input: False
                "isExistingMember": boolean
                    description: |
                      This is a Boolean variable that indicates if user is inquiring about an existing member or not.
                    label: "isExistingMember"
                    is_required: False
                    is_user_input: False
                "isInsuranceSelected": boolean
                    description: |
                      This is a Boolean variable that indicates if user selected the Insurance Subagent.
                    label: "isInsuranceSelected"
                    is_required: False
                    is_user_input: False
                "isProductSelected": boolean
                    description: |
                      This is a Boolean variable that indicates if user selected the Product Subagent.
                    label: "isProductSelected"
                    is_required: False
                    is_user_input: False
                "schemeCategory": string
                    description: |
                      This is a String variable that stores the value of scheme category selected by the user.
                    label: "schemeCategory"
                    is_required: False
                    is_user_input: False
                "searchQuery": string
                    description: |
                      Question asked by the User for which you need to provide a response.
                    label: "searchQuery"
                    is_required: True
                    is_user_input: False
                "selectedL2DocumentFilePath": string
                    description: |
                      This variable stores the filepath value of Selected L2 Document
                    label: "selectedL2DocumentFilePath"
                    is_required: False
                    is_user_input: False
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
            outputs:
                "Data": string
                    description: |
                      Resolved prompt passed to Agentforce reasoning engine.
                    label: "Data"
                    is_displayable: False
                    filter_from_agent: False

subagent Show_Menu:
    label: "Show Menu"
    description: | 
        Handles requests to display the Main Menu. Triggers when the user explicitly asks to return to main menu by using phrases such as "Return to Main Menu", "Main Menu", "Show Main Menu".
    reasoning:
        instructions: ->
            set @variables.ShowMainMenu = True
            set @variables.IsProductSelected = False
            set @variables.IsInsuranceSelected = False
            set @variables.isExistingMember = False
            set @variables.SelectedSchemeCategory = ""
            set @variables.InputQuestion = ""
            set @variables.OutputAnswer = ""
            set @variables.MemberId = ""
            set @variables.MemberSummary = ""
            set @variables.SelectedEmployerName = ""
            set @variables.SelectedL2Document = ""
            set @variables.IsTopicSelected = False
            run @actions.go_to_welcome_subagent
        actions:
            go_to_welcome_subagent: @utils.transition to @subagent.Welcome_Menu

subagent Select_L2_Documents:
    label: "Select L2 Documents"
    description: |Strictly invoke this subagent only when the user's exact message is "show more docs".Once user selects a document from input component and clicks on 'Submit' button, then run {!@actions.Select_Insurance_L2_Document} action to store the selected document's filepath in {!@variables.SelectedL2Document}.
    reasoning:
        instructions: ->
            if @variables.IsInsuranceSelected == True and @variables.IsProductSelected == False:
                |Step 1: Always Call {!@actions.Select_Insurance_L2_Document} action's User_Input component to get the Selection of the L2 Documents. 
                 Step 2: When user submits the selection then run {!@actions.Select_Insurance_L2_Document} action.
            if @variables.IsInsuranceSelected == False and @variables.IsProductSelected == True:
                |Step 1: Always Call {!@actions.Select_Product_L2_Document} action's User_Input component to get the Selection of the L2 Documents.
                 Step 2: When user submits the selection then run {!@actions.Select_Product_L2_Document} action.
            else:
                |Step 1: Always Call {!@actions.Select_Brighter_Library_L2_Document} action's User_Input component to get the Selection of the L2 Documents. 
                 Step 2: When user submits the selection then run {!@actions.Select_Brighter_Library_L2_Document} action.
            if @variables.SelectedL2Document != None and @variables.SelectedL2Document != "":
                | Display: 'I've loaded the L2 Document, please ask your question'.
                  go to {!@actions.go_to_Find_Answers_Subagent}.
        actions:
            Select_Insurance_L2_Document: @actions.Select_Insurance_L2_Document
                with selectorData = ...
                set @variables.SelectedL2Document = @outputs.selectedL2Document
                available when @variables.IsInsuranceSelected == True and @variables.IsProductSelected == False
            Select_Product_L2_Document: @actions.Select_Product_L2_Document
                with selectorData = ...
                set @variables.SelectedL2Document = @outputs.selectedL2Document
                available when @variables.IsInsuranceSelected == False and @variables.IsProductSelected == True
            Select_Brighter_Library_L2_Document: @actions.Select_Brighter_Library_L2_Document
                with selectorData = ...
                set @variables.SelectedL2Document = @outputs.selectedL2Document
                available when @variables.IsInsuranceSelected == False and @variables.IsProductSelected == False
            go_to_Find_Answers_Subagent: @utils.transition to @subagent.Find_Answers
            go_to_Show_Menu: @utils.transition to @subagent.Show_Menu
                description: "When user types 'Show Menu' or 'Switch Topic' or 'Main Menu' or 'Return to Main Menu' then transition the user to show menu subagent as user wants to see the Topic Selection Menu Again."
    actions:
        Select_Insurance_L2_Document:
            description: |
                This action is used for getting the L2 Document Selection using the Input Rendering Component. Run this action only when a selection is made.
            label: "Select Insurance L2 Document"
            require_user_confirmation: False
            include_in_progress_indicator: False
            source: "Select_Insurance_L2_Document"
            target: "apex://AF_L2DocumentSelector"
                                                                                                                                                                                
            inputs:
                "selectorData": object
                    description: |
                      Render this Input component to get L2 Document selection.
                    label: "selectorData"
                    is_required: True
                    is_user_input: True
                    complex_data_type_name: "c__SparkieL2DocumentSelectorInsurance"
                                                                                                                                                                                
            outputs:
                "selectedL2Document": string
                    description: |
                      This variable stores the filepath of selected L2 Document
                    label: "Selected L2 Document"
                    is_displayable: False
                    filter_from_agent: False
        Select_Product_L2_Document:
            description: |
                This action is used for getting the L2 Document Selection using the Input Rendering Component for Product Subagent.
            label: "Select Product L2 Document"
            require_user_confirmation: False
            include_in_progress_indicator: False
            progress_indicator_message: "Render this Input component to get L2 Document selection."
            source: "Select_Product_L2_Document"
            target: "apex://AF_L2DocumentSelector"
                                                                                                                                                                                
            inputs:
                "selectorData": object
                    description: |
                      Render this Input component to get L2 Document selection.
                    label: "selectorData"
                    is_required: True
                    is_user_input: True
                    complex_data_type_name: "c__SparkieL2DocumentSelectorProduct"
                                                                                                                                                                                
            outputs:
                "selectedL2Document": string
                    description: |
                      This variable stores the filepath of selected L2 Document
                    label: "Selected L2 Document"
                    is_displayable: False
                    filter_from_agent: False
        Select_Brighter_Library_L2_Document:
            description: |
                This action is used for getting the L2 Document Selection using the Input Rendering Component for Brighter Library.
            label: "Select Brighter Library L2 Document"
            require_user_confirmation: False
            include_in_progress_indicator: False
            source: "Select_Brighter_Library_L2_Document"
            target: "apex://AF_L2DocumentSelector"
                                                                                                                
            inputs:
                "selectorData": object
                    description: |
                       Render this Input component to get L2 Document selection.
                    label: "selectorData"
                    is_required: True
                    is_user_input: True
                    complex_data_type_name: "c__SparkieL2DocumentSelectorBrighterLibrary"
                                                                                                                
            outputs:
                "selectedL2Document": string
                    description: |
                      This variable stores the filepath of selected L2 Document
                    label: "Selected L2 Document"
                    is_displayable: False
                    filter_from_agent: False

subagent Change_Branch:
    label: "Change Branch"
    system:
        instructions: "Your job is to transition the user back to the beginning of either Insurance Subagent or Product Subagent based on the defined conditions. NEVER ask any follow up questions."
    description: |This subagent is responsible for transitioning the user back to the top of Insurance or Product Subagent. Triggering utterance for this subagent is: "Change Branch".
    before_reasoning:
        set @variables.ShowMainMenu = False
        set @variables.isExistingMember = False
        set @variables.SelectedSchemeCategory = ""
        set @variables.InputQuestion = ""
        set @variables.OutputAnswer = ""
        set @variables.MemberId = ""
        set @variables.MemberSummary = ""
        set @variables.SelectedEmployerName = ""
        set @variables.SelectedL2Document = ""
    reasoning:
        instructions: ->
            |Transition the user to agent_router
            if @variables.IsProductSelected == True and @variables.IsInsuranceSelected == False:
                transition to @subagent.Product
            else:
                transition to @subagent.Insurance
        actions:
            go_to_Product_Subagent: @utils.transition to @subagent.Product
            go_to_Insurance_Subagent: @utils.transition to @subagent.Insurance
