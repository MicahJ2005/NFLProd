/**
 * If Send Notification is check on the Push Notification record
 * API calls go out to Acoustic/IBM to send out the Push Notification
 * 
 * Change History
 * ------------------------------------
 * 06.18.2021	Sophia Murphy (Demand Chain)
 * 				Initial Creation
*   20220707    Sophia Murphy DCS       Added enable/disable flag
 * ------------------------------------
 */
trigger TriggerFramework_PushNotification on Push_Notification__c (after insert, after update) {
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
    if(mapAPEXSettings.get('enablePushNotificationTrigger')) {
        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {

            //Determines if the notifications should be sent by checking if "Send Notifications" is checked
            System.debug('DC: calling processNotifications');
            PushNotifications_Handler.processNotifications(Trigger.new);
        }
    }

}