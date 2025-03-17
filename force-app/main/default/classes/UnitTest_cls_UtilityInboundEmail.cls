/**
*   {Purpose}  �  Provide Test Coverage of the FPI Inbound Email Handler
*
*	{Code Covered}	- UtilityInboundEmail.cls
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140826  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_UtilityInboundEmail {
	
	@isTest static void testEmailHandler() {
		
		InboundEmailHandler__c iehEmail = new InboundEmailHandler__c();
		iehEmail.Name = 'test-pass';
		iehEmail.RT_Name__c = 'Customer Care Queue';
		iehEmail.Case_Origin__c = 'Email';
		insert iehEmail;

		////////////////////////
		// GOOD TEST
		////////////////////////
		// create a new email and envelope object
		Messaging.InboundEmail emailGood = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope envGood = new Messaging.InboundEnvelope();

		// setup the data for the email
		emailGood.subject = 'Test Inbound Email';
		emailGood.fromname = 'Test User';
		envGood.fromAddress = 'testuser@email.com';
		envGood.toAddress = 'test-pass@salesforce-fpi.com';

		// add an attachment
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body = blob.valueOf('my attachment text');
		attachment.fileName = 'textfile.txt';
		attachment.mimeTypeSubType = 'text/plain';

		emailGood.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

		// call the email service class and test it with the data in the testMethod
		UtilityInboundEmail emailProcess = new UtilityInboundEmail();
		emailProcess.handleInboundEmail(emailGood, envGood);

		////////////////////////
		// BAD TEST
		////////////////////////
		// create a new email and envelope object
		Messaging.InboundEmail emailBad = new Messaging.InboundEmail() ;
		Messaging.InboundEnvelope envBad = new Messaging.InboundEnvelope();

		// setup the data for the email
		emailGood.subject = 'Test Inbound Email';
		emailGood.fromname = 'Test User';
		envBad.fromAddress = 'testuser@email.com';
		envBad.toAddress = 'test-fail@salesforce-fpi.com';

		// call the email service class and test it with the data in the testMethod
		UtilityInboundEmail emailProcessBad = new UtilityInboundEmail();
		emailProcessBad.handleInboundEmail(emailBad, envBad);

	}
	
}