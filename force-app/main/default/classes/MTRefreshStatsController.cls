public class MTRefreshStatsController  
{
    private final Master_Test__c MTest;

    public MTRefreshStatsController(ApexPages.StandardController scController) 
    {
        this.MTest = (Master_Test__c)scController.getRecord();
    }   

    //This method is also called from MTRefreshStatsBatch
    public static void updateMT(Id mtId) {
        Map<String, Integer> myStats = HostToolLightning.updateTrackerStats_Map(mtId);
        System.debug('DC: ' + myStats);
        Master_Test__c mtUpdate = new Master_Test__c(Id = mtId);
        for(String s : myStats.keySet())
        {
            Integer statNum = myStats.get(s);
            if(s == 'Pending') mtUpdate.Pending__c = statNum;
            if(s == 'Tested')  mtUpdate.Tested__c = statNum;
            if(s == 'PSA')  mtUpdate.PSA__c = statNum;
            if(s == 'PO/FG – PSA')  mtUpdate.PO_FG_PSA__c = statNum;
            if(s == 'Additional Tested')  mtUpdate.Additional_Tested__c = statNum;
            if(s == 'In Progress')  mtUpdate.In_Progress__c = statNum;
            if(s == 'Bonus')  mtUpdate.Bonus__c = statNum;
            if(s == 'Disqualified - Paid')  mtUpdate.Disqualified_Paid__c = statNum;
            if(s == 'Tardy Not Paid')  mtUpdate.Tardy_Not_Paid__c = statNum;
            if(s == 'Disqualified - Not Paid')  mtUpdate.Disqualified_Not_Paid__c = statNum;
            if(s == 'Cancelled')  mtUpdate.Cancelled__c = statNum;
            if(s == 'FPI-Cancelled')  mtUpdate.FPI_Cancelled__c = statNum;
            if(s == 'Void')  mtUpdate.Void__c = statNum;
            if(s == 'No Show')  mtUpdate.No_Show__c = statNum;
            mtUpdate.Stats_Last_Updated__c = DateTime.now();
        }

        update mtUpdate;
        //return mtUpdate;
    }

    public PageReference runMe()
    {
        /**
            The HostToolLightning controller already has all the logic we want - so we will use that.
        */
        /**Map<String, Integer> myStats = HostToolLightning.updateTrackerStats_Map(MTest.Id);
        System.debug('DC: ' + myStats);
        Master_Test__c mtUpdate = new Master_Test__c(Id = this.MTest.Id);
        for(String s : myStats.keySet())
        {
            Integer statNum = myStats.get(s);
            if(s == 'Pending') mtUpdate.Pending__c = statNum;
            if(s == 'Tested')  mtUpdate.Tested__c = statNum;
            if(s == 'PSA')  mtUpdate.PSA__c = statNum;
            if(s == 'PO/FG – PSA')  mtUpdate.PO_FG_PSA__c = statNum;
            if(s == 'Additional Tested')  mtUpdate.Additional_Tested__c = statNum;
            if(s == 'In Progress')  mtUpdate.In_Progress__c = statNum;
            if(s == 'Bonus')  mtUpdate.Bonus__c = statNum;
            if(s == 'Disqualified - Paid')  mtUpdate.Disqualified_Paid__c = statNum;
            if(s == 'Tardy Not Paid')  mtUpdate.Tardy_Not_Paid__c = statNum;
            if(s == 'Disqualified - Not Paid')  mtUpdate.Disqualified_Not_Paid__c = statNum;
            if(s == 'Cancelled')  mtUpdate.Cancelled__c = statNum;
            if(s == 'FPI-Cancelled')  mtUpdate.FPI_Cancelled__c = statNum;
            if(s == 'Void')  mtUpdate.Void__c = statNum;
            if(s == 'No Show')  mtUpdate.No_Show__c = statNum;
        }

        update mtUpdate;
        */
        updateMT(this.MTest.Id);
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Master Test numbers have been updated.  You may need to refresh the page to see the updated numbers.');
        ApexPages.addMessage(myMsg);

        return null;
    }

    public PageReference returnToMT()
    {
        PageReference pr = new PageReference('/' + MTest.Id);
        return pr;
    }
}