/**
 * 07.28.2022   Sophia Murphy (Demand Chain)
 *              Controller behind Tasteocracy_EmailDateTime component
 *              Used in emails, needs to be based on timezone.
 * 06.30.2023   Sophia Murphy (Demand Chain)
 *              Updated to be more generic, and added to the Tasteocracy_EmailGreeting component as well.
 * 07.19.2023   Sophia Murphy (Demand Chain)
 *              Added in Brand, instead of timezone.
 * 08.02.2023   Sophia Murphy (Demand Chain)
 *              Added in calc to figure out no shows
 * 
 */
public class Tasteocracy_EmailComponentController {



    public String contactId {
        get;
        set;
    } 

    public String getFormattedOrdinal() {
        String returnValue = '1st'; //default

        if(contactId != null) {
            List<Test_Respondent__c> trNoShowList = new List<Test_Respondent__c>([SELECT Id, CreatedDate, Tested_Status__c
                                                                FROM Test_Respondent__c
                                                                WHERE Respondent__c = :contactId
                                                                AND CALENDAR_YEAR(CreatedDate) = :system.now().year()
                                                                AND Tested_Status__c = 'No Show']);

            Integer noShowCount = 0;
            if(trNoShowList != null) {
                noShowCount = trNoShowList.size();
            }
                       
            if(noShowCount > 0) {
                if(noShowCount == 1) {
                    returnValue = '1st';
                }
                else if(noShowCount == 2) {
                    returnValue = '2nd';
                }
                else if(noShowCount == 3) {
                    returnValue = '3rd';
                }
                else {
                    returnValue = noShowCount + 'th';
                }
            }
        }

        return returnValue;
    }

    public DateTime dateTimeToUse {
        get;
        set;
    } 
    public String dateFormatToUse {
        get;
        set;
    } 
    //public String tzToUse {
    //    get;
    //    set;
    //} 
    public String brandToUse {
        get;
        set;
    } 
    public String getFormattedDatetime() {
        if (dateTimeToUse == null) {
            return '';
        } else {
            //if(tzToUse == '' || tzToUse == null) {
            //    tzToUse = 'CST';
            //}

            String tZone = 'CST';   //CST is the default
            if(brandToUse == 'Livermore') {
                tZone = 'PST';
            }
            if(brandToUse == 'BoundBrook') {
                tZone = 'EST';
            }

            if(dateFormatToUse == null) {
                return dateTimeToUse.format('EEEE M/d/yyyy h:mm a', tZone); //Specify Time zone like PST,CST
            } else {
                return dateTimeToUse.format(dateFormatToUse, tZone); //Specify Time zone like PST,CST
            }
        }
    }

    public String useCase {
        get;
        set;
    } 
    public String trName {
        get;
        set;
    } 
    public String schedName {
        get;
        set;
    } 
    public String getFormattedGreeting() {
        String returnValue = '';

        if(trName == null || trName == '') {
            trName = 'Tasteocracy Member';
        }
        if(schedName == null || schedName == '') {
            schedName = 'Tasteocracy Member';
        }

        if (useCase == null) {
            returnValue = '<b>Dear Tasteocracy Member</b>, ';
        } else {
            if(useCase.contains('Pairs')) {
                returnValue = '<b>Dear ' + schedName + '</b>,';
            }
            else if(useCase.contains('Child')) {
                returnValue = '<b>Dear Parent/Guardian of ' + trName + '</b>,';
            } else {
                returnValue = '<b>Dear ' + trName + '</b>,';
            }
        }

        return returnValue;
    }
}