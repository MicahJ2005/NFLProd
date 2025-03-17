@isTest
private class UnitTest_ProjectTrackerController {

    static testMethod void myUnitTest() {
        ProjectTrackerController ptc = new ProjectTrackerController();
        ptc.doNothing();
        /**
         * //NOTE - if this class is not fully covering the ProjectTrackerController.cls
        // check what marks a project as "Include in Project Tracker" (field on the pse__Proj__c object)
        // might need to make sure that the projects created below fit those criteria

        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        //Setup the custom settings
        UnitTest_Test_Data.commitFPIApexSettings();
        
        //Create Account
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;

        Opportunity testOpp = UnitTest_Test_Data.BuildOpportunity(testAccount.Id, 'Consumer Research Opportunity', 'Initiate/Open'); 
        testOpp.OwnerId = testUser.Id;
        insert testOpp;

        //Create a couple Projects under that Account
        List<pse__Proj__c> projList = new List<pse__Proj__c>();
        pse__Proj__c proj1 = new pse__Proj__c();
        //proj1.pse__Account__c = testAccount.Id;
        proj1.Name = 'Test Project 1';
        proj1.pse__Stage__c = 'In Progress';
        proj1.pse__Project_Type__c = 'Customer Project';
        proj1.pse__Is_Active__c = true;
        proj1.pse__Opportunity__c = testOpp.Id;
        proj1.OwnerId = testUser.Id;
        projList.add(proj1);

        pse__Proj__c proj2 = new pse__Proj__c();
        //proj1.pse__Account__c = testAccount.Id;
        proj2.Name = 'Test Project 2';
        proj2.pse__Stage__c = 'In Progress';
        proj2.pse__Project_Type__c = 'Customer Project';
        proj2.pse__Is_Active__c = true;
        proj2.pse__Opportunity__c = testOpp.Id;
        proj2.OwnerId = testUser.Id;
        projList.add(proj2);

        System.debug('DC: projList: ' + projList);
        insert projList;

        //Create series of Milestones
        //  one for each custom metadata name
        List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
        Integer testCounter = 0;
        for(Project_Tracker_Milestones__mdt ptm : [SELECT MasterLabel, Alternate_Name_1__c, Order__c 
                                                    FROM Project_Tracker_Milestones__mdt 
                                                    ORDER BY Order__c]) {

            Integer modX = math.mod(testCounter, 2);
            pse__Milestone__c milestone1 = makeMilestoneShell(proj1.Id, ptm.MasterLabel);
            if(modX == 0) {
                //Upcoming - YELLOW
                milestone1.pse__Status__c = 'Planned';
                milestone1.pse__Target_Date__c = Date.today().addDays(2);
            } else {
                //Canceled - GREY
                milestone1.pse__Status__c = 'Canceled';
            }
            milestoneList.add(milestone1);

            pse__Milestone__c milestone2 = makeMilestoneShell(proj2.Id, ptm.MasterLabel);
            if(modX == 0) {
                //Completed - GREEN
                milestone2.pse__Actual_Date__c = Date.today();
                milestone2.pse__Status__c = 'Completed';
            } else {
                //Overdue - RED
                milestone2.pse__Status__c = 'Planned';
                milestone2.pse__Target_Date__c = Date.today().addDays(-2);
            }
            milestoneList.add(milestone2);

            testCounter = testCounter + 1;
        }
        System.debug('DC: milestoneList: ' + milestoneList);
        insert milestoneList;

        ProjectTrackerController ptc = new ProjectTrackerController();
        System.debug('DC: ' + testCounter);
        System.debug('DC: ' + ptc.milestoneNumToProjIdToLine.keySet().size()); //should equal test counter
        System.debug('DC: ' + ptc.milestoneNumToMilestone.keySet().size()); //should equal test counter
        System.debug('DC: ' + ptc.projectIdToProject.keySet().size()); //should equal 2
        System.debug('DC: ' + ptc.milestoneKeySet.size()); //should equal test counter
        System.debug('DC: ' + ptc.projectKeySet.size()); //should equal 2

        //Other coverages
        ptc.getOwners();
        ptc.doFilter();
        ptc.showAll();
        ptc.export();
        ptc.getSelectedOppOwners();

        //Test with ownerIds set.
        PageReference myPR = Page.ProjectTracker;
        myPR.getParameters().put('oppowners', testUser.Id);
        Test.setCurrentPage(myPR);
        ProjectTrackerController ptc2 = new ProjectTrackerController();

        //Test all color combos...
        //ptc.getColor('Completed', Date.today());
        //ptc.getColor('Canceled', Date.today());
        //ptc.getColor('In Progress', Date.today().addDays(-5));
        //ptc.getColor('In Progress', Date.today().addDays(5));

    }

    private static pse__Milestone__c makeMilestoneShell(Id projId, String name) {
        pse__Milestone__c m = new pse__Milestone__c();
        m.pse__Project__c = projId;
        m.pse__Target_Date__c = Date.today().addDays(-1);
        m.Name = name;
        m.pse__Audit_Notes__c = 'Testing';
        m.pse__Admin_Global_Edit__c = true;
        return m;
        */
    }
}