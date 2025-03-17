/**
*   Called from the afterCaseQueue FLOW
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20201116	Sophia Murphy DCS		Initial Creation
*   =============================================================================
*/global class Invocable_FindCQUser {

    @InvocableMethod
    public static List<String> findUser() {

        //Given the current time, find the Recruiting User that is "on call" during that time
        // based on the CQ_Start_Time and CQ_End_Time values.
        //WHERE CQ_Start_Time__c <= currentTime 
        //AND CQ_End_Time__c >= currentTime 
        //AND CQ_Assignment_Bypass__c = false 
        //ORDER BY CQ_Last_Assigned__c ASC LIMIT 1

        List<User> usrList = new List<User>();
        DateTime currentDT = DateTime.newInstance(2020,1,1,DateTime.now().hour(),DateTime.now().minute(), 0);
        for(User u: [SELECT Id, CQ_Start_Time__c, CQ_End_Time__c, CQ_Last_Assigned__c
            FROM User 
            WHERE CQ_Assignment_Bypass__c = false
             AND CQ_Start_Time__c != null]) {
                 
                 DateTime startDT = parseStringToDT(u.CQ_Start_Time__c);
                 DateTime endDT = parseStringToDT(u.CQ_End_Time__c);

                if(startDT <= currentDT && endDT >= currentDT) {
                    usrList.add(u);
                }

             }
        System.debug('DC: usrList: ' + usrList);

        DateTime earliestAssignedDate = DateTime.newInstance(2099,1,1,1,1,0);
        System.debug('DC: earliestAssignedDate: ' + earliestAssignedDate);

        User returnUser;
        for(User u : usrList) {
            System.debug('DC: earliestAssignedDate: ' + earliestAssignedDate);
            System.debug('DC: u.CQ_Last_Assigned__c: ' + u.CQ_Last_Assigned__c);
            if(u.CQ_Last_Assigned__c < earliestAssignedDate || u.CQ_Last_Assigned__c == null) {
                earliestAssignedDate = u.CQ_Last_Assigned__c;
                returnUser = u;
            }
        }

        List<String> returnVal = new List<String>();
        if(returnUser != null) {
            returnVal.add(returnUser.Id);
        }
        return returnVal;
    }

    public static DateTime parseStringToDT(String myString) {
        List<String> parseString = myString.split(':');
        List<String> amPM = parseString[1].split(' ');

        //Hour = parseString[0]
        //Minute = amPM[0]
        //AM/PM = amPM[1]

        Integer timeHour = Integer.valueOf(parseString[0]);
        Integer timeMinute = Integer.valueOf(amPM[0]);
        if(amPM[1] == 'PM' && timeHour < 12) {
            timeHour = timeHour+12;
        }

        return DateTime.newInstance(2020,1,1,timeHour,timeMinute,0);
    }

 }