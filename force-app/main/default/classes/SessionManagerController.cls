public with sharing class SessionManagerController {
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
*	20170510	Jeff Johnson			adding 4 fields to the session for the CTC1 page to display links (and descriptions) for questionnaires
*										added lines 54-57
*   =============================================================================
*/
	private final Master_Test__c mtRecord;
	public List<hClsQuota> lstMasterQuotas {get;set;}
	public Id idSessionTemplate {get;set;}
	public Id idSessionEdit {get;set;}
	public Boolean bolCreateBefore {get;set;}
	public Session__c seNew {get;set;}
	public Boolean bolDummyCheckbox {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public SessionManagerController(ApexPages.StandardController scController) {
		this.mtRecord = (Master_Test__c)scController.getRecord();
		bolCreateBefore = false;
		bolDummyCheckbox = true;
		instanciateNewSession();
		fillMasterQueues();
	}	
	
	///////////////////////////
	// GET / SET
	///////////////////////////
	public List<Session__c> lstSessions {
		get {
			return [SELECT 
					Id,
					Name,
                    Brand__c,
					Session_Start__c,
					Session_End__c,
					Research_Type__c,
					Test_Type__c,
					Status__c,
					Testing_Location__r.Name,
					Related_Test__c,
					Time_Between_Sessions__c,
                    Questionnaire_Link__c,
                    Questionnaire_Link_Description__c,
                    Moderator_Link__c,
                    Moderator_Link_Description__c
				FROM
					Session__c
				WHERE
					Related_Test__c = :mtRecord.Id
				ORDER BY
					Session_Start__c ASC];
		}
	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public void fillMasterQueues() {
		lstMasterQuotas = new List<hClsQuota>();

		// Get Existing Session Quotas
		Map<Id, Session_Quota__c> mapMasterSession = new Map<Id, Session_Quota__c>();
		for(Session_Quota__c sq : [SELECT Id, Master_Quota__c, Scheduled_Respondents__c, Screened_Respondents__c, IsOpen__c,
									Minimum_Respondents__c, Maximum_Respondents__c 
									FROM Session_Quota__c WHERE Related_Session__c = :idSessionEdit]) {
			mapMasterSession.put(sq.Master_Quota__c, sq);
		}

		for(Quota__c mq : [SELECT Id, Beacon_Condition__c, Quota_Summary__c, Minimum_Respondents__c, 
								Maximum_Respondents__c 
							FROM Quota__c 
							WHERE Related_Test__c = :mtRecord.Id]) {
			hClsQuota sqNew = new hClsQuota(mq, true);
			if(mapMasterSession.containsKey(mq.Id)) {
				sqNew.sqQuota = mapMasterSession.get(mq.Id);
				sqNew.checkScreened();
			}
			lstMasterQuotas.add(sqNew);
		}
	}

	public void instanciateNewSession() {
		seNew = new Session__c(Related_Test__c=mtRecord.Id,Name='New Session');
		seNew.Session_Start__c = System.Now();
		seNew.Session_End__c = System.Now().addHours(1);
		fillMasterQueues();
	}

	public void resetSession() {

		// Determine if new or edit
		Id idSessionTarget = idSessionTemplate;
		if(idSessionEdit != null) { idSessionTarget = idSessionEdit; }


		// Query for fields in target session
		String strQuery = 'SELECT ';
		for(Schema.FieldSetMember fsm : SObjectType.Session__c.FieldSets.Wizard.getFields()) {
			strQuery+= fsm.getFieldPath() + ', ';
		}
		strQuery+= 'Id, Session_Length__c FROM Session__c WHERE Id = :idSessionTarget';
		Session__c seTemplate = Database.query(strQuery);

		if(idSessionEdit == null) {
			seNew = new Session__c(Related_Test__c=mtRecord.Id);
		} else {
			seNew = new Session__c(Id=idSessionEdit);
		}
		
		for(Schema.FieldSetMember fsm : SObjectType.Session__c.FieldSets.Wizard.getFields()) {
			seNew.put(fsm.getFieldPath(), seTemplate.get(fsm.getFieldPath()));
		}

		// Push out start/end times if this is new
		if(idSessionEdit == null) {
			seNew.Name = seNew.Name + ' - Copy';
			if(bolCreateBefore) {

				// Compute new End Time first
				DateTime dtmEnd = seNew.Session_End__c.addMinutes(Integer.valueOf(-seTemplate.Time_Between_Sessions__c));

				// Compute new Start Time
				DateTime dtmStart = dtmEnd.addMinutes(Integer.valueOf(-seTemplate.Session_Length__c));

				seNew.Session_Start__c = dtmStart;
				seNew.Session_End__c = dtmEnd;
			} else {

				// Compute new Start Time first
				DateTime dtmStart = seNew.Session_End__c.addMinutes(Integer.valueOf(seTemplate.Time_Between_Sessions__c));

				// Compute new End Time first
				DateTime dtmEnd = dtmStart.addMinutes(Integer.valueOf(seTemplate.Session_Length__c));

				seNew.Session_Start__c = dtmStart;
				seNew.Session_End__c = dtmEnd;
			}
		}

		fillMasterQueues();

		idSessionTemplate = null;
		idSessionEdit = null;
	}

	public void saveSession() {

		if(seNew.Time_Between_Sessions__c == null) {
			seNew.Time_Between_Sessions__c = 0;
		}
		upsert seNew;

		//Check for addition to Master Quotas
		List<Session_Quota__c> lstInsertSQs = new List<Session_Quota__c>();
		List<Session_Quota__c> lstDeleteSQs = new List<Session_Quota__c>();
		for(hClsQuota mq : lstMasterQuotas) {
			if(mq.bolChecked) {
				Session_Quota__c sqNew;

				if(mq.sqQuota == null) {
					sqNew = new Session_Quota__c(Related_Session__c=seNew.Id, Master_Quota__c=mq.mtQuota.Id);
					sqNew.Minimum_Respondents__c = mq.mtQuota.Minimum_Respondents__c;
					sqNew.Maximum_Respondents__c = mq.mtQuota.Maximum_Respondents__c;
					sqNew.IsOpen__c = mq.bolIsOpen;
					sqNew.IsUseMasterScreener__c = true;
					lstInsertSQs.add(sqNew);
				} else {
					lstInsertSQs.add(mq.sqQuota);
				}
			} else {
				if(mq.sqQuota != null) {
					lstDeleteSQs.add(mq.sqQuota);
				}
			}
		}
		if(lstInsertSQs.size() > 0) { upsert lstInsertSQs; }
		if(lstDeleteSQs.size() > 0) { delete lstDeleteSQs; }

		instanciateNewSession();
	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsQuota {

		public Boolean bolChecked {get;set;}
		public Session_Quota__c sqQuota {get;set;}
		public Quota__c mtQuota {get;set;}
		public Boolean bolScreened {get;set;}
		public Boolean bolIsOpen {get;set;}

		public hClsQuota(Quota__c passQuota, Boolean passChecked) {
			bolChecked = passChecked;
			mtQuota = passQuota;
			bolScreened = false;
			bolIsOpen = true;
		}

		public void checkScreened() {
			if(sqQuota.Screened_Respondents__c > 0) {
				bolScreened = true;
			}
		}
	}
}