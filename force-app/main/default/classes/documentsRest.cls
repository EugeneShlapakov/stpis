/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-15-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   03-14-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
global with sharing class documentsRest {
    public String accountName { get; set; }
    public static List<Department__c> deps { get; set; }
    public List<String> currNameList { get; set; }
    public List<String> amountList { get; set; }
    public List<String> abbrList { get; set; }
    public List<Decimal> rateList { get; set; }
    public List<wrapperCurr> currList { get; set; }
    public date dat {get;set;}
    public String searchTerm {get;set;}
    public String contFirstName { get;set; }
    public String contLastName { get;set; }
    public String recDelId { get;set; }

    public List<Document__c> acc{get; set;}

    public Pagereference getAccsInit(){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://'+URL.getSalesforceBaseUrl().getHost()+'/services/data/v39.0/query/?q=SELECT+Id,Name,Status__c,CreatedDate,Department__r.Name,Owner.Name+FROM+Document__c');
        req.setMethod('GET');
        string autho = 'Bearer '+userInfo.getSessionId();
        req.setHeader('Authorization', autho);
        Http http = new Http();
        HTTPresponse res= http.send(req);
        string response = res.getBody();
        string str = '['+ response.substring(response.indexOf('records":[')+10,response.indexof(']}')) +']';
        this.acc = (List<Document__c>)JSON.deserialize(str,List<Document__c>.class);
        return null;
    }

    public  Pagereference getAccsBySearchTerm(){
        if (this.searchTerm != '' && this.searchTerm != null){
            String newSearchText = '%25'+this.searchTerm+'%25';
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://'+URL.getSalesforceBaseUrl().getHost()+'/services/data/v39.0/query/?q=SELECT+Id,Name,Status__c,CreatedDate,Department__r.Name,Owner.Name+FROM+Document__c+WHERE+Name+LIKE+\''+newSearchText+'\'');
            req.setMethod('GET');
            string autho = 'Bearer '+userInfo.getSessionId();
            req.setHeader('Authorization', autho);
            Http http = new Http();
            HTTPresponse res= http.send(req);
            string response = res.getBody();
            string str = '['+ response.substring(response.indexOf('records":[')+10,response.indexof(']}')) +']';
            this.acc = (List<Document__c>)JSON.deserialize(str,List<Document__c>.class);
        }
        else {
            getAccsInit();
        }
        return null;
    }

    @RemoteAction
    global static List<Department__c> getDepartments() {
        deps = [
            SELECT Name, Office__latitude__s, Office__longitude__s, Address__c
            FROM Department__c
        ];
        return deps;
    }


    public List<SelectOption> currOptionList
    {
        get
        {
            List<SelectOption> currOptionList = new List<SelectOption>();
            currOptionList.add(new SelectOption('usd', 'US Dollar'));
            currOptionList.add(new SelectOption('eur', 'Euro'));
            currOptionList.add(new SelectOption('gbp', 'Pound Sterling'));
            currOptionList.add(new SelectOption('rub', 'Russian Ruble'));
            return currOptionList;
        }
        set;
    }
    public HttpResponse restRequestCurrOnDate() {
        String selectedDate = dat.year() + '-' + dat.month() + '-' + dat.day();
        String url = 'https://www.nbrb.by/api/exrates/rates?ondate=' + selectedDate + '&periodicity=0';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse resp = h.send(req);
        return resp;
    }

    public Pagereference showRatesDate() {
        HttpResponse resp = restRequestCurrOnDate();
        currList = new List<wrapperCurr>();
        currNameList = new List<String>();
        amountList = new List<String>();
        abbrList = new List<String>();
        rateList = new List<Decimal>();
        if (resp.getStatusCode() == 200){
            JSONParser parser = JSON.createParser(resp.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'Cur_Abbreviation')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    abbrList.add(parser.getText());
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'Cur_Scale')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    amountList.add(parser.getText());
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'Cur_Name')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    currNameList.add(parser.getText());
                }
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&
                    (parser.getText() == 'Cur_OfficialRate')) {
                    // Get the value.
                    parser.nextToken();
                    // Compute the grand total price for all invoices.
                    rateList.add(parser.getDecimalValue());
                }
            }
        }
        for (Integer i = 0; i<currNameList.size(); ++i){
            wrapperCurr wrapItem  = new wrapperCurr(currNameList.get(i), abbrList.get(i), amountList.get(i), rateList.get(i));
            currList.add(wrapItem);
        }
        return null;
    }
    public class wrapperCurr{
        public String name { get; set; }
        public Decimal rate { get; set; }
        public String abbr { get; set; }
        public String amount { get; set; }
        public wrapperCurr(String name, String abbr,  String amount, Decimal rate){
            this.name = name;
            this.rate = rate;
            this.abbr = abbr;
            this.amount = amount;
        }
    }

    public void saveOrder(){
        Document__c newDoc = new Document__c(
            Name = contFirstName,
            Text__c = contLastName
        );
        insert newDoc;
    }

    public void delDoc(){
        String recId = recDelId;
        Document__c newDoc = [
            SELECT Id
            FROM Document__c
            WHERE Id = :recId
            LIMIT 1
        ];
        delete newDoc;
    }

    @AuraEnabled
    public static List<ContentDocument> getRelatedDocs(){
        List<Document__c> recList = [
            SELECT Id
            FROM Document__c
        ];
        Set<Id> setDocId = new Set<Id>();
        for (Document__c doc : recList) {
            setDocId.add(doc.Id);
        }
        List<ContentDocument> cdList = new List<ContentDocument>();
        List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId FROM ContentDocumentLink
                                             WHERE LinkedEntityId IN :setDocId];
        Set<Id> cdIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdlList) {
            cdIds.add(cdl.ContentDocumentId);
        }
        cdList = [SELECT Id, Title, FileType, OwnerId, Owner.Name, CreatedDate,
                  CreatedById, CreatedBy.Name, ContentSize
                  FROM ContentDocument WHERE Id IN :cdIds];
        return cdList;
    }

    @AuraEnabled
    public static string getDocURL(Id docId){
        ContentVersion cv = [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :docId AND IsLatest = true];
        String cvDownloadURL = URL.getSalesforceBaseUrl().toExternalForm() + '/sfc/servlet.shepherd/version/download/' + cv.Id;
        return cvDownloadURL;
    }
}