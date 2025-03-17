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
private class UnitTest_cls_EmailMessageMethod {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        Case CA = UnitTest_Test_Data.BuildCase();
        insert CA;

        EmailMessage EM = UnitTest_Test_Data.BuildEmailMessage(CA.Id);
        	EM.Subject = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis eu orci nulla volutpat.';
        EmailMessage EM2 = UnitTest_Test_Data.BuildEmailMessage(CA.Id);
        	EM2.Subject = EM2.Subject + CA.Case_Thread_ID__c;
        Attachment a = new Attachment();
			a.name = 'test attachment';
			a.body = blob.valueof('attachment body');
			a.parentid = CA.id;

    Test.startTest();
    	insert EM;
    	insert EM2;
    	insert a;
    	Attachment att = new Attachment();
			att.name = 'test attachment';
			att.body = blob.valueof('attachment body');
			att.parentid = EM2.id;
		insert att;

    Test.stopTest();    									
    }
}