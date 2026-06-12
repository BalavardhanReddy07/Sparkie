List<Topic_Document_Record__c> recordsToUpdate = [
    SELECT Id, Sub_Topic__c, Topic__r.Name
    FROM Topic_Document_Record__c
    WHERE Topic__r.Name = 'Product'
    AND Sub_Topic__c IN ('Member Products', 'Non Member Products')
];

for (Topic_Document_Record__c rec : recordsToUpdate) {
    
    if (rec.Sub_Topic__c == 'Member Products') {
        rec.Sub_Topic__c = 'Member Specific Products';
    }
    else if (rec.Sub_Topic__c == 'Non Member Products') {
        rec.Sub_Topic__c = 'Non-UI Based';
    }
}

if (!recordsToUpdate.isEmpty()) {
    update recordsToUpdate;
    System.debug('Updated Records Count: ' + recordsToUpdate.size());
} else {
    System.debug('No matching records found.');
}
