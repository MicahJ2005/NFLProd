trigger TriggerFramework_Lead on Lead (after delete/**, after insert, after update, 
before delete, before insert, before update */) {
/**
*   {Purpose}  �  Wrapper trigger for all functions on Lead - all business logic is to be placed in referenced
*				classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032
*
*	{Usage}		- Place this in the object's Trigger
*				S2STriggerHandler.handleRecords('NAME OF S2S SETTING', 'SOBJECT', JSON.serialize(Trigger.new));
*              
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20131212  	Andy Boettcher DCS		Created
*   20171226	Andy Boettcher DCS 		Added S2STriggerHandler
*	20240308	Sophia Murphy DCS		Commented out whole thing - no longer using any of this
*   =============================================================================
*/

	// Create Map of APEX Trigger Settings
	//Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();

	/**if(trigger.isBefore) {
		if(mapAPEXSettings.get('leadSoundexKey')) {
			if(trigger.isInsert || trigger.isUpdate) {
				UtilityMethods.determineSoundexKey('LastNameSoundexKey__c', 'LastName');
				UtilityMethods.determineSoundexKey('FirstNameSoundexKey__c', 'FirstName');
			}
		}
	}*/

	//if(trigger.isAfter && !trigger.isDelete) {

        //Case 5250 - 01/11/2019
		//if((!System.isFuture() && !System.isBatch())) {
        //    S2STriggerHandler.handleRecords('CovanceDrugSandbox', 'Covance_Lead', JSON.serialize(Trigger.new));
        //}

		/** 20220707	Sophia Murphy DCS	Commented out, no longer needed
		 * if(mapAPEXSettings.get('moveProfileOnLeadConvert')) {
			if(trigger.isUpdate) {
				Boolean bolProcessConvert = false;
				Map<Id, Lead> mapConverted = new Map<Id, Lead>();
				for(Lead ld : trigger.new) {
					if(ld.IsConverted != trigger.oldMap.get(ld.Id).IsConverted) {
						mapConverted.put(ld.id, ld);
					}
				}
				LeadLibrary.moveProfileOnLeadConvert(mapConverted);
			}
		}
		*/
	//}

}