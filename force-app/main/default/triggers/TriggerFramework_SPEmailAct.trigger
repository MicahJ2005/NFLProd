trigger TriggerFramework_SPEmailAct on silverpop__Silverpop_Email_Activity__c (after insert, after update) {
/**
*   {Purpose}  �  Wrapper trigger for all functions on silverpop__Silverpop_Email_Activity__c
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140807  	Andy Boettcher DCS		Created
*   20220707    Sophia Murphy DCS       Added enable/disable flag
*	20240110	Sophia Murphy DCS		Add check for null values
*   =============================================================================
*/
Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
if(mapAPEXSettings.get('enableSPEmailTrigger')) {
	if(trigger.isAfter) {

		// Get all Contacts in Scope
		Set<Id> setContactIds = new Set<Id>();
		for(silverpop__Silverpop_Email_Activity__c spEA : trigger.new) {
			setContactIds.add(spEA.silverpop__Contact__c);
		}

		Map<Id, Contact> mapContactUpdates = new Map<Id, Contact>([
			SELECT Id, Bad_Email__c, Emails_Sent__c, Emails_Opened__c, Status__c, Inactivation_Reason__c FROM Contact WHERE Id IN :setContactIds
		]);
		List<Contact> updContactList1 = new List<Contact>();
		List<Contact> updContactList2 = new List<Contact>();
		List<Contact> updContactList3 = new List<Contact>();

		if(trigger.isInsert) {

			for(silverpop__Silverpop_Email_Activity__c spEA : trigger.new) {

				Contact tmpContact = mapContactUpdates.get(spEA.silverpop__Contact__c);
				if(tmpContact != null) {
					if(tmpContact.Emails_Sent__c == null) {
						tmpContact.Emails_Opened__c = 0;
						tmpContact.Emails_Sent__c = 0;
					}
					tmpContact.Emails_Sent__c = tmpContact.Emails_Sent__c + 1;
	
					// If Unsubscribe, deactivate Contact
					if(spEA.silverpop__Date_Unsubscribed__c != null) {
						tmpContact.Status__c = 'Inactive';
						tmpContact.Inactivation_Reason__c = 'Respondent Request';
					}
					updContactList1.add(tmpContact);
				}

				// General Count Metrics
				/**if(mapContactUpdates.get(spEA.silverpop__Contact__c).Emails_Sent__c == null) {
					mapContactUpdates.get(spEA.silverpop__Contact__c).Emails_Opened__c = 0;
					mapContactUpdates.get(spEA.silverpop__Contact__c).Emails_Sent__c = 0;
				}
				mapContactUpdates.get(spEA.silverpop__Contact__c).Emails_Sent__c = mapContactUpdates.get(spEA.silverpop__Contact__c).Emails_Sent__c + 1;

				// If Unsubscribe, deactivate Contact
				if(spEA.silverpop__Date_Unsubscribed__c != null) {
					mapContactUpdates.get(spEA.silverpop__Contact__c).Status__c = 'Inactive';
					mapContactUpdates.get(spEA.silverpop__Contact__c).Inactivation_Reason__c = 'Respondent Request';
				}
				*/

			}

		}

		if(trigger.isInsert || trigger.isUpdate) {
			for(silverpop__Silverpop_Email_Activity__c spEA : trigger.new) {
				if(spEA.silverpop__Status__c == 'Bounced') {
					Contact tmpContact = mapContactUpdates.get(spEA.silverpop__Contact__c);
					if(tmpContact != null) {
						tmpContact.Bad_Email__c = true;
						updContactList2.add(tmpContact);
					}
					
				}
			}
		}
		
		if(trigger.isUpdate) {
			for(silverpop__Silverpop_Email_Activity__c spEA : trigger.new) {
				if(spEA.silverpop__Opened__c) {
					Contact tmpContact = mapContactUpdates.get(spEA.silverpop__Contact__c);
					if(tmpContact != null) {
						tmpContact.Emails_Opened__c = tmpContact.Emails_Opened__c + 1;
						updContactList3.add(tmpContact);
					}
				}
			}
		}

		// Update Contacts
		UtilityMethods.bolPreventContactSQS = true;
		//if(mapContactUpdates.values().size() > 0) { update mapContactUpdates.values(); }
		if(updContactList1.size() > 0) {
			update updContactList1;
		}
		if(updContactList2.size() > 0) {
			update updContactList2;
		}
		if(updContactList3.size() > 0) {
			update updContactList3;
		}
		
	}
}
	

}