/**
*   {Purpose}  �  Test MasterTestDashboard and MasterTestDashboardController
*
*	{Code Covered}	- MasterTestDashboard and MasterTestDashboardController
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140722  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_MasterTestDBCntrl {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings(true);

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'Test Master Test';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
		mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
		insert mtQuota;

		Session__c seTest = new Session__c(Related_Test__c=mtTest.Id);
		seTest.Name = 'Test Session';
		seTest.Session_Start__c = System.Now();
		seTest.Session_End__c = System.Now().addHours(1);
		insert seTest;

		Session_Quota__c sqTest = new Session_Quota__c();
		sqTest.Master_Quota__c = mtQuota.Id;
		sqTest.Related_Session__c = seTest.Id;
		insert sqTest;

		Contact conTest = UnitTest_Test_data.createRespondent();
		Test_Respondent__c trTest = new Test_Respondent__c();
		trTest.Master_Test__c = mtTest.Id;
		trTest.Respondent__c = conTest.Id;
		insert trTest;

		Test_Respondent_Quota__c trqTest = new Test_Respondent_Quota__c();
		trqTest.Test_Respondent__c = trTest.Id;
		trqTest.Session_Quota__c = sqTest.Id;
		trqTest.IsQualified__c = true;
		trqTest.IsScheduled__c = true;
		insert trqTest;

		/**********************************************/
		test.startTest();
		
		CalendarSources__c csCal = new CalendarSources__c();
		csCal.Name = 'Test Setting';
		csCal.IsActive__c = true;
		csCal.Background_Color__c = '#FFFFFF';
		csCal.End_Field__c = 'Actual_Calendar_Dates_End__c';
		csCal.Object__c = 'Task_Queue__c';
		csCal.SOQL_Where__c = 'CreatedDate != NULL';
		csCal.SOQL_Select__c = 'Event_Notes__c,Date_Opened__c,Calendar_Information__c';
		csCal.Start_Field__c = 'Actual_Calendar_Dates_Start__c';
		csCal.Subject_Field__c = 'Calendar_Information__c';
		csCal.Text_Color__c = '#000000';
		insert csCal;

		Task_Queue__c tq = new Task_Queue__c();
		tq.Actual_Calendar_Dates_Start__c = Date.today();
		tq.Actual_Calendar_Dates_End__c = Date.today().addDays(4);
		insert tq;

		/**Event evt = new Event();
		evt.Subject = 'Test';
		evt.WhatId = mtTest.Id;
		evt.StartDateTime = System.Now();
		evt.EndDateTime = System.Now().addDays(4);
		evt.Actual_Calendar_Dates_Start__c = Date.today();
		evt.Actual_Calendar_Dates_End__c = Date.today().addDays(4);
		insert evt;*/

		//DateTime dtmStart = System.Now();
		//DateTime dtmEnd = System.Now().addMonths(4);

		Date dtmStart = Date.today().addDays(-1);
		Date dtmEnd = Date.today().addDays(5);

		MasterTestDashboardController clsMTC = new MasterTestDashboardController();
		List<MasterTestDashboardController.hClsSource> lstCalendarEvents = 
			MasterTestDashboardController.lstCalendarEvents(String.valueOf(dtmStart), String.valueOf(dtmEnd), '[]', '[]');

		//System.Assert(lstCalendarEvents.size() == 1, 'Not the right number of events!');

		CalendarSources__c csTEST = [SELECT Id FROM CalendarSources__c LIMIT 1];
		System.Debug('**************** - ' + csTEST);

		MasterTestDashboardController.toggleVisibility(csTEST.Id, false);
		lstCalendarEvents = MasterTestDashboardController.lstCalendarEvents(String.valueOf(dtmStart), String.valueOf(dtmEnd), '[]', '[]');
		MasterTestDashboardController.toggleVisibility(csTEST.Id, true);
		lstCalendarEvents = MasterTestDashboardController.lstCalendarEvents(String.valueOf(dtmStart), String.valueOf(dtmEnd), '[]', '[]');

		//Call the select list "getters" for more coverage
		MasterTestDashboardController cntrlr = new MasterTestDashboardController();
		List<SelectOption> locationOptions = cntrlr.lstLocations;
		List<SelectOption> serviceOptions = cntrlr.lstServiceLines;


		test.stopTest();
		/**********************************************/

	}
	
}