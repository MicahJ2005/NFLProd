/**
*   Called from the Merge Accounts Lightning Screen FLOW
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name / Description
*   1.22.2024  Chris Mollet (Demand Chain)    
*               Initial Creation
*   =============================================================================
*/global class Invocable_MergeAccounts {

    @InvocableMethod
    public static List<String> mergeAccounts(List<AccountId> accountIds)  {

        String masterAccountId = accountIds[0].masterAccount;
        String account2Id = accountIds[0].mergeAccount2;
        String account3Id = accountIds[0].mergeAccount3;

        Account masterAccount;
        List<Account> otherAccounts = new List<Account>();

        for(Account a : [SELECT Id FROM Account WHERE Id = :masteraccountId OR Id = :account2Id OR Id = :account3Id]) {
            if(a.Id == masterAccountId) {
                masterAccount = a;
            }
            if(a.Id == account2Id || a.Id == account3Id) {
                otherAccounts.add(a);
            }
        }

        // Merge  into master
        Database.MergeResult[] results = Database.merge(masterAccount, otherAccounts, false);

        List<String> returnVal = new List<String>();
        if(masterAccountId != null) {
            returnVal.add(masterAccountId);
        }
        return returnVal;
    }
    global class AccountId {
        @InvocableVariable
        global String masterAccount;
    
        @InvocableVariable
        global String mergeAccount2;
       
        @InvocableVariable
        global String mergeAccount3;
      }
 }