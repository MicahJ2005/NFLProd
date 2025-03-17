/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UnitTest_Lead_Triggers {

    static testMethod void myUnitTest() {

        Test.setMock(HttpCalloutMock.class, new UnitTest_S2STokenSuccess_MOCK());
        
        UnitTest_Test_Data.commitFPIApexSettings();
        
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;
        
        Lead testLead = UnitTest_Test_data.buildFPILead(testuser.Id, 'matt.test@gmail.com', 'FPI Lead');
        
        test.startTest();
            insert testLead;
            testLead.Status = 'Converted - Strategic Fit';
            update testLead;        
        test.stopTest();
    }
}