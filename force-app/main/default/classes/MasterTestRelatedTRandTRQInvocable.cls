/**
 * @description       : Invocable Class (called from a Flow and Record Action) for touching /
 *                    : updating Test Respondents and Test Respondent Quotas related to a
 *                    : particular Master Test record.
 * @author            : James Loghry (Demand Chain)
 * @group             : Demand Chain
 * @last modified on  : 05-07-2021
 * @last modified by  : James Loghry (Demand Chain)
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   05-06-2021   James Loghry (Demand Chain)   Initial Version
**/
public class MasterTestRelatedTRandTRQInvocable {
    @InvocableMethod(label='Update Master Test Related Records' description='Update related test respondents and test repsondent quotas')
    public static void updateRelatedRecords(List<Id> masterTestId){
        //MasterTestRelatedTRBatch calls MasterTestRelatedTRQBatch from it's finish method.
        Database.executeBatch(new MasterTestRelatedTRBatch(masterTestId.get(0), 50),50);
    }
}