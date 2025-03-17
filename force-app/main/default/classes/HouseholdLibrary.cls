public with sharing class HouseholdLibrary
{

/**
*   {Purpose}  ?  Supports the TriggerFramework_Household trigger
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
*   Date        Name                    Description
*   20160321    Jason Flippen (DCS)     Created.
*   =============================================================================
*/

/** Public Methods **/

    /*******************************************************************************
     * afterUpdate
     * @Description: Method for handling all "After Update" functionality.
     * 
     * @Date: 03/21/2016
     * @Author: Jason Flippen (Demand Chain Systems)
     * 
     * @Updated: N/A
     *
     * @Params: List<Household__c> a_newRecordList,
     *          Map<Id,Household__c> a_newRecordMap,
     *          List<Household__c> a_oldRecordList,
     *          Map<Id,Household__c> a_oldRecordMap
     *
     * @Return: N/A
     *******************************************************************************/
    public static void afterUpdate(List<Household__c> a_newRecordList,
                                   Map<Id,Household__c> a_newRecordMap,
                                   List<Household__c> a_oldRecordList,
                                   Map<Id,Household__c> a_oldRecordMap){
        UtilityMethods.bolPreventContactSQS = true;
        System.debug(LoggingLevel.DEBUG, '*** START: HouseholdLibrary.afterUpdate()');

                                                 // Get the Set of Ids from the
                                                 // records that have had their
                                                 // Head_of_Household__c changed.
        Set<Id> updatedHouseholdIdSet = new Set<Id>();
        for (Household__c h : a_newRecordList){
            if (h.Head_of_Household__c != a_oldRecordMap.get(h.Id).Head_of_Household__c){
                updatedHouseholdIdSet.add(h.Id);
            }
        }
        System.debug(LoggingLevel.DEBUG, '*** updatedHouseholdIdSet: ' + updatedHouseholdIdSet);

                                                 // Grab a Household-To-Household Contact
                                                 // Map related to the Household records
                                                 // that have been updated.
        Map<Id,Map<Id,String>> householdContactMap = getHouseholdContactMap(updatedHouseholdIdSet);

                                                 // Re-Iterate through the List of updated
                                                 // Household records that have had their
                                                 // Head_of_Household__c field changed.
        List<Contact> updateContactList = new List<Contact>();
        for (Household__c h : a_newRecordList){
            if (updatedHouseholdIdSet.contains(h.Id)){
                                                 // If this particular Household has any
                                                 // Household Contacts related to them,
                                                 // determine if their Household Contact
                                                 // Email needs to be updated.
                if (householdContactMap.containsKey(h.Id)){
                    for (Id contactId : householdContactMap.get(h.Id).keySet()){
                        String currentHSEContEmail = householdContactMap.get(h.Id).get(contactId);
                        if (h.Household_Contact_Email__c != currentHSEContEmail){
                            Contact updateContact = new Contact();
                            updateContact.Id = contactId;
                            updateContact.Household_Contact_Email__c = h.Household_Contact_Email__c;
                            updateContactList.add(updateContact);
                        }

                    } // End For (Id contactId : householdContactMap.get(h.Id).keySet())

                } // End If (householdContactMap.containsKey(h.Id))

            } // End If (allContactIdSet.contains(h.Id))

        } // End For (Household__c h : a_newRecordList)
        System.debug(LoggingLevel.DEBUG, 'updateContactList: ' + updateContactList);

                                                 // If we have any Contact records to
                                                 // update, update them.
        if (updateContactList.size() > 0){
            update(updateContactList);
        }

        System.debug(LoggingLevel.DEBUG, '*** END: HouseholdLibrary.afterUpdate()');

    } // End Method: afterUpdate()

/** Private Methods **/

    /******************************************************************************
     * getHouseholdContactMap
     *
     * @Description: Method to get a Household-To-Household Contact Map.
     * 
     * @Author: Jason Flippen (DCS)
     * @Date: 03/21/2016
     *
     * @Updated: N/A
     *
     * @Params: Set<Id> a_householdIdSet
     * @Return: Map<Id,Map<Id,String>> returnMap
     ******************************************************************************/
    private static Map<Id,Map<Id,String>> getHouseholdContactMap(Set<Id> a_householdIdSet){
        System.debug(LoggingLevel.DEBUG, '*** START: HouseholdLibrary.getHouseholdContactMap()');

        Map<Id,Map<Id,String>> returnMap = new Map<Id,Map<Id,String>>();
        for (Household_Contact__c hc : [SELECT Household__c,
                                               Contact__c,
                                               Contact__r.Household_Contact_Email__c
                                        FROM   Household_Contact__c
                                        WHERE  Household__c IN :a_householdIdSet]){
            if (!returnMap.containsKey(hc.Household__c)){
                returnMap.put(hc.Household__c, new Map<Id,String>());
            }
            returnMap.get(hc.Household__c).put(hc.Contact__c,hc.Contact__r.Household_Contact_Email__c);
        }
        System.debug(LoggingLevel.DEBUG, '*** returnMap: ' + returnMap);
        System.debug(LoggingLevel.DEBUG, '*** END: HouseholdLibrary.getHouseholdContactMap()');
        return returnMap;
    } // End Method: getHouseholdContactMap()

    @future
    public static void checkHeadOfHousehold(Set<Id> setHids){
        UtilityMethods.bolPreventHouseholdSQS = true;
        UtilityMethods.bolPreventContactSQS = true;

        List<Contact> lstContactClear = new list<Contact>();
        List<Contact> lstSetHofH = new List<Contact>();
        //01.22.2019 - put contacts in SET first, to prevent duplicates.
        Set<Id> contactIds = new Set<Id>();
        for(Household_Contact__c hc :[SELECT Id, Contact__c FROM Household_Contact__c WHERE Household__c in :setHids AND Contact__c != null]){
            //Contact c = new Contact ();
            //    c.Id = hc.Contact__c;
            //    c.Head_of_Household__c = false;
            //lstContactClear.add(c);
            contactIds.add(hc.Contact__c);
        }
        //Now go through the SET to add to lstContactClear
        for(Id cId : contactIds)
        {
            Contact c = new Contact (Id = cId);
            c.Head_of_Household__c = false;
            lstContactClear.add(c);
        }



        for(Household__c h :[SELECT Id, Head_of_Household__c FROM Household__c WHERE Id in :setHids AND Head_of_Household__c != null]){
            Contact c = new Contact ();
                c.Id = h.Head_of_Household__c;
                c.Head_of_Household__c = true;
            lstSetHofH.add(c);
        }
        if(lstContactClear.size()>0){
            update lstContactClear;
        }
        if(lstSetHofH.size()>0){
            update lstSetHofH;
        }
    }
}