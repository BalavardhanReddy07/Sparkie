public with sharing class AF_HybridSearchService {
    
    // ===== INPUT =====
    public class Request {
        @InvocableVariable(required=true)
        public String searchQuery;
        
        @InvocableVariable(required=true)
        public String filePathsJson;
    }
    
    // ===== OUTPUT =====
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
    
    @InvocableMethod(label='Data Cloud Hybrid Search Service')
    public static List<Response> SearchRetriever(List<Request> requests) {
        List<String> paths = (List<String>) JSON.deserialize(
            requests[0].filePathsJson,
            List<String>.class
        );
        system.debug('paths>>>' + paths);
        String preFilterConditions = buildFilePathFilter(paths);
        system.debug('preFilterConditions>> '+ preFilterConditions);
        List<Response> responses = new List<Response>();
        responses.add(ExecuteSearch(requests[0].searchQuery, preFilterConditions));
        return responses;
    }
    
    public static Response ExecuteSearch(String searchQuery, String preFilterConditions) {
        
        Response executionResponse = new Response();            
        String sqlQuery =
            'select c.Chunk__c, d.FilePath__c, h.hybrid_score__c, h.keyword_score__c, h.vector_score__c from '+ 
            'hybrid_search(table(ADL_All_Documents_Custom_index__dlm ), \'' + searchQuery + '\',' + preFilterConditions + ', 20) as h join ADL_All_Documents_Custom_chunk__dlm as c on h.SourceRecordId__c = c.RecordId__c join ADL_All_Documents_L__dlm as d on c.SourceRecordId__c = d.FilePath__c '+
            'Order By h.hybrid_score__c DESC';
        
        ConnectApi.CdpQueryInput input = new ConnectApi.CdpQueryInput();
        input.sql = sqlQuery;
        ConnectApi.CdpQueryOutputV2 output = ConnectApi.CdpQuery.queryAnsiSqlV2(input);
        // Step 1: Collect all unique FilePaths from results
    Set<String> filePathSet = new Set<String>();
    List<List<Object>> rawRows = new List<List<Object>>();
    if(output.data != null && !output.data.isEmpty()){
        for (ConnectApi.CdpQueryV2Row rowObj : output.data) {
            
            List<Object> row = rowObj.rowData;
            rawRows.add(row);
            if(row[1] != null) {
                filePathSet.add((String) row[1]);
            }
        }
    }
    
    // Step 2: Query Document_Details__c to get Name and URL for each FilePath
    Map<String, Document_Detail__c> filePathToDocMap = new Map<String, Document_Detail__c>();
    if(!filePathSet.isEmpty()) {
        for(Document_Detail__c doc : [
            SELECT Name, Document_URL__c, Data_Cloud_File_Path__c
            FROM Document_Detail__c
            WHERE Data_Cloud_File_Path__c IN :filePathSet
        ]) {
            filePathToDocMap.put(doc.Data_Cloud_File_Path__c, doc);
        }
    }
    
    // Step 3: Build results with enriched document details
    List<Map<String, Object>> results = new List<Map<String, Object>>();
    for(List<Object> row : rawRows) {
        String filePath = (String) row[1];
        Document_Detail__c doc = filePathToDocMap.get(filePath);
        
        Map<String, Object> record = new Map<String, Object>{
            'chunk'             => row[0],
            'filePath'          => filePath,
            'Name'      		=> doc != null ? doc.Name : null,
            'URL'       		=> doc != null ? doc.Document_URL__c : null,
            'hybridSearchScore' => row[2],
            'keywordSearchScore'=> row[3],
            'vectorSearchScore' => row[4]
        };
        results.add(record);
    }
        // Now serialize YOUR structure
        String jsonOutput = JSON.serialize(results);
        executionResponse.Prompt = jsonOutput;
        return executionResponse;
    }
    
    public static String buildFilePathFilter(List<String> filePaths) {
        if (filePaths == null || filePaths.isEmpty()) return '\'1=1\'';
        
        List<String> escaped = new List<String>();
        for (String fp : filePaths) {
            escaped.add('\'\'' + fp.replace('\'', '\'\'') + '\'\'');        
        }
        
        return '\'' + 'FilePath__c IN (' + String.join(escaped, ', ') + ')' + '\'';
    }
}



This is the collection to Json class, Which will make all the documents path into a json format and pass it to this Hybrid Class
public with sharing class AF_CollectionToJson {
    
    public class Request {
        @InvocableVariable(required=true)
        public List<String> inputCollection;
    }
    
    public class Response {
        @InvocableVariable
        public String jsonString;
    }
    
    @InvocableMethod(label='Convert Text Collection to JSON')
    public static List<Response> convert(List<Request> requests) {
        Response res = new Response();
        res.jsonString = JSON.serialize(requests[0].inputCollection);
        return new List<Response>{ res };
    }
}



so My flow approach is 

If IsproductSelected == True
then it will go and get the records of those records and send the document path to the CollectionJson class and this Class converts into Json and pass to hybrid search 

This is the Document_Detail__c fields  : 
Created By	CreatedById	Lookup(User)		False	
Data Cloud File Path	Data_Cloud_File_Path__c	Text(255)		False	
Document Name	Name	Text(80)		True	
Document URL	Document_URL__c	URL(255)		False	
Last Modified By	LastModifiedById	Lookup(User)		False	
Owner	OwnerId	Lookup(User,Group)		True	
Warning for L2 document	Warning_for_L2_document__c	Long Text Area(32768)

This is the Topic_Document_Mapping__c fields : 
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



