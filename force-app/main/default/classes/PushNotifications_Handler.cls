/**
*   {Purpose}  ?  Calls from TriggerFramework_PushNotification.trigger and TriggerFramework_Contract.trigger
                  Main purpose is to send API calls to Acoustic that send out Push Notifications.
*/
/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name / Description
*   06.18.2021  Sophia Murphy (Demand Chain)
*               Initial creation
*   =============================================================================
*/
public with sharing class PushNotifications_Handler {

    public static Acoustic_Setting__mdt acousticSetting;
    public static String accessToken;


    public PushNotifications_Handler() {
        getCustomMetadata();
    }

    //called from the Contact Trigger - if a contact comes across with Push Ids - but has not been merged
    // we want to merge them.
    // We don't check for push field changes because we could have all the info about this contact in Salesforce
    // but they haven't yet synced their email record over to Acoustic yet - so there would be nothing to merge with.
    // we look at the Merge Successful field
    //
    // we need to find the record of that mobile device in Acoustic and merge it with the Contact's email record
    // Refer to https://api5.silverpop.com/restdoc/#!/databases/databases_contacts_get_get_2
    // and https://api5.silverpop.com/restdoc/#!/databases/establishidentity_put_put_15 
    // a merge cannot be undone
    public static void mergeContactsInAcoustic(List<Contact> contactList) {
        if(acousticSetting == null) {
            getCustomMetadata();
        }

        if(acousticSetting.Disable_All_Callouts__c != true) {
            System.debug('DC: Inside mergeContactsInAcoustic');
            List<Contact> contactsToMerge = new List<Contact>();
            for(Contact c : contactList) {
                //first - do we have device ids?
                System.debug('DC: c.Push_Notification_Device_Id__c: ' + c.Push_Notification_Device_Id__c);
                System.debug('DC: c.Push_Notification_User_Id__c: ' + c.Push_Notification_User_Id__c);
                System.debug('DC: c.Push_Notification_Merge_Successful__c: ' + c.Push_Notification_Merge_Successful__c);
                if(c.Push_Notification_Device_Id__c != null && c.Push_Notification_User_Id__c != null) {
                    //second - have they already been successfully merged? or have we tried this more than 3x?
                    if(c.Push_Notification_Merge_Successful__c == false && (c.Push_Notification_Merge_Attempt_Count__c < 3 || c.Push_Notification_Merge_Attempt_Count__c == null) ) {
                        //third - did we JUST try to merge them??
                        if(c.Push_Notification_Last_Merge_Attempt__c < DateTime.now().addMinutes(-2) || c.Push_Notification_Last_Merge_Attempt__c == null) {
                            contactsToMerge.add(c);
                        }
                    }
                }
            }   //END: (Contact c : contactList) {
            
            System.debug('DC:contactsToMerge: ' + contactsToMerge);   
            //Now we have our list of contacts that have device info; need to go through each and send the merge call to acoustic
            if(contactsToMerge.size() > 0) {
                List<Contact> contactsToUpdate = new List<Contact>();
                //NOTE - mergeSingleContact method does a callout.  And this is in a loop - because they have to be done 1 by 1.
                for(Contact c : contactsToMerge) {
                    System.debug('DC: calling mergeSingleContact');
                    mergeSingleContact(c.Id, c.PID__c, c.Push_Notification_Device_Id__c, c.Push_Notification_User_Id__c, (Integer)c.Push_Notification_Merge_Attempt_Count__c);
                }
            }
        }
    }

    @future(callout=true)
    public static void mergeSingleContact(String sfContactId, String sfPID, String deviceId, String userId, Integer curCount) {
        System.debug('DC: inside mergeSingleContact');
        Contact updContact = new Contact(Id = sfContactId);
        if(accessToken == null) {
            getAccessToken();
        }

        String endPt = substituteTokens(acousticSetting.Databases_URL__c, '', '', '', acousticSetting.Database_ID__c);
        endPt = endPt + '/establishidentity/Push-' + acousticSetting.App_Key_Qualifier__c + '/' + userId + '|' + deviceId;

        String endPt_Android = endPt + '/establishidentity/Push-' + acousticSetting.App_Key_Qualifier_Android__c + '/' + userId + '|' + deviceId;

        //String endPt = 'https://enptzoffwluj73m.m.pipedream.net';
        System.debug('DC: endPt: ' + endPt);

        //SFDC Contact Id is the name of a lookup field in Acoustic
        //for Production Acoustic we use PID as the lookup field; not SFDC Contact Id
        //String body = '{"identity":{"name":"SFDC Contact Id", "value":"' + sfContactId + '"}}';

        Map<String, Object> mapJSON = new Map<String, Map<String, Object>>();
        Map<String, Object> innerMapJSON = new Map<String, Object>();
        
        //innerMapJSON.put('name', 'SFDC Contact Id');
        //innerMapJSON.put('value', sfContactId);
        innerMapJSON.put('name', 'PID');
        innerMapJSON.put('value', sfPID);
        mapJSON.put('identity', innerMapJSON);
        
        String body = JSON.serialize(mapJSON);
        System.debug('DC: body: ' + body);
        
        Http objHttp = new Http();
        HttpRequest objReq = new HttpRequest();
        objReq.setTimeout(60000);
        objReq.setEndpoint(endPt);
        objReq.setMethod('PUT');
        system.debug('DC: accessToken: ' + accessToken);
        objReq.setHeader('Authorization', 'Bearer ' + accessToken);
        //objReq.setHeader('Authorization', 'Bearer 837c31b61174e71da8531b96a479cfaa');
        objReq.setHeader('Content-Type', 'application/json');
        objReq.setHeader('Accept', 'application/json');

        objReq.setBody(body);

        HttpResponse objRes;
        if(Test.isRunningTest()) {
            HttpResponse tmpRes = new HttpResponse();
            tmpRes.setStatus('OK');
            //Need status code to NOT be 200; so the Android portion runs in the test classes
            tmpRes.setStatusCode(400);
            String strTestJSONResponse = '{"something":"something","success":true,"errors":[]}';
            tmpRes.setBody(strTestJSONResponse);
            objRes = tmpRes;
        } else {
            objRes = objHttp.send(objReq);
        }   
        System.debug('DC: objRes: ' + objRes);
        System.debug('DC: objRes.getBody(): ' + objRes.getBody());
        //Status code will be 200 if the merge was successful.
        //400 if it wasn't.  
        if(curCount == null) {
            curCount = 0;
        }

        updContact.Push_Notification_Last_Merge_Attempt__c = DateTime.now();
        updContact.Push_Notification_Last_Merge_Response__c = objRes.getBody();
        updContact.Push_Notification_Merge_Attempt_Count__c = curCount + 1;

        if(objRes.getStatusCode() == 200) {
            updContact.Push_Notification_Merge_Successful__c = true;
        } else {
            //Try under the Android app qualifier
            //START: Send under Android qualifier
            Http objHttp_Android = new Http();
            HttpRequest objReq_Android = new HttpRequest();
            objReq_Android.setTimeout(60000);
            objReq_Android.setEndpoint(endPt_Android);
            objReq_Android.setMethod('PUT');
            
            objReq_Android.setHeader('Authorization', 'Bearer ' + accessToken);
            objReq_Android.setHeader('Content-Type', 'application/json');
            objReq_Android.setHeader('Accept', 'application/json');
    
            objReq_Android.setBody(body);
    
            HttpResponse objRes_Android;
            if(Test.isRunningTest()) {
                HttpResponse tmpRes_Android = new HttpResponse();
                tmpRes_Android.setStatus('OK');
                tmpRes_Android.setStatusCode(200);
                String strTestJSONResponse_Android = '{"something":"something","success":true,"errors":[]}';
                tmpRes_Android.setBody(strTestJSONResponse_Android);
                objRes_Android = tmpRes_Android;
            } else {
                objRes_Android = objHttp_Android.send(objReq_Android);
            }   
            System.debug('DC: objRes_Android: ' + objRes_Android);
            System.debug('DC: objRes_Android.getBody(): ' + objRes_Android.getBody());
            //Status code will be 200 if the merge was successful.
            //400 if it wasn't.  
            
            if(objRes_Android.getStatusCode() == 200) {
                updContact.Push_Notification_Merge_Successful__c = true;
            }
            //END: Send under Android qualifier
        }
        System.debug('DC: updContact: ' + updContact);
        update updContact;
        
        //return updContact;
    }

    public static void processNotifications(List<Push_Notification__c> pnList)  {
        if(acousticSetting == null) {
            getCustomMetadata();
        }

        if(acousticSetting.Disable_All_Callouts__c != true) {
            List<Push_Notification__c> sendThesePNs = new List<Push_Notification__c>();
            //Update the fields we needed from the TR to be formulas - so we don't have to query to get them.
            //for(Push_Notification__c pn : [SELECT Id, Title__c, Body__c, Test_Respondent__c, TR_Cancelled__c
            //        , PID__c, Cancelled__c, Send_Notification__c, Date_Notification_Sent__c, Push_Notifications_Enabled__c
            //        , TR_QC_Contact__c
            //        FROM Push_Notification__c WHERE Id IN :pnList]) {
            for(Push_Notification__c pn : pnList) {
                System.debug('DC: pn.Cancelled__c ' + pn.Cancelled__c);
                System.debug('DC: pn.Send_Notification__c ' + pn.Send_Notification__c);
                System.debug('DC: pn.Date_Notification_Sent__c ' + pn.Date_Notification_Sent__c);
                System.debug('DC: pn.TR_Cancelled__c ' + pn.TR_Cancelled__c);
                if(pn.Cancelled__c == false 
                    && pn.Send_Notification__c == true 
                    && pn.Date_Notification_Sent__c == null 
                    && pn.TR_Cancelled__c == false
                    && pn.Title__c != null) {

                        if( (acousticSetting.Only_Send_to_QC_Contacts__c == true && pn.TR_QC_Contact__c == true) || acousticSetting.Only_Send_to_QC_Contacts__c == false) {
                            sendThesePNs.add(pn);
                        }

                }
            }

            if(sendThesePNs.size() > 0) {
                for(Push_Notification__c pn : sendThesePNs) {
                    System.debug('DC: pn.PID__c ' + pn.PID__c);
                    System.debug('DC: pn.Push_Notifications_Enabled__c ' + pn.Push_Notifications_Enabled__c);
                    if(pn.PID__c != null && pn.Push_Notifications_Enabled__c == true) {
                        sendSinglePushNotification(pn.Id, pn.PID__c, pn.Title__c, pn.Body__c);
                    }
                }
            }
        } //END: if disableAllCallouts is true
    }

    @future(callout=true)
    public static void sendSinglePushNotification(String pnId, String sfPID, String pushTitle, String pushBody) {
        System.debug('DC: sendSinglePushNotification');
        //Push_Notification__c updPN = new Push_Notification__c(Id = pnId);
        if(accessToken == null) {
            getAccessToken();
        }

        if(acousticSetting.Disable_All_Callouts__c != true) {
            String endPt = substituteTokens(acousticSetting.Channel_Push_URL__c, '', '', '', '');
            endPt = endPt + '/push/sends';
            System.debug('DC: endPt: ' + endPt);

            //SFDC Contact Id is the name of a lookup field in Acoustic
            //for Production Acoustic we use PID as the lookup field; not SFDC Contact Id
            //String body = '{"identity":{"name":"SFDC Contact Id", "value":"' + sfContactId + '"}}';
            
            //TEST BODY - with Sophia's PID 606700 HARD CODED IN
            //String body = '{ "channelQualifiers": [' + acousticSetting.Channel_Qualifiers__c + '], "content": { "simple": { "apns": { "aps": { "alert": { "title": "' + pushTitle + '", "subtitle": "", "body": "' + pushBody + '" } }, "notification-action": { "type": "openApp", "name": "Open App", "value": null } }, "gcm": { "alert": { "subject": "' + pushTitle + '", "message": "' + pushBody + '", "notification-action": { "type": "openApp", "name": "Open App", "value": null } } } } }, "contacts": [{ "lookupKeyFields": [{ "name": "PID", "value": "606700" }] }], "campaignName": "Push Notifications"}';
            
            //ACTUAL BODY to use
            String body = '{ "channelQualifiers": [' + acousticSetting.Channel_Qualifiers__c + '], "content": { "simple": { "apns": { "aps": { "alert": { "title": "' + pushTitle + '", "subtitle": "", "body": "' + pushBody + '" } }, "notification-action": { "type": "openApp", "name": "Open App", "value": null } }, "gcm": { "alert": { "subject": "' + pushTitle + '", "message": "' + pushBody + '", "notification-action": { "type": "openApp", "name": "Open App", "value": null } } } } }, "contacts": [{ "lookupKeyFields": [{ "name": "PID", "value": "' + sfPID + '" }] }], "campaignName": "Push Notifications"}';
            System.debug('DC: body: ' + body);
            
            Http objHttp = new Http();
            HttpRequest objReq = new HttpRequest();
            objReq.setTimeout(60000);
            objReq.setEndpoint(endPt);
            objReq.setMethod('POST');
            system.debug('DC: accessToken: ' + accessToken);
            objReq.setHeader('Authorization', 'Bearer ' + accessToken);
            //objReq.setHeader('Authorization', 'Bearer 837c31b61174e71da8531b96a479cfaa');
            objReq.setHeader('Content-Type', 'application/json');
            objReq.setHeader('Accept', 'application/json');

            objReq.setBody(body);

            HttpResponse objRes;
            if(Test.isRunningTest()) {
                HttpResponse tmpRes = new HttpResponse();
                tmpRes.setStatus('OK');
                tmpRes.setStatusCode(200);
                String strTestJSONResponse = '{"something":"something"}';
                tmpRes.setBody(strTestJSONResponse);
                objRes = tmpRes;
            } else {
                objRes = objHttp.send(objReq);
            }  

            if(objRes.getStatusCode() == 200 || objRes.getStatusCode() == 202) {
                Push_Notification__c pnUpdate = new Push_Notification__c(Id = pnId);
                pnUpdate.Date_Notification_Sent__c = DateTime.now();
                update pnUpdate;
            }
        }
        //return updContact;
    }
 

    //gets the access token and puts in a global variable that we can use
    public static void getAccessToken() {
        if(acousticSetting == null) {
            getCustomMetadata();
        }
        if(acousticSetting.Disable_All_Callouts__c != true) {
            String authEndpoint = substituteTokens(acousticSetting.Authentication_URL__c, acousticSetting.Client_Token__c, acousticSetting.Client_Secret__c, acousticSetting.Refresh_Token__c, '');
            
            Http objHttp = new Http();
            HttpRequest objReq = new HttpRequest();
            objReq.setTimeout(60000);
            objReq.setEndpoint(authEndpoint);
            objReq.setMethod('POST');
            objReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');

            //objReq.setBody('');
            HttpResponse objRes;
            if(Test.isRunningTest()) {
                HttpResponse tmpRes = new HttpResponse();
                tmpRes.setStatus('OK');
                tmpRes.setStatusCode(200);
                String strTestJSONResponse = '{"access_token":"testing123"}';
                tmpRes.setBody(strTestJSONResponse);
                objRes = tmpRes;
            } else {
                objRes = objHttp.send(objReq);
            }  

            TokenResponse tr = (TokenResponse)JSON.deserialize(objRes.getBody(),TokenResponse.class);
            accessToken = tr.access_token;
        }
    }

    private static String substituteTokens(String initialString, String clienttoken, String clientsecret, String refreshtoken, String databaseid) {
        String returnStr = initialString;
        returnStr = returnStr.replace('{clienttoken}', acousticSetting.Client_Token__c);
        returnStr = returnStr.replace('{clientsecret}', acousticSetting.Client_Secret__c);
        returnStr = returnStr.replace('{refreshtoken}', acousticSetting.Refresh_Token__c);
        returnStr = returnStr.replace('{databaseid}', acousticSetting.Database_ID__c);
        return returnStr;
    } 

    public static void getCustomMetadata() {
        Acoustic_Setting__mdt tmpSetting = [SELECT Id, App_Key_Qualifier__c, Authentication_URL__c, Channel_Push_URL__c
            , Channel_Qualifiers__c, Client_Secret__c, Client_Token__c, Database_ID__c
            , Databases_URL__c, Refresh_Token__c, Disable_All_Callouts__c
            , App_Key_Qualifier_Android__c, Only_Send_to_QC_Contacts__c
            FROM Acoustic_Setting__mdt WHERE DeveloperName = 'Default' LIMIT 1];
        if(tmpSetting != null) {
            acousticSetting = tmpSetting;
        }
    }

    public class TokenResponse{
        public String access_token {get; set;}
    }
}