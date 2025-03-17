public with sharing class GenerateWordDocs_Controller {
    public static void doNothing() {}
    /** Commented out - no longer used
//Controller behind "generateWordDocsFromMasterTest"
//Requires 2 URL parameters = "mtId" is the Id of the Master Test record and "docType"
//		docType values are "ship", "drive", "testday"
	
    public String masterTestId {get;set;}
    public String docType {get;set;}
    public List<Task_Queue__c> cqList {get;set;}
    
    public String selectedCaseQueue;
    
    public GenerateWordDocs_Controller()
    {
        //Get the values from the URL, and query for the Task/Case Queue records.
        this.masterTestId = ApexPages.currentPage().getParameters().get('mtId');
    	this.docType = ApexPages.currentPage().getParameters().get('docType');
        
        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByName();
		Id rtId = recordTypes.get('Fielding Test Summary').getRecordTypeId();
        
       	this.cqList = [SELECT Id, Name FROM Task_Queue__c WHERE Master_Test__c = :this.masterTestId AND RecordTypeId = :rtId];
    }
    
    public PageReference runNow()
    {
        //Called from the action method in the VF page.
        //If this.cqList.size is 1 - send the user on to the right page.
        PageReference pr;
        if(this.cqList.size() == 1)
        {
            setSelectedCaseQueue(this.cqList[0].Id);
            pr = getPageBasedOnDocType();
        }
        return pr;
    }
    
    public PageReference redirect()
    {
        //Called from the onchange method.  Once user selects a value from the dropdown.
        PageReference pr = getPageBasedOnDocType();
        return pr;
    }
    
	private PageReference getPageBasedOnDocType()
    {
        //Based on the doctype value passed in, send user to the right spot.
        PageReference pr;
        if(docType == 'ship')
        {
            pr = Page.Shipping_Information;
            pr.getParameters().put('id', this.selectedCaseQueue);
        }
        if(docType == 'drive')
        {
            pr = Page.Driving_Directions;
            pr.getParameters().put('id', this.selectedCaseQueue);
        }
        if(docType == 'testday')
        {
            pr = Page.TestDayClientInfo;
            pr.getParameters().put('id', this.selectedCaseQueue);
        }
        return pr;
    }
    
    //Getter and setter for the selectedCaseQueue variable
    public String getSelectedCaseQueue() {
        return this.selectedCaseQueue; 
    }
    public void setSelectedCaseQueue(string s){
        this.selectedCaseQueue = s; 
    }
    
    public List<SelectOption> getAvailableCQs()
    {
        //Loops through the cqList to load the dropdown.
        List<SelectOption> optionList = new List<SelectOption>();
        optionList.add(new SelectOption('','None'));

        for(Task_Queue__c cq : this.cqList)
        {
            optionList.add(new SelectOption(cq.Id, cq.Name));
        }
        return optionList;
    }
    */
}