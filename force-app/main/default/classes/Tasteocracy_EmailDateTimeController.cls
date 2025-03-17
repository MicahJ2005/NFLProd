/**
 * 07.28.2022   Sophia Murphy (Demand Chain)
 *              Controller behind Tasteocracy_EmailDateTime component
 *              Used in emails, needs to be based on timezone.
 * 06.30.2023   Sophia Murphy (Demand Chain)
 *              Deprecated
 *              Replaced with Tasteocracy_EmailComponentController
 * 
 */
public class Tasteocracy_EmailDateTimeController {
    public void something() {}
    /**public DateTime dateTimeToUse {
        get;
        set;
    } 
    public String dateFormatToUse {
        get;
        set;
    } 
    public String tzToUse {
        get;
        set;
    } 
    public String getFormattedDatetime() {
        if (dateTimeToUse == null) {
            return '';
        } else {
            if(tzToUse == '' || tzToUse == null) {
                tzToUse = 'CST';
            }

            if(dateFormatToUse == null) {
                return dateTimeToUse.format('EEEE M/d/yyyy h:mm a', tzToUse); //Specify Time zone like IST,CST
            } else {
                return dateTimeToUse.format(dateFormatToUse, tzToUse); //Specify Time zone like IST,CST
            }
        }
    }
    */
}