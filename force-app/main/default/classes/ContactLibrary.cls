public with sharing class ContactLibrary {

/**
*   {Purpose}  ?  Supports the TriggerFramework_Contact trigger
*                 
*   {Function}  ? DESCRIBE PUBLIC FUNCTIONS
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20131212  	Andy Boettcher DCS		Created
*	20131222	Andy Boettcher DCS		Refactored to be a supporting class for 
*										the TriggerFramework_Contact trigger
*	20210707	Sophia Murphy DC		Updated to include Do_Not_Include_in_Past_Participation__c, DC Case #10055
*   =============================================================================
*/
	///////////////////////////////////
	// Action Methods
	///////////////////////////////////
	public static void assignToRespondentAccount(List<Contact> lstTrigger) {
		Map<String, String> mapAppSettings = UtilityMethods.APP_SETTINGS();
		for(Contact con : lstTrigger) {
			if(con.RecordTypeId == mapAppSettings.get('RT_ContactRespondentAdult') || con.RecordTypeId == mapAppSettings.get('RT_ContactRespondentChild')) {
				con.AccountId = mapAppSettings.get('ID_RespondentAccount');
			}
		}
	}

	public static void rollupSummaryDates(Set<Id> setContactIds, Boolean bolSaveChanges) {

		//////////////////////////////////////
		// This will compute Last Quant, Last Qual, Last Scheduled, 
		// Next Scheduled for all TRs related to setContactId keyset
		//////////////////////////////////////
	    if(Limits.getQueries() > 90) {
        	return;
		}

        // Create Contact Map from TRQs that are scheduled and primary
    	Map<Id, List<Test_Respondent_Quota__c>> mapContactTRQs = new Map<Id, List<Test_Respondent_Quota__c>>();
    	for(Id objId : setContactIds) {
    		mapContactTRQs.put(objId, new List<Test_Respondent_Quota__c>());
    	}

    	//for(Test_Respondent_Quota__c objTRQ : [SELECT Test_Respondent__r.Respondent__c,
    	//												Test_Respondent__r.Tested_Status__c,
     //                                                   Session_Quota__r.Related_Session__r.Research_Type__c, 
     //                                                   Session_Quota__r.Related_Session__r.Session_Start__c,
     //                                                   IsScheduled__c, 
     //                                                   IsPreQualified__c
     //                                               FROM Test_Respondent_Quota__c 
     //                                               WHERE Test_Respondent__r.Respondent__c IN :setContactIds
     //                                               	AND (IsScheduled__c = TRUE OR IsPrequalified__c = TRUE)
     //                                               	AND Session_Quota__r.Master_Quota__r.IsTrackingOnly__c = FALSE
     //                                               	AND Session_Quota__r.Master_Quota__r.IsScheduleEnabled__c = TRUE]) {
    	//	mapContactTRQs.get(objTRQ.Test_Respondent__r.Respondent__c).add(objTRQ);

    	//}

        for(Test_Respondent_Quota__c objTRQ : [SELECT Test_Respondent__r.Respondent__c,
    													Test_Respondent__r.Tested_Status__c,
                                                        Session_Quota__r.Related_Session__r.Research_Type__c, 
														Session_Quota__r.Related_Session__r.Session_Start__c,
														Session_Quota__r.Related_Session__r.Test_Type__c,
														Test_Respondent__r.Master_Test__r.Population_Type__c,
														Test_Respondent__r.Master_Test__r.Do_Not_Include_in_Past_Participation__c,
                                                        IsScheduled__c, 
                                                        IsPreQualified__c,
                                                        //SM-DC: Added
                                                        Test_Respondent__r.Respondent__r.Next_Scheduled_Date__c
                                                    FROM Test_Respondent_Quota__c 
                                                    WHERE Test_Respondent__r.Respondent__c IN :setContactIds
                                                    	AND (IsScheduled__c = TRUE OR IsPrequalified__c = TRUE)]) {
    		mapContactTRQs.get(objTRQ.Test_Respondent__r.Respondent__c).add(objTRQ);

    	}

        Set<String> setTested = new Set<String>();
		setTested.add('Additional Tested');
        setTested.add('Tested');
        setTested.add('In Progress');
        setTested.add('No Show');

    	// Spin through Contact Map and find rollup values
    	Map<Id, Contact> mapUpdateContacts = new Map<Id, Contact>();

        for(Id objId : mapContactTRQs.keySet()) {
        	Contact objContact = new Contact(Id=objId);

            //Set each of these to a fictitous date
    		Date dteNextReserved = System.Today().addYears(-10);
    		Date dteNextScheduled = dteNextReserved;
    		Date dteLastQual = dteNextReserved;
    		Date dteLastQuant = dteNextReserved;

    		Boolean bolSaveNextReserved = false;
    		Boolean bolSaveNextScheduled = false;
    		Boolean bolSaveLastQual = false;
    		Boolean bolSaveLastQuant = false;

    		for(Test_Respondent_Quota__c objTRQ : mapContactTRQs.get(objId)) {

                //SM-DC: Added
                //objContact.Next_Scheduled_Date__c = objTRQ.Test_Respondent__r.Respondent__r.Next_Scheduled_Date__c;

                Date dteSessionStart = objTRQ.Session_Quota__r.Related_Session__r.Session_Start__c.date();
    			String strResearchType = objTRQ.Session_Quota__r.Related_Session__r.Research_Type__c;
    			Boolean bolIsScheduled = objTRQ.IsScheduled__c;
    			Boolean bolIsPrequalified = objTRQ.IsPreQualified__c;
				Boolean includeSession = objTRQ.Test_Respondent__r.Master_Test__r.Do_Not_Include_in_Past_Participation__c;

    			System.Debug('Checking on ' + dteSessionStart + ' for ' + objTRQ.Test_Respondent__r.Respondent__c);
    			System.Debug('Current Next Reserved = ' + dteNextReserved);
    			System.Debug('Current Next Scheduled = ' + dteNextScheduled);
    			System.Debug('Current Last Qual = ' + dteLastQual);
    			System.Debug('Current Last Quant = ' + dteLastQuant);

               	// Find Next Reserved
    			if(dteSessionStart > System.Today() 
    					&& dteSessionStart > dteNextReserved
    					&& bolIsPrequalified
    					&& !bolIsScheduled
    				) {
					bolSaveNextReserved = true;
					dteNextReserved = dteSessionStart;
				}

				// Find Next Scheduled

				//Case 9104
				Boolean bolSaveNextScheduled_Sub = true;
				if(objTRQ.Session_Quota__r.Related_Session__r.Test_Type__c == 'SD - Screendown' &&
					objTRQ.Test_Respondent__r.Master_Test__r.Population_Type__c == 'Express Test') {
						bolSaveNextScheduled_Sub = false;
					}
    			if(dteSessionStart >= System.Today() 
    					&& dteSessionStart >= dteNextScheduled
    					&& bolIsScheduled
						&& !bolIsPrequalified
						&& bolSaveNextScheduled_Sub
    				) {
					bolSaveNextScheduled = true;
					dteNextScheduled = dteSessionStart;
				}

				// Determine Last Qual
				if(strResearchType == 'Qual' 
						&& dteSessionStart > dteLastQual 
						&& setTested.contains(objTRQ.Test_Respondent__r.Tested_Status__c)
						&& dteSessionStart <= System.Today()
						&& bolIsScheduled
						&& !bolIsPrequalified
						&& !includeSession
					) {
					bolSaveLastQual = true;
					dteLastQual = dteSessionStart;
				}

				// Determine Last Quant
				if(strResearchType == 'Quant' 
						&& dteSessionStart > dteLastQuant 
						&& setTested.contains(objTRQ.Test_Respondent__r.Tested_Status__c)
						&& dteSessionStart <= System.Today()
						&& bolIsScheduled
						&& !bolIsPrequalified
						&& !includeSession
					) {
					bolSaveLastQuant = true;
					dteLastQuant = dteSessionStart;
				}
    		} //END: for(Test_Respondent_Quota__c objTRQ : mapContactTRQs.get(objId))

            //BEGIN---Jeff Johnson update 9/18/18
	    		if(dteLastQuant == objContact.Next_Scheduled_Date__c && dteLastQual < objContact.Next_Scheduled_Date__c
	   					|| dteLastQual  == objContact.Next_Scheduled_Date__c && dteLastQuant < objContact.Next_Scheduled_Date__c
	   					) {
	    			bolSaveNextScheduled = FALSE;
	    		}
	    		//--- ADD THE BELOW...
				if(dteNextScheduled == System.today() && objContact.Next_Scheduled_Date__c == null)
						{
					bolSaveNextScheduled = FALSE;
				}

            //END---Jeff Johnson update 9/18/18

    		// Save Values to Contact Record if found
    		if(bolSaveNextReserved) { objContact.Next_Reserved__c = dteNextReserved; } else { objContact.Next_Reserved__c = null; }
    		if(bolSaveNextScheduled) { objContact.Next_Scheduled_Date__c = dteNextScheduled; } else { objContact.Next_Scheduled_Date__c = null; }
    		if(bolSaveLastQual) { objContact.Last_Qualitative_Participation__c = dteLastQual; } else { objContact.Last_Qualitative_Participation__c = null; }
    		if(bolSaveLastQuant) { objContact.Last_Quantitative_Participation__c = dteLastQuant; } else { objContact.Last_Quantitative_Participation__c = null; }

   			mapUpdateContacts.put(objId, objContact);
    	}


    	System.Debug('ContactLibrary.rollupSummaryDates');
    	System.Debug(mapUpdateContacts);

    	if(mapUpdateContacts.size() > 0 && bolSaveChanges) {
    		update mapUpdateContacts.values();
    	}

    }

    //02.27.2019 - Sophia Murphy (Demand Chain)
    //              Added summary for Tardy Not Paid tested status.  Case 5767 (DC) // Case 101814 (Euro)
	public static void rollupSummary(Set<Id> setContactID){

		//THESE VALUES ARE ALL DETERMINED VIA REPORTS NOW - AND WE NO LONGER SEND EMAILS VIA SILVERPOP
		/**

		if(Limits.getQueries() > 90) {
			return;
		}

		integer intTestedYear = 0;
		integer intTested365 = 0;
		integer intNoShowYear = 0;
        integer intTardyNotPaid = 0;
		integer intPSAYear = 0;
		integer intCancelsYear = 0;
		Decimal decDonateYear = 0;
		Decimal decPayYear = 0;
		integer intSilverPopYear = 0;
		map <Id,Contact> mapUpdateContact = new map <Id,Contact>();
		map <Id,Contact> mapUpdateContact2 = new map <Id,Contact>();

		List<Contact> lstContact = [
			SELECT ID FROM Contact WHERE ID in:setContactID
		];

		List<Test_Respondent__c> lstTestRespond = [
			SELECT ID, Respondent__c, Donation_Amount_Per_Event__c, Check_Amount__c, Tested_Status__c, CreatedDate, LastModifiedDate 
			FROM Test_Respondent__c 
			WHERE Respondent__c in:setContactID 
				AND CreatedDate = LAST_N_DAYS:740
		];
		List<silverpop__Silverpop_Email_Activity__c> lstSilverPop = [
			SELECT Id, silverpop__Contact__c 
			FROM silverpop__Silverpop_Email_Activity__c 
			WHERE silverpop__Contact__c in:setContactID 
				AND CreatedDate = LAST_N_DAYS:365
		];

		Set<String> setTested = new Set<String>();
		setTested.add('Additional Tested');
        setTested.add('Tested');

		
		if(lstContact.size()>0){
			for (Contact c: lstContact){

				// Reset Counters
				intTestedYear = 0;
				intTested365 = 0;
				intNoShowYear = 0;
                intTardyNotPaid = 0;
				intPSAYear = 0;
				intCancelsYear = 0;
				decDonateYear = 0;
				decPayYear = 0;
				intSilverPopYear = 0;

				// Loop through all TRs
				for(Test_Respondent__c t: lstTestRespond){
					if(c.ID == t.Respondent__c){

						// Number of Tests in the calendar year
						if(setTested.contains(t.Tested_Status__c) && t.CreatedDate.Year() == system.now().year()){
							intTestedYear += 1;
						}

						// Number of tests in last 12 months
						if(setTested.contains(t.Tested_Status__c) && t.CreatedDate > system.now().addMonths(-12)){
							intTested365 += 1;
						}

						// Number of PSAs in the last 12 months
						if(t.Tested_Status__c == 'PSA' && t.CreatedDate > system.now().addMonths(-12)){
							intPSAYear += 1;
						}

						// Number of Cancellations in the last 12 months
						if(t.Tested_Status__c == 'Cancelled' && t.CreatedDate > system.now().addMonths(-12)){
							intCancelsYear += 1;
						}

						// Number of No Shows in the last 24 months
						//if(t.Tested_Status__c == 'No Show' && t.CreatedDate > system.now().addMonths(-24)){
						// Changed to be static date 20160101 by Lisa Moceri 2160105 AAB
						Date dteJanFirst = Date.parse('1/1/2016');
						if(t.Tested_Status__c == 'No Show' && t.CreatedDate > Datetime.newInstance(dteJanFirst.year(), dteJanFirst.month(), dteJanFirst.day())){
							intNoShowYear += 1;
						}

                        //02.27.2019
                        if(t.Tested_Status__c == 'Tardy Not Paid' && t.CreatedDate > Datetime.newInstance(dteJanFirst.year(), dteJanFirst.month(), dteJanFirst.day())){
                            intTardyNotPaid += 1;
                        }

						// Payment and Donation Amounts
						if((t.Tested_Status__c == 'Disqualified - Paid' || t.Tested_Status__c == 'PSA' || setTested.contains(t.Tested_Status__c)) 
							&& t.CreatedDate.Year() == system.now().year() && t.Check_Amount__c != null){
							
							// Pay in current year
							if(test.isRunningTest()) { decPayYear+=100;	} 
								else { decPayYear += t.Check_Amount__c;	}
							
							// Donation in current year
							if(t.Donation_Amount_Per_Event__c == 'Full Payment') { decDonateYear += t.Check_Amount__c; }
							if(t.Donation_Amount_Per_Event__c == 'Partial payment of $10') { decDonateYear += 10; }
						}
					}

					//THESE ARE HANDLED VIA REPORTS NOW

					// Put totals in the fields
					//c.This_Year_Donations__c = decDonateYear;
					//c.This_Year_Participations__c = intTestedYear;
					//c.This_Year_Payments__c = decPayYear;
					//c.Total_No_Shows__c = intNoShowYear;
                    //02.27.2019
                    //c.Total_Tardy_Not_Paid__c = intTardyNotPaid;
					//c.Last_12_Months_of_PSA__c = intPSAYear;
					//c.Last_12_Months_Participations__c = intTested365;
					//c.Last_12_Months_Respondent_Cancels__c = intCancelsYear;
					mapUpdateContact.put(c.Id,c);
				}

				if(lstSilverPop.size()>0){
					for(silverpop__Silverpop_Email_Activity__c sp:lstSilverPop){
						if(c.Id == sp.silverpop__Contact__c){
							intSilverPopYear += 1;
						}
					}
						c.Number_of_Emails_Sent__c = intSilverPopYear;
					mapUpdateContact2.put(c.Id, c);
				}
			}
		}
		if(mapUpdateContact.size()>0){
			update mapUpdateContact.values();
		}
		if(mapUpdateContact2.size()>0){
			update mapUpdateContact2.values();
		}
		*/
	}

	public static void rollupQuantQual(Set<Id> setTRScopeIds) {

		UtilityMethods.LOG_MESSAGE('ContactLibrary.rollupQuantQual', 'STARTING METHOD');

		Map<String, String> mapContactFields = new Map<String, String>();
        mapContactFields.put('Quant', 'Last_Quantitative_Participation__c');
        mapContactFields.put('Qual', 'Last_Qualitative_Participation__c');

		Map<Id, AggregateResult> mapLastType = new Map<Id, AggregateResult>();
        for(AggregateResult ar : [SELECT Test_Respondent__r.Respondent__c ContactId, 
                                                Session_Quota__r.Related_Session__r.Research_Type__c ResearchType, 
                                                MAX(Session_Quota__r.Related_Session__r.Session_Start__c) LastDate 
                                            FROM Test_Respondent_Quota__c 
                                            WHERE Test_Respondent__r.Respondent__c != null 
                                                AND Test_Respondent__c IN :setTRScopeIds
                                            GROUP BY Test_Respondent__r.Respondent__c, 
                                                Session_Quota__r.Related_Session__r.Research_Type__c]) {
            mapLastType.put((Id)ar.get('ContactId'), ar);
        }

        List<Contact> lstUpdateContacts = new List<Contact>();
        Set<Id> setIdsToUpdate = new Set<Id>();
        for(AggregateResult ar : mapLastType.values()) {
            Contact conUpdate = new Contact();
            conUpdate.Id = (Id)ar.get('ContactId');
            setIdsToUpdate.add(conUpdate.Id);
            DateTime dtmLastTest = (DateTime)ar.get('LastDate');
            conUpdate.put(mapContactFields.get((String)ar.get('ResearchType')), dtmLastTest.Date());
            lstUpdateContacts.add(conUpdate);
        }

        UtilityMethods.LOG_MESSAGE('ContactLibrary.rollupQuantQual', 'UPDATE CHECK');
        System.Debug(lstUpdateContacts);

        if(lstUpdateContacts.size() > 0) { 
            update lstUpdateContacts; 
        }
	}

    /*******************************************************************************
     * afterUpdate
     * @Description: Method for handling all "After Update" functionality.
     * 
     * @Date: 03/21/2016
     * @Author: Jason Flippen (Demand Chain Systems)
     * 
     * @Updated:
     * 03.20.2019   Sophia Murphy (Demand Chain)
     *              Added method for sending the IBM callout for SMS double optin
     *
     * @Params: List<Contact> a_newRecordList,
     *          Map<Id,Contact> a_newRecordMap,
     *          List<Contact> a_oldRecordList,
     *          Map<Id,Contact> a_oldRecordMap
     *
     * @Return: N/A
     *******************************************************************************/
    public static void afterUpdate(List<Contact> a_newRecordList,
                                   Map<Id,Contact> a_newRecordMap,
                                   List<Contact> a_oldRecordList,
                                   Map<Id,Contact> a_oldRecordMap)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: ContactLibrary.afterUpdate()');


        sendIBMCallout(a_newRecordMap, a_oldRecordMap);


                                                 // Get the Set of Ids from the
                                                 // records that have had their
                                                 // Email changed.
        Set<Id> updatedContIdSet = new Set<Id>();
        for (Contact c : a_newRecordList)
        {
        	if (c.Email != a_oldRecordMap.get(c.Id).Email)
        	{
            	updatedContIdSet.add(c.Id);
        	}
        }
        System.debug(LoggingLevel.DEBUG, '*** updatedContIdSet: ' + updatedContIdSet);

        										 // Grab a Head of Household-To-Household Contact
        										 // Map related to the Contact records that have
        										 // been updated.
    	Map<Id,Map<Id,String>> hohHouseholdContactMap = getHOHHouseholdContactMap(updatedContIdSet);

    											 // Make sure our Map has some data
    											 // in it before proceeding.
    	if (!hohHouseholdContactMap.isEmpty())
    	{
    											 // Re-Iterate through the List of updated
    											 // Contact records that have had their
    											 // Email field changed.
	    	List<Contact> updateContactList = new List<Contact>();
	    	for (Contact c : a_newRecordList)
	    	{
	    		if (updatedContIdSet.contains(c.Id))
	    		{
	    										 // If this particular Contact has any
	    										 // Household Contacts related to them,
	    										 // determine if their Household Contact
	    										 // Email needs to be updated.
	    			if (hohHouseholdContactMap.containsKey(c.Id))
	    			{
	    				for (Id contactId : hohHouseholdContactMap.get(c.Id).keySet())
	    				{
	    					String currentHSEContEmail = hohHouseholdContactMap.get(c.Id).get(contactId);
	    					if (c.Email != currentHSEContEmail)
	    					{
	    						Contact updateContact = new Contact();
	    						updateContact.Id = contactId;
	    						updateContact.Household_Contact_Email__c = c.Email;
	    						updateContactList.add(updateContact);
	    					}

	    				} // End For (Id contactId : hohHouseholdContactMap.get(c.Id).keySet())

	    			} // End If (hohHouseholdContactMap.containsKey(c.Id))

	    		} // End If (allContactIdSet.contains(c.Id))

	    	} // End For (Contact c : a_newRecordList)
	    	System.debug(LoggingLevel.DEBUG, 'updateContactList: ' + updateContactList);

	    										 // If we have any Contact records to
	    										 // update, update them.
	    	if (updateContactList.size() > 0)
	    	{
	    		update(updateContactList);
	    	}

    	} // End If (!hohHouseholdContactMap.isEmpty())

        System.debug(LoggingLevel.DEBUG, '*** END: ContactLibrary.afterUpdate()');

    } // End Method: afterUpdate()

    /******************************************************************************
     * getHOHHouseholdContactMap
     *
     * @Description: Method to get a Head of Household-To-Household Contact Map.
     * 
     * @Author: Jason Flippen (DCS)
     * @Date: 03/21/2016
     *
     * @Updated: N/A
     *
     * @Params: Set<Id> a_contactIdSet
     * @Return: Map<Id,Map<Id,String>> returnMap
     ******************************************************************************/
    private static Map<Id,Map<Id,String>> getHOHHouseholdContactMap(Set<Id> a_contactIdSet)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: ContactLibrary.getHOHHouseholdContactMap()');

    	Map<Id,Map<Id,String>> returnMap = new Map<Id,Map<Id,String>>();
        for (Household__c h : [SELECT Id,
        							  Head_of_Household__c,
        							  (SELECT Contact__c,
        							  		  Contact__r.Household_Contact_Email__c
        							   FROM   Household_Contacts__r)
                               FROM   Household__c
                               WHERE  Head_of_Household__c IN :a_contactIdSet])
        {
            for (Household_Contact__c hc : h.Household_Contacts__r)
            {
            	if (!a_contactIdSet.contains(hc.Contact__c))
            	{
	            	if (!returnMap.containsKey(h.Head_of_Household__c))
	             	{
	             		returnMap.put(h.Head_of_Household__c, new Map<Id,String>());
	              	}
	              	returnMap.get(h.Head_of_Household__c).put(hc.Contact__c,hc.Contact__r.Household_Contact_Email__c);
            	}
            }
        }
        System.debug(LoggingLevel.DEBUG, '*** returnMap: ' + returnMap);

        System.debug(LoggingLevel.DEBUG, '*** END: ContactLibrary.getHOHHouseholdContactMap()');

        return returnMap;

    } // End Method: getHOHHouseholdContactMap()


    public static void sendIBMCallout(Map<Id,Contact> newMap, Map<Id,Contact> oldMap) {

        //Look to see if the Send IBM Callout checkbox went from unchecked to checked. 
        // and SMS_Opt_in_Date__c is filled in.
        List<Contact> contactList = new List<Contact>();
        for(Id cId : newMap.keySet()) {
            Contact oldContact = oldMap.get(cId);
            Contact newContact = newMap.get(cId);

            if(oldContact.Send_IBM_Callout__c == false && newContact.Send_IBM_Callout__c == true && newContact.SMS_Opt_in_Date__c != null) {
                contactList.add(newContact);
            }
        }

        for(Contact c : contactList) {
            if(c.SMSPhoneW1__c != null && c.SMSPhoneW1__c != '') {
                sendIBMCallout_future(c.SMSPhoneW1__c); 
            }
        }
    } //END: sendIBMCallout

    @future(callout=true)
    private static void sendIBMCallout_future(String phNumber) {
        String initialURL = 'https://communicatepro.mgage.com/api/gateway';
        String messge = EncodingUtil.urlEncode('TASTE:To confirm opt-in please respond with FOODS', 'UTF-8');
        String message_billed = 'no';
        String message_type = 'sms';
        //String phnumber = '19522372315';
        String spoof_from = 'US-87767';
        String program_id = '111806';

        String preEndpoint = '{0}?message={1}&message_billed={2}&message_type={3}&numbers={4}&spoof_from={5}&program_id={6}';
        List<Object> parameters = new List<Object> {initialURL, messge, message_billed, message_type, phNumber, spoof_from, program_id};
        String IBMEndpoint = String.format(preEndpoint, parameters);

        //String IBMEndpoint = 'https://communicatepro.mgage.com/api/gateway?message=TASTE%3ATo%20confirm%20opt-in%20please%20respond%20with%20FOODS&message_billed=no&message_type=sms&numbers=19522372315&spoof_from=US-87767&program_id=111806';

        Http objHttp = new Http();
        HttpRequest objReq = new HttpRequest();
        objReq.setTimeout(60000);
        objReq.setEndpoint(IBMEndpoint);
        objReq.setMethod('POST');
        objReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        //need to base64encode this: fpiincapiuser@foodperspectives.com:Fpi100!
        objReq.setHeader('Authorization', 'Basic ZnBpaW5jYXBpdXNlckBmb29kcGVyc3BlY3RpdmVzLmNvbTpGcGkxMDAh');  //base64encoded of above

        //objReq.setBody('');
		HttpResponse objRes;
		if(!Test.isRunningTest()) {
			objRes = objHttp.send(objReq);
		}
    }

}