global class UtilitySched_MaintData implements Schedulable {
/**
*   {Purpose}  �  Schedules hourly data cleanup tasks
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032
*
*   {EXECUTION}  �  System.schedule('Daily Data Maintenance Job', '0 0 2 * * ?', new UtilitySched_MaintData());
*              
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             				Description
*   20150427  	Andy Boettcher DCS				Created
*	20230715	Sophia Murphy (Demand Chain)	Updated to include additional TRQs
*   =============================================================================
*/
	global void execute(SchedulableContext sc) {
		
		// TRQ Sweeper - Completed Projects
		UtilityBatch_CleanTRQ trqCustodian = new UtilityBatch_CleanTRQ();
		//trqCustodian.strQuery = 'SELECT Id FROM Test_Respondent_Quota__c WHERE (Test_Respondent__r.Master_Test__r.Opportunity__r.Project_Stage__c = \'Completed\' OR Test_Respondent__r.Master_Test__r.Opportunity__r.Project_Stage__c = \'Invoiced\') AND IsScheduled__c = FALSE AND LastModifiedDate = LAST_N_WEEKS:5';
		trqCustodian.strQuery = 'SELECT Id FROM Test_Respondent_Quota__c WHERE Test_Respondent__r.Master_Test__r.Opportunity__r.Project_Stage__c IN (\'Complete\', \'Invoiced\', \'Completed\')  AND IsScheduled__c = FALSE';
		database.executeBatch(trqCustodian, 9999);
		
		// TRQ Sweeper - Completed INVOICED
		// 07.15.2023 - With the move away from Opportunities - we need to clean  up TRQs on data NOT related to opps!
		UtilityBatch_CleanTRQ trqCustodian2 = new UtilityBatch_CleanTRQ();
		trqCustodian2.strQuery = 'SELECT Id FROM Test_Respondent_Quota__c WHERE Test_Respondent__r.Master_Test__r.IsOpportunityInvoiced__c = true AND IsScheduled__c = FALSE';
		database.executeBatch(trqCustodian2, 9999);

		// TRQ Sweeper - Silverpop Emails
		UtilityBatch_CleanTRQ spCustodian = new UtilityBatch_CleanTRQ();
		spCustodian.strQuery = 'SELECT Id FROM silverpop__Silverpop_Email_Activity__c WHERE CreatedDate <= N_DAYS_AGO:7';
		database.executeBatch(spCustodian, 9999);

	}
}