/**
*   {Purpose}  �  TODO:  Provide Purpose
*
*	{Code Covered}	- Note the triggers/classes that this test covers
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
@isTest
private class UnitTest_cls_WSWebProcessor {
	
	@isTest static void testControllerRun1() {

		// Get PrefixIds for all objects
		Map<String, String> mapObjects = new Map<String, String>();
		for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
			Schema.DescribeSObjectResult dsr = t.getDescribe();
			mapObjects.put(dsr.getName(), dsr.getKeyPrefix() + '000000000000');
		}
		
		WS_WebProcessor.wsRequest wsRequest;
		setTestData();

		test.startTest();

		/*** testExcludedProjects ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'testExcludedProjects';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.mtTest = new Master_Test__c(Id=mapObjects.get('Master_Test__c'));
		wsRequest.actionName = 'testExcludedProjects';
		processRequest(wsRequest,'9999');

		Master_Test__c mtTest = [SELECT Id FROM Master_Test__c LIMIT 1];
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'testExcludedProjects';
		processRequest(wsRequest,'0');

	}
    
	//@isTest static void testRespondentSignIn() {

	//	// Get PrefixIds for all objects
	//	Map<String, String> mapObjects = new Map<String, String>();
	//	for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
	//		Schema.DescribeSObjectResult dsr = t.getDescribe();
	//		mapObjects.put(dsr.getName(), dsr.getKeyPrefix() + '000000000000');
	//	}
		
	//	WS_WebProcessor.wsRequest wsRequest;
	//	setTestData();

	//	test.startTest();

	//}
	
	@isTest static void testRespondentHouseholding() {

		// Get PrefixIds for all objects
		Map<String, String> mapObjects = new Map<String, String>();
		for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
			Schema.DescribeSObjectResult dsr = t.getDescribe();
			mapObjects.put(dsr.getName(), dsr.getKeyPrefix() + '000000000000');
		}
		
		WS_WebProcessor.wsRequest wsRequest;
		setTestData();

		test.startTest();

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentManage';
		wsRequest.conRespondent = new Contact(Lastname='respondent',firstname='test',email='me@you.com',Birthdate=System.Today().addYears(-12));
		processRequest(wsRequest,'0');

		Contact conRefresh = [SELECT Id FROM Contact LIMIT 1];

		/*** householdManage ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hseHousehold = new Household__c(Id=mapObjects.get('Household__c'));
		wsRequest.actionName = 'householdManage';
		processRequest(wsRequest,'9999');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'householdManage';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hseHousehold = new Household__c();
		wsRequest.actionName = 'householdManage';
		processRequest(wsRequest,'0');

		/*** householdRefresh / householdRefreshDate ***/
		Household__c hseTest = [SELECT Id FROM Household__c LIMIT 1];

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hseHousehold = new Household__c(Id=mapObjects.get('Household__c'));
		wsRequest.actionName = 'householdRefresh';
		processRequest(wsRequest,'9999');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'householdRefresh';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hseHousehold = hseTest;
		wsRequest.actionName = 'householdRefresh';
		processRequest(wsRequest,'0');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'householdRefreshDate';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hseHousehold = hseTest;
		wsRequest.actionName = 'householdRefreshDate';
		processRequest(wsRequest,'0');

		/*** householdMemberManage ***/

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'householdMemberManage';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hcMember = new Household_Contact__c(Id=mapObjects.get('Household_Contact__c'));
		wsRequest.actionName = 'householdMemberManage';
		processRequest(wsRequest,'9999');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hcMember = new Household_Contact__c(Household__c=hseTest.Id,Contact__c=conRefresh.Id);
		wsRequest.actionName = 'householdMemberManage';
		processRequest(wsRequest,'0');

		/*** householdMemberRefresh ***/
		Household_Contact__c hcMember = [SELECT Id FROM Household_Contact__c LIMIT 1];

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'householdMemberRefresh';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hcMember = hcMember;
		wsRequest.actionName = 'householdMemberRefresh';
		processRequest(wsRequest,'0');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hcMember = new Household_Contact__c(Id=mapObjects.get('Household_Contact__c'));
		wsRequest.actionName = 'householdMemberRefresh';
		processRequest(wsRequest,'9999');

		/*** householdMemberRemove ***/

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'householdMemberRemove';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hcMember = new Household_Contact__c(Id=mapObjects.get('Household_Contact__c'));
		wsRequest.actionName = 'householdMemberRemove';
		processRequest(wsRequest,'9999');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.hcMember = hcMember;
		wsRequest.actionName = 'householdMemberRemove';
		processRequest(wsRequest,'0');

	}

	@isTest static void testRespondentManagement() {

		// Get PrefixIds for all objects
		Map<String, String> mapObjects = new Map<String, String>();
		for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
			Schema.DescribeSObjectResult dsr = t.getDescribe();
			mapObjects.put(dsr.getName(), dsr.getKeyPrefix() + '000000000000');
		}
		
		WS_WebProcessor.wsRequest wsRequest;
		setTestData();

		test.startTest();

		// TEST 1A - NULL Input
		processRequest(null,'9999');

		// TEST 1B - Invalid Input
		processInvalidRequest();

		// TEST 2 - missing action
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = '';
		processRequest(wsRequest,'1001');

		// TEST 3 - bad action
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'badaction';
		processRequest(wsRequest,'1001');

		/*** respondentSignup ***/
		// TEST - Create Respondent, no Contact object.
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentSignup';
		processRequest(wsRequest,'1002');

		// TEST - Create Respondent - CATCH
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentSignup';
		wsRequest.conRespondent = new Contact(Lastname='newsignup',firstname='test',email='me@yousignup.com',Birthdate=System.Today().addYears(-30));
		wsRequest.hseHousehold = new Household__c(Id=mapObjects.get('Household__c'));
		processRequest(wsRequest,'9999');

		// TEST - Create Respondent
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentSignup';
		wsRequest.conRespondent = new Contact(Lastname='newsignup',firstname='test',email='me@yousignup.com',Birthdate=System.Today().addYears(-30));
		wsRequest.hseHousehold = new Household__c();
		processRequest(wsRequest,'0');

		/*** respondentManage ***/
		// TEST - Create Respondent, no Contact object.
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentManage';
		processRequest(wsRequest,'1002');

		// TEST - Create Respondent, NO BIRTHDAY
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentManage';
		wsRequest.conRespondent = new Contact(Lastname='respondent',firstname='test',email='me@you.com');
		processRequest(wsRequest,'1002');

		// TEST - Create Respondent, NO LASTNAME
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentManage';
		wsRequest.conRespondent = new Contact(firstname='test',email='me@you.com');
		processRequest(wsRequest,'1002');

		// TEST - Negative, Create Respondent, Minor
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentManage';
		wsRequest.conRespondent = new Contact(Id=mapObjects.get('Contact'),Birthdate=System.Today().addYears(-12));
		processRequest(wsRequest,'9999');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentManage';
		wsRequest.conRespondent = new Contact(Lastname='respondent',firstname='test',email='me@you.com',Birthdate=System.Today().addYears(-12));
		processRequest(wsRequest,'0');

		/*** respondentRefresh ***/

		// TEST - Refresh Respondent, no Contact
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = null;
		wsRequest.actionName = 'respondentRefresh';
		processRequest(wsRequest,'1002');

		// TEST - Refresh Respondent
		Contact conRefresh = [SELECT Id FROM Contact LIMIT 1];
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = conRefresh;
		wsRequest.actionName = 'respondentRefresh';
		processRequest(wsRequest,'0');

		/*** testRefresh / testRefreshDate ***/
		Master_Test__c mtTest = [SELECT Id FROM Master_Test__c LIMIT 1];

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'testRefresh';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'testRefresh';
		processRequest(wsRequest,'0');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'testRefreshDate';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'testRefreshDate';
		processRequest(wsRequest,'0');

		/*** sessionRefresh ***/
		Session__c ssTest = [SELECT Id FROM Session__c LIMIT 1];

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'sessionRefresh';
		processRequest(wsRequest,'1002');
		
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.seSession = ssTest;
		wsRequest.actionName = 'sessionRefresh';
		processRequest(wsRequest,'0');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'testAllOpenRecords';
		processRequest(wsRequest,'0');

		///*** quotaRefresh ***/
		//Session_Quota__c qtSession = [SELECT Id FROM Session_Quota__c LIMIT 1];

		//wsRequest = new WS_WebProcessor.wsRequest();
		//wsRequest.actionName = 'quotaRefresh';
		//processRequest(wsRequest,'1002');

		//wsRequest = new WS_WebProcessor.wsRequest();
		//wsRequest.qtSession = qtSession;
		//wsRequest.actionName = 'quotaRefresh';
		//processRequest(wsRequest,'0');

	}

	@isTest static void testRespondentSignIn() {

		WS_WebProcessor.wsRequest wsRequest;
		setTestData();

		test.startTest();

		Contact conRefresh = [SELECT Id FROM Contact LIMIT 1];

		/*** respondentSignin ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = conRefresh;
		wsRequest.actionName = 'respondentSignin';
		processRequest(wsRequest,'0');

		test.stopTest();

	}

	@isTest static void testScheduleManagementScreener() {

		// Get PrefixIds for all objects
		Map<String, String> mapObjects = new Map<String, String>();
		for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
			Schema.DescribeSObjectResult dsr = t.getDescribe();
			mapObjects.put(dsr.getName(), dsr.getKeyPrefix() + '000000000000');
		}
		
		WS_WebProcessor.wsRequest wsRequest;
		setTestData();

		test.startTest();

		// TEST - Create Respondent
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentSignup';
		wsRequest.conRespondent = new Contact(Lastname='newsignup',firstname='test',email='me@yousignup.com',Birthdate=System.Today().addYears(-30));
		wsRequest.hseHousehold = new Household__c();
		processRequest(wsRequest,'0');

		Contact conRefresh = [SELECT Id FROM Contact LIMIT 1];
		Master_Test__c mtTest = [SELECT Id FROM Master_Test__c LIMIT 1];
		Session__c ssTest = [SELECT Id FROM Session__c LIMIT 1];


		/*** screenerCreateStub - NEGATIVE ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'screenerCreateStub';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = new Contact(Id=mapObjects.get('Contact'));
		wsRequest.mtTest = new Master_Test__c(Id=mapObjects.get('Master_Test__c'));
		wsRequest.actionName = 'screenerCreateStub';
		processRequest(wsRequest,'9999');

		/*** screenerCreateStub ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = conRefresh;
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'screenerCreateStub';
		processRequest(wsRequest,'0');
		Test_Respondent__c trRefresh = [SELECT Id FROM Test_Respondent__c ORDER BY CreatedDate DESC LIMIT 1];

		/*** screenerResetSweeper ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = trRefresh;
		wsRequest.actionName = 'screenerResetSweeper';
		processRequest(wsRequest,'0');

		/*** screenerAddResults - NEGATIVE ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'screenerAddResults';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = new Test_Respondent__c(Id=mapObjects.get('Test_Respondent__c'));
		wsRequest.mtTest = new Master_Test__c(Id=mapObjects.get('Master_Test__c'));
		wsRequest.actionName = 'screenerAddResults';
		wsRequest.jsonBulkData = new List<WS_WebProcessor.jsonQuestion>();
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('badtest','1'));
		processRequest(wsRequest,'9999');

		/*** screenerAddResults ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = trRefresh;
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'screenerAddResults';
		wsRequest.jsonBulkData = new List<WS_WebProcessor.jsonQuestion>();
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('conditionsQuota','1'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('contactupdate1','1'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('contactupdate2','updateme'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('CardSortMr5c7','0'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('CardSortMr3c1','1'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('CardSortMr5c1','0'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('lastparticipationdate',''));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('status','3'));
		processRequest(wsRequest,'0');

	}

	@isTest static void testScheduleManagementSchedule() {

		// Get PrefixIds for all objects
		Map<String, String> mapObjects = new Map<String, String>();
		for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
			Schema.DescribeSObjectResult dsr = t.getDescribe();
			mapObjects.put(dsr.getName(), dsr.getKeyPrefix() + '000000000000');
		}
		
		WS_WebProcessor.wsRequest wsRequest;
		setTestData();

		// TEST - Create Respondent
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentSignup';
		wsRequest.conRespondent = new Contact(Lastname='newsignup',firstname='test',email='me@yousignup.com',Birthdate=System.Today().addYears(-30));
		wsRequest.hseHousehold = new Household__c();
		processRequest(wsRequest,'0');

		Contact conRefresh = [SELECT Id FROM Contact LIMIT 1];
		Master_Test__c mtTest = [SELECT Id FROM Master_Test__c LIMIT 1];
		Session__c ssTest = [SELECT Id FROM Session__c LIMIT 1];

		/*** screenerCreateStub ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = conRefresh;
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'screenerCreateStub';
		processRequest(wsRequest,'0');
		Test_Respondent__c trRefresh = [SELECT Id FROM Test_Respondent__c ORDER BY CreatedDate DESC LIMIT 1];

		test.startTest();

		/*** screenerAddResults ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = trRefresh;
		wsRequest.mtTest = mtTest;
		wsRequest.actionName = 'screenerAddResults';
		wsRequest.jsonBulkData = new List<WS_WebProcessor.jsonQuestion>();
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('conditionsQuota','1'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('contactupdate1','1'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('contactupdate2','updateme'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('CardSortMr5c7','0'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('CardSortMr3c1','1'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('CardSortMr5c1','0'));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('lastparticipationdate',''));
		wsRequest.jsonBulkData.add(new WS_WebProcessor.jsonQuestion('status','3'));
		processRequest(wsRequest,'0');

		/*** testRespondentRefresh ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'testRespondentRefresh';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = trRefresh;
		wsRequest.actionName = 'testRespondentRefresh';
		processRequest(wsRequest,'0');

		/*** respondentSchedule ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentSchedule';
		wsRequest.overrideCancellation = false;
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = trRefresh;
		wsRequest.seSession = ssTest;
		wsRequest.overrideCancellation = false;
		wsRequest.actionName = 'respondentSchedule';
		processRequest(wsRequest,'0');

		/*** respondentCancel ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentCancel';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = trRefresh;
		wsRequest.seSession = ssTest;
		wsRequest.actionName = 'respondentCancel';
		processRequest(wsRequest,'0');

		/*** respondentRefreshDate ***/
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.actionName = 'respondentRefreshDate';
		processRequest(wsRequest,'1002');

		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.conRespondent = new Contact(Lastname='respondent',firstname='test',email='me@you.com',Birthdate=System.Today().addYears(-12));
		wsRequest.actionName = 'respondentRefreshDate';
		processRequest(wsRequest,'0');

		//Added for confirmTesting - YES
		wsRequest = new WS_WebProcessor.wsRequest();
		trRefresh.Confirmed_Testing__c = 'Yes';
		wsRequest.trRespondent = trRefresh;
		wsRequest.seSession = ssTest;
		wsRequest.actionName = 'confirmTesting';
		processRequest(wsRequest,'0');

		//Added for confirmTesting - NO
		wsRequest = new WS_WebProcessor.wsRequest();
		trRefresh.Confirmed_Testing__c = 'No';
		wsRequest.trRespondent = trRefresh;
		wsRequest.seSession = ssTest;
		wsRequest.actionName = 'confirmTesting';
		processRequest(wsRequest,'0');

		//Added for confirmTesting - BLANK!
		wsRequest = new WS_WebProcessor.wsRequest();
		trRefresh.Confirmed_Testing__c = '';
		wsRequest.trRespondent = trRefresh;
		wsRequest.seSession = ssTest;
		wsRequest.actionName = 'confirmTesting';
		processRequest(wsRequest,'0');

		//Added for confirmTesting - NULL
		wsRequest = new WS_WebProcessor.wsRequest();
		wsRequest.trRespondent = null;
		wsRequest.seSession = ssTest;
		wsRequest.actionName = 'confirmTesting';
		processRequest(wsRequest,'0');

		test.stopTest();

	}

	private static void setTestData() {

		UnitTest_Test_data.commitFPIApexSettings(true);

		//Account acct = new Account(Name='Respondent Master Account');
		//Account acct = UnitTest_Test_Data.buildTestAccount('Respondent Master Account', UserInfo.getUserId());
		//insert acct;

		//FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('ID_RespondentAccount', acct.Id);
        //insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //FPI_AppSettings__c testAppSetting4 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentChild', 'Child-Respondent', 'Contact');
        //insert testAppSetting3;
        //insert testAppSetting4;

		Id rtId = UtilityMethods.RECORDTYPE_ID('Contact', 'Adult-Respondent');
        Contact conTest = new Contact(Lastname='Lastname',FirstName='firstname',email='me@you.com',birthdate=System.Today().addYears(-40),RecordTypeId=rtId);
        insert conTest;

        Household__c hhTest = new Household__c(MailingStreet__c='123 MyStreet',MailingPostalCode__c='12345');
        insert hhTest;

        Household_Contact__c hcTest = new Household_Contact__c(Household__c=hhTest.Id,Contact__c=conTest.Id);
        insert hcTest;

        Master_Test__c mtTest = new Master_Test__c();
        insert mtTest;

        Quota__c mqTest = new Quota__c(Related_Test__c=mtTest.Id, IsScheduleEnabled__c=true,Beacon_Condition__c='conditionsQuota',IsOpen__c=true);
        insert mqTest;

        Quota__c mqUpdate1 = new Quota__c(Related_Test__c=mtTest.Id, IsScheduleEnabled__c=false,Beacon_Condition__c='contactupdate1',
        									Screener_Update_Field__c='Description',Screener_Update_Value__c='test123',IsOpen__c=true);
        insert mqUpdate1;

        Quota__c mqUpdate2 = new Quota__c(Related_Test__c=mtTest.Id, IsScheduleEnabled__c=false,Beacon_Condition__c='contactupdate2',
        									Screener_Update_Field__c='Department', IsOpen__c=true);
        insert mqUpdate2;

        Session__c ssTest = new Session__c(Name='Test Session',Related_Test__c=mtTest.Id,Session_Start__c=System.Now(),Session_End__c=System.Now().addHours(1));
        insert ssTest;

        Session_Quota__c sqTest = new Session_Quota__c(Related_Session__c=ssTest.Id,Master_Quota__c=mqTest.Id, IsOpen__c=true);
        insert sqTest;


	}

	private static void processRequest(WS_WebProcessor.wsRequest wsRequest, String strExpectedResponseCode) {

		WS_WebProcessor.wsResponse wsResponse = new WS_WebProcessor.wsResponse();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		RestContext.response = res;

		// Set Request Object
		req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/actions';
		req.httpMethod = 'POST';

		System.Debug(wsRequest);

		req.requestBody = Blob.valueOf(JSON.serialize(wsRequest));
		RestContext.request = req;
		WS_WebProcessor.actionRouter();
		wsResponse = (WS_WebProcessor.wsResponse)JSON.deserializeStrict(RestContext.response.responseBody.ToString(), WS_WebProcessor.wsResponse.class);
		//System.Assert(wsResponse.errorCode == strExpectedResponseCode, 'Request did not fail properly - expected ' + strExpectedResponseCode + ', it returned as ' + wsResponse);

	}

	private static void processInvalidRequest() {

		WS_WebProcessor.wsResponse wsResponse = new WS_WebProcessor.wsResponse();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		RestContext.response = res;

		// Set Request Object
		req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/actions';
		req.httpMethod = 'POST';

		req.requestBody = Blob.valueOf(JSON.serialize(new Contact(LastName='invalid',firstname='invalid',email='me@you.com')));
		RestContext.request = req;
		WS_WebProcessor.actionRouter();
		wsResponse = (WS_WebProcessor.wsResponse)JSON.deserializeStrict(RestContext.response.responseBody.ToString(), WS_WebProcessor.wsResponse.class);
		//System.Assert(wsResponse.errorCode == '1000', 'Request did not fail properly - expected 1000, it returned as ' + wsResponse);

	}
	
}