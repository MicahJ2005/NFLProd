public with sharing class SessionCloneController {
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
	private final sObject soObject;
	public Id idMasterTest {get;set;}
	public List<hClsRespondent> lstRespondents {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public SessionCloneController(ApexPages.StandardController scController) {
		this.soObject = (Session__c)scController.getRecord();
		idMasterTest = [SELECT Related_Test__c FROM Session__c WHERE Id = :this.soObject.Id].Related_Test__c;
		fillRespondentList();
	}	
	
	///////////////////////////
	// GET / SET
	///////////////////////////
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public void fillRespondentList() {
		lstRespondents = new List<hClsRespondent>();

		// Get all Session Quotas
		Map<Id, Session_Quota__c> mapQuotas = new Map<Id, Session_Quota__c>([
			SELECT Id FROM Session_Quota__c WHERE Related_Session__c = :this.soObject.Id
		]);

		// Get all TRs from TRQs
		Set<Id> setTRs = new Set<Id>();
		for(Test_Respondent_Quota__c trq : [SELECT Test_Respondent__c FROM Test_Respondent_Quota__c WHERE Session_Quota__c IN :mapQuotas.keyset()]) {
			setTRs.add(trq.Test_Respondent__c);
		}

		for(Test_Respondent__c tr : [SELECT Id, Respondent__r.Name, Respondent__r.PID__c, Respondent__r.Birthdate,
										Master_Test__c, Organization__c, Donation_Amount_Per_Event__c 
										FROM Test_Respondent__c WHERE Id IN :setTRs]) {
			lstRespondents.add(new hClsRespondent(tr, true));
		}

	}

	public PageReference cloneSession() {

		// Get relationship fields from original Session
		Session__c seOriginal = [SELECT Related_Test__c FROM Session__c WHERE Id = :this.soObject.Id];

		// Clone Session
		Session__c seNew = (Session__c)this.soObject.clone(false,true);
		seNew.Related_Test__c = seOriginal.Related_Test__c;
		insert seNew;

		// Search for Clone Master Quota
		List<Quota__c> lstMQClone = [SELECT Id FROM Quota__c WHERE Quota_Summary__c = 'Session Clone Quota' AND Related_Test__c = :idMasterTest LIMIT 1];

		Quota__c mqClone;
		if(lstMQClone.size() == 0) {
			// Create Master Quota Clone
			mqClone = new Quota__c();
			mqClone.Related_Test__c = idMasterTest;
			mqClone.Quota_Summary__c = 'Session Clone Quota';
			mqClone.Minimum_Respondents__c = 0;
			mqClone.Maximum_Respondents__c = 0;
			mqClone.IsOpen__c = false;
			mqClone.IsScheduleEnabled__c = false;
			insert mqClone;
		} else {
			mqClone = lstMQClone[0];
		}

		// Create Session Quota
		Session_Quota__c sqNew = new Session_Quota__c(Related_Session__c=seNew.Id);
		sqNew.Master_Quota__c = mqClone.Id;
		sqNew.Minimum_Respondents__c = 0;
		sqNew.Maximum_Respondents__c = 0;
		sqNew.IsOpen__c = false;
		insert sqNew;

		List<Test_Respondent__c> lstInsertTRs = new List<Test_Respondent__c>();
		for(hClsRespondent htr : lstRespondents) {
			if(htr.bolChecked) {
				Test_Respondent__c trClone = htr.trContact.clone();
				trClone.Respondent_Status__c = 'Scheduled';
				trClone.Tested_Status__c = 'Pending';
				lstInsertTRs.add(trClone);
			}
		}

		if(lstInsertTRs.size() > 0) {
			insert lstInsertTRs;

			List<Test_Respondent_Quota__c> lstInsertTRQs = new List<Test_Respondent_Quota__c>();
			for(Test_Respondent__c tr : lstInsertTRs) {
				Test_Respondent_Quota__c trq = new Test_Respondent_Quota__c();
				trq.Test_Respondent__c = tr.Id;
				trq.Session_Quota__c = sqNew.Id;
				trq.IsQualified__c = true;
				trq.IsScheduled__c = true;
				lstInsertTRQs.add(trq);
			}

			if(lstInsertTRQs.size() > 0) { insert lstInsertTRQs; }
		}

		PageReference prRef = new PageReference('/' + seNew.Id);
		prRef.setRedirect(true);
		return prRef;

	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsRespondent {
		public Test_Respondent__c trContact {get;set;}
		public Boolean bolChecked {get;set;}

		public hClsRespondent(Test_Respondent__c passTR, Boolean checked) {
			trContact = passTR;
			bolChecked = checked;
		}
	}
}