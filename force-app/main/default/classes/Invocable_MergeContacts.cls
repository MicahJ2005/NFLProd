/**
*   Called from the Merge Contacts Lightning Screen FLOW
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name / Description
*   12.16.2022	Sophia Murphy (Demand Chain)		
*               Initial Creation
*   =============================================================================
*/global class Invocable_MergeContacts {

    @InvocableMethod
    public static List<String> mergeContacts(List<ContactId> contactIds)  {

        String masterContactId = contactIds[0].masterContact;
        String contact2Id = contactIds[0].mergeContact2;
        String contact3Id = contactIds[0].mergeContact3;

        Contact masterContact;
        List<Contact> otherContacts = new List<Contact>();

        for(Contact c : [SELECT Id FROM Contact WHERE Id = :masterContactId OR Id = :contact2Id OR Id = :contact3Id]) {
            if(c.Id == masterContactId) {
                masterContact = c;
            }
            if(c.Id == contact2Id || c.Id == contact3Id) {
                otherContacts.add(c);
            }
        }

        // Merge  into master
        Database.MergeResult[] results = Database.merge(masterContact, otherContacts, false);

        List<String> returnVal = new List<String>();
        if(masterContactId != null) {
            returnVal.add(masterContactId);
        }
        return returnVal;
    }
    global class ContactId {
        @InvocableVariable
        global String masterContact;
    
        @InvocableVariable
        global String mergeContact2;
       
        @InvocableVariable
        global String mergeContact3;
      }
 }