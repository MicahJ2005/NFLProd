public with sharing class QuotaGroupVisualizerController {
/**
*   {Purpose}  �  Controller for QuotaGroupVisualizer
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140907  	Andy Boettcher DCS		Created
*   =============================================================================
*/
	public Id idMasterTest {get;set;}
	public List<Quota__c> lstMQs {get;set;}
	public List<Session__c> lstSessions {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public QuotaGroupVisualizerController(ApexPages.StandardController scController) {
		idMasterTest = (Id)scController.getId();
		fillMQs();
		fillSessions();
	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public void fillMQs() {

		lstMQs = new List<Quota__c>();
		lstMQs = [SELECT Id, Quota_Summary__c, Beacon_Condition__c, IsTrackingOnly__c, MQG__c 
					FROM Quota__c 
					WHERE Related_Test__c = :idMasterTest
						AND IsScheduleEnabled__c = true
					ORDER BY IsTrackingOnly__c ASC, Beacon_Condition__c ASC];

	}

	public void fillSessions() {

		lstSessions = new List<Session__c>();
		lstSessions = [SELECT Id, Name, Session_Start__c, Session_End__c, Time_Between_Sessions__c, Recruits_Per_Session__c, 
							(SELECT Id, MQG__c, Master_Quota__c, Master_Quota_Description__c, Beacon_Condition__c, SQGManual__c 
								FROM Session_Quotas__r
								WHERE Master_Quota__r.IsScheduleEnabled__c = true
								ORDER BY Master_Quota__r.IsTrackingOnly__c, Beacon_Condition__c) 
						FROM Session__c WHERE Related_Test__c = :idMasterTest 
						ORDER BY Session_Start__c ASC];

	}

	public void saveQuotas() {

		// Save MQs
		update lstMQs;

		// Save SQs
		List<Session_Quota__c> lstUpdateSQs = new List<Session_Quota__c>();
		for(Session__c ses : lstSessions) {
			lstUpdateSQs.addAll(ses.Session_Quotas__r);
		}
		update lstUpdateSQs;

		fillMQs();
		fillSessions();

	} 

}