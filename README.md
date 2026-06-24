system:
    instructions: |You are an AI Agent.

        The user's current context is:
        Current App Name: {!@variables.currentAppName}
        Current Object Name: {!@variables.currentObjectApiName}
        Current Page Type: {!@variables.currentPageType}
        Current Record ID: {!@variables.currentRecordId}
    messages:
        welcome: "Welcome to Sparkie. I help you find policies, processes, FAQs and trusted links, with sources provided where available. I can make mistakes, so please verify information before sharing with members - final accountability always sits with you"
        error: "Something went wrong. Try again."

config:
    agent_label: "Sparkie"
    agent_template: "EmployeeCopilot__AgentforceEmployeeAgent"
    developer_name: "Sparkie_V3"
    agent_type: "AgentforceEmployeeAgent"
    description: "Automate common business tasks and assist users in their flow of work. Agentforce Employee Agent can search knowledge articles and other data sources. Customize it further to meet your employees' business needs."

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
        description: ""
    Member_Id: mutable string
        label: "Member Id"
        visibility: "External"
        description: ""
    Selected_Scheme_Category: mutable string = ""
        label: "Selected Scheme Category"
        visibility: "External"
        description: ""
    Member_Summary: mutable string = ""
        description: "This is the summary of the member found after entering the memberId, this shows the Member Summary with list of products and related cases"
        label: "Member Summary"
        visibility: "External"
    # Canonical context variables for Process Topic selector in Preview
    processTopic: mutable string = ""
        label: "Process Topic"
        visibility: "External"
        description: "Canonical context key for the selected process topic"
    IsInsuranceSelected: mutable boolean = False
        label: "IsInsuranceSelected"
        visibility: "External"
        description: ""
    IsProductSelected: mutable boolean = False
        label: "IsProductSelected"
        visibility: "External"
        description: ""
    IsTopicSelected: mutable boolean = False
        label: "IsTopicSelected"
        visibility: "External"
        description: ""
    UserSelection: mutable object
        label: "UserSelection"
        visibility: "External"
        description: "The topic value selected by the user from the lightning component"
    ShowTopicMenu: mutable boolean = True
        label: "ShowTopicMenu"
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
    EmployerName: mutable string = ""
        label: "Employer Name"
        visibility: "External"
        description: "This is the value of Emloyer Selected by the user."
    IsEmployerSelected: mutable boolean = False
        label: "IsEmployerSelected"
        visibility: "External"
        description: "This indicates if the user selected any employer in the Insurance Topic."
    Has_Documents: mutable boolean
        label: "Has Documents"
        visibility: "External"
        description: ""
    Selected_Topic_for_L2: mutable string
        label: "Selected Topic for L2"
        visibility: "External"
        description: ""
    SwitchSubTopic: mutable boolean = False
        label: "Switch Sub Topic"
        visibility: "External"
        description: "This is a boolena variable that indicated if the user requested for switching the sub topic."
    num_turn: mutable number = 0
        label: "turn number"
        visibility: "External"
        description: "This is a boolena variable that indicated if the user requested for switching the sub topic."
    Document_List_Options: mutable object
        label: "Document List Options"
        visibility: "External"
        description: ""
    Session_ID: mutable string
        label: "Session ID"
        visibility: "External"
        description: ""
    SelectedL2Document: mutable string
        label: "SelectedL2Document"
        visibility: "External"
        description: ""
    Document_Options_for_L2: mutable object
        label: "Document Options for L2"
        visibility: "External"
        description: ""

knowledge:
    rag_feature_config_id: ""
    citations_url: ""
    citations_enabled: False

start_agent agent_router:
    label: "Agent Router"
    description: "Welcome the user and determine the appropriate subagent based on user input"
    model_config:
        model: "model://sfdc_ai__DefaultEinsteinHyperClassifier"
    reasoning:
        instructions: ->
            if @variables.ShowTopicMenu == True:
                |You are an agent routed for this assistant. Welcome the guest and analyze their input to determine the most appropriate subagentto handle their request.
                | {!@actions.go_to_Welcome_Topic}
            if @variables.SwitchSubTopic == True:
                | You need to show the Member Id component again by transitioning the user at the top of Product or Insurance Topic.
                | {!@actions.go_to_Switch_Sub_Topic}
        actions:
            go_to_Welcome_Topic: @utils.transition to @subagent.Welcome_Topic
                description: "Shows the Topic Selection Menu"
                available when @variables.ShowTopicMenu == True
            go_to_Insurance: @utils.transition to @subagent.Insurance
                description: "Handles the queries when user explicitly selects the Insurance Topic"
                available when @variables.IsInsuranceSelected == True
            go_to_Product: @utils.transition to @subagent.Product
                description: "Handles the queries when user explicitly selects the Product Topic"
                available when @variables.IsProductSelected == True
            go_to_Find_Answers: @utils.transition to @subagent.Find_Answers
                description: "Handles the questions asked by the user"
            go_to_Show_Menu: @utils.transition to @subagent.Show_Menu
            go_to_L2_Document_Answers: @utils.transition to @subagent.L2_Document_Answers
            go_to_Switch_Sub_Topic: @utils.transition to @subagent.Switch_Sub_Topic
                description: "Handles queries when user wants to switch the sub topic to enter a different member id"
                available when @variables.IsInsuranceSelected == True or @variables.IsProductSelected == True
subagent Welcome_Topic:
    label: "Welcome Topic"
    description: "Greets the user and presents a topic selection UI using a custom lightning input component, if a selection is made in the UI component then run the action and route the user to the Insurance or Product subagent based, no selection route to Find_Answers subagent."
    reasoning:
        instructions: ->
            if @variables.ShowTopicMenu == True:
                set @variables.ShowTopicMenu = False
                |Welcome the user warmly and present the topic selection component by caling the {!@actions.Topic_Selection_Process} action's user_input so they can choose a topic to get started.
            else:
                |There are 2 things the user can do at this stage, so analyse the activity and take the appropriate decisions. There is no scope for the inaccuracy:
                |1. If they select the topic from the UI component (they can either select "Product" or "Insurance"), if they make a selection then run {!@actions.Topic_Selection_Process} action by passing in the "inputs" and store the output in the mapped variables.
                |2. If they don't select any option and start typing their question, in this case transition the user to Find_Answers subagent.
            if @variables.IsProductSelected == True:
                transition to @subagent.Product
            if @variables.IsInsuranceSelected == True:
                transition to @subagent.Insurance
        actions:
            Topic_Selection_Process: @actions.Topic_Selection_Process
                with inputs = ...
                set @variables.IsInsuranceSelected = @outputs.IsInsuranceSelected
                set @variables.IsProductSelected = @outputs.IsProductSelected
                set @variables.IsTopicSelected = @outputs.IsTopicSubmitted
            go_to_find_answers: @utils.transition to @subagent.Find_Answers
                available when @variables.IsTopicSelected == False and @variables.ShowTopicMenu == False
            go_to_Insurance_subagent: @utils.transition to @subagent.Insurance
                available when @variables.IsInsuranceSelected == True
            go_to_product_subagent: @utils.transition to @subagent.Product
                available when @variables.IsProductSelected == True
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
    description: "Use this subagent to handle all inquiries related to the member's products. It must always begin by capturing the Member ID to retrieve and display the member's summary, active products, and recent cases. Once the member is successfully identified, use the available actions to accurately answer the user's product-specific questions."
    model_config:
        model: "model://sfdc_ai__DefaultGPT54Mini"
    reasoning:
        instructions: ->
            if @variables.IsProductSelected == True:
                |Step 1: Always Call {!@actions.Get_Member_ID} action's user_input to get the memberData. Use this memberData to run the action and set the output variables.
                |There are 2 things the user can do at this stage, so analyse the activity and take the appropriate decisions. There is no scope for the inaccuracy:
                |1. If the user select a particular product from the UI component and clicks on submit then RUN {!@actions.Get_Member_ID} action by passing in the "memberData" and store the output in the mapped variables.
                |2. If they don't select any product and start typing their question, then store their question.
        actions:
            Get_Member_ID: @actions.Get_Member_ID
                with memberData = ...
                set @variables.isExistingMember = @outputs.existingMember
                set @variables.Member_Id = @outputs.memberId
                set @variables.Member_Summary = @outputs.memberSummary
                set @variables.Selected_Scheme_Category = @outputs.selectedSchemeCategory
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
    description: "This Subagent is used to solve customer queries related to the Insurance"
    reasoning:
        instructions: ->
            |You'll be only work when {!@variables.IsInsuranceSelected}= True and You handle all insurance-related queries. Follow these steps in strict order.
             STEP 1 — Acknowledge the topic and begin. Confirm to the user that you will help with their insurance query. Call your insurance-specific actions as needed to answer the user's questions. if no actions are tied just greet the user that they are in the insurance topic
             HARD RULES:
             Only enter this subagent when {!@variables.IsInsuranceSelected} was explicitly set to True by the Topic_Selection_Process action. Never enter this subagent for any other reason.
             Do not answer product-related questions, Knowledge based questions and general inquires.
             Treat each user question as a new request. Do not repeat prior answers.

subagent Find_Answers:
    label: "Find Answers"
    description: "This Subagent is responsible for searching user's question in the Data cloud and the knowledge articles"
    model_config:
        #model: "model://sfdc_ai__DefaultEinsteinHyperClassifier"
        model: "model://sfdc_ai__DefaultGPT5"
    reasoning:
        instructions: ->
            set @variables.InputQuestion = @system_variables.user_input
            | Run {!@actions.AF_Unified_ADL_and_KA_Hybrid_Search_Service} and analyse the output to generate an answer for the user with citations and display the answer.
        actions:
            AF_Unified_ADL_and_KA_Hybrid_Search_Service: @actions.AF_Unified_ADL_and_KA_Hybrid_Search_Service
                with employerName = @variables.EmployerName
                with isEmployerSelected = @variables.IsEmployerSelected
                with isExistingMember = @variables.isExistingMember
                with isInsuranceSelected = @variables.IsInsuranceSelected
                with isProductSelected = @variables.IsProductSelected
                with schemeCategory = @variables.Selected_Scheme_Category
                with searchQuery = @variables.InputQuestion
                
    actions:
        AF_Unified_ADL_and_KA_Hybrid_Search_Service:
            description: |
                This action is used for searching user's question in Agentforce Data Library and Knowledge Articles
            label: "AF Unified ADL and KA Hybrid Search Service"
            require_user_confirmation: False
            include_in_progress_indicator: True
            progress_indicator_message: "Please wait while I retrieve the information"
            source: "AF_Unified_ADL_and_KA_Hybrid_Search_Service"
            target: "apex://AF_UnifiedSearchService"
                
            inputs:
                "employerName": string
                    description: |
                      This variable stores the name of employer selected by user in Insurance Subagent.
                    label: "employerName"
                    is_required: False
                    is_user_input: False
                "isEmployerSelected": boolean
                    description: |
                      This is a Boolean variable that indicates if any Employer is selected by the User in Insurance Subagent.
                    label: "isEmployerSelected"
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
                      This is a String variable that stores the value of scheme category selected by the user
                    label: "schemeCategory"
                    is_required: False
                    is_user_input: False
                "searchQuery": string
                    description: |
                      Question asked by the User for which you need to provide a response.
                    label: "searchQuery"
                    is_required: True
                    is_user_input: False
                
            outputs:
                "Data": string
                    description: |
                      Resolved prompt passed to Agentforce reasoning engine.
                    label: "Data"
                    is_displayable: False
                    filter_from_agent: False
                "sources": object
                    description: |
                      Citation sources for inline references.
                    label: "sources"
                    is_displayable: False
                    filter_from_agent: False
                    complex_data_type_name: "@apexClassType/AiCopilot__GenAiCitationInput"

subagent Show_Menu:
    label: "Show Menu"
    description: | 
        Handles requests to display the topic selection menu. Triggers when the user explicitly asks to see the menu using the phrases such as "Show Menu", "Switch Topic", "Show Main Menu".
    reasoning:
        instructions: ->
            set @variables.ShowTopicMenu = True
            set @variables.IsProductSelected = False
            set @variables.IsInsuranceSelected = False
            set @variables.isExistingMember = False
            set @variables.Selected_Scheme_Category = ""
            set @variables.InputQuestion = ""
            set @variables.OutputAnswer = ""
            | Transition the user to the welcome topic to show the topic menu again using {!@actions.go_to_welcome_subagent}.
        actions:
            go_to_welcome_subagent: @utils.transition to @subagent.Welcome_Topic

subagent L2_Document_Answers:
    label: "L2 Document Answers"
    description: |

        This Subagent is Invoked when User type "Show L2 documents", It has to take the certain inputs from the Agent Context varaibles and pass them to the action and then render the component to let users select the L2 documents for answers, After User clicks on Submit show a message "Please Ask your Questions"
    reasoning:
        instructions: ->
            |Strictly call the UI Component of  {!@actions.AF_Get_L2_Documents_V2} action immediately, pass the Selected Topic to the Action before rendering the UI component
             It must show the UI component to let users select the L2 documents., Showing Documents names in Normal Raw text is strictly not allowed
            if @variables.IsProductSelected == True:
                set @variables.Selected_Topic_for_L2 = "Product"
            if @variables.IsInsuranceSelected == True:
                set @variables.Selected_Topic_for_L2 = "Insurance"
            if @variables.IsProductSelected == False and @variables.IsInsuranceSelected == False:
                set @variables.Selected_Topic_for_L2 = "Brighter Library"
        actions:
            AF_Get_L2_Documents_V2: @actions.AF_Get_L2_Documents_V2
                with agentSessionId = @variables.RoutableId
                with schemeCategory = @variables.Selected_Scheme_Category
                with selectedTopic = @variables.Selected_Topic_for_L2
                set @variables.Document_List_Options = @outputs.documentOptions
                set @variables.Has_Documents = @outputs.hasDocuments
                set @variables.SelectedL2Document = @outputs.selectedFilePath
    actions:
        AF_Get_L2_Documents_V2:
            description: |
                Fetches the available L2 documents for the current scheme category and topic.
            label: "AF Get L2 Documents V2"
            require_user_confirmation: False
            include_in_progress_indicator: False
            source: "AF_Get_L2_Documents_V2"
            target: "apex://AF_GetL2DocumentsService"
                                                                                                                                                                                                                                                                                                        
            inputs:
                "agentSessionId": string
                    description: |
                      The active Session ID from Agent Builder used to map selected document value back to the chat
                    label: "Agent Session ID"
                    is_required: False
                    is_user_input: False
                "schemeCategory": string
                    description: |
                      Pass the scheme Category which is already in Agent's Context
                    label: "Scheme Category"
                    is_required: False
                    is_user_input: False
                "selectedTopic": string
                    description: |
                      Pass the Selected topic which is already in Agent's Context
                    label: "Selected Topic"
                    is_required: True
                    is_user_input: False
                                                                                                                                                                                                                                                                                                        
            outputs:
                "documentOptions": list[object]
                    description: |
                      The list of documents found for the category and topic.
                    label: "Document Options"
                    is_displayable: False
                    filter_from_agent: False
                    complex_data_type_name: "c__documentResult"
                "hasDocuments": boolean
                    description: |
                      True if any documents were found.
                    label: "Has Documents"
                    is_displayable: False
                    filter_from_agent: False
                "selectedDocumentName": string
                    description: |
                      Populated by the LWC on Submit
                    label: "Selected Document Name"
                    is_displayable: False
                    filter_from_agent: False
                "selectedFilePath": string
                    description: |
                      Populated by the LWC on Submit
                    label: "Selected File Path"
                    is_displayable: False
                    filter_from_agent: False

subagent Switch_Sub_Topic:
    label: "Switch Sub Topic"
    description: | 
        This subagent is responsible for transitioning the user back to the top of Insurance or Product Subagent. Triggering utterance for this subagent is: "Switch Sub Topic" .
    reasoning:
        instructions: ->
            set @variables.ShowTopicMenu = False
            set @variables.isExistingMember = False
            set @variables.Selected_Scheme_Category = ""
            set @variables.InputQuestion = ""
            set @variables.OutputAnswer = ""
            set @variables.Member_Id = ""
            set @variables.Member_Summary = ""
                   
        if @variables.IsProductSelected == True and @variables.IsInsuranceSelected == False:
            transition to @subagent.Product
        if @variables.IsInsuranceSelected == True and @variables.IsProductSelected == False:
            transition to @subagent.Insurance
        actions:
            go_to_Product_Subagent: @utils.transition to @subagent.Product
            go_to_Insurance_Subagent: @utils.transition to @subagent.Insurance

    
