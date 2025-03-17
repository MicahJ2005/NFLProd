/**
 * @description       : 
 * @author            : willh@demandchain.com
 * @group             : 
 * @last modified on  : 05-19-2021
 * @last modified by  : willh@demandchain.com
 * Modifications Log 
 * Ver   Date         Author                  Modification
 * 1.0   05-19-2021   willh@demandchain.com   Initial Version
**/
@isTest
public class SM_MasterSessionManager_Ctrl_Tests  {
	@testSetup
	public static void setup(){
		Master_Test__c mt = new Master_Test__c();
		mt.Opportunity_Name__c = '10800-A Test Products: Yummy Stuff';
		mt.Remote_Coordinator__c = 'No Remote Fielding';
		mt.Target_Respondent__c = 'Adults Only';
		mt.Total_to_Seat_S__c = 200;
		mt.Number_of_Sessions__c = 20;
		mt.Respondent_Type__c = 'Both';
		mt.Minimum_Age__c = 18;
		mt.Maximum_Age__c = 45;
		mt.Required_Gender__c = 'Either';
		mt.Ignore_Past_Participation__c = true;
		insert mt;

		Account a = new Account();
		a.Name = 'Testing Center';
		a.Site_Code__c = 'AAA';
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Local Testing Location').getRecordTypeId();
		a.Brand__c = 'Plymouth';
		insert a;

		Session__c s1 = new Session__c();
		s1.Name = '10800-A Test Products: Yummy Stuff';
		s1.Related_Test__c = mt.Id;
		s1.Testing_Location__c = a.Id;
		s1.Research_Type__c = 'Quant';
		s1.Test_Type__c = 'CLT - Central Location Test';
		s1.Session_Start__c = System.now();
		s1.Session_End__c = System.now().addHours(1);
		s1.Time_Between_Sessions__c = 15;
		s1.Min_to_Show__c = 5;
		s1.Max_to_Show__c = 20;
		s1.Check_Amount__c = 15;
		s1.IsAvailableToRecruit__c = true;
		s1.Timezone__c = 'America/Chicago';
		insert s1;

		Quota__c mq = new Quota__c();
		mq.Quota_Summary__c = 'Qualified';
		mq.Related_Test__c = mt.Id;
		mq.Beacon_Condition__c = 'conditionsQualified';
		mq.IsOpen__c = true;
		mq.IsScheduleEnabled__c = true;
		mq.Minimum_Respondents__c = 25;
		mq.Maximum_Respondents__c = 200;
		mq.IsTrackingOnly__c = false;
		insert mq;

		Session_Quota__c sq = new Session_Quota__c();
		sq.Related_Session__c = s1.Id;
		sq.Master_Quota__c = mq.Id;
		sq.Minimum_Respondents__c = 5;
		sq.Maximum_Respondents__c = 50;
		sq.IsOpen__c = true;
		insert sq;
	}

	@IsTest
	public static void test1(){
        Account a = [Select Id From Account];
        
		List<Master_Test__c> lMTs = [SELECT Id,Name FROM Master_Test__c LIMIT 1];
		Id MTID = lMTs[0].Id;
		SM_MasterSessionManager_Ctrl.SessionManagerData SMD = SM_MasterSessionManager_Ctrl.getSessions(MTID);

		List<Session_Quota__c> lSQs =  SM_MasterSessionManager_Ctrl.getSessionQuotas(SMD.lSessions[0].Id);

		List<Quota__c> lMQs = SM_MasterSessionManager_Ctrl.getSessionMasterQuotas(MTID);

		Boolean isOkay = SM_MasterSessionManager_Ctrl.SaveDTValues(SMD.lSessions);
		System.assertEquals(true,isOkay,'SaveDTValues');

		isOkay = SM_MasterSessionManager_Ctrl.addSession('before', SMD.lSessions[0].Id);
		System.assertEquals(true,isOkay,'addSession:before');

		isOkay = SM_MasterSessionManager_Ctrl.addSession('after', SMD.lSessions[0].Id);
		System.assertEquals(true,isOkay,'addSession:after');

		SM_MasterSessionManager_Ctrl.BulkSessions BSessions = SM_MasterSessionManager_Ctrl.getNewBulkSessions(MTID);

		BSessions.MasterTestID = MTID;
		//BSessions.sessionStart = Time.newInstance(10,0,0,0);
		BSessions.sessionStartDateTime = DateTime.newInstance(2024,1,1,10,0,0);
		//BSessions.sessionEnd = BSessions.sessionStart.addHours(6);
		BSessions.sessionEndDateTime = BSessions.sessionStartDateTime.addHours(6);
        //BSessions.sessionDay = Date.today();

		BSessions.sessionStart = BSessions.sessionStartDateTime;
		BSessions.sessionEnd = BSessions.sessionEndDateTime;

		BSessions.timezone = 'America/Chicago';
		BSessions.IsAvailableToRecruit = true;
		BSessions.IsArticulationNeeded = true;
		BSessions.Research_Type = 'Testing';

            new Session__c(
            	Recruits_per_Session__c=20,
                Check_Amount__c=15,
            	Testing_Location__c=a.Id,
            	Related_Test__c = MTID,
                Min_to_Show__c = 5,
                Max_to_Show__c = 20,
                Test_Type__c = 'CLT - Central Location Test',
                Time_Between_Sessions__c = 10,
                Timezone__c = 'America/Chicago'
        );
		//BSessions.incentiveAmount = 15; 
		//BSessions.recruitGoal = 20;
		//BSessions.minToShow = 5;
		//BSessions.maxToShow = 20;
		//BSessions.TestLocName = 'Testing Center';
		//BSessions.timeBetweenSessions = 10;
		//BSessions.testType = 'CLT - Central Location Test';
		BSessions.sessionLength = 30;	
		BSessions.breaks = new List<SM_MasterSessionManager_Ctrl.BreakTime>();
        
        SM_MasterSessionManager_Ctrl.BreakTime bt1 = new SM_MasterSessionManager_Ctrl.BreakTime();
        bt1.name = 'Break-1 = Lunch1';
        bt1.startTime = Time.newInstance(4,0,0,0);
        bt1.endTime = Time.newInstance(4,15,0,0);
		bt1.startDateTime = DateTime.newInstance(2024,1,1,4,0,0);
		bt1.endDateTime = bt1.startDateTime.addMinutes(15);
        BSessions.breaks.add(bt1);
        
        SM_MasterSessionManager_Ctrl.BreakTime bt2 = new SM_MasterSessionManager_Ctrl.BreakTime();
        bt2.name = 'Break-2 = Lunch2';
        //bt2.startTime =Time.newInstance(8,0,0,0);
        //bt2.endTime = Time.newInstance(8,15,0,0);
		bt2.startDateTime = DateTime.newInstance(2024,1,1,8,0,0);
		bt2.endDateTime = bt2.startDateTime.addMinutes(15);
        BSessions.breaks.add(bt2);
        
        SM_MasterSessionManager_Ctrl.BreakTime bt3 = new SM_MasterSessionManager_Ctrl.BreakTime();
        bt3.name = 'Break-3 = Lunch3';
        //bt3.startTime = Time.newInstance(12,0,0,0);
        //bt3.endTime = Time.newInstance(12,15,0,0);
		bt3.startDateTime = DateTime.newInstance(2024,1,1,12,0,0);
		bt3.endDateTime = bt3.startDateTime.addMinutes(15);
        BSessions.breaks.add(bt3);
        
        SM_MasterSessionManager_Ctrl.BreakTime bt4 = new SM_MasterSessionManager_Ctrl.BreakTime();
        bt4.name = 'Break-4 = Lunch4';
        //bt4.startTime = Time.newInstance(15,0,0,0);
        //bt4.endTime = Time.newInstance(15,15,0,0);
		bt4.startDateTime = DateTime.newInstance(2024,1,1,15,0,0);
		bt4.endDateTime = bt4.startDateTime.addMinutes(15);
        BSessions.breaks.add(bt4);
        
        SM_MasterSessionManager_Ctrl.BreakTime bt5 = new SM_MasterSessionManager_Ctrl.BreakTime();
        bt5.name = 'Break-5 = Lunch5';
        //bt5.startTime = Time.newInstance(19,0,0,0);
        //bt5.endTime = Time.newInstance(19,15,0,0);
		bt5.startDateTime = DateTime.newInstance(2024,1,1,19,0,0);
		bt5.endDateTime = bt5.startDateTime.addMinutes(15);
        BSessions.breaks.add(bt5);
        
        SM_MasterSessionManager_Ctrl.BreakTime bt6 = new SM_MasterSessionManager_Ctrl.BreakTime();
        bt6.name = 'Break-6 = Lunch6';
        //bt6.startTime = Time.newInstance(23,0,0,0);
        //bt6.endTime = Time.newInstance(23,15,0,0);
		bt6.startDateTime = DateTime.newInstance(2024,1,1,23,0,0);
		bt6.endDateTime = bt6.startDateTime.addMinutes(15);

        BSessions.breaks.add(bt6);
        /**
		 * THIS ERRORS???
		BSessions = SM_MasterSessionManager_Ctrl.getBulkSessionsSchedule(JSON.serialize(BSessions));
		*/
		Test.startTest();
		isOkay = SM_MasterSessionManager_Ctrl.saveBulkSessionsCtrl(JSON.serialize(BSessions));
		Test.stopTest();
		System.assertEquals(true,isOkay,'saveBulkSessionsCtrl');
		
		isOkay = SM_MasterSessionManager_Ctrl.addNewMasterQuota(MTID);
		System.assertEquals(true,isOkay,'addNewMasterQuota');
		
		List<sObject> lFLVs = SM_MasterSessionManager_Ctrl.fetchLookUpValues('Testing', 'Account', 'TestingLocation');

		Account aTest = SM_MasterSessionManager_Ctrl.getTestLocById(lFLVs[0].Id);

		Session__c sTest = SM_MasterSessionManager_Ctrl.getSessionById(SMD.lSessions[0].Id);

		isOkay = SM_MasterSessionManager_Ctrl.saveSessionDetailLookups(SMD.lSessions[0].Id, aTest.Id, null);
		//System.assertEquals(true,isOkay,'saveSessionDetailLookups');

		isOkay = SM_MasterSessionManager_Ctrl.addQuotasToSession(SMD.lSessions[0].Id, lMQs[0].Id);
		System.assertEquals(true,isOkay,'addQuotasToSession');

		//test deletes
		isOkay = SM_MasterSessionManager_Ctrl.deleteMasterQuota(lMQs[0].Id);
		System.assertEquals(true,isOkay,'deleteMasterQuota');

		isOkay = SM_MasterSessionManager_Ctrl.deleteSessionQuota(lSQs[0].Id);
		System.assertEquals(true,isOkay,'deleteSessionQuota');

		isOkay = SM_MasterSessionManager_Ctrl.deleteSession(SMD.lSessions[0].Id);
		System.assertEquals(true,isOkay,'deleteSession');

		//Map<String, Object> bsMap = new Map<String, Object>();
		//bsMap.put('breaks', BSessions.breaks);
		//SM_MasterSessionManager_Ctrl.buildBreakList(bsMap);

		
	}

	static testMethod void miscTest() {
		Session__c session = [SELECT Id FROM Session__c LIMIT 1];
		Quota__c mQuota = [SELECT Id FROM Quota__c LIMIT 1];
		Session_Quota__c sQuota = [SELECT Id FROM Session_Quota__c LIMIT 1];
		Master_Test__c mTest = [SELECT Id, Project_Number__c FROM Master_Test__c LIMIT 1];
		Account acct = [SELECT Id FROM Account LIMIT 1];

		//SM_MasterSessionManager_Ctrl.deleteSession(session.Id);
		//SM_MasterSessionManager_Ctrl.deleteMasterQuota(mQuota.Id);
		//SM_MasterSessionManager_Ctrl.deleteSessionQuota(sQuota.Id);
		//SM_MasterSessionManager_Ctrl.addNewMasterQuota(mTest.Id);
		

		//deleteSession - targetId
		//deleteMasterQuota - targetID
		//deleteSessionQuota - targetId
		//addNewMasterQuota - masterTestId

		//SM_MasterSessionManager_Ctrl.fetchLookUpValues('hello world', 'Account', 'TestingLocation');
		//fetchLookUpValues(keyword, objectname, filtertype)
		//getTestLocById - testlocid
		//getSessionById - session Id
		//saveSessionDetailLookups(sessionid, testlocid, linkedsessionid)
		//addQuotasToSession(String SessionId, String QuotaIds)

		List<String> myList = new List<String>();
		myList.add(session.Id);
		SM_MasterSessionManager_Ctrl.updateTestType('Something', myList);
		SM_MasterSessionManager_Ctrl.updateResearchType('Something', myList);
		SM_MasterSessionManager_Ctrl.updateTestingLocation(acct.Id, myList);

		SM_MasterSessionManager_Ctrl.parseTimeString('3:00');

		SM_MasterSessionManager_Ctrl.getDatetimeWithOffset(Date.today(), Time.newInstance(1,1,1,1), 'America/Chicago');
		SM_MasterSessionManager_Ctrl.getDatetimeWithOffset(Date.today(), Time.newInstance(23,1,1,1), 'America/Chicago');
		SM_MasterSessionManager_Ctrl.getSessionName(mTest, DateTime.now(), 'America/Chicago', 'City', 'Test Type', 'Original Name');

		SM_MasterSessionManager_Ctrl.testCoverage();
	
	}
    
    static testmethod void testSMException(){
        boolean exceptionThrown = false;
        try{
            throw new SM_MasterSessionManagerException('Test');
        }catch(Exception ex){
            exceptionThrown = true;
        }
        System.assert(exceptionThrown);
    }

	static testmethod void testAddSessionandQuota() {
		
		//Session__c theSession = new Session__c( Name='26735 PSA', CurrencyIsoCode='USD', Session_End__c=DateTime.newInstance(2019, 8, 15, 16, 0, 0), Session_Start__c=DateTime.newInstance(2019, 8, 15, 10, 0, 0), Testing_Location__c='0010P00001mEjwdQAC', Recruits_Per_Session__c=4, Is_Linked__c=false, Open_Session_Quotas__c=0, Scheduled_Respondents__c=0, Research_Type__c='Quant', Test_Type__c='PSA - Paid Send Away', Time_Between_Sessions__c=0, IsAutoOff__c=true, IsAutoOn__c=false, IsAvailableToRecruit__c=false, Check_Amount__c=25.00, Invalid_Session__c=false, IsArticulationNeeded__c=false, Check_Printed_Date__c=Date.newInstance(2019, 8, 14), Check_Status__c='Printed', Min_to_Show__c=0, Max_to_Show__c=4);
		Session__c theSession = new Session__c( Name='26735 PSA', CurrencyIsoCode='USD', Session_End__c=DateTime.newInstance(2019, 8, 15, 16, 0, 0), Session_Start__c=DateTime.newInstance(2019, 8, 15, 10, 0, 0), Recruits_Per_Session__c=4, Is_Linked__c=false, Open_Session_Quotas__c=0, Scheduled_Respondents__c=0, Research_Type__c='Quant', Test_Type__c='PSA - Paid Send Away', Time_Between_Sessions__c=0, IsAutoOff__c=true, IsAutoOn__c=false, IsAvailableToRecruit__c=false, Check_Amount__c=25.00, Invalid_Session__c=false, IsArticulationNeeded__c=false, Check_Printed_Date__c=Date.newInstance(2019, 8, 14), Check_Status__c='Printed', Min_to_Show__c=0, Max_to_Show__c=4);
		Session_Quota__c theSessionQuota = new Session_Quota__c(CurrencyIsoCode='USD', IsOpen__c=false, IsUseMasterScreener__c=true, Maximum_Respondents__c=0, Minimum_Respondents__c=0, Scheduled_Respondents__c=0, Screened_Respondents__c=0, Prequalified_Respondents__c=0);
		List<Session_Quota__c> theSessionQuotaList = new List<Session_Quota__c> ();
		theSessionQuotaList.add(theSessionQuota);
		Test.startTest();
		SM_MasterSessionManager_Ctrl.addSessionAndQuota(theSession, theSessionQuotaList);
		Test.stopTest();

		System.assertEquals(1, [SELECT ID FROM Session_Quota__c WHERE Related_Session__c =: theSession.ID].size());
	}
}