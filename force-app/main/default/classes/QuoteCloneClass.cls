public with sharing class QuoteCloneClass {
	public static void doNothing() {}/** NO LONGER NEEDED
    
	public static ID ClonedQuoteID;
	
	public static void QuoteClone (ID QuoteCloneID, ID OpportunityID){
		// Clone Root Quote Record
        Quote qOrig = [SELECT Id, Name, ExpirationDate, Description, Pass_Thru__c, Test_Admin__c FROM Quote WHERE Id = :QuoteCloneID];
        Quote qClone = new Quote();
        	qClone.Name = qOrig.Name + ' - Clone';
        	qClone.OpportunityId = OpportunityID;
        	qClone.ExpirationDate = qOrig.ExpirationDate;
        	qClone.Description = qOrig.Description;
        	qClone.Pass_Thru__c = qOrig.Pass_Thru__c;
        	qClone.Test_Admin__c = qOrig.Test_Admin__c;
        insert qClone;
        
        ClonedQuoteID = qclone.Id;
        
	}
*/
}