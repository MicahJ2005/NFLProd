public with sharing class CheckGeneratorWizardController {
/**
*   {Purpose}  �  Provides the user an interface to check for TR data quality 
*					and options for check generation.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140715  	Andy Boettcher DCS		Created
*	20240925	Sophia Murphy DCS		EXCLUDE Hut Not Complete, No Show Tested Statues (DC Case 12092)
*   =============================================================================
*/
	public Id idMasterTest {get;set;}
	public String strSession {get;set;}
	public String strTest {get;set;}
	//private Id idChunkerMasterTest;
	//private Id idChunkerSession;
	public List<hClsSession> lstFullSessions {get;set;}
	public hClsDotChecks clsDotOptions {get;set;}
	public Integer intRespondentCount {get;set;}
	public Task tskOptions {get;set;}
	public Set<String> setRespondentStatuses = new Set<String>();
	public Set<String> setTestedStatuses_EXCLUDE = new Set<String>();

	///////////////////////////
	// Constructors
	///////////////////////////
	public CheckGeneratorWizardController() {
		lstFullSessions = new List<hClsSession>();
		clsDotOptions = new hClsDotChecks();
		intRespondentCount = 0;

		setRespondentStatuses.add('Scheduled');
		setRespondentStatuses.add('Request gift card');

		setTestedStatuses_EXCLUDE.add('No Show');
		setTestedStatuses_EXCLUDE.add('HUT Not Complete');

		// Pull Ids from Chunker
		//idChunkerMasterTest = ApexPages.currentPage().getParameters().get('m');
		//idChunkerSession = ApexPages.currentPage().getParameters().get('s');

		//if(idChunkerMasterTest != null && idChunkerSession != null) {

		//}


	}
	
	
	///////////////////////////
	// GET / SET
	///////////////////////////
	public List<SelectOption> lstProjects {
		get {
			List<SelectOption> lstTemp = new List<SelectOption>();
			lstTemp.add(new SelectOption('','-- Select --'));
			for(Master_Test__c mt : [SELECT Id, Project_Number__c, Public_Test_Description__c
						FROM Master_Test__c
                                     //Updated to -60 so checks can be run after tests are complete.  
						WHERE Last_Session_Start__c >= :System.Today().addDays(-60)
						ORDER BY Project_Number__c ASC]) {
						// WHERE Check_Status__c = 'Not Printed'
				lstTemp.add(new SelectOption(mt.Id,mt.Project_Number__c + ' - ' + mt.Public_Test_Description__c));
			}
			return lstTemp;
		}
	}

	public List<SelectOption> lstSessions {
		get {
			List<SelectOption> lstTemp = new List<SelectOption>();
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
	public void fillRespondents() {

		Set<Id> setSelectedSessions = new Set<Id>();
		for(String objStr : strSession.split(',')) {
			if(objStr.length() > 3) {
				objStr = objStr.replace('[', '');
				objStr = objStr.replace(']', '');
				setSelectedSessions.add(Id.valueOf(objStr.trim()));
			}
		}

		lstFullSessions = new List<hClsSession>();
		tskOptions = new Task();
		tskOptions.ActivityDate = System.Today();

		// Get all respondents for this Master Test
		Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>(
			[SELECT Id, Check_Amount__c, Check_Number__c, Session_Check_Amount__c, 
				Check_Printed_Date__c, Respondent__c, Respondent__r.Name, 
				Respondent__r.PID__c, Donation_Amount_Per_Event__c, Respondent__r.Status__c,
				Respondent__r.Age__c, Pair_Primary__c, Organization__r.Name, 
				(SELECT Id, Respondent__c, Respondent__r.Name, Respondent__r.PID__c,
						Respondent__r.Age__c FROM Test_Respondents__r 
						WHERE Respondent_Status__c IN :setRespondentStatuses 
							AND Tested_Status__c NOT IN :setTestedStatuses_EXCLUDE
							AND Respondent__c != null)
			FROM Test_Respondent__c
			WHERE Respondent_Status__c IN :setRespondentStatuses 
				AND Tested_Status__c NOT IN :setTestedStatuses_EXCLUDE
				AND Pair_Primary__c = null
				AND Master_Test__c = :idMasterTest
				AND Respondent__c != null
				AND Check_Printed_Date__c = null
				AND (Check_Number__c = null OR Check_Number__c = '')
		]);

		//// Check to see if we're going to need to fire the chunker
		//if(mapRespondents.size() > 600) {
		//	PageReference prRef = new PageReference('/apex/CheckGenWizardChunk');
		//	prRef.setRedirect(true);
		//	return prRef;
		//}

		// Get all Households based on Respondents
		Set<Id> setContactIds = new Set<Id>();
		Map<Id, Household_Contact__c> mapHouseholds = new Map<Id, Household_Contact__c>();
		for(Test_Respondent__c tr : mapRespondents.values()) { setContactIds.add(tr.Respondent__c); }
		for(Household_Contact__c hc : [SELECT Contact__c, Household__r.MailingStreet__c,
											Household__r.MailingState__c, Household__r.MailingPostalCode__c, Household__r.MailingCity__c
											FROM Household_Contact__c WHERE Contact__c IN :setContactIds]) {
			mapHouseholds.put(hc.Contact__c, hc);
		}

		// Get all Sessions for this MT
		List<Session__c> lstSessions;

		Set<String> setFields = new Set<String>();
		setFields.add('Check_Amount__c');
		setFields.add('Check_Status__c');
		setFields.add('Check_Printed_Date__c');
		setFields.add('Session_Start__c');
		setFields.add('Session_End__c');
		setFields.add('Recruits_Per_Session__c');
		for(Schema.FieldSetMember fsm : SObjectType.Session__c.FieldSets.Quick_Display.getFields()) {
			setFields.add(fsm.getFieldPath());
		}

		String strQuery = 'SELECT ';
		for(String str : setFields) { strQuery+= str + ', '; }
		//strQuery+= 'Id, Name, (SELECT Id FROM Session_Quotas__r WHERE Scheduled_Respondents__c > 0) FROM Session__c ';
		strQuery+= 'Id, Name, (SELECT Id FROM Session_Quotas__r) FROM Session__c ';
		strQuery+= ' WHERE Related_Test__c = :idMasterTest ';
		if(setSelectedSessions.size() > 0) {
			strQuery += ' AND Id IN :setSelectedSessions ';
		}
		strQuery+= ' ORDER BY Session_Start__c ASC';

		lstSessions = Database.query(strQuery);

		// Dive in!
		for(Session__c ses : lstSessions) {
			
			// Get all SQs
			Set<Id> setSQIDs = new Set<Id>();
			for(Session_Quota__c sq : ses.Session_Quotas__r) {
				setSQIDs.add(sq.Id);
			}

			// Query for (TODO - get out of loop) Respondents in SQs
			Map<Id, Id> mapTRQRespIds = new Map<Id, Id>();
			if(setSQIDs.size() > 0) {
				for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Test_Respondent__r.Respondent__c
														FROM Test_Respondent_Quota__c
														WHERE IsScheduled__c = TRUE
															AND (PrimaryQuota__c = 'primary' OR IsTrackingQuota__c = false)
															AND Session_Quota__c IN :setSQIDs
															AND Test_Respondent__c IN :mapRespondents.keyset()
														ORDER BY Test_Respondent__r.Respondent__r.Lastname, 
															Test_Respondent__r.Respondent__r.FirstName]) {
					
					mapTRQRespIds.put(trq.Test_Respondent__c, trq.Test_Respondent__r.Respondent__c);
				}
			}

			List<hClsRespondent> lstTRTemp = new List<hClsRespondent>();
			for(Id idR : mapTRQRespIds.keyset()) {
				lstTRTemp.add(new hClsRespondent(mapRespondents.get(idR), mapHouseholds.get(mapTRQRespIds.get(idR))));	
			}

			// Add everything to the final list!
			lstFullSessions.add(new hClsSession(ses, lstTRTemp));
		}

		for(hClsSession clsSession : lstFullSessions) {
			System.Debug('Session ' + clsSession.ses.Id + ' has ' + clsSession.lstTR.size() + ' respondents for the check tool');
		}

		// Calculate Check generation metrics
		calculateDotCheckMetrics();

	}

	public void calculateDotCheckMetrics() {
		calculateCheckMetrics();
	}

	public void calculateCheckMetrics() {

		clsDotOptions.intGapChecksCount = 0;
		clsDotOptions.intTotalDotCount = 0;
		clsDotOptions.intTotalChecks = 0;
		clsDotOptions.intNonOrgCount = 0;
		clsDotOptions.intOrgCount = 0;
		intRespondentCount = 0;

		for(hClsSession clsSession : lstFullSessions) {
			if(clsSession.bolChecked) {
				intRespondentCount+= clsSession.lstTR.size();
				clsDotOptions.intGapChecksCount+= clsSession.clsChecks.intGapChecksCount;
				clsDotOptions.intTotalChecks+= clsSession.lstTR.size();
				clsDotOptions.intNonOrgCount+= clsSession.clsChecks.intNonOrgCount;
				clsDotOptions.intOrgCount+= clsSession.clsChecks.intOrgCount;
			}
		}

		clsDotOptions.intTotalDotCount+= clsDotOptions.intNonOrgCount + clsDotOptions.intOrgCount;
		clsDotOptions.intTotalChecks+= clsDotOptions.intTotalDotCount;

		// Compute Metrics!
		clsDotOptions.intMetricsScheduledRespCount = 0;
		clsDotOptions.intMetricsScheduledRespMaximum = 0;
		clsDotOptions.intMetricsScheduledRespGap = 0;
		clsDotOptions.intMetricsGapChecks = 0;
		clsDotOptions.intMetricsBlankChecks = 0;
		clsDotOptions.intMetricsTotalDOTChecks = 0;
		clsDotOptions.intMetricsPartialDonations = 0;
		clsDotOptions.intMetricsNoDonations = 0;
		clsDotOptions.intMetricsTotalDonations = 0;

		for(hClsSession clsSession : lstFullSessions) {
			if(clsSession.bolChecked) {
				clsDotOptions.intMetricsScheduledRespCount+=clsSession.lstTR.size();

				Integer intRecruitsPerSession = 0;
				if(clsSession.ses.Recruits_Per_Session__c != null) { intRecruitsPerSession = Integer.valueOf(clsSession.ses.Recruits_Per_Session__c); }
				clsDotOptions.intMetricsScheduledRespMaximum+=intRecruitsPerSession;
			}
		}

		// Respondent Gap
		clsDotOptions.intMetricsScheduledRespGap = clsDotOptions.intMetricsScheduledRespMaximum - clsDotOptions.intMetricsScheduledRespCount;

		// Check Gaps
		clsDotOptions.intMetricsGapChecks = clsDotOptions.intMetricsScheduledRespGap;
		clsDotOptions.intMetricsTotalDOTChecks = clsDotOptions.intTotalDotCount;
		clsDotOptions.intMetricsBlankChecks = clsDotOptions.intMetricsTotalDOTChecks - clsDotOptions.intMetricsGapChecks;

		// Donation Checks
		clsDotOptions.intMetricsPartialDonations = clsDotOptions.intOrgCount;
		clsDotOptions.intMetricsNoDonations = clsDotOptions.intNonOrgCount;
		clsDotOptions.intMetricsTotalDonations = clsDotOptions.intMetricsPartialDonations + clsDotOptions.intMetricsNoDonations;

	}
	
	public void saveRespondentChanges() {

		Map<Id, Contact> mapUpdateContacts = new Map<Id, Contact>();
		Map<Id, Household__c> mapUpdateHouseholds = new Map<Id, Household__c>();

		for(hClsSession clsSession : lstFullSessions) {
			if(!clsSession.bolLocked) {
				for(hClsRespondent clsResp : clsSession.lstTR) {
					// Contact Record
					//if(!mapUpdateContacts.containsKey(clsResp.tr.Respondent__c)) {
					mapUpdateContacts.put(clsResp.tr.Respondent__c, new Contact(Id=clsResp.tr.Respondent__c,Status__c=clsResp.tr.Respondent__r.Status__c));

					// Pairs Logic
					for(Test_Respondent__c trPair : clsResp.tr.Test_Respondents__r) {
						mapUpdateContacts.put(trPair.Respondent__c, new Contact(Id=trPair.Respondent__c,Status__c=clsResp.tr.Respondent__r.Status__c));
					}
					//}

					// Household Record
					if(!mapUpdateHouseholds.containsKey(clsResp.hc.Household__c) && clsResp.hc.Household__c != null) {
						Household__c hseUpdate = new Household__c(Id=clsResp.hc.Household__c);
						hseUpdate.MailingStreet__c = clsResp.hc.Household__r.MailingStreet__c;
						//hseUpdate.MailingStreet2__c = clsResp.hc.Household__r.MailingStreet2__c;
						hseUpdate.MailingCity__c = clsResp.hc.Household__r.MailingCity__c;
						hseUpdate.MailingState__c = clsResp.hc.Household__r.MailingState__c;
						hseUpdate.MailingPostalCode__c = clsResp.hc.Household__r.MailingPostalCode__c;
						mapUpdateHouseholds.put(clsResp.hc.Household__c, hseUpdate);
					}
				}
			}	
		}

		if(mapUpdateContacts.size() > 0) { update mapUpdateContacts.values(); }
		if(mapUpdateHouseholds.size() > 0) { update mapUpdateHouseholds.values(); }

	}

	public void prepareChecksForGeneration() {

		Map<String, Boolean> mapApexSettings = UtilityMethods.CODE_SETTINGS();

		/**********************************
		** GAP CHECK GENERATION
		**********************************/

		// Step 1:  Create or find Master Quota for "Gap Checks"
		List<Quota__c> lstMQClone = [SELECT Id FROM Quota__c WHERE Quota_Summary__c = 'Gap Checks' AND Related_Test__c = :idMasterTest LIMIT 1];
		Quota__c mqClone;
		if(lstMQClone.size() == 0) {
			// Create Master Quota Clone
			mqClone = new Quota__c();
			mqClone.Related_Test__c = idMasterTest;
			mqClone.Quota_Summary__c = 'Gap Checks';
			mqClone.Minimum_Respondents__c = 0;
			mqClone.Maximum_Respondents__c = 0;
			mqClone.IsOpen__c = false;
			mqClone.IsScheduleEnabled__c = false;
			mqClone.IsTrackingOnly__c = true;
			insert mqClone;
		} else {
			mqClone = lstMQClone[0];
		}

		// Step 2:  Create SQs per Session and get amount per session
		Map<Id, Id> mapSQs = new Map<Id, Id>();
		Map<Id, Decimal> mapSessionAmounts = new Map<Id, Decimal>();
		for(Session_Quota__c sq : [SELECT Id, Related_Session__c, Related_Session__r.Check_Amount__c FROM Session_Quota__c WHERE Related_Session__r.Related_Test__c = :idMasterTest AND Master_Quota__c = :mqClone.Id]) {
			mapSQs.put(sq.Related_Session__c, sq.Id);
			mapSessionAmounts.put(sq.Related_Session__c, sq.Related_Session__r.Check_Amount__c);
		}

		List<Session_Quota__c> lstInsertSQs = new List<Session_Quota__c>();
		for(hClsSession clsSession : lstFullSessions) {
			if(!mapSQs.containsKey(clsSession.ses.Id) && clsSession.bolChecked) {
				Session_Quota__c sqNew = new Session_Quota__c(Related_Session__c=clsSession.ses.Id);
				sqNew.Master_Quota__c = mqClone.Id;
				sqNew.Minimum_Respondents__c = 0;
				sqNew.Maximum_Respondents__c = 0;
				sqNew.IsOpen__c = false;
				lstInsertSQs.add(sqNew);
			}
		}

		if(lstInsertSQs.size() > 0) { 
			insert lstInsertSQs; 
			lstInsertSQs = [SELECT Id, Related_Session__c, Related_Session__r.Check_Amount__c FROM Session_Quota__c WHERE Master_Quota__c = :mqClone.Id];
			for(Session_Quota__c sq : lstInsertSQs) {
				mapSQs.put(sq.Related_Session__c, sq.Id);
				mapSessionAmounts.put(sq.Related_Session__c, sq.Related_Session__r.Check_Amount__c);
			}
		}

		System.Debug('mapSessionAmounts = ' + mapSessionAmounts);

		/////////////////////////////
		// Create Gap Test Respondents per Session in Gap Check Quota
		/////////////////////////////
		Map<Id, List<Test_Respondent__c>> mapSessionTRs = new Map<Id, List<Test_Respondent__c>>();
		for(hClsSession clsSession : lstFullSessions) {
			List<Test_Respondent__c> lstInsertGAPTRs = new List<Test_Respondent__c>();

			if(clsSession.bolChecked) {
			
				// NON ORG - FULL PAYMENT
				for(Integer iGap = 0; iGap < clsSession.clsChecks.intNonOrgCount;iGap++) {
					Test_Respondent__c trGap = new Test_Respondent__c(Master_Test__c=idMasterTest);
					trGap.Check_Amount__c = mapSessionAmounts.get(clsSession.ses.Id);
					trGap.Respondent_Status__c = 'Scheduled';
					trGap.Tested_Status__c = 'Pending';
					lstInsertGAPTRs.add(trGap);
					System.Debug('CREATING NON ORG TR - ' + trGap);
				}

				// ORG - PARTIAL PAYMENT
				for(Integer iGap = 0; iGap < clsSession.clsChecks.intOrgCount;iGap++) {
					Test_Respondent__c trGap = new Test_Respondent__c(Master_Test__c=idMasterTest);
					trGap.Respondent_Status__c = 'Scheduled';
					trGap.Tested_Status__c = 'Pending';
					trGap.Donation_Amount_Per_Event__c = 'Partial payment of $10';

					Decimal decCheckAmount = 0;
					decCheckAmount = mapSessionAmounts.get(clsSession.ses.Id);
					decCheckAmount = decCheckAmount - 10;
					if(decCheckAmount < 0) { decCheckAmount = 0; }
					trGap.Check_Amount__c = decCheckAmount;

					lstInsertGAPTRs.add(trGap);
					System.Debug('CREATING ORG TR - ' + trGap);
				}

				mapSessionTRs.put(clsSession.ses.Id, lstInsertGAPTRs);
			}
		}

		// Insert gap TRs and TRQs
		List<Test_Respondent_Quota__c> lstInsertTRQs = new List<Test_Respondent_Quota__c>();
		for(Id idSession : mapSessionTRs.keyset()) {
			List<Test_Respondent__c> lstInsert = mapSessionTRs.get(idSession);

			if(lstInsert.size() > 0) { insert lstInsert; }
			mapSessionTRs.put(idSession, lstInsert);

			for(Test_Respondent__c tr : lstInsert) {
				Test_Respondent_Quota__c trqNew = new Test_Respondent_Quota__c();
				trqNew.Test_Respondent__c = tr.Id;
				trqNew.Session_Quota__c = mapSQs.get(idSession);
				trqNew.IsQualified__c = false;
				trqNew.IsScheduled__c = true;
				lstInsertTRQs.add(trqNew);
			}
		}

		if(lstInsertTRQs.size() > 0) { insert lstInsertTRQs; }

		/////////////////////////////
		// Combine all Processing of Gap and Scheduled - begin processing checks
		/////////////////////////////
		FPI_AppSettings__c csAppSettings = FPI_AppSettings__c.getInstance('CurrentCheckNumber');
		Integer intNextCheckNumber = Integer.valueOf(csAppSettings.Value__c);

		// Generate Ordered List of TRs to cut checks for
		List<Test_Respondent__c> lstChecksToCut = new List<Test_Respondent__c>();

		// BY SESSION
		if(clsDotOptions.intCheckSort == 0) {

			// By Session - Just take lstTR and append Gap Checks
			for(hClsSession clsSession : lstFullSessions) {
				if(clsSession.bolChecked) {
					for(hClsRespondent clsTR : clsSession.lstTR) { lstChecksToCut.add(clsTR.tr); }
					lstChecksToCut.addAll(mapSessionTRs.get(clsSession.ses.Id));
				}
			}
		}

		// BY WAVE
		if(clsDotOptions.intCheckSort == 1) {

			// By Wave - get all lstTRs in Alpha order and then append Gap Checks at the end
			Set<Id> setTRIds = new Set<Id>();
			for(hClsSession clsSession : lstFullSessions) {
				if(clsSession.bolChecked) {
					for(hClsRespondent clsTR : clsSession.lstTR) {
						setTRIds.add(clsTR.tr.Id);
					}
				}
			}

			// Requery TR object
			List<Test_Respondent__c> lstAlphaTRs = [SELECT Id, Check_Amount__c, Check_Printed_Date__c, Check_Number__c 
											FROM Test_Respondent__c WHERE Id IN :setTRIds 
											ORDER BY Respondent__r.LastName ASC,
												Respondent__r.FirstName ASC];
			lstChecksToCut.addAll(lstAlphaTRs);
			for(Id idSession : mapSessionTRs.keyset()) {
				lstChecksToCut.addAll(mapSessionTRs.get(idSession));

			}

		}

		// Finally - spin through lstChecksToCut and assign Check Numbers and Date!
		for(Test_Respondent__c trCheck : lstChecksToCut) {
			if(trCheck.Check_Amount__c > 0) {
				trCheck.Check_Number__c = String.valueOf(intNextCheckNumber);
				intNextCheckNumber++;
			}
			trCheck.Check_Printed_Date__c = tskOptions.ActivityDate;
		}

		// Prevent Contact rollups from happening (don't need to do it)
		UtilityMethods.bolPreventContactRollup = true;

		//for(Test_Respondent__c trPrint : lstChecksToCut) {
		//	System.Debug(trPrint.Id);
		//}

		// Commit check information
		if(lstChecksToCut.size() > 0) { update lstChecksToCut; }

		// Step 5:  Replace the max check number in custom setting
		csAppSettings.Value__c = string.valueOf(intNextCheckNumber);
		update csAppSettings;

		// Step 6:  Update Session Check Status and Printed Date
		List<Session__c> lstUpdateSessions = new List<Session__c>();
		for(hClsSession clsSession : lstFullSessions) {
			if(clsSession.bolChecked) {
				clsSession.ses.Check_Status__c = 'Generated';
				clsSession.ses.Check_Printed_Date__c = clsDotOptions.dteCheckDate;
				lstUpdateSessions.add(clsSession.ses);
			}
		}
		if(lstUpdateSessions.size() > 0) { update lstUpdateSessions; }

		// Immediately send checks to Wells Fargo Positive Pay
		//System.Debug('PASSING TO WF PP GENERATOR, SENDING = ' + mapApexSettings.get('TransmitCheckDataToWFPositivePay'));
		//CheckGeneratorController.transmitPositivePayRegister(mapApexSettings.get('TransmitCheckDataToWFPositivePay'));

	}

	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsSession {

		public Session__c ses {get;set;}
		public Boolean bolChecked {get;set;}
		public Boolean bolLocked {get;set;}
		public List<hClsRespondent> lstTR {get;set;}
		public hClsDotChecks clsChecks {get;set;}
		public hClsSession(Session__c passSession, List<hClsRespondent> passRL) {
			bolChecked = true;
			ses = passSession;
			lstTR = passRL;
			clsChecks = new hClsDotChecks();
			bolLocked = false;
			if(ses.Check_Status__c == 'Printed') { 
				bolChecked = false;
				bolLocked = true; 
			}

			// Calculate Checks
			calculateChecks();
		}
		private void calculateChecks() {

			// Spin through real Respondents
			for(hClsRespondent clsR : lstTR) {
				//Decimal decCheckAmount = ses.Check_Amount__c;
				Decimal decCheckAmount = 0;
				decCheckAmount = clsR.tr.Check_Amount__c;
				//decCheckAmount = clsR.tr.Session_Check_Amount__c;
				if(clsR.tr.Donation_Amount_Per_Event__c == 'Partial payment of $10') { decCheckAmount = decCheckAmount - 10; clsR.bolDonationFlag=true; }
				if(clsR.tr.Donation_Amount_Per_Event__c == 'Full Payment') { decCheckAmount = 0; clsR.bolDonationFlag=true; }
				if(decCheckAmount < 0) { decCheckAmount = 0; }
				clsR.decCheckAmount = decCheckAmount;
			}

			// Calculate Count of GAP Checks for Session
			clsChecks.intGapChecksCount = 0;
			if(ses.Recruits_Per_Session__c > lstTR.size()) {
				clsChecks.intGapChecksCount = Integer.valueOf(ses.Recruits_Per_Session__c) - lstTR.size();
			}

			// Calculate Pairs Testing - Linked TRs get $0, all goes to parent
			for(hClsRespondent clsR : lstTR) {
				if(clsR.tr.Pair_Primary__c != null) {
					clsR.decCheckAmount = 0;
				}
			}

			/****************************
			* GAP CHECK CALCS
			****************************/

			// Reset Calculation Fields
			//clsChecks.intGapChecksCount = 0;
			clsChecks.intDotCount = 0;
			clsChecks.intTotalDotCount = 0;
			clsChecks.intNonOrgCount = 0;
			clsChecks.intOrgCount = 0;

			// Determine count of DOT checks
			clsChecks.intDotCount+= clsChecks.intGapChecksCount;

			Integer intRecruitsPerSession = 0;
			if(ses.Recruits_Per_Session__c != null) { intRecruitsPerSession = Integer.valueOf(ses.Recruits_Per_Session__c); }
			clsChecks.intDotCount+= Integer.valueOf(Math.Ceil(intRecruitsPerSession * .05));

			// Determine Split of Org/Non-Org
			clsChecks.intNonOrgCount = Integer.valueOf(Math.Ceil(clsChecks.intDotCount * .75));
			clsChecks.intOrgCount+= Integer.valueOf(Math.Ceil(clsChecks.intDotCount * .25));

			clsChecks.intTotalDotCount = clsChecks.intNonOrgCount + clsChecks.intOrgCount;

		}
	}

	public class hClsRespondent {
		public Test_Respondent__c tr {get;set;}
		public List<Test_Respondent__c> lstPairs {get;set;}
		public Household_Contact__c hc {get;set;}
		public Decimal decCheckAmount {get;set;}
		public Boolean bolDonationFlag {get;set;}
		public hClsRespondent(Test_Respondent__c passTR, Household_Contact__c passHC) {
			tr = passTR;
			hc = passHC;
			decCheckAmount = 0;
			bolDonationFlag = false;
		}
	}

	public class hClsDotChecks {

		public Integer intMetricsScheduledRespCount {get;set;}
		public Integer intMetricsScheduledRespMaximum {get;set;}
		public Integer intMetricsScheduledRespGap {get;set;}
		public Integer intMetricsGapChecks {get;set;}
		public Integer intMetricsBlankChecks {get;set;}
		public Integer intMetricsTotalDOTChecks {get;set;}
		public Integer intMetricsPartialDonations {get;set;}
		public Integer intMetricsNoDonations {get;set;}
		public Integer intMetricsTotalDonations {get;set;}

		public Integer intGapChecksCount {get;set;}
		public Integer intDotCount {get;set;}
		public Integer intNonOrgCount {get;set;}
		public Integer intOrgCount {get;set;}
		public Integer intTotalDotCount {get;set;}
		public Integer intTotalChecks {get;set;}
		public Integer intCheckSort {get;set;}
		public Date dteCheckDate {get;set;}
		public hClsDotChecks() {
			intGapChecksCount = 0;
			intDotCount = 0;
			intNonOrgCount = 0;
			intOrgCount = 0;
			intTotalDotCount = 0;
			intTotalChecks = 0;
			intCheckSort = 0;
			dteCheckDate = System.Today();
		}
		public List<SelectOption> lstCheckSort {
			get {
				List<SelectOption> lstTemp = new List<SelectOption>();
				lstTemp.add(new SelectOption('0','By Session'));
				lstTemp.add(new SelectOption('1','By Wave'));
				return lstTemp;
			}
		}
	}
}