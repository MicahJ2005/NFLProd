public with sharing class HostToolController {
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
*   20140608  	Andy Boettcher DCS		Created
*   =============================================================================
*/
	public Id idMasterTest {get;set;}
	public Id idSession {get;set;}
	public String strRespSearch {get;set;}
	public String strViewType {get;set;}
	public List<hClsSession> lstFullSessions {get;set;}
	public Map<Id, List<hClsQuota>> mapRespondentQuotas {get;set;}
	public Map<String, Integer> mapStatusCount {get;set;}
	public Map<Id, hClsQuotaKey> mapQuotaCount {get;set;}
	public Id idTR {get;set;}

	public Map<Id, List<Test_Respondent__c>> mapPairs {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public HostToolController() {
		idMasterTest = ApexPages.currentPage().getParameters().get('tid');
		idSession = ApexPages.currentPage().getParameters().get('sid');
		strRespSearch = '';
		manageUserViewPreference();

	}

	public HostToolController(ApexPages.standardController scMain) { 
		strRespSearch = '';
		idMasterTest = ApexPages.currentPage().getParameters().get('id');
		manageUserViewPreference();
	}
	
	
	///////////////////////////
	// GET / SET
	///////////////////////////
	public Master_Test__c mtFieldSet {
		get {
			String strQuery = 'SELECT ';
			for(Schema.FieldSetMember fsm : SObjectType.Master_Test__c.FieldSets.HostToolView.getFields()) {
				strQuery+= fsm.getFieldPath() + ', ';
			}
			strQuery+= 'Id FROM Master_Test__c WHERE Id = :idMasterTest';

			return (Master_Test__c)Database.query(strQuery);
		}
	}
	public List<SelectOption> lstViewTypes {
		get {
			List<SelectOption> lstTemp = new List<SelectOption>();
			lstTemp.add(new SelectOption('Session View','Session View'));
			lstTemp.add(new SelectOption('List View','List View'));
			return lstTemp;
		}
	}

	public List<SelectOption> lstProjects {
		get {
			List<SelectOption> lstTemp = new List<SelectOption>();
			lstTemp.add(new SelectOption('','-- Select --'));
			//for(Master_Test__c mt : [SELECT Id, Opportunity_Name__c 
			//			FROM Master_Test__c 
			//			WHERE Opportunity_Name__c != NULL 
			//				AND Opportunity_Name__c != ''
			//				AND First_Session_Start__c > :System.Today().addMonths(-1)
			//				AND Last_Session_Start__c < :System.Today().addMonths(1)
			//			ORDER BY Opportunity_Name__c ASC]) {
			for(Master_Test__c mt : [SELECT Id, Opportunity_Name__c 
						FROM Master_Test__c 
						WHERE Opportunity_Name__c != NULL 
							AND Opportunity_Name__c != ''
							AND IsOpportunityInvoiced__c = false 
						ORDER BY Opportunity_Name__c ASC]) {
				lstTemp.add(new SelectOption(mt.Id,mt.Opportunity_Name__c));
			}
			return lstTemp;
		}
	}

	public List<SelectOption> lstSessions {
		get {
			List<SelectOption> lstTemp = new List<SelectOption>();
			lstTemp.add(new SelectOption('','-- Select --'));
			lstTemp.add(new SelectOption('','-- All Sessions --'));
			for(Session__c ss : [SELECT Id, Name, Testing_Location__r.Name, Session_Length__c
						FROM Session__c
						WHERE Related_Test__c = :idMasterTest
						ORDER BY Session_Start__c]) {
				lstTemp.add(new SelectOption(ss.Id,ss.Name + ' - ' + ss.Testing_Location__r.Name + ' - ' + Integer.valueOf(ss.Session_Length__c) + ' mins'));
			}

			return lstTemp;
		}
	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public void manageUserViewPreference() {
		UserPreference__c USER_PREFERENCES = UtilityMethods.USER_PREFERENCES();
		strViewType = USER_PREFERENCES.HostCheckViewMode__c;
		if(strViewType == '' || strViewType == null ) {
			strViewType = 'Session View';
		}
	}

	public void renderPrintable() {
		fillAllRespondentQuotas();
		fillRespondentList();
	}

	public void fillAllRespondentQuotas() {

		//mapRespondentQuotas = new Map<Id, List<hClsQuota>>();

		//// Spin through all Respondents
		//for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Master_Test__c = :idMasterTest]) {

		//	List<hClsQuota> lstConditions = new List<hClsQuota>();

		//	// Put all in list first
		//	List<hClsQuota> lstAll = new List<hClsQuota>();
		//	if(tr.Screener_Results__c != null) {
		//		lstAll = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
		//		for(hClsQuota clsQ : lstAll) {
		//			if(clsQ.key.indexOf('conditions') >= 0) {
		//				lstConditions.add(clsQ);
		//			}
		//		}
		//	} else {
		//		hClsQuota clsQ = new hClsQuota();
		//		clsQ.key = 'No Quota Information';
		//		clsQ.value = 'No Quota Information';
		//		lstConditions.add(clsQ);
		//	}
			
		//	// Pull out only "conditions"
			
		//	mapRespondentQuotas.put(tr.Id, lstConditions);
		//}
	}

	public void fillRespondentList() {

		// Set Preferences
		UserPreference__c USER_PREFERENCES = UtilityMethods.USER_PREFERENCES();
		USER_PREFERENCES.HostCheckViewMode__c = strViewType;
		upsert USER_PREFERENCES;

		// Get Linked Session Hierarchy
		Map<Id, Map<Id, Decimal>> mapLinkedSessionTRNumbers = new Map<Id, Map<Id, Decimal>>();

		// Fill List
		lstFullSessions = new List<hClsSession>();

		// Get all respondents for this Master Test
		//Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>(
		//	[SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
		//		Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName,
		//		Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c,
		//		Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c,
		//		Organization__r.Name, Respondent__r.IVRPhone__c, Session_ID__c, 
		//			(SELECT Id, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, Tested_Status__c,
		//				Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c, Session_ID__c FROM Test_Respondents__r 
		//				WHERE Respondent_Status__c = 'Scheduled' AND Respondent__c != null)
		//	FROM Test_Respondent__c
		//	WHERE Respondent_Status__c = 'Scheduled'
		//		AND Respondent__c != null 
		//		AND Pair_Primary__c = null
		//		AND Master_Test__c = :idMasterTest
		//]);

		Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>();
		String strRespQuery = 'SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c, ';
		strRespQuery+=' Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName, ';
		strRespQuery+=' Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c, ';
		strRespQuery+=' Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c, ';
		strRespQuery+=' Organization__r.Name, Respondent__r.IVRPhone__c, Session_ID__c,  ';
		strRespQuery+=' (SELECT Id, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, Tested_Status__c, ';
		strRespQuery+=' Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c, Session_ID__c FROM Test_Respondents__r  ';
		strRespQuery+=' WHERE Respondent_Status__c = \'Scheduled\' AND Respondent__c != null) ';
		strRespQuery+=' FROM Test_Respondent__c ';
		strRespQuery+=' WHERE Respondent_Status__c = \'Scheduled\' ';
		strRespQuery+=' AND Respondent__c != null  ';
		strRespQuery+=' AND Pair_Primary__c = null' ;

		if(idSession == null || strRespSearch != '') { 
			strRespQuery+= ' AND Master_Test__c = :idMasterTest ';
		} else {
			strRespQuery+= ' AND Session_ID__c = :idSession ';
		}

		for(Test_Respondent__c tr : Database.query(strRespQuery)) {
			mapRespondents.put(tr.Id, tr);
		}

		// HANDLE PAIRS
		mapPairs = new Map<Id, List<Test_Respondent__c>>();
		for(Test_Respondent__c tr : [SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
										Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName,
										Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c,
										Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c,
										Organization__r.Name, Respondent__r.IVRPhone__c, Pair_Primary__c
									FROM Test_Respondent__c
									WHERE Pair_Primary__c IN :mapRespondents.keySet()
										AND Respondent_Status__c = 'Scheduled'
										AND Respondent__c != null]) {
			
			List<Test_Respondent__c> lstTemp = new List<Test_Respondent__c>();
			if(mapPairs.containsKey(tr.Pair_Primary__c)) {
				lstTemp = mapPairs.get(tr.Pair_Primary__c);
			}

			lstTemp.add(tr);
			mapPairs.put(tr.Pair_Primary__c, lstTemp);
		}

		// GET QUOTA INFORMATION
		mapRespondentQuotas = new Map<Id, List<hClsQuota>>();

		// Spin through all Respondents
		for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id IN :mapRespondents.keyset()]) {

			List<hClsQuota> lstConditions = new List<hClsQuota>();

			// Put all in list first
			List<hClsQuota> lstAll = new List<hClsQuota>();
			if(tr.Screener_Results__c != null) {
				lstAll = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
				for(hClsQuota clsQ : lstAll) {
					if(clsQ.key.indexOf('conditions') >= 0) {
						lstConditions.add(clsQ);
					}
				}
			} else {
				hClsQuota clsQ = new hClsQuota();
				clsQ.key = 'No Quota Information';
				clsQ.value = 'No Quota Information';
				lstConditions.add(clsQ);
			}
			
			// Pull out only "conditions"
			mapRespondentQuotas.put(tr.Id, lstConditions);
		}


		// Pull all ContactIds in for HCIds
		Set<Id> setContactIds = new Set<Id>();
		for(Test_Respondent__c tr : mapRespondents.values()) {
			setContactIds.add(tr.Respondent__c);
		}

		// Pull all household info
		Map<Id, Household_Contact__c> mapHouseholds = new Map<Id, Household_Contact__c>();
		for(Household_Contact__c hc : [SELECT Contact__c, Household__r.MailingStreet__c, Household__r.MailingStreet2__c, 
											Household__r.MailingState__c, Household__r.MailingPostalCode__c, Household__r.MailingCity__c,
											Household__c
											FROM Household_Contact__c WHERE Contact__c IN :setContactIds]) {
			mapHouseholds.put(hc.Contact__c, hc);
		}

		// Get all Sessions for this MT
		List<Session__c> lstSessions;

		String strQuery = 'SELECT ';
		for(Schema.FieldSetMember fsm : SObjectType.Session__c.FieldSets.Quick_Display.getFields()) {
			strQuery+= fsm.getFieldPath() + ', ';
		}
		strQuery+= 'Id, Name, (SELECT Id FROM Session_Quotas__r) FROM Session__c ';


		if(idSession == null || strRespSearch != '') { 
			strQuery+= ' WHERE Related_Test__c = :idMasterTest ';
		} else {
			strQuery+= ' WHERE Id = :idSession ';
		}

		lstSessions = Database.query(strQuery);

		/**************************/
		/******* List View	*******/
		/**************************/
		if(strViewType == 'List View') {

			//Map<Id, Session_Quota__c> mapSQIDs = new Map<Id, Session_Quota__c>([
			//	SELECT Id FROM Session_Quota__c WHERE Related_Session__r.Related_Test__c = :idMasterTest
			//]);

			Map<Id, Session_Quota__c> mapSQIDs = new Map<Id, Session_Quota__c>();
			String strSQIDQuery = 'SELECT Id FROM Session_Quota__c WHERE ';
			if(idSession == null || strRespSearch != '') { 
				strSQIDQuery+= ' Related_Session__r.Related_Test__c = :idMasterTest ';
			} else {
				strSQIDQuery+= ' Related_Session__c = :idSession ';
			}

			for(Session_Quota__c sq : (List<Session_Quota__c>)Database.Query(strSQIDQuery)) {
				mapSQIDs.put(sq.Id, sq);
			}

			// Query for (TODO - get out of loop) Respondents in SQs
			Map<Id, Test_Respondent_Quota__c> mapTRQRespIds = new Map<Id, Test_Respondent_Quota__c>();
			for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Test_Respondent__r.Respondent__c, 
													Session_Quota__r.Related_Session__r.Name,
													Session_Quota__r.Related_Session__c   
													FROM Test_Respondent_Quota__c
													WHERE IsScheduled__c = TRUE
														AND IsTrackingQuota__c = FALSE 
														AND Test_Respondent__r.Respondent_Status__c = 'Scheduled'
														AND Session_Quota__c IN :mapSQIDs.keySet()
														AND Test_Respondent__r.Respondent__c != null
														AND Test_Respondent__r.Pair_Primary__c = null
													ORDER BY Test_Respondent__r.Respondent__r.Lastname, 
														Test_Respondent__r.Respondent__r.FirstName]) {
				
				mapTRQRespIds.put(trq.Test_Respondent__c, trq);
			}

			List<hClsRespondent> lstTRTemp = new List<hClsRespondent>();
			for(Id idR : mapTRQRespIds.keyset()) {
				if(strRespSearch != '') {
					if(mapRespondents.get(idR).Respondent__r.Name.toLowerCase().indexOf(strRespSearch.toLowerCase()) >= 0 ||
						mapRespondents.get(idR).Respondent__r.PID__c == strRespSearch) {
						lstTRTemp.add(new hClsRespondent(
							mapRespondents.get(idR), 
							mapHouseholds.get(mapTRQRespIds.get(idR).Test_Respondent__r.Respondent__c), 
							mapTRQRespIds.get(idR),
							mapPairs.get(idR),
							mapRespondentQuotas.containsKey(idR)
						));
					}
				} else {
					lstTRTemp.add(new hClsRespondent(
						mapRespondents.get(idR), 
						mapHouseholds.get(mapTRQRespIds.get(idR).Test_Respondent__r.Respondent__c), 
						mapTRQRespIds.get(idR),
						mapPairs.get(idR),
						mapRespondentQuotas.containsKey(idR)
					));	
				}
				
			}

			// Add everything to the final list!
			Session__c seNew = new Session__c(Name='List View Session');
			lstFullSessions.add(new hClsSession(seNew, lstTRTemp));

		} else {

			// Get Respondents for selected Sessions
			for(Session__c ses : lstSessions) {
				
				// Get all SQs
				Set<Id> setSQIDs = new Set<Id>();
				for(Session_Quota__c sq : ses.Session_Quotas__r) {
					setSQIDs.add(sq.Id);
				}

				// Query for (TODO - get out of loop) Respondents in SQs
				Map<Id, Id> mapTRQRespIds = new Map<Id, Id>();
				for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Test_Respondent__r.Respondent__c
														FROM Test_Respondent_Quota__c
														WHERE IsScheduled__c = TRUE
															AND IsTrackingQuota__c = FALSE 
															AND Test_Respondent__r.Respondent_Status__c = 'Scheduled'
															AND Session_Quota__c IN :setSQIDs
															AND Test_Respondent__r.Respondent__c != null
															AND Test_Respondent__r.Pair_Primary__c = null
														ORDER BY Test_Respondent__r.Respondent__r.Lastname, 
															Test_Respondent__r.Respondent__r.FirstName]) {
					
					mapTRQRespIds.put(trq.Test_Respondent__c, trq.Test_Respondent__r.Respondent__c);
				}

				List<hClsRespondent> lstTRTemp = new List<hClsRespondent>();
				for(Id idR : mapTRQRespIds.keyset()) {
					if(strRespSearch != '' && mapRespondents.containsKey(idR)) {
						if(mapRespondents.get(idR).Respondent__r.Name.toLowerCase().indexOf(strRespSearch.toLowerCase()) >= 0 ||
							mapRespondents.get(idR).Respondent__r.PID__c == strRespSearch) {
							lstTRTemp.add(new hClsRespondent(
								mapRespondents.get(idR), 
								mapHouseholds.get(mapTRQRespIds.get(idR)), 
								null,
								mapPairs.get(idR),
								mapRespondentQuotas.containsKey(idR)
							));
						}
					} else {

						System.Debug(mapRespondents.get(idR));
						System.Debug(mapHouseholds.get(mapTRQRespIds.get(idR)));
						System.Debug(mapPairs.get(idR));
						System.Debug(mapRespondentQuotas.containsKey(idR));

						lstTRTemp.add(new hClsRespondent(
							mapRespondents.get(idR), 
							mapHouseholds.get(mapTRQRespIds.get(idR)), 
							null,
							mapPairs.get(idR),
							mapRespondentQuotas.containsKey(idR)
						));	
					}
					
				}

				// Add everything to the final list!
				lstFullSessions.add(new hClsSession(ses, lstTRTemp));
			}
		}

		/**************************/
		/******* Status Map	*******/
		/**************************/
		updateTrackerStats();


	}

	public void updateTrackerStats() {

		// Initialize Status Map
		mapStatusCount = new Map<String, Integer>();
		for(String str : UtilityMethods.getValuesForPicklist('Test_Respondent__c', 'Tested_Status__c')) {
			mapStatusCount.put(str, 0);
		}

		// Spin back through the list and get status counts
		for(hClsSession clsSession : lstFullSessions) {
			for(hClsRespondent clsResp : clsSession.lstTR) {
				if(clsResp.tr.Tested_Status__c != null) {
					mapStatusCount.put(clsResp.tr.Tested_Status__c, mapStatusCount.get(clsResp.tr.Tested_Status__c)+1);
				}
				for(Test_Respondent__c trPair : clsResp.lstPairs) {
					if(trPair.Tested_Status__c != null) {
						mapStatusCount.put(trPair.Tested_Status__c, mapStatusCount.get(trPair.Tested_Status__c)+1);
					}
				}
			}
		}
		
		// Initialize Quota Map
		mapQuotaCount = new Map<Id, hClsQuotaKey>();
		for(Quota__c mq : [SELECT Quota_Summary__c FROM Quota__c WHERE Related_Test__c = :idMasterTest]) {
			mapQuotaCount.put(mq.Id, new hClsQuotaKey(mq.Id, mq));
		}

	}

	@RemoteAction
	public static void saveRespondent(Contact passContact, Test_Respondent__c passRespondent, Household__c passHousehold) {
		if(passContact.Id != null) { upsert passContact; }
		if(passRespondent.Id != null) { 
			upsert passRespondent; 
		}
		if(passHousehold.Id != null) { upsert passHousehold; }
	}

	@RemoteAction
	public static List<hClsQuota> respondentQuota(Id respondentId) {
		List<hClsQuota> lstTemp = new List<hClsQuota>();
		for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id = :respondentId]) {
			String strJSON = tr.Screener_Results__c;
			if(tr.Screener_Results__c != null) {
				lstTemp = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
			}
		}
		return lstTemp;
	}

	@RemoteAction
	public static List<Test_Respondent__c> listDOTChecksForTest(Id masterTestId) {
		return [SELECT Id, Check_Number__c, Check_Amount__c 
					FROM Test_Respondent__c 
					WHERE Master_Test__c = :masterTestId
						AND Respondent__c = null];
	}

	@RemoteAction
	public static void updateTRWithDOTCheck(Id passTRDot, Id passTR) {

		Test_Respondent__c trDOT = [SELECT Check_Number__c, Check_Amount__c, Check_Memo__c, Check_Printed_Date__c 
									FROM Test_Respondent__c 
									WHERE Id = :passTRDot];

		Test_Respondent__c trReal = [SELECT Check_Number__c, Check_Amount__c, Check_Memo__c, Check_Printed_Date__c 
									FROM Test_Respondent__c 
									WHERE Id = :passTR];

		trReal.Check_Number__c = trDOT.Check_Number__c;
		trReal.Check_Amount__c = trDOT.Check_Amount__c;
		trReal.Check_Memo__c = trDOT.Check_Memo__c;
		trReal.Check_Printed_Date__c = trDOT.Check_Printed_Date__c;

		delete trDOT;
		update trReal;

	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsSession {

		public Session__c ses {get;set;}
		public List<hClsRespondent> lstTR {get;set;}

		public hClsSession(Session__c passSession, List<hClsRespondent> passRL) {
			ses = passSession;
			lstTR = passRL;
		}
	}

	public class hClsRespondent {

		public Test_Respondent__c tr {get;set;}
		public Household_Contact__c hc {get;set;}
		public Test_Respondent_Quota__c trq {get;set;}
		public List<Test_Respondent__c> lstPairs {get;set;}
		public Integer intRowSpan {get;set;}
		public String strPairStyle {get;set;}
		public Boolean bolShowQuota {get;set;}

		//public hClsRespondent(Test_Respondent__c passTR, Household_Contact__c passHC, Test_Respondent_Quota__c passTRQ, List<Test_Respondent__c> passPairList) {
		//	tr = passTR;
		//	hc = passHC;
		//	trq = passTRQ;
		//	bolShowQuota = false;
		//	lstPairs = new List<Test_Respondent__c>();
		//	strPairStyle = '';
		//	if(passPairList != null) {
		//		lstPairs = passPairList;
		//		strPairStyle = ' pairCol';
		//	}
		//	intRowSpan = lstPairs.size() + 1;
		//}

		public hClsRespondent(Test_Respondent__c passTR, Household_Contact__c passHC, Test_Respondent_Quota__c passTRQ, List<Test_Respondent__c> passPairList, Boolean showQuota) {
			tr = passTR;
			hc = passHC;
			trq = passTRQ;
			bolShowQuota = showQuota;
			lstPairs = new List<Test_Respondent__c>();
			strPairStyle = '';
			if(passPairList != null) {
				lstPairs = passPairList;
				strPairStyle = ' pairCol';
			}
			intRowSpan = lstPairs.size() + 1;
		}

	}

	public class hClsQuota {
		public String key {get;set;}
		public String value {get;set;}
	}

	public class hClsQuotaKey {
		public Id idMQ {get;set;}
		public Integer intCount {get;set;}
		public Quota__c mq {get;set;}
		public hClsQuotaKey(Id passId, Quota__c passMQ) {
			idMQ = passId;
			mq = passMQ;
			intCount = 0;
		}
	}

}