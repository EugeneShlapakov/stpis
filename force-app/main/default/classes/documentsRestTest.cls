/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 03-15-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   03-12-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
@isTest
private class documentsRestTest {
    @TestSetup
    static void makeData(){
        Document__c doc = new Document__c(
            Name='Test'
        );
        insert doc;
        Department__c dep = new Department__c(
            Name = 'Test Dep'
        );
        insert dep;
    }


    @isTest
    public static void testGetDeps() {
        List<Department__c> result = documentsRest.getDepartments();
        System.assertEquals(1, result.size());
    }

    @isTest
    public static void testSaveDoc() {
        documentsRest handler = new documentsRest();
        handler.contFirstName = 'Name';
        handler.contLastName = 'Surname';
        handler.saveOrder();
        List<Document__c> listRes = [
            SELECT Name, Text__c
            FROM Document__c
            WHERE Name = 'Name'
        ];
        System.assertEquals('Name', listRes.get(0).Name);
    }

    @isTest
    public static void testDelDoc() {
        documentsRest handler = new documentsRest();
        List<Document__c> listRes = [
            SELECT Id, Name, Text__c
            FROM Document__c
            WHERE Name = 'Test'
        ];
        handler.recDelId = listRes.get(0).Id;
        handler.delDoc();
        Integer resAmount = [
            SELECT Count()
            FROM Document__c
        ];
        System.assertEquals(0, resAmount);
    }

    @isTest
    public static void testGetRelatedDocs() {
        List<ContentDocument> check = documentsRest.getRelatedDocs();
        List<Document__c> docList = [
            SELECT Id
            FROM Document__c
        ];
    }

}
