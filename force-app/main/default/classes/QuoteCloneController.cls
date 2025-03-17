public with sharing class QuoteCloneController {
	public static void doNothing() {}

/**
*   {Purpose}  �  Supports the QuoteClone VF Page
*                 
*   {Function}  � DESCRIBE PUBLIC FUNCTIONS
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140221    Andy Boettcher DCS      Created
*   =============================================================================
*/
	/** NO LONGER NEEDED
    private final sObject mysObject;

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public QuoteCloneController(ApexPages.StandardController stdController) {
        this.mysObject = (sObject)stdController.getRecord();
    }

    public PageReference cloneRecord() {

        // Clone Root Quote Record
        Quote qOrig = [SELECT Id, Name, OpportunityId, ExpirationDate, Description, Pass_Thru__c, Test_Admin__c FROM Quote WHERE Id = :mysObject.Id];
        Quote qClone = new Quote();
        qClone.Name = qOrig.Name + ' - Clone';
        qClone.OpportunityId = qOrig.OpportunityId;
        qClone.ExpirationDate = qOrig.ExpirationDate;
        qClone.Description = qOrig.Description;
        qClone.Pass_Thru__c = qOrig.Pass_Thru__c;
        qClone.Test_Admin__c = qOrig.Test_Admin__c;
        insert qClone;

        PageReference prRef = new PageReference('/' + qClone.Id);
        prRef.setRedirect(true);
        return prRef;
    }
	*/
}