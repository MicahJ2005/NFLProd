public with sharing class HseContactLibrary
{

/**
*   {Purpose}  ?  Supports the TriggerFramework_HseContact trigger
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
*   20160203    Jason Flippen (DCS)     Created.
*   =============================================================================
*/

/** Public Methods **/

    /*******************************************************************************
     * afterInsert
     * @Description: Method for handling all "After Insert" functionality.
     * 
     * @Date: 02/03/2016
     * @Author: Jason Flippen (Demand Chain Systems)
     * 
     * @Updated: N/A
     *
     * @Params: List<Household_Contact__c> a_newRecordList
     *          Map<Id,Household_Contact__c> a_newRecordMap
     *
     * @Return: N/A
     *******************************************************************************/
    public static void afterInsert(List<Household_Contact__c> a_newRecordList,
                                   Map<Id,Household_Contact__c> a_newRecordMap)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: HseContactLibrary.afterInsert()');

                                                 // Get Sets of Contact Ids and
                                                 // Household Ids from the
                                                 // records being inserted.
        Set<Id> allContactIdSet = new Set<Id>();
        Set<Id> allHouseholdIdSet = new Set<Id>();
        for (Household_Contact__c hc : a_newRecordList)
        {
            allContactIdSet.add(hc.Contact__c);
            allHouseholdIdSet.add(hc.Household__c);
        }
        System.debug(LoggingLevel.DEBUG, 'allContactIdSet: ' + allContactIdSet);    
        System.debug(LoggingLevel.DEBUG, 'allHouseholdIdSet: ' + allHouseholdIdSet);    

                                                 // Grab Maps of Contact and
                                                 // Household records related
                                                 // to the Household Contact
                                                 // records being inserted.
        Map<Id,Contact> contactMap = getContactMap(allContactIdSet);
        Map<Id,Household__c> householdMap = getHouseholdMap(allHouseholdIdSet);
        System.debug(LoggingLevel.DEBUG, '*** contactMap: ' + contactMap);
        System.debug(LoggingLevel.DEBUG, '*** householdMap: ' + householdMap);

                                                 // The Contact and Household
                                                 // Maps must have data to
                                                 // continue  processing.
        if (!contactMap.isEmpty() && 
            !householdMap.isEmpty())
        {
                                                 // Re-Iterate through the List
                                                 // of records being inserted
                                                 // and determine which Contact
                                                 // records need to be updated.
            Set<Id> updateContactIdSet = new Set<Id>();
            List<Contact> updateContactList = new List<Contact>();
            for (Household_Contact__c hc : a_newRecordList)
            {
                if (contactMap.containsKey(hc.Contact__c) &&
                    householdMap.containsKey(hc.Household__c))
                {
                                                 // Make sure we aren't trying to
                                                 // update a Contact a second time.
                    if (!updateContactIdSet.contains(hc.Contact__c))
                    {
                        updateContactIdSet.add(hc.Contact__c);
                        Contact updateContact = contactMap.get(hc.Contact__c);
                        updateContact.Household_Contact_Email__c = householdMap.get(hc.Household__c).Household_Contact_Email__c;
                        updateContactList.add(updateContact);
                    }
                }
            }
            System.debug(LoggingLevel.DEBUG, '*** updateContactList: ' + updateContactList);
            
                                                 // If we have Contact records to
                                                 // update, update them.
            if (updateContactList.size() > 0)
            {
                update(updateContactList);
            }
        }

        System.debug(LoggingLevel.DEBUG, '*** END: HseContactLibrary.afterInsert()');

    } // End Method: afterInsert()

    /*******************************************************************************
     * afterUpdate
     * @Description: Method for handling all "After Update" functionality.
     * 
     * @Date: 02/03/2016
     * @Author: Jason Flippen (Demand Chain Systems)
     * 
     * @Updated: N/A
     *
     * @Params: List<Household_Contact__c> a_newRecordList,
     *          Map<Id,Household_Contact__c> a_newRecordMap,
     *          List<Household_Contact__c> a_oldRecordList,
     *          Map<Id,Household_Contact__c> a_oldRecordMap
     *
     * @Return: N/A
     *******************************************************************************/
    public static void afterUpdate(List<Household_Contact__c> a_newRecordList,
                                   Map<Id,Household_Contact__c> a_newRecordMap,
                                   List<Household_Contact__c> a_oldRecordList,
                                   Map<Id,Household_Contact__c> a_oldRecordMap)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: HseContactLibrary.afterUpdate()');

                                                 // Get Sets of Contact Ids and
                                                 // Household Ids from the
                                                 // records being updated.
        Set<Id> allContactIdSet = new Set<Id>();
        Set<Id> allHouseholdIdSet = new Set<Id>();
        for (Household_Contact__c hc : a_newRecordList)
        {
            allContactIdSet.add(hc.Contact__c);
            allHouseholdIdSet.add(hc.Household__c);
        }
        System.debug(LoggingLevel.DEBUG, 'allContactIdSet: ' + allContactIdSet);    
        System.debug(LoggingLevel.DEBUG, 'allHouseholdIdSet: ' + allHouseholdIdSet);    

                                                 // Grab Maps of Contact and
                                                 // Household records related
                                                 // to the Household Contact
                                                 // records being updated.
        Map<Id,Contact> contactMap = getContactMap(allContactIdSet);
        Map<Id,Household__c> householdMap = getHouseholdMap(allHouseholdIdSet);
        System.debug(LoggingLevel.DEBUG, '*** contactMap: ' + contactMap);
        System.debug(LoggingLevel.DEBUG, '*** householdMap: ' + householdMap);

                                                 // The Contact and Household
                                                 // Maps must have data to
                                                 // continue  processing.
        if (!contactMap.isEmpty() && 
            !householdMap.isEmpty())
        {
                                                 // Re-Iterate through the List
                                                 // of records being inserted
                                                 // and determine which Contact
                                                 // records need to be updated.
            Set<Id> updateContactIdSet = new Set<Id>();
            List<Contact> updateContactList = new List<Contact>();
            for (Household_Contact__c hc : a_newRecordList)
            {
                if (contactMap.containsKey(hc.Contact__c) &&
                    householdMap.containsKey(hc.Household__c))
                {
                                                 // Make sure we aren't trying to
                                                 // update a Contact a second time.
                    if (!updateContactIdSet.contains(hc.Contact__c))
                    {
                        updateContactIdSet.add(hc.Contact__c);
                        Contact updateContact = contactMap.get(hc.Contact__c);
                        updateContact.Household_Contact_Email__c = householdMap.get(hc.Household__c).Household_Contact_Email__c;
                        updateContactList.add(updateContact);
                    }
                }
            }
            System.debug(LoggingLevel.DEBUG, '*** updateContactList: ' + updateContactList);
            
                                                 // If we have Contact records to
                                                 // update, update them.
            if (updateContactList.size() > 0)
            {
                update(updateContactList);
            }
        }

        System.debug(LoggingLevel.DEBUG, '*** END: HseContactLibrary.afterUpdate()');

    } // End Method: afterUpdate()

    /*******************************************************************************
     * beforeDelete
     * @Description: Method for handling all "Before Delete" functionality.
     * 
     * @Date: 02/03/2016
     * @Author: Jason Flippen (Demand Chain Systems)
     * 
     * @Updated: N/A
     *
     * @Params: List<Household_Contact__c> a_oldRecordList
     *          Map<Id,Household_Contact__c> a_oldRecordMap
     *
     * @Return: N/A
     *******************************************************************************/
    public static void beforeDelete(List<Household_Contact__c> a_oldRecordList,
                                    Map<Id,Household_Contact__c> a_oldRecordMap)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: HseContactLibrary.beforeDelete()');
        
                                                 // Get a Set of Contact Ids
                                                 // from the records being
                                                 // deleted.
        Set<Id> allContactIdSet = new Set<Id>();
        for (Household_Contact__c hc : a_oldRecordList)
        {
            allContactIdSet.add(hc.Contact__c);
        }
        System.debug(LoggingLevel.DEBUG, 'allContactIdSet: ' + allContactIdSet);    

                                                 // Grab a Map of Contact
                                                 // records related to the
                                                 // Household Contact records
                                                 // being inserted.
        Map<Id,Contact> contactMap = getContactMap(allContactIdSet);
        System.debug(LoggingLevel.DEBUG, '*** contactMap: ' + contactMap);

                                                 // The Contact Map must have
                                                 // data to continue  processing.
        if (!contactMap.isEmpty())
        {
                                                 // Re-Iterate through the List
                                                 // of records being deleted
                                                 // and determine which Contact
                                                 // records need to be updated.
            Set<Id> updateContactIdSet = new Set<Id>();
            List<Contact> updateContactList = new List<Contact>();
            for (Household_Contact__c hc : a_oldRecordList)
            {
                if (contactMap.containsKey(hc.Contact__c))
                {
                                                 // Make sure we aren't trying to
                                                 // update a Contact a second time.
                    if (!updateContactIdSet.contains(hc.Contact__c))
                    {
                        updateContactIdSet.add(hc.Contact__c);
                        Contact updateContact = contactMap.get(hc.Contact__c);
                        updateContact.Household_Contact_Email__c = null;
                        updateContactList.add(updateContact);
                    }
                }
            }
            System.debug(LoggingLevel.DEBUG, '*** updateContactList: ' + updateContactList);
            
                                                 // If we have Contact records to
                                                 // update, update them.
            if (updateContactList.size() > 0)
            {
                update(updateContactList);
            }
        }

        System.debug(LoggingLevel.DEBUG, '*** END: HseContactLibrary.beforeDelete()');

    } // End Method: beforeDelete()

/** Private Methods **/

    /******************************************************************************
     * getContactMap
     *
     * @Description: Method to get a Map of Contact records.
     * 
     * @Author: Jason Flippen (DCS)
     * @Date: 02/03/2016
     *
     * @Updated: N/A
     *
     * @Params: Set<Id> a_contactIdSet
     * @Return: Map<Id,Contact> returnMap
     ******************************************************************************/
    private static Map<Id,Contact> getContactMap(Set<Id> a_contactIdSet)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: HseContactLibrary.getContactMap()');

        Map<Id,Contact> returnMap = new Map<Id,Contact>([SELECT Id,
                                                                Household_Contact_Email__c
                                                         FROM   Contact
                                                         WHERE  Id IN :a_contactIdSet]);

        System.debug(LoggingLevel.DEBUG, '*** END: HseContactLibrary.getContactMap()');

        return returnMap;

    } // End Method: getContactMap()

    /******************************************************************************
     * getHouseholdMap
     *
     * @Description: Method to get a Map of Household__c records.
     * 
     * @Author: Jason Flippen (DCS)
     * @Date: 02/03/2016
     *
     * @Updated: N/A
     *
     * @Params: Set<Id> a_householdIdSet
     * @Return: Map<Id,Household__c> returnMap
     ******************************************************************************/
    private static Map<Id,Household__c> getHouseholdMap(Set<Id> a_householdIdSet)
    {
        System.debug(LoggingLevel.DEBUG, '*** START: HseContactLibrary.getHouseholdMap()');

        Map<Id,Household__c> returnMap = new Map<Id,Household__c>([SELECT Id,
                                                                          Household_Contact_Email__c
                                                                   FROM   Household__c
                                                                   WHERE  Id IN :a_householdIdSet]);

        System.debug(LoggingLevel.DEBUG, '*** END: HseContactLibrary.getHouseholdMap()');

        return returnMap;

    } // End Method: getHouseholdMap()

} // End Class