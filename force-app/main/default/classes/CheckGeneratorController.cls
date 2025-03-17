public with sharing class CheckGeneratorController {
/**
*   {Purpose}  �  This class and page are used to pull TR records for check printing.
*					This class takes over after the CheckGeneratorWizardController assigns
*					check numbers and verifies business logic.  All records set in the SOQL
*					query of fillRespondents() below are included to be printed.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 952.223.5604                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    				Name             		Description
*   A LONG LONG TIME AGO  	Andy Boettcher DCS		Created
*   20170405				Andy Boettcher DCS		Refactored Valtira Check code for WF Positive Pay
*   =============================================================================
*/
	public Id idMasterTest;
	public List<hClsCheck> lstChecks {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public CheckGeneratorController() { 
		idMasterTest = ApexPages.currentPage().getParameters().get('id');
		lstChecks = new List<hClsCheck>(); 
	}	
	
	///////////////////////////
	// PDF GENERATOR METHODS
	///////////////////////////
	@Future(callout=true)
	public static void transmitPositivePayRegister(Boolean bolSendViaWS) {

		UtilityMethods.bolPreventTRSQS = true;
		UtilityMethods.bolPreventTRQSQS = true;
		UtilityMethods.bolPreventMetricRollup = true;

		String strValtiraEndpoint = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_PositivePay_Endpoint').Value__c);
		String strValtiraAPIKey = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_PositivePay_APIKey').Value__c);

		UtilityMethods.hClsValtiraCheckGenerator clsCheckHandler = new UtilityMethods.hClsValtiraCheckGenerator();
		clsCheckHandler.lstRespondents = new List<Test_Respondent__c>();

		clsCheckHandler.lstRespondents = [SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
											Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, 
											Master_Test__r.Project_Number__c, Master_Test__c, Donation_Amount_Per_Event__c,
											Session_Check_Amount__c, Organization__r.Name, Session_Id__c, IsPositivePayTransmitted__c,
											PositivePayTransmitted__c
											FROM Test_Respondent__c
											WHERE 
												Check_Number__c != null
												AND Check_Printed_Date__c != null
												AND IsPositivePayTransmitted__c = false
											ORDER BY CheckSortField__c ASC];

		if(clsCheckHandler.lstRespondents.isEmpty()) { return; }

		System.Debug(clsCheckHandler.lstRespondents.size());

		// ASSEMBLE CHECK DATA
		clsCheckHandler = CheckGeneratorController.generatePDFCheckData(clsCheckHandler);

		// ASSEMBLE THIS THING...
		valtiraEnvelope envelope = new valtiraEnvelope();
		envelope.forms = clsCheckHandler.formFields;

		System.Debug(envelope.forms);
		
		Http objHttp = new Http();
		HttpRequest objReq = new HttpRequest();
		objReq.setTimeout(60000);
		objReq.setEndpoint(strValtiraEndpoint);
		objReq.setMethod('POST');
		objReq.setHeader('Content-Type', 'application/json');
		objReq.setHeader('x-api-key', strValtiraAPIKey);
		objReq.setBody(JSON.serialize(envelope));

		System.Debug(objReq);
		System.Debug(objReq.getBody());
		System.Debug(objReq.getHeader('x-api-key'));

		if(!bolSendViaWS) { return; }

		//try {
			HttpResponse objRes = objHttp.send(objReq);
			valtiraReturnEnvelope objResponse = (valtiraReturnEnvelope)JSON.deserialize(objRes.getBody(), valtiraReturnEnvelope.class);
			System.Debug(objResponse);

			if(objResponse.succeeded) {

				// Mark all TRs as SENT
				for(Test_Respondent__c soTR : clsCheckHandler.lstRespondents) {
					soTR.IsPositivePayTransmitted__c = true;
					soTR.PositivePayTransmitted__c = System.Now();
				}

				if(!clsCheckHandler.lstRespondents.isEmpty()) { update clsCheckHandler.lstRespondents; }

			}

		//} catch(Exception ex) {
			//System.Debug(ex);
		//}
	}

	public static PageReference generatePDFChecks(Id idMasterTest, Boolean bolUpdateSession) {

		String strValtiraEndpoint = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_Endpoint').Value__c);
		String strValtiraAPIKey = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_APIKey').Value__c);

		UtilityMethods.hClsValtiraCheckGenerator clsCheckHandler = new UtilityMethods.hClsValtiraCheckGenerator();
		clsCheckHandler.idMasterTest = idMasterTest;
		clsCheckHandler.lstRespondents = new List<Test_Respondent__c>();

		// Find only sessions that have been 'Generated'
		Set<Id> setSessionIds = new Set<Id>();
		for(Session__c ses : [SELECT Id FROM Session__c WHERE Related_Test__c = :clsCheckHandler.idMasterTest AND Check_Status__c = 'Generated']) {
			setSessionIds.add(ses.Id);
		}

		clsCheckHandler.lstRespondents = [SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
											Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, 
											Master_Test__r.Project_Number__c, Master_Test__c, Donation_Amount_Per_Event__c,
											Session_Check_Amount__c, Organization__r.Name, Session_Id__c
											FROM Test_Respondent__c
											WHERE 
												Session_Id__c IN :setSessionIds
												AND Respondent_Status__c = 'Scheduled' 
												AND Scheduled_TRQ_Count__c > 0 
												AND Master_Test__c = :clsCheckHandler.idMasterTest
												AND Pair_Primary__c = null
                                                //06.25.2019 - need to be records that have Check_Printed_Date__c
                                                AND Check_Printed_Date__c != null
											ORDER BY CheckSortField__c ASC];

		if(clsCheckHandler.lstRespondents.isEmpty()) { return null; }

		// ASSEMBLE CHECK DATA
		clsCheckHandler = CheckGeneratorController.generatePDFCheckData(clsCheckHandler);

		// ASSEMBLE THIS THING...
		valtiraEnvelope envelope = new valtiraEnvelope();
		envelope.forms = clsCheckHandler.formFields;
		
		Http objHttp = new Http();
		HttpRequest objReq = new HttpRequest();
		objReq.setTimeout(60000);
		objReq.setEndpoint(strValtiraEndpoint);
		objReq.setMethod('POST');
		objReq.setHeader('Content-Type', 'application/json');
		objReq.setHeader('x-api-key', strValtiraAPIKey);
		objReq.setBody(JSON.serialize(envelope));

		PageReference prReturn;

		try {
			HttpResponse objRes = objHttp.send(objReq);
			valtiraReturnEnvelope objResponse = (valtiraReturnEnvelope)JSON.deserialize(objRes.getBody(), valtiraReturnEnvelope.class);
			System.Debug(objResponse);

			if(objResponse.succeeded) {

				// Update the Session with Printed Status and Date
				if(clsCheckHandler.mapUpdateSessions.size() > 0 && bolUpdateSession) { 
					update clsCheckHandler.mapUpdateSessions.values(); 
				}

				prReturn = new PageReference(objResponse.location.url);
				prReturn.setRedirect(true);
				return prReturn;
			} else {
				return null;
			}
		} catch(Exception ex) {
			System.Debug(ex);
			return null;
		}

	}

	public static UtilityMethods.hClsValtiraCheckGenerator generatePDFCheckData(UtilityMethods.hClsValtiraCheckGenerator clsCheckData) {

		clsCheckData.formFields = new List<Map<String, List<valtiraField>>>();
		clsCheckData.mapUpdateSessions = new Map<Id, Session__c>();

		Set<Id> setContactIds = new Set<Id>();
		Map<Id, Household_Contact__c> mapHouseholds = new Map<Id, Household_Contact__c>();
		for(Test_Respondent__c tr : clsCheckData.lstRespondents) {
			setContactIds.add(tr.Respondent__c);
		}

		for(Household_Contact__c hc : [SELECT Contact__c, Household__r.MailingStreet__c, Household__r.MailingStreet2__c, 
											Household__r.MailingState__c, Household__r.MailingPostalCode__c, Household__r.MailingCity__c
											FROM Household_Contact__c WHERE Contact__c IN :setContactIds]) {
			mapHouseholds.put(hc.Contact__c, hc);
		}

		// START THE BIG LOOP
		Integer iCount = 1; Integer recCount = 1;
		
		Map<String, List<valtiraField>> fields = new Map<String, List<valtiraField>>();
		fields.put('fields', new List<valtiraField>());
		for(Test_Respondent__c tr : clsCheckData.lstRespondents) {
		 System.debug('Date ' + tr.Check_Printed_Date__c);
            system.debug(clsCheckData.lstRespondents);
         
			/////////////////////////
			// GENERATE LINES
			/////////////////////////
			if(iCount == 4) { 
				clsCheckData.formFields.add(fields);
				//fields = new List<valtiraField>();
				fields = new Map<String, List<valtiraField>>();
				fields.put('fields', new List<valtiraField>());
				iCount = 1;
			}

			/////////////////////////
			// PREP DATA
			/////////////////////////

			// Handle Donation Receipts
			Decimal decCheckAmount = tr.Check_Amount__c;
			Boolean bolDonationReceipt = false;
			if(tr.Donation_Amount_Per_Event__c == 'Full Payment' || 
				(tr.Donation_Amount_Per_Event__c == 'Partial payment of $10' && tr.Check_Amount__c <= 0) ||
				(tr.Donation_Amount_Per_Event__c == 'No, $0' && tr.Check_Amount__c <= 0)) {
				decCheckAmount = tr.Session_Check_Amount__c;
				bolDonationReceipt = true;
			}
			if(decCheckAmount == null) { decCheckAmount = 0; }
			String strAmountInWords = UtilityMethods.english_number(Integer.valueOf(Math.floor(decCheckAmount)));

			/////////////////////////
			// GENERATE LINES
			/////////////////////////

			// MEMO LINE
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Memo',
				'Study: ' + tr.Master_Test__r.Project_Number__c + ' PID: ' + tr.Respondent__r.PID__c,
				null, false, null
			));

			// AMOUNT TEXT
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Amount Text',
				strAmountInWords.toUpperCase() + ' AND 00/100 DOLLARS',
				null, false, null
			));

			// PAY LINE 1
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Pay Line 1',
				(bolDonationReceipt) ? UtilityMethods.checkForNull(tr.Organization__r.Name) + ' c/o ' + tr.Respondent__r.Name : tr.Respondent__r.Name,
				null, false, null
			));

			// PAY LINE 2
			if(mapHouseholds.get(tr.Respondent__c) != null) {
				fields.get('fields').add(new valtiraField(
					'Check ' + iCount + ': Pay Line 2',
					UtilityMethods.checkForNull(mapHouseholds.get(tr.Respondent__c).Household__r.MailingStreet__c) + ' ' + UtilityMethods.checkForNull(mapHouseholds.get(tr.Respondent__c).Household__r.MailingStreet2__c),
					null, false, null
				));
			}

			// PAY LINE 3
			if(mapHouseholds.get(tr.Respondent__c) != null) {
				fields.get('fields').add(new valtiraField(
					'Check ' + iCount + ': Pay Line 3',
					UtilityMethods.checkForNull(mapHouseholds.get(tr.Respondent__c).Household__r.MailingCity__c) + ', ' + UtilityMethods.checkForNull(mapHouseholds.get(tr.Respondent__c).Household__r.MailingState__c) + ' ' + UtilityMethods.checkForNull(mapHouseholds.get(tr.Respondent__c).Household__r.MailingPostalCode__c),
					null, false, null
				));
			}

			// DATE
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Date',
				datetime.newInstance(tr.Check_Printed_Date__c.year(), tr.Check_Printed_Date__c.month(), tr.Check_Printed_Date__c.day()).format('MM/dd/yyyy'),
				null, false, null
			));

			// AMOUNT
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Amount',
				String.valueOf(decCheckAmount),
				null, false, null
			));

			// CHECK NUMBER
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Check Number',
				(bolDonationReceipt) ? 'RECEIPT' : tr.Check_Number__c,
				null, false, null
			));

			// VOID TEXT
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Void Text',
				(bolDonationReceipt) ? 'THIS IS YOUR DONATION RECEIPT' : 'VOID 180 DAYS AFTER CHECK DATE',
				null, false, null
			));

			// MICR BLOCK
			if(!bolDonationReceipt) {
				String strCheckNumber = 'c' + tr.Check_Number__c;
				fields.get('fields').add(new valtiraField(
					'Check ' + iCount + ': MICR',
					strCheckNumber.leftPad(12) + 'c a064000017a 0256123493c',
					null, true, null
				));
			}

			// SIGNATURE IMAGE
			fields.get('fields').add(new valtiraField(
				'Check ' + iCount + ': Signature Image',
				null,
				null, false, (bolDonationReceipt) ? 2 : 1
			));

			// VOID WATERMARK
			if(bolDonationReceipt) {
				fields.get('fields').add(new valtiraField(
					'Check ' + iCount + ': Void',
					'VOID',
					null, false, null
				));
			}

			/////////////////////////
			// IF LAST IN SET, ADD LIST TO COLLECTION
			/////////////////////////
			if(recCount == clsCheckData.lstRespondents.size()) {
				clsCheckData.formFields.add(fields);
			}

			/////////////////////////
			// ITERATION COUNTS
			/////////////////////////

			recCount+=1;
			iCount+=1;

			// Update Sessions for printed checks
			clsCheckData.mapUpdateSessions.put(tr.Session_Id__c, new Session__c(Id=tr.Session_Id__c,Check_Status__c='Printed',Check_Printed_Date__c=System.Today()));
		}

		return clsCheckData;

	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public PageReference runValtiraChecks() {
		return CheckGeneratorController.generatePDFChecks(idMasterTest, true);
	}
	
	public void fillRespondents() {
		lstChecks = new List<hClsCheck>();
		//Map<Id, Master_Test__c> mapMTsToUpdate = new Map<Id, Master_Test__c>();
		List<Test_Respondent__c> lstTRsToUpdate = new List<Test_Respondent__c>();
		Integer iCount = 1;

		// Find only sessions that have been 'Generated'
		Set<Id> setSessionIds = new Set<Id>();
		for(Session__c ses : [SELECT Id FROM Session__c WHERE Related_Test__c = :idMasterTest AND Check_Status__c = 'Generated']) {
			setSessionIds.add(ses.Id);
		}

		System.Debug(setSessionIds);

		List<Test_Respondent__c> lstRespondents = [SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
													Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, 
													Master_Test__r.Project_Number__c, Master_Test__c, Donation_Amount_Per_Event__c,
													Session_Check_Amount__c, Organization__r.Name, Session_Id__c
													FROM Test_Respondent__c
													WHERE 
														Session_Id__c IN :setSessionIds
														AND Respondent_Status__c = 'Scheduled' 
														AND Scheduled_TRQ_Count__c > 0 
														AND Master_Test__c = :idMasterTest
														AND Pair_Primary__c = null
                                                        //Added 05.20.2019 - so this query matches what we have in CheckGeneratorWizardController - near line 115.
                                                        AND Check_Printed_Date__c != null
                                                        AND Check_Number__c != null
                                                        //Added 05.20.2019 - so this query matches what we have in CheckGeneratorWizardController - near line 115.
                                                        //we need null respondents for the org/non-org checks
                                                        //AND Respondent__c != null
													ORDER BY CheckSortField__c ASC];

		System.Debug(lstRespondents);

		Set<Id> setContactIds = new Set<Id>();
		Map<Id, Household_Contact__c> mapHouseholds = new Map<Id, Household_Contact__c>();
		for(Test_Respondent__c tr : lstRespondents) {
			setContactIds.add(tr.Respondent__c);
		}

		for(Household_Contact__c hc : [SELECT Contact__c, Household__r.MailingStreet__c, Household__r.MailingStreet2__c, 
											Household__r.MailingState__c, Household__r.MailingPostalCode__c, Household__r.MailingCity__c
											FROM Household_Contact__c WHERE Contact__c IN :setContactIds]) {
			mapHouseholds.put(hc.Contact__c, hc);
		}

		Map<Id, Session__c> mapUpdateSessions = new Map<Id, Session__c>();
		for(Test_Respondent__c tr : lstRespondents) {

			// Add to list for display
			Boolean bolNextPage = false;
			if(iCount == 3) { bolNextPage = true; iCount = 0;}
			lstChecks.add(new hClsCheck(bolNextPage, tr, mapHouseholds.get(tr.Respondent__c)));
			iCount+=1;

			// Update Sessions for printed checks
			mapUpdateSessions.put(tr.Session_Id__c, new Session__c(Id=tr.Session_Id__c,Check_Status__c='Printed',Check_Printed_Date__c=System.Today()));
		}
		
		// Update the Session with Printed Status and Date
		if(mapUpdateSessions.size() > 0) { update mapUpdateSessions.values(); }

	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsCheck {

		public Boolean bolNextPage {get;set;}
		public Boolean bolDonationReceipt {get;set;}
		public String strMemoLine {get;set;}
		public Date dteIssued {get;set;}
		public Decimal decCheckAmount {get;set;}
		public String strAmountInWords {get;set;}
		public String strMICRString {get;set;}
		public Test_Respondent__c tr {get;set;}
		public Household_Contact__c hc {get;set;}


		public hClsCheck(Boolean passNextPage, Test_Respondent__c passTR, Household_Contact__c passHC) {
			bolNextPage = passNextPage;
			tr = passTR;
			hc = passHC;
			decCheckAmount = tr.Check_Amount__c;
			bolDonationReceipt = false;

			// Handle Donation Receipts
			if(tr.Donation_Amount_Per_Event__c == 'Full Payment' || 
				(tr.Donation_Amount_Per_Event__c == 'Partial payment of $10' && tr.Check_Amount__c <= 0) ||
				(tr.Donation_Amount_Per_Event__c == 'No, $0' && tr.Check_Amount__c <= 0)) {
				decCheckAmount = tr.Session_Check_Amount__c;
				bolDonationReceipt = true;
			}

			if(decCheckAmount == null) { decCheckAmount = 0; }

			strAmountInWords = UtilityMethods.english_number(Integer.valueOf(Math.floor(decCheckAmount)));

			// Parse MICR String
			//strMICRString = 'c' + tr.Check_Number__c + 'c a104910795a 2023 5642c';
			strMICRString = 'c' + tr.Check_Number__c + 'c a053101561a 8018019557c';
		}

	}

	public class valtiraFieldFont {
		public String url {get;set;}
	}

	public class valtiraField {
		public String name {get;set;}
		public String value {get;set;}
		public valtiraFieldFont font {get;set;}
		public String fieldType {get;set;}

		public valtiraField(String strName, String strValue, String strFieldType, Boolean bolMICR, Integer intSignatureImage) {
			name = strName;
			value = strValue;
			fieldType = strFieldType;

			if(bolMICR) {
				valtiraFieldFont clsFont = new valtiraFieldFont();
				clsFont.url = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_MICRUrl').Value__c);
				font = clsFont;
			}

			if(intSignatureImage == 1) {
				value = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_CheckSignature').Value__c);
				fieldType = 'image';
			}

			if(intSignatureImage == 2) {
				value = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_CheckThankYou').Value__c);
				fieldType = 'image';
			}
		}

	}

	public class valtiraLocationDetail {
		public String key {get;set;}
		public String bucket {get;set;}
		public String region {get;set;}
		public valtiraLocationDetail() {
			key = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_Template').Value__c);
			bucket = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_S3Bucket').Value__c);
			region = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_S3Region').Value__c);
		}
	}

	public class valtiraLocation {
		public valtiraLocationDetail s3Location {get;set;}
		public String url {get;set;}
		public valtiraLocation() {
			s3Location = new valtiraLocationDetail();
		}
	}

	public class valtiraEnvelope {
		public valtiraLocation template {get;set;}
		public List<Map<String, List<valtiraField>>> forms {get;set;}
		public valtiraEnvelope() {
			template = new valtiraLocation();
			forms = new List<Map<String, List<valtiraField>>>();
		}
	}

	public class valtiraReturnEnvelope {
		public valtiraLocation location {get;set;}
		public String message {get;set;}
		public Boolean succeeded {get;set;}
	}
}