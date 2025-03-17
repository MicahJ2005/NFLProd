trigger TriggerFramework_Opportunity on Opportunity (after insert/** ,
after update, before insert, before update*/) {
/**
*   {Purpose}  �  Wrapper trigger for all functions on Opportunity - all business logic is to be placed in referenced
*               classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 952.223.5604                 
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20180309    Andy Boettcher DCS      Header
*	20210604	Will Hawkins DCS		Commented out AVATA fields; uninstalled
*   =============================================================================
*/

    /** NO LONGER NEED

	list<Quote> Qupdate = new List<Quote>();
	Set<id> ListOppIds = new Set<id>();
	
	for(Opportunity OsetID: trigger.new){
		if(OsetID.StageName == 'Approved'){
			ListOppIds.add(OsetID.Id);
		}
	}
	
	if (trigger.isAfter && trigger.isUpdate) {

		list<Quote> lquote = [SELECT Id, Status, OpportunityId FROM Quote WHERE OpportunityId in :ListOppIds AND Status = 'Signature' LIMIT 1];
		for(Quote Q:lquote){
			QUpdate.add( new Quote (ID = Q.Id, Status = 'Approved'));
		}

		// Update all attached AVATA Lists to "Active" if the status of the Opp is "Invoiced"
		Set<Id> setScopeIds = new Set<Id>();
		for(Opportunity opp : trigger.new) {
			if(opp.StageName == 'Invoiced') {
				setScopeIds.add(opp.Id);
			}
		}

		if(setScopeIds.size() > 0) {
			// List<ATC__Hlist__c> lstAvata = [SELECT Id, ATC__Active__c FROM ATC__Hlist__c WHERE Opportunity__c IN :setScopeIds];
			// for(ATC__Hlist__c hlist : lstAvata) {
			// 	hlist.ATC__Active__c = false;
			// }
			// if(lstAvata.size() > 0) { update lstAvata; }

			List<Master_Test__c> lstMTs = [SELECT IsOpportunityInvoiced__c FROM Master_Test__c WHERE Opportunity__c IN :setScopeIds];
			for(Master_Test__c mt : lstMTs) {
				mt.IsOpportunityInvoiced__c = true;
			}
			if(lstMTs.size() > 0) { update lstMTs; }
		}
		
	}

	update Qupdate;
	*/
}