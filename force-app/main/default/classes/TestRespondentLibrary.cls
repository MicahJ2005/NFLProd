public with sharing class TestRespondentLibrary {
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
*   20160502  	Andy Boettcher DCS		Created
*   =============================================================================
*/	

	///////////////////////////
	// Action Methods
	///////////////////////////
	public static void processTriggeredTREmails(Map<Id, Test_Respondent__c> oldMap, Map<Id, Test_Respondent__c> newMap) {

		Set<Id> setTRScope = new Set<Id>();

		Set<String> setScopedTRStatus = new Set<String>();
		Set<String> setScopedTestedStatus = new Set<String>();

		setScopedTRStatus.add('FPI Canceled');
		setScopedTRStatus.add('Prequalified Unscheduled');
		setScopedTRStatus.add('Scheduled');
		setScopedTRStatus.add('Canceled');
		setScopedTRStatus.add('Pending');
		setScopedTRStatus.add('Qualified');

		setScopedTestedStatus.add('No Show');
		setScopedTestedStatus.add('Pending');

		/*************************************************/
		// NOTE!!  This scope only covers UPDATES of TRs.
		// Inserts in Linked or Pairs are covered by the 
		// update of the original TR, not the insertion 
		// of the associated TR's status.
		/*************************************************/

		if(trigger.isUpdate) {
			for(Test_Respondent__c objTR : newMap.values()) {

				system.debug(objTR.Respondent_Status__c + ' ' + oldMap.get(objTR.Id).Respondent_Status__c);

				// Determine Criteria to enter the EmailLogLibrary (prevents dupes on edit/save without changing criteria)
				if((setScopedTRStatus.contains(objTR.Respondent_Status__c) && oldMap.get(objTR.Id).Respondent_Status__c != objTR.Respondent_Status__c) || 
					(setScopedTestedStatus.contains(objTR.Tested_Status__c) && oldMap.get(objTR.Id).Tested_Status__c != objTR.Tested_Status__c)) {
					setTRScope.add(objTR.Id);
				}
			}

			system.debug(setTRScope);

			if(!setTRScope.isEmpty()) {
				EmailLogLibrary.processTR(setTRScope, oldMap);
			}
		}

	}
}