public with sharing class documentTriggerHandler {
    public static void updateDoc(List<Document__c> docsList) {
        for (Document__c doc :docsList){
            System.debug('test');
            if(doc.Status__c == null || doc.Status__c == ''){
                doc.Status__c = 'New';
            }
            doc.Department__c = 'a065g0000032AEuAAM';
        }
    }
}