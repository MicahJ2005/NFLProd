trigger TriggerFramework_HseContact on Household_Contact__c (after delete, after insert, after undelete,
															 after update, before delete) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on Household Contact - all business logic is to be placed in referenced
*               classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140926    Andy Boettcher (DCS)	Created
*	20160203	Jason Flippen (DCS)		Added code to explicitly handle After Insert,
*										After Update, and Before Delete events.
*   20220707    Sophia Murphy DCS       Added enable/disable flag
*   =============================================================================
*/

    // Create Map of APEX Trigger Settings
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();

	if(mapAPEXSettings.get('enableHouseholdContactTrigger')) {
		if (Trigger.isAfter)
		{
			if (Trigger.isInsert)
			{
														// After Insert
				HseContactLibrary.afterInsert(Trigger.new,
											Trigger.newMap);
			}
			else if (Trigger.isUpdate) 
			{
														// After Update
				HseContactLibrary.afterUpdate(Trigger.new,
											Trigger.newMap,
											Trigger.old,
											Trigger.oldMap);
			}

			///////////////////////////
			// Amazon SQS
			///////////////////////////
			UtilityMethods.sendSAPITriggerWrapper('FPIHouseholdContact');
		}
		else if (Trigger.isBefore)
		{
			if (Trigger.isDelete)
			{
													// Before Delete
				HseContactLibrary.beforeDelete(Trigger.old,
											Trigger.oldMap);
			}
		}
	}
}