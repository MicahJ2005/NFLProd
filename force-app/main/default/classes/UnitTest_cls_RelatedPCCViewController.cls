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
*   20150527  	Andy Boettcher DCS		Created
*	20180521	Jeff Johnson			Added PCC hours to test automation.
*	20231120	Sophia Murphy DCS		Commented out all
*   =============================================================================
*/
@isTest
private class UnitTest_cls_RelatedPCCViewController {
	@isTest
	static void doNothing(){
		RelatedPCCViewController.doNothing();
	}
	/**
	@isTest static void testPCCViewer() {
		
		// Create Records
		Account acctTest = UnitTest_Test_Data.buildTestAccount('Eurofins Client', Userinfo.getUserId()); insert acctTest;
		Opportunity oppTest = UnitTest_Test_Data.BuildOpportunity(acctTest.Id,'Consumer Research Opportunity', 'Initiate/Open'); insert oppTest;
		//Quote quoteTest = UnitTest_Test_Data.BuildQuote(); insert quoteTest;
        
        
		Master_Test__c mtTest = UnitTest_Test_Data.BuildMasterTest();
		mtTest.Opportunity__c = oppTest.Id;
		insert mtTest;

		Task_Queue__c tskPCC = new Task_Queue__c();
		tskPCC.Name = 'TEST PCC';
		tskPCC.Master_Test__c = mtTest.Id;
		tskPCC.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Task_Queue__c', 'Project Change Control Request');
		tskPCC.Amount__c = 1000000;
        tskPCC.Total_CSD_Estimated_hours__c = 2;
        tskPCC.Total_Fielding_Office_Estimated_hours__c = 2;
        tskPCC.Total_Fielding_Site_Estimated_hours__c = 2;
        tskPCC.Total_PM_Estimated_hours__c = 2;
        tskPCC.Total_Recruiting_Estimated_hours__c = 2;
        tskPCC.Total_Stats_Estimated_hours__c = 2;
        tskPCC.Total_STeam_Estimated_hours__c = 2;
		insert tskPCC;
        
         //setup the Quote as approved and have the CSD numbers populated
        //quoteTest.Opportunity = oppTest.Id;
        //quoteTest.Quote_CSD_Estimated_Hours__c = 1;
        //quoteTest.Quote_PM_Estimated_Hours__c = 1;
        //quoteTest.Quote_Recruiting_Estimated_Hours__c = 1;
        //quoteTest.Quote_STeam_Estimated_Hours__c = 1;
        //quoteTest.Quote_Fielding_Office_Estimated_hours__c= 1;
        //quoteTest.Quote_Fielding_Site_Estimated_Hours__c = 1;
        //quoteTest.Quote_Stats_Estimated_Hours__c = 1;
        //quoteTest.Status = 'Approved';

		// Create Opp PCC
		CaseQueueLibrary clsCQL = new CaseQueueLibrary(new ApexPages.StandardController(tskPCC));
		clsCQL.convertToOppPCC();

		Project_Change_Control__c pccTest = [SELECT Id FROM Project_Change_Control__c WHERE Opportunity__c = :oppTest.Id];

		test.startTest();

		RelatedPCCViewController clsPCC = new RelatedPCCViewController(new ApexPages.StandardController(pccTest));
		PageReference prTest = Page.RelatedPCCView;
		prTest.getParameters().put('Id', tskPCC.Id);
		Test.setCurrentPage(prTest);

		List<Task_Queue__c> lstPCCs = clsPCC.lstPCCs;
		System.Assert(lstPCCs.size() == 1, 'Whoops, no PCCs!');

		test.stopTest();

	}
	*/
}