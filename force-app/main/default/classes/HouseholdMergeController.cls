public with sharing class HouseholdMergeController {
/**
*   {Purpose}  �  Controller for VF Household Merge page
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140514    Andy Boettcher (DCS)    Created
*   =============================================================================
*/

	private final sObject mysObject;
    public Household_Contact__c hhcSourceLookup {get;set;}
    public Household_Contact__c hhcTargetLookup {get;set;}
    public Household__c hseTarget {get;set;}

    ///////////////////////////////////
    // Constructors
    /////////////////////////////////// 
    public HouseholdMergeController(ApexPages.StandardController stdController) {
        this.mysObject = (sObject)stdController.getRecord();
        hhcSourceLookup = new Household_Contact__c(Household__c=(Id)mysObject.get('Id'));
        hhcTargetLookup = new Household_Contact__c();
        hseTarget = new Household__c();
    }

    ///////////////////////////////////
    // GET / SET
    ///////////////////////////////////
    public Household__c householdSource {
        get{
            return [SELECT Id, Name, MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c,
                Head_Of_Household__r.Name 
                FROM Household__c
                WHERE Id = :hhcSourceLookup.Household__c];

        }
        set{ householdSource = value; }
    }

    public Household__c householdTarget {
        get{
            if(hhcTargetLookup.Household__c != null) {
                return [SELECT Id, Name, MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c,
                    Head_Of_Household__r.Name 
                    FROM Household__c
                    WHERE Id = :hhcTargetLookup.Household__c];
            } else {
                return new Household__c();
            }

        }
        set{ householdTarget = value; }
    }

    public List<Household_Contact__c> householdSourceMembers {
        get {
            return [SELECT Id, Contact__c, Contact_Age__c,
                    Contact__r.Name, Contact__r.Lastname, Status__c 
                    FROM Household_Contact__c 
                    WHERE Household__c = :hhcSourceLookup.Household__c];
        }
        set { householdSourceMembers = value; }
    }

    public List<Household_Contact__c> householdTargetMembers {
        get {
            return [SELECT Id, Contact__c, Contact_Age__c,
                    Contact__r.Name, Contact__r.Lastname, Status__c 
                    FROM Household_Contact__c 
                    WHERE Household__c = :hhcTargetLookup.Household__c];
        }
        set { householdSourceMembers = value; }
    }

    ///////////////////////////////////
    // Action Methods
    ///////////////////////////////////
    public pageReference mergeHouseholds() {

        if(hhcSourceLookup.Household__c == null && hhcTargetLookup.Household__c == null) {
            return null;
        }

        Map<Id, Household_Contact__c> mapContacts = new Map<Id, Household_Contact__c>([
            SELECT Id, Household__c 
            FROM Household_Contact__c 
            WHERE Household__c = :hhcSourceLookup.Household__c
        ]);
        //List<Household_Contact__c> lstContacts = [SELECT Id, Household__c FROM Household_Contact__c 
        //                                            WHERE Household__c = :hhcSourceLookup.Household__c];

        for(Household_Contact__c hhc : mapContacts.values()) {
            hhc.Household__c = hhcTargetLookup.Household__c;
        }
        update mapContacts.values();

        // Send updated HCs via SQS
        UtilityMethods.sendSAPIWrapper('FPIHouseholdContact', 'update', mapContacts.keyset());

        Household__c hseDelete = new Household__c(Id=hhcSourceLookup.Household__c);
        delete hseDelete;

        PageReference prRef = new PageReference('/' + hhcTargetLookup.Household__c);
        prRef.setRedirect(true);
        return prRef;

    }
}