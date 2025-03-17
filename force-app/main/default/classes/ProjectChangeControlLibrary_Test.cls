@isTest
public class ProjectChangeControlLibrary_Test {
    @isTest
	static void doNothing(){
		ProjectChangeControlLibrary.doNothing();
	}
  /** Commented out - PCCs are no longer used 
    @isTest 
    private static void testEstHrs()
    {
        //Setup an Opportunity for the numbers to bubble up to
        Account acctTest = UnitTest_Test_Data.buildTestAccount('Eurofins Client', Userinfo.getUserId()); 
        insert acctTest;
        
		Opportunity oppTest = UnitTest_Test_Data.BuildOpportunity(acctTest.Id,'Consumer Research Opportunity', 'Initiate/Open'); 
        insert oppTest;
		
		Master_Test__c mtTest = UnitTest_Test_Data.BuildMasterTest();
		mtTest.Opportunity__c = oppTest.Id;
		insert mtTest;
        
        Test.startTest();
            //setup the Quote as approved and have the CSD numbers populated
            Quote objQ = new Quote();
            objQ.OpportunityId = oppTest.Id;
            objQ.Name = 'FPI - Test Quote';
            objQ.Quote_CSD_Estimated_Hours__c = 1;
            objQ.Quote_PM_Estimated_Hours__c = 1;
            objQ.Quote_Recruiting_Estimated_Hours__c = 1;
            objQ.Quote_STeam_Estimated_Hours__c = 1;
            objQ.Quote_Fielding_Office_Estimated_hours__c= 1;
            objQ.Quote_Fielding_Site_Estimated_Hours__c = 1;
            objQ.Quote_Stats_Estimated_Hours__c = 1;
            objQ.Status = 'Approved';
            insert objQ;
            
            //After insert the Quote - the Opp items should be 1
            oppTest = [SELECT Id, Total_CSD_Estimated_hours__c, Total_PM_Estimated_hours__c
                       , Total_Recruiting_Estimated_hours__c, Total_Stats_Estimated_hours__c
                       , Total_STeam_Estimated_hours__c, Total_Fielding_Office_Estimated_hours__c
                       , Total_Fielding_Site_Estimated_hours__c FROM Opportunity
                       WHERE Id = :oppTest.Id];
            System.assertEquals(oppTest.Total_CSD_Estimated_hours__c, 1);
            System.assertEquals(oppTest.Total_PM_Estimated_hours__c, 1);
            System.assertEquals(oppTest.Total_Recruiting_Estimated_hours__c, 1);
            System.assertEquals(oppTest.Total_Stats_Estimated_hours__c, 1);
            System.assertEquals(oppTest.Total_STeam_Estimated_hours__c, 1);
            System.assertEquals(oppTest.Total_Fielding_Office_Estimated_hours__c, 1);
            System.assertEquals(oppTest.Total_Fielding_Site_Estimated_hours__c, 1);
            
            //create a PCC to start the trigger
            Project_Change_Control__c objPCC = new Project_Change_Control__c();
            objPCC.Opportunity__c = oppTest.Id;
            objPCC.Total_CSD_Estimated_hours__c = 1;
            objPCC.Total_PM_Estimated_hours__c = 1;
            objPCC.Total_Recruiting_Estimated_hours__c = 1;
            objPCC.Total_STeam_Estimated_hours__c = 1;
            objPCC.Total_Fielding_Office_Estimated_hours__c = 1;
            objPCC.Total_Fielding_Site_Estimated_hours__c = 1;
            objPCC.Total_Stats_Estimated_hours__c = 1;
            insert objPCC;
            
            //After insert the Project - the Opp items should be 2
            oppTest = [SELECT Id, Total_CSD_Estimated_hours__c, Total_PM_Estimated_hours__c
                       , Total_Recruiting_Estimated_hours__c, Total_Stats_Estimated_hours__c
                       , Total_STeam_Estimated_hours__c, Total_Fielding_Office_Estimated_hours__c
                       , Total_Fielding_Site_Estimated_hours__c FROM Opportunity
                       WHERE Id = :oppTest.Id];
            System.assertEquals(oppTest.Total_CSD_Estimated_hours__c, 2);
            System.assertEquals(oppTest.Total_PM_Estimated_hours__c, 2);
            System.assertEquals(oppTest.Total_Recruiting_Estimated_hours__c, 2);
            System.assertEquals(oppTest.Total_Stats_Estimated_hours__c, 2);
            System.assertEquals(oppTest.Total_STeam_Estimated_hours__c, 2);
            System.assertEquals(oppTest.Total_Fielding_Office_Estimated_hours__c, 2);
            System.assertEquals(oppTest.Total_Fielding_Site_Estimated_hours__c, 2);
        
		Test.stopTest();        
    }  
    */
}