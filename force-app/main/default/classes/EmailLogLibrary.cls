public with sharing class EmailLogLibrary {
/**
*   {Purpose}	- Support to create EmailLog records to email respondents via Process Builder
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20160403  	Andy Boettcher DCS		Created
*   20160729	Andy Boettcher DCS 		Added Pair Primary criteria to Emails
*	20200206	Sophia Murphy (Demand Chain)
*				added in check against Do_not_send_respondent_email__c to suppress emails on resche
*				Case #6939
*	20200108	Sophia Murphy (Demand Chain)
*				Suppressed creation of Reminder/Scheduled emails if this is for a Express Panel "filling" test
				DC Case 9092
*	20200924	Sophia Murphy (Demand Chain)
*				Added in creation of Push Notification records; alongside Email Log records.
*   =============================================================================
*/	
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	//public static void processTRSingle(Test_Respondent__c objTR) {

	//	Set<Id> setScope = new Set<Id>();
	//	setScope.add(objTR.Id);
	//	EmailLogLibrary.processTR(setScope);

	//}
	

	public static List<Email_Log__c> lstInsertELL { get; set; }
	public static List<Push_Notification__c> lstInsertPNs { get; set; }

	//@Future
	public static void processTR(Set<Id> setScope, Map<Id, Test_Respondent__c> oldMap) {

		if(setScope.size() <= 0 || setScope == null) {
			return;
		}

		Map<Id, Set<String>> mapTRUseCases = new Map<Id, Set<String>>();

		for(Id objId : setScope) {
			mapTRUseCases.put(objId, new Set<String>());
		}

		// Empty List to Insert
		lstInsertELL = new List<Email_Log__c>();
		lstInsertPNs = new List<Push_Notification__c>();

		// Get Scope
		List<Test_Respondent__c> lstScopeTR = [SELECT
												Id,
												Respondent__c,
												Respondent__r.Email,
												Household_Contact_Email__c,
												Age__c,
												Master_Test__r.Pairs_Test__c,
												Master_Test__c,
												Respondent_Status__c,
												Tested_Status__c,
												Session_Type__c,
												Session_Date__c,
												Pair_Primary__c,
                                                Schedule_Contact_Email__c
											FROM
												Test_Respondent__c
											WHERE
												Id IN :setScope
                                               AND
                                                Do_not_send_respondent_email__c = false
											];

		List<Test_Respondent_Quota__c> lstScopeTRQ = [SELECT
												Id,
												Test_Respondent__c,
												Test_Respondent__r.Respondent__c,
												Test_Respondent__r.Respondent__r.Email,
												Test_Respondent__r.Household_Contact_Email__c,
												Test_Respondent__r.Age__c,
												Test_Respondent__r.Master_Test__r.Pairs_Test__c,
												Test_Respondent__r.Master_Test__c,
												Test_Respondent__r.Respondent_Status__c,
												Test_Respondent__r.Tested_Status__c,
												Test_Respondent__r.Session_Type__c,
												Test_Respondent__r.Pair_Primary__c,
												Session_Quota__c,
												Session_Quota__r.Related_Session__c,
												Session_Quota__r.Related_Session__r.Session_Start__c,
												IsQualified__c,
												IsScheduled__c,
												IsPreQualified__c,
												IsTrackingQuota__c,
												Test_Respondent__r.Schedule_Contact_Email__c,
												Session_Quota__r.Related_Session__r.Test_Type__c, 
												Test_Respondent__r.Master_Test__r.Population_Type__c
											FROM
												Test_Respondent_Quota__c
											WHERE
												Test_Respondent__c IN :setScope
                                            AND
                                                Test_Respondent__r.Do_not_send_respondent_email__c  = false
											];
        
		// Loop through TR Scope
		for(Test_Respondent__c objTR : lstScopeTR) {
			
			UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR START', 'Looping on ' + objTR);

			// ELL FPI Cancellation Adult
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c >= 18 &&
				objTR.Master_Test__r.Pairs_Test__c == false &&
				objTR.Respondent_Status__c == 'FPI Canceled'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL FPI Cancellation Adult');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Respondent__r.Email,
					Email_Address__c = objTR.Respondent__r.Email,
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'FPI Cancellation Adult'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Respondent__r.Email, objTR.Master_Test__c, objTR.Id, 'FPI Cancellation Adult');
			}

			// ELL FPI Cancellation Child
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c < 18 &&
				objTR.Age__c > 0 &&
				objTR.Master_Test__r.Pairs_Test__c == false &&
				objTR.Respondent_Status__c == 'FPI Canceled'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL FPI Cancellation Child');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Household_Contact_Email__c, //uses household contact email, this is not desired as of 8/28/18
					Email_Address__c = objTR.Schedule_Contact_Email__c,//added
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'FPI Cancellation Child'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Schedule_Contact_Email__c, objTR.Master_Test__c, objTR.Id, 'FPI Cancellation Child');
			}

			// ELL FPI Cancellation Pairs
			if(
				objTR.Respondent__c != null &&
				objTR.Master_Test__r.Pairs_Test__c == true &&
				objTR.Respondent_Status__c == 'FPI Canceled'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL FPI Cancellation Pairs');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Household_Contact_Email__c, //objTR.Scheduler_Contact_ID__c
					Email_Address__c = objTR.Schedule_Contact_Email__c,//added
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'FPI Cancellation Pairs'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Schedule_Contact_Email__c, objTR.Master_Test__c, objTR.Id, 'FPI Cancellation Pairs');

			}

			// ELL No Show Adult
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c >= 18 &&
				objTR.Tested_Status__c == 'No Show' &&
				objTR.Respondent_Status__c == 'Scheduled' &&
				objTR.Session_Type__c != 'HUT - Home Use Test'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL No Show Adult');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					Email_Address__c = objTR.Respondent__r.Email,
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'No Show Adult'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Respondent__r.Email, objTR.Master_Test__c, objTR.Id, 'No Show Adult');
			}

			// ELL No Show Adult HUT
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c >= 18 &&
				objTR.Tested_Status__c == 'No Show' &&
				objTR.Session_Type__c == 'HUT - Home Use Test'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL No Show Adult HUT');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					Email_Address__c = objTR.Respondent__r.Email,
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'No Show Adult HUT'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Respondent__r.Email, objTR.Master_Test__c, objTR.Id, 'No Show Adult HUT');
			}

			// ELL No Show Child
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c < 18 &&
				objTR.Age__c > 0 &&
				objTR.Tested_Status__c == 'No Show' &&
				objTR.Session_Type__c != 'HUT - Home Use Test'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL No Show Child');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Household_Contact_Email__c, //objTR.Scheduler_Contact_ID__c
					Email_Address__c = objTR.Schedule_Contact_Email__c,//added
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'No Show Child'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Schedule_Contact_Email__c, objTR.Master_Test__c, objTR.Id, 'No Show Child');
			}

			// ELL No Show Child HUT
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c < 18 &&
				objTR.Age__c > 0 &&
				objTR.Tested_Status__c == 'No Show' &&
				objTR.Session_Type__c == 'HUT - Home Use Test'
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL No Show Child HUT');

				/**stInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Household_Contact_Email__c, //objTR.Scheduler_Contact_ID__c
					Email_Address__c = objTR.Schedule_Contact_Email__c,//added
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'No Show Child HUT'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Schedule_Contact_Email__c, objTR.Master_Test__c, objTR.Id, 'No Show Child HUT');
			}

			// ELL Scheduled for Call Back Adult
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c >= 18 &&
				objTR.Master_Test__r.Pairs_Test__c == false &&
				objTR.Respondent_Status__c == 'Prequalified Unscheduled' &&
				objTR.Session_Date__c >= System.Now()
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'ELL Scheduled for Call Back Adult');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					Email_Address__c = objTR.Respondent__r.Email,
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'Scheduled for Call Back Adult'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Respondent__r.Email, objTR.Master_Test__c, objTR.Id, 'Scheduled for Call Back Adult');
			}

			// ELL Scheduled for Call Back Child
			if(
				objTR.Respondent__c != null &&
				objTR.Age__c < 18 &&
				objTR.Age__c > 0 &&
				objTR.Master_Test__r.Pairs_Test__c == false &&
				objTR.Respondent_Status__c == 'Prequalified Unscheduled' &&
				objTR.Session_Date__c >= System.Now()
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'Scheduled for Call Back Child');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Household_Contact_Email__c, //objTR.Scheduler_Contact_ID__c
					Email_Address__c = objTR.Schedule_Contact_Email__c,//added
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'Scheduled for Call Back Child'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Schedule_Contact_Email__c, objTR.Master_Test__c, objTR.Id, 'Scheduled for Call Back Child');
			}

			// ELL Scheduled for Call Back Pairs
			if(
				objTR.Respondent__c != null &&
				objTR.Master_Test__r.Pairs_Test__c == true &&
				objTR.Pair_Primary__c == null &&
				objTR.Respondent_Status__c == 'Prequalified Unscheduled' &&
				objTR.Session_Date__c >= System.Now()
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'Scheduled for Call Back Pairs');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTR.Respondent__c,
					//Email_Address__c = objTR.Household_Contact_Email__c, //objTR.Scheduler_Contact_ID__c
					Email_Address__c = objTR.Schedule_Contact_Email__c,//added
					Master_Test__c = objTR.Master_Test__c,
					Test_Respondent__c = objTR.Id,
					Use_Case__c = 'Scheduled for Call Back Pairs'
				));*/
				createELL_PN(objTR.Respondent__c, objTR.Schedule_Contact_Email__c, objTR.Master_Test__c, objTR.Id, 'Scheduled for Call Back Pairs');
			}
		}

		// Loop through TRQ Scope
		Map<Id,Set<Id>> trSessionQuotasMap = new Map<Id,Set<Id>>();
		for(Test_Respondent_Quota__c objTRQ : lstScopeTRQ) {

            if (!trSessionQuotasMap.containsKey(objTRQ.Test_Respondent__c)) {
                trSessionQuotasMap.put(objTRQ.Test_Respondent__c, new Set<Id>());
            }
            
            
			UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ START', 'Looping on ' + objTRQ);

			// ELL Reminder Email Adult
			// ELL Scheduled Email Adult


			//01.02.2021 - DC Case 9092 - If this is a "test" just to fill the Express Panel; 
			//	we don't want to send them emails
			Boolean isExpressPanelFiller = false;
			if(objTRQ.Session_Quota__r.Related_Session__r.Test_Type__c == 'SD - Screendown'
			&& 
			objTRQ.Test_Respondent__r.Master_Test__r.Population_Type__c == 'Express Test') {
				isExpressPanelFiller = true;
			}

			if(
				objTRQ.Test_Respondent__r.Respondent__c != null &&
				objTRQ.IsQualified__c == true &&
				objTRQ.IsScheduled__c == true &&
				objTRQ.IsTrackingQuota__c == false && 
				objTRQ.Test_Respondent__r.Age__c >= 18 &&
				objTRQ.Test_Respondent__r.Master_Test__r.Pairs_Test__c == false &&
				objTRQ.Test_Respondent__r.Respondent_Status__c == 'Scheduled' && 
				objTRQ.Test_Respondent__r.Tested_Status__c == 'Pending' &&
				objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c >= System.Now() &&
				isExpressPanelFiller == false
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ', 'Scheduled and Reminder Email Adult');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
					Email_Address__c = objTRQ.Test_Respondent__r.Respondent__r.Email,
					Session_Quota__c = objTRQ.Session_Quota__c,
					Test_Respondent_Quota__c = objTRQ.Id,
					Test_Respondent__c = objTRQ.Test_Respondent__c,
					Use_Case__c = 'Reminder Email Adult'
				));*/
				createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Respondent__r.Email
					, objTRQ.Session_Quota__c, objTRQ.Id, objTRQ.Test_Respondent__c, 'Reminder Email Adult');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
					Email_Address__c = objTRQ.Test_Respondent__r.Respondent__r.Email,
					Session_Quota__c = objTRQ.Session_Quota__c,
					Test_Respondent_Quota__c = objTRQ.Id,
					Test_Respondent__c = objTRQ.Test_Respondent__c,
					Use_Case__c = 'Scheduled Email Adult'
				));*/
				createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Respondent__r.Email
					, objTRQ.Session_Quota__c, objTRQ.Id, objTRQ.Test_Respondent__c, 'Scheduled Email Adult');

			}

			// ELL Reminder Email Child
			// ELL Scheduled Email Child
			if(
				objTRQ.Test_Respondent__r.Respondent__c != null &&
				objTRQ.IsQualified__c == true &&
				objTRQ.IsScheduled__c == true &&
				objTRQ.IsTrackingQuota__c == false && 
				objTRQ.Test_Respondent__r.Age__c < 18 &&
				objTRQ.Test_Respondent__r.Age__c > 0 &&
				objTRQ.Test_Respondent__r.Master_Test__r.Pairs_Test__c == false &&
				objTRQ.Test_Respondent__r.Respondent_Status__c == 'Scheduled' && 
				objTRQ.Test_Respondent__r.Tested_Status__c == 'Pending' &&
				objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c >= System.Now()
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ', 'Scheduled and Reminder Email Child');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
					//Email_Address__c = objTRQ.Test_Respondent__r.Household_Contact_Email__c, //objTRQ.Test_Respondent__r.Scheduler_Contact_ID__c
					Email_Address__c = objTRQ.Test_Respondent__r.Schedule_Contact_Email__c,//added
					Session_Quota__c = objTRQ.Session_Quota__c,
					Test_Respondent_Quota__c = objTRQ.Id,
					Test_Respondent__c = objTRQ.Test_Respondent__c,
					Use_Case__c = 'Reminder Email Child'
				));*/
				createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Schedule_Contact_Email__c
					, objTRQ.Session_Quota__c, objTRQ.Id, objTRQ.Test_Respondent__c, 'Reminder Email Child');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
					//Email_Address__c = objTRQ.Test_Respondent__r.Household_Contact_Email__c, //objTRQ.Test_Respondent__r.Scheduler_Contact_ID__c
					Email_Address__c = objTRQ.Test_Respondent__r.Schedule_Contact_Email__c,//added
					Session_Quota__c = objTRQ.Session_Quota__c,
					Test_Respondent_Quota__c = objTRQ.Id,
					Test_Respondent__c = objTRQ.Test_Respondent__c,
					Use_Case__c = 'Scheduled Email Child'
				));*/
				createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Schedule_Contact_Email__c
					, objTRQ.Session_Quota__c, objTRQ.Id, objTRQ.Test_Respondent__c, 'Scheduled Email Child');

			}

			// ELL Reminder Email Pairs
			// ELL Scheduled Email Pairs
			if(
				objTRQ.Test_Respondent__r.Respondent__c != null &&
				objTRQ.IsQualified__c == true &&
				objTRQ.IsScheduled__c == true &&
				objTRQ.IsTrackingQuota__c == false && 
				objTRQ.Test_Respondent__r.Master_Test__r.Pairs_Test__c == true &&
				objTRQ.Test_Respondent__r.Respondent_Status__c == 'Scheduled' && 
				objTRQ.Test_Respondent__r.Tested_Status__c == 'Pending' &&
				objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c >= System.Now()
				) {

				UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ', 'Scheduled and Reminder Email Pairs');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
					//Email_Address__c = objTRQ.Test_Respondent__r.Household_Contact_Email__c, //objTRQ.Test_Respondent__r.Scheduler_Contact_ID__c
					Email_Address__c = objTRQ.Test_Respondent__r.Schedule_Contact_Email__c,//added
					Session_Quota__c = objTRQ.Session_Quota__c,
					Test_Respondent_Quota__c = objTRQ.Id,
					Test_Respondent__c = objTRQ.Test_Respondent__c,
					Use_Case__c = 'Reminder Email Pairs'
				));*/
				createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Schedule_Contact_Email__c
					, objTRQ.Session_Quota__c, objTRQ.Id, objTRQ.Test_Respondent__c, 'Reminder Email Pairs');

				/**lstInsertELL.add(new Email_Log__c(
					Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
					//Email_Address__c = objTRQ.Test_Respondent__r.Household_Contact_Email__c, //objTRQ.Test_Respondent__r.Scheduler_Contact_ID__c
					Email_Address__c = objTRQ.Test_Respondent__r.Schedule_Contact_Email__c,//added
					Session_Quota__c = objTRQ.Session_Quota__c,
					Test_Respondent_Quota__c = objTRQ.Id,
					Test_Respondent__c = objTRQ.Test_Respondent__c,
					Use_Case__c = 'Scheduled Email Pairs'
				));*/
				createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Schedule_Contact_Email__c
					, objTRQ.Session_Quota__c, objTRQ.Id, objTRQ.Test_Respondent__c, 'Scheduled Email Pairs');

			}

			// ELL Respondent Cancellation Adult
			if(
				objTRQ.Test_Respondent__r.Respondent__c != null &&
				objTRQ.IsQualified__c == true &&
				objTRQ.IsScheduled__c == false &&
				objTRQ.IsTrackingQuota__c == false && 
				objTRQ.Test_Respondent__r.Age__c >= 18 &&
				objTRQ.Test_Respondent__r.Master_Test__r.Pairs_Test__c == false &&
				//objTRQ.Test_Respondent__r.Respondent_Status__c == 'Canceled'
				objTRQ.Test_Respondent__r.Respondent_Status__c == 'Qualified' && 
				oldMap.get(objTRQ.Test_Respondent__c).Respondent_Status__c == 'Scheduled' &&
				(Id)oldMap.get(objTRQ.Test_Respondent__c).Session_ID__c == objTRQ.Session_Quota__r.Related_Session__c &&
				objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c >= System.Now()
				) {

				if (!trSessionQuotasMap.get(objTRQ.Test_Respondent__c).contains(objTRQ.Session_Quota__c)) {
					
                    UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ', 'ELL Respondent Cancellation Adult');
    
                    /**lstInsertELL.add(new Email_Log__c(
                        Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
                        Email_Address__c = objTRQ.Test_Respondent__r.Respondent__r.Email,
                        Test_Respondent__c = objTRQ.Test_Respondent__c,
                        Use_Case__c = 'Respondent Cancellation Adult'
                    ));*/
					createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Respondent__r.Email
								, null, objTRQ.Test_Respondent__c, 'Respondent Cancellation Adult');
    
                    // Cancel any previous reminders!
                    mapTRUseCases.get(objTRQ.Test_Respondent__c).add('Reminder Email Adult');
    
				}
                    
			}

			// ELL Respondent Cancellation Child
			if(
				objTRQ.Test_Respondent__r.Respondent__c != null &&
				objTRQ.IsQualified__c == true &&
				objTRQ.IsScheduled__c == false &&
				objTRQ.IsTrackingQuota__c == false && 
				objTRQ.Test_Respondent__r.Age__c < 18 &&
				objTRQ.Test_Respondent__r.Age__c > 0 &&
				objTRQ.Test_Respondent__r.Master_Test__r.Pairs_Test__c == false &&
				//objTRQ.Test_Respondent__r.Respondent_Status__c == 'Canceled'
				objTRQ.Test_Respondent__r.Respondent_Status__c == 'Qualified' && 
				oldMap.get(objTRQ.Test_Respondent__c).Respondent_Status__c == 'Scheduled' &&
				(Id)oldMap.get(objTRQ.Test_Respondent__c).Session_ID__c == objTRQ.Session_Quota__r.Related_Session__c &&
				objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c >= System.Now()
				) {

				if (!trSessionQuotasMap.get(objTRQ.Test_Respondent__c).contains(objTRQ.Session_Quota__c)) {
					
                    UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ', 'ELL Respondent Cancellation Child');
    
                    /**lstInsertELL.add(new Email_Log__c(
                        Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
                        //Email_Address__c = objTRQ.Test_Respondent__r.Household_Contact_Email__c, //objTRQ.Test_Respondent__r.Scheduler_Contact_ID__c
                        Email_Address__c = objTRQ.Test_Respondent__r.Schedule_Contact_Email__c,//added
                        Test_Respondent__c = objTRQ.Test_Respondent__c,
                        Use_Case__c = 'Respondent Cancellation Child'
                    ));*/
					createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Schedule_Contact_Email__c
								, null, objTRQ.Test_Respondent__c, 'Respondent Cancellation Child');
    
                    // Cancel any previous reminders!
                    mapTRUseCases.get(objTRQ.Test_Respondent__c).add('Reminder Email Child');
                }

			}

			// ELL Respondent Cancellation Pairs
			if(
				objTRQ.Test_Respondent__r.Respondent__c != null &&
				objTRQ.IsQualified__c == true &&
				objTRQ.IsScheduled__c == false &&
				objTRQ.IsTrackingQuota__c == false && 
				objTRQ.Test_Respondent__r.Master_Test__r.Pairs_Test__c == true &&
				//objTRQ.Test_Respondent__r.Respondent_Status__c == 'Canceled'
				objTRQ.Test_Respondent__r.Respondent_Status__c == 'Qualified' && 
				oldMap.get(objTRQ.Test_Respondent__c).Respondent_Status__c == 'Scheduled' &&
				(Id)oldMap.get(objTRQ.Test_Respondent__c).Session_ID__c == objTRQ.Session_Quota__r.Related_Session__c &&
				objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c >= System.Now()
				) {

				if (!trSessionQuotasMap.get(objTRQ.Test_Respondent__c).contains(objTRQ.Session_Quota__c)) {
					
                    UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTRQ', 'ELL Respondent Cancellation Pairs');
    
                    /**lstInsertELL.add(new Email_Log__c(
                        Contact__c = objTRQ.Test_Respondent__r.Respondent__c,
                        //Email_Address__c = objTRQ.Test_Respondent__r.Household_Contact_Email__c, //objTRQ.Test_Respondent__r.Scheduler_Contact_ID__c
                        Email_Address__c = objTRQ.Test_Respondent__r.Schedule_Contact_Email__c,//added
                        Test_Respondent__c = objTRQ.Test_Respondent__c,
                        Use_Case__c = 'Respondent Cancellation Pairs'
                    ));*/
					createELL_PN(objTRQ.Test_Respondent__r.Respondent__c, objTRQ.Test_Respondent__r.Schedule_Contact_Email__c
								, null, objTRQ.Test_Respondent__c, 'Respondent Cancellation Pairs');
    
                    // Cancel any previous reminders!
                    mapTRUseCases.get(objTRQ.Test_Respondent__c).add('Reminder Email Pairs');
                    
                }

			}
			
            trSessionQuotasMap.get(objTRQ.Test_Respondent__c).add(objTRQ.Session_Quota__c);
		}

		System.Debug(mapTRUseCases);

		// Final Processing
		if(!lstInsertELL.isEmpty()) {

			List<Email_Log__c> lstUpdateELL = new List<Email_Log__c>();
			//Set<String> setUseCases = new Set<String>();
			//for(Set<String> setUC : mapTRUseCases.values()) {
			//	setUseCases.addAll(setUC);
			//}

			// Process Existing ELLs and Deactivate any that are conflicting
			if(mapTRUseCases.size() > 0) {
				for(Email_Log__c objEL : [SELECT Id, Test_Respondent__c, Use_Case__c, Cancelled__c FROM Email_Log__c WHERE Test_Respondent__c IN :mapTRUseCases.keySet()]) {
					if(mapTRUseCases.get(objEL.Test_Respondent__c).contains(objEL.Use_Case__c)) {
						objEL.Cancelled__c = true;
						lstUpdateELL.add(objEL);
					}
				}
			}

			// Update Existing ELLs
			if(!lstUpdateELL.isEmpty()) {
				update lstUpdateELL;
			}

			// Insert ELLs
			UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'COMPLETE, ELLS TO BE INSERTED = ' + lstInsertELL.size());
			insert lstInsertELL;
		}
		if(!lstInsertPNs.isEmpty()) {
			
			List<Push_Notification__c> lstUpdatePNs = new List<Push_Notification__c>();
			//Set<String> setUseCases = new Set<String>();
			//for(Set<String> setUC : mapTRUseCases.values()) {
			//	setUseCases.addAll(setUC);
			//}

			// Process Existing PNs and Deactivate any that are conflicting
			if(mapTRUseCases.size() > 0) {
				for(Push_Notification__c objPN : [SELECT Id, Test_Respondent__c, Use_Case__c, Cancelled__c FROM Push_Notification__c WHERE Test_Respondent__c IN :mapTRUseCases.keySet()]) {
					if(mapTRUseCases.get(objPN.Test_Respondent__c).contains(objPN.Use_Case__c)) {
						objPN.Cancelled__c = true;
						lstUpdatePNs.add(objPN);
					}
				}
			}

			// Update Existing PNs
			if(!lstUpdatePNs.isEmpty()) {
				update lstUpdatePNs;
			}

			// Insert PNs
			UtilityMethods.LOG_MESSAGE('EmailLogLibrary.processTR', 'COMPLETE, Push Notifications TO BE INSERTED = ' + lstInsertPNs.size());
			insert lstInsertPNs;
		}

	}

	//Creates an email log record and a push notification record
	//	Adds them to the lstInsertELL and lstInsertPN lists
	private static void createELL_PN(Id contactId, String emailAddr, Id masterTestId, Id trId, String useCase) {
		lstInsertELL.add(new Email_Log__c(
			Contact__c = contactId,
			Email_Address__c = emailAddr,
			Master_Test__c = masterTestId,
			Test_Respondent__c = trId,
			Use_Case__c = useCase
		));

		Set<String> validUseCases = new Set<String>();
		validUseCases.add('Reminder Email Adult');
		validUseCases.add('Scheduled Email Adult');
		validUseCases.add('Reminder Email Child');
		validUseCases.add('Scheduled Email Child');
		validUseCases.add('Reminder Email Pairs');
		validUseCases.add('Scheduled Email Pairs');

		if(validUseCases.contains(useCase) || Test.isRunningTest()) {
			lstInsertPNs.add(new Push_Notification__c(
				Contact__c = contactId,
				Master_Test__c = masterTestId,
				Test_Respondent__c = trId,
				Use_Case__c = useCase
			));
		}
	}

	private static void createELL_PN(Id contactId, String emailAddr, Id sessQuotaId, Id trqId, Id trId, String useCase) {
		lstInsertELL.add(new Email_Log__c(
			Contact__c = contactId,
			Email_Address__c = emailAddr,
			Session_Quota__c = sessQuotaId,
			Test_Respondent_Quota__c = trqId,
			Test_Respondent__c = trId,
			Use_Case__c = useCase
		));

		Set<String> validUseCases = new Set<String>();
		validUseCases.add('Reminder Email Adult');
		validUseCases.add('Scheduled Email Adult');
		validUseCases.add('Reminder Email Child');
		validUseCases.add('Scheduled Email Child');
		validUseCases.add('Reminder Email Pairs');
		validUseCases.add('Scheduled Email Pairs');

		if(validUseCases.contains(useCase) || Test.isRunningTest()) {
			lstInsertPNs.add(new Push_Notification__c(
				Contact__c = contactId,
				Session_Quota__c = sessQuotaId,
				Test_Respondent_Quota__c = trqId,
				Test_Respondent__c = trId,
				Use_Case__c = useCase
			));
		}
	}

}