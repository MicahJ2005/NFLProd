public with sharing class RelatedPCCViewController {
/**
*   {Purpose}  �  TODO:  Provide Purpose
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20150527  	Andy Boettcher DCS		Created
*	20231120	Sophia Murphy DCS		Commented out all
*   =============================================================================
*/
	public static void doNothing() {}

	/**private final Id idRecord;
	private final Project_Change_Control__c pccRecord;

	///////////////////////////
	// Constructors
	///////////////////////////
	public RelatedPCCViewController(ApexPages.StandardController scController) {
		// TODO
		this.idRecord = scController.getId();
		this.pccRecord = [SELECT Id, Opportunity__c, Subject__c FROM Project_Change_Control__c WHERE Id = :idRecord];
	}	
	
	///////////////////////////
	// GET / SET
	///////////////////////////
	public List<Task_Queue__c> lstPCCs {
		get {
			return [SELECT 
						Id, 
						Name,
						Type__c,
						Amount__c,
						(SELECT 
							Status, 
							LastModifiedBy.Name, 
							LastModifiedDate 
						FROM ProcessInstances) 
					FROM Task_Queue__c 
					WHERE 
						RecordType.DeveloperName = 'Project_Change_Control_Request' 
						AND Master_Test__r.Opportunity__c = :pccRecord.Opportunity__c];
		}
	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	*/
}