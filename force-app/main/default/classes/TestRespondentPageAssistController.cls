global with sharing class TestRespondentPageAssistController {
/**
*   {Purpose}  �  Provide support for the Test Respondent Visualforce UI
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20150226  	Andy Boettcher DCS		Created
*   =============================================================================
*/

	///////////////////////////
	// Constructors
	///////////////////////////

	///////////////////////////
	// GET / SET
	///////////////////////////
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	webservice static Boolean ws_cancelRespondentSingleSession(Id idRespondent, Id idSession) {
		Test_Respondent__c trRespondent = [SELECT Id FROM Test_Respondent__c WHERE Id = :idRespondent];
		Session__c seSession = [SELECT Id FROM Session__c WHERE Id = :idSession];
		return MasterTestLibrary.cancelRespondentFromSession(trRespondent, seSession);
	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////

}