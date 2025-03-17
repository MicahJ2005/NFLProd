public with sharing class TestFillWeightingController {
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
*   YYYYMMDD  	FN LN DCS				Created
*   =============================================================================
*/
	private final Master_Test__c mtRecord;
	public List<Quota__c> lstQuotas {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public TestFillWeightingController(ApexPages.StandardController scController) {
		// TODO
		mtRecord = (Master_Test__c)scController.getRecord();
		fillQuotaList();
	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public void fillQuotaList() {
		lstQuotas = [SELECT Id, Quota_Summary__c, Fill_Weighting__c 
						FROM Quota__c 
						WHERE Related_Test__c = :mtRecord.Id
						ORDER BY Fill_Weighting__c ASC];
	}

	public PageReference saveWeighting() {

		if(lstQuotas.size() > 0) { update lstQuotas; }
		PageReference prRef = new PageReference('/'+mtRecord.Id);
		prRef.setRedirect(true);
		return prRef;

	}
	
}