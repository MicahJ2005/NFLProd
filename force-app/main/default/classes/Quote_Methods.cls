//11.20.2020	Sophia Murphy (Demand Chain)
//				Cleaned up old/commented out code
public with sharing class Quote_Methods {
	public static void doNothing() {}
/** NO LONGER NEEDED
    
	public static void Quote_Status_Approved (list<Quote> lstQuote){

        /*********************************************
        *   Goals of this class:
        *   - Validation 1:  A Design Overview must be attached to the Quote before proceeding
        *   - Case 1:  When a Quote is "Approved"
        *       - Reject all other Quotes
        *           - Except if there is already an "Approved" Quote, change to "Superceded"
        *       - Copy financials to parent Opp
        *       - Copy Quote "Assumptions" of Approved Quote to all Master Tests linked to Parent Opp
        *       - Link Design Overview of "Approved" Quote via PDJ to parent Opportunity and all MTs linked to Opp
        *       
        *********************************************
        Set<String> setScopeQuoteStatuses = new Set<String>();
        setScopeQuoteStatuses.add('Approved');
		
        ///////////////////////////
        // Get Data Scope Sets
        ///////////////////////////
        Map<Id, hClsOpportunity> mapOpportunities = new Map<Id, hClsOpportunity>();
        //Map<Id, PD_Junction__c> mapPDJs = new Map<Id, PD_Junction__c>();
        //List<PD_Junction__c> lstInsertPDJs = new List<PD_Junction__c>();

        // Get all Opp Ids
        Set<Id> setScopeOpportunityIds = new Set<Id>();
        for(Quote qte : (List<Quote>)trigger.new) {
            setScopeOpportunityIds.add(qte.OpportunityId);
        }

        // Get all Master Tests linked to the Opp Ids
        Map<Id, List<Master_Test__c>> mapOppMTs = new Map<Id, List<Master_Test__c>>();
        for(Opportunity opp : [SELECT Id, (SELECT Id, Assumptions__c FROM Master_Tests__r) FROM Opportunity WHERE Id IN :setScopeOpportunityIds]) {
            mapOppMTs.put(opp.Id, opp.Master_Tests__r);
            
        }

        // Put all Opps and Quotes in the master Map
        for(Opportunity oppScope : [SELECT Id, Amount, StageName, Estimated_Expenses__c, 
                                        Test_Admin__c, Discount__c, Incentives__c, Bid_Vendor_Partner_Costs__c,
                                        Bid_Cost_of_Sales__c, Bid_Pass_Thru__c, Total_CSD_Estimated_hours__c, Total_Fielding_Office_Estimated_hours__c,
                                    	Total_Fielding_Site_Estimated_hours__c, Total_PM_Estimated_hours__c, Total_Recruiting_Estimated_hours__c,
                                    	Total_Stats_Estimated_hours__c, Total_STeam_Estimated_hours__c, Name_of_Approved_Quote__c, (SELECT Id, Name, Status, Quote_CSD_Estimated_Hours__c,
                                                                                                         Quote_Fielding_Office_Estimated_hours__c, Quote_Fielding_Site_Estimated_hours__c,
                                                                                                         Quote_PM_Estimated_hours__c, Quote_Recruiting_Estimated_hours__c,
                                                                                                         Quote_Stats_Estimated_hours__c, Quote_STeam_Estimated_hours__c FROM Quotes)
                                        FROM Opportunity WHERE Id IN :setScopeOpportunityIds]) {
            mapOpportunities.put(oppScope.Id, new hClsOpportunity(oppScope, oppScope.Quotes));
        }

        ///////////////////////////
        // Start Logic
        ///////////////////////////
        //
        for(Quote qte : (List<Quote>)trigger.new) {
            if(setScopeQuoteStatuses.contains(qte.Status)) {

                // 1:  Handle Sibling Quote Statuses
                for(Quote qteSibling : mapOpportunities.get(qte.OpportunityId).lstQuotes) {
                    
                    if(qteSibling.Id != qte.Id) {

                        // Set any previously Approved Quotes to be "Superceded"
                        if(qteSibling.Status == 'Approved') { qteSibling.Status = 'Superceded'; }

                        // Reject all other non-superceded quotes
                        if(qteSibling.Status != 'Superceded') { qteSibling.Status = 'Rejected'; }
                    }
                }

                    // 2:  Copy Financials of Approved Quote to Opportunity
                mapOpportunities.get(qte.OpportunityId).opp.Amount = qte.Total_Price__c;
                {mapOpportunities.get(qte.OpportunityId).opp.StageName = 'Closed Won';}
                mapOpportunities.get(qte.OpportunityId).opp.Estimated_Expenses__c = qte.Estimated_Expenses__c;
                mapOpportunities.get(qte.OpportunityId).opp.Test_Admin__c = qte.Test_Admin__c;
                mapOpportunities.get(qte.OpportunityId).opp.Discount__c = qte.Discount__c;
                mapOpportunities.get(qte.OpportunityId).opp.Incentives__c = qte.Incentives__c;
                mapOpportunities.get(qte.OpportunityId).opp.Bid_Vendor_Partner_Costs__c = qte.Vendor_Partner_Cost__c;
                mapOpportunities.get(qte.OpportunityId).opp.Bid_Cost_of_Sales__c = qte.Cost_Of_Sales__c;
                mapOpportunities.get(qte.OpportunityId).opp.Name_of_Approved_Quote__c = qte.Name; //20180620 added new field ot help the execution team know which quote was approved.
                mapOpportunities.get(qte.OpportunityId).opp.Bid_Pass_Thru__c = qte.Pass_Thru_Calc__c;

                // 3:  Copy Quote Assumptions to All MTs for the attached Opp
                for(Master_Test__c mt : mapOppMTs.get(qte.OpportunityId)) {
                    mt.Assumptions__c = qte.Assumptions__c;    
                }

                ////// 4: Copy Estimated hours from Approved Quote to the Opportunity
                mapOpportunities.get(qte.OpportunityId).opp.Total_CSD_Estimated_hours__c = qte.Quote_CSD_Estimated_Hours__c;
                mapOpportunities.get(qte.OpportunityId).opp.Total_PM_Estimated_hours__c = qte.Quote_PM_Estimated_Hours__c;
                mapOpportunities.get(qte.OpportunityId).opp.Total_STeam_Estimated_hours__c = qte.Quote_STeam_Estimated_Hours__c;
                mapOpportunities.get(qte.OpportunityId).opp.Total_Recruiting_Estimated_hours__c = qte.Quote_Recruiting_Estimated_Hours__c;
                mapOpportunities.get(qte.OpportunityId).opp.Total_Fielding_Office_Estimated_hours__c = qte.Quote_Fielding_Office_Estimated_Hours__c;
                mapOpportunities.get(qte.OpportunityId).opp.Total_Fielding_Site_Estimated_hours__c = qte.Quote_Fielding_Site_Estimated_Hours__c;
                mapOpportunities.get(qte.OpportunityId).opp.Total_Stats_Estimated_hours__c = qte.Quote_Stats_Estimated_Hours__c;
                //5.18.2020 - added - Sophia Murphy (Demand Chain)
                mapOpportunities.get(qte.OpportunityId).opp.Total_Recruiting__c = qte.Quote_Recruiting_Estimated__c;
            }
        }

        ///////////////////////////
        // DML
        ///////////////////////////
        
        // Opportunities and Sibling Quotes
        List<Opportunity> lstUpdateOpportunities = new List<Opportunity>();
        List<Quote> lstUpdateQuotes = new List<Quote>();
        for(hClsOpportunity clsOpp : mapOpportunities.values()) {
            lstUpdateOpportunities.add(clsOpp.opp);
            for(Quote qteSibling : clsOpp.lstQuotes) {
                if(!trigger.newMap.keyset().contains(qteSibling.Id)) { lstUpdateQuotes.add(qteSibling); }
            }
        }
        if(lstUpdateOpportunities.size() > 0) { update lstUpdateOpportunities; }
        
        //04.29.2020 - Sophia Murphy (Demand Chain)
        //Getting errors when this is combined with the Quote Date Stage flow
        //Updated to "update" these as "new" records
        if(lstUpdateQuotes.size() > 0) { update lstUpdateQuotes; }
        
        // PDJs
        //if(lstInsertPDJs.size() > 0) { insert lstInsertPDJs; }

    }

    /////////////////////////
    // Inner / Helper Classes
    /////////////////////////
    public class hClsOpportunity {
        public Opportunity opp {get;set;}
        public List<Quote> lstQuotes {get;set;}
        public hClsOpportunity(Opportunity passOppty, List<Quote> passQuoteList) {
            opp = passOppty;
            lstQuotes = passQuoteList;
        }
    }
    public static void Quote_Status_Changed (list<Quote> lstQuote, map<id,Quote> mapOldQuotes){
        integer statusLevel = 0;
        for (quote q : lstQuote){
            if(mapOldQuotes == null || mapOldQuotes.get(q.id).Status != q.Status){
                switch on q.Status {
                    when 'Draft'{
                        q.Date_Draft_Status__c = date.today();
                        q.Date_Bidding_Status__c = null;
                        q.Date_Bid_Complete_Status__c = null;
                        q.Date_Presented_Status__c = null;
                        q.Date_Sent_For_Signature__c = null;
                        q.Date_Proposal_Signed__c = null;
                        q.Date_Approved_Status__c = null;
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Bidding'{
                        if(q.Date_Draft_Status__c == null){q.Date_Draft_Status__c = date.today();}
                        q.Date_Bidding_Status__c = date.today();
                        q.Date_Bid_Complete_Status__c = null;
                        q.Date_Presented_Status__c = null;
                        q.Date_Sent_For_Signature__c = null;
                        q.Date_Proposal_Signed__c = null;
                        q.Date_Approved_Status__c = null;
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Bid Complete'{
                        if(q.Date_Draft_Status__c == null){q.Date_Draft_Status__c = date.today();}
                        if(q.Date_Bidding_Status__c == null){q.Date_Bidding_Status__c = date.today();}
                        q.Date_Bid_Complete_Status__c = date.today();
                        q.Date_Presented_Status__c = null;
                        q.Date_Sent_For_Signature__c = null;
                        q.Date_Proposal_Signed__c = null;
                        q.Date_Approved_Status__c = null;
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Presented'{
                        if(q.Date_Draft_Status__c == null){q.Date_Draft_Status__c = date.today();}
                        if(q.Date_Bidding_Status__c == null){q.Date_Bidding_Status__c = date.today();}
                        if(q.Date_Bid_Complete_Status__c == null){q.Date_Bid_Complete_Status__c = date.today();}
                        q.Date_Presented_Status__c = date.today();
                        q.Date_Sent_For_Signature__c = null;
                        q.Date_Proposal_Signed__c = null;
                        q.Date_Approved_Status__c = null;
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Sent For Signature'{
                        if(q.Date_Draft_Status__c == null){q.Date_Draft_Status__c = date.today();}
                        if(q.Date_Bidding_Status__c == null){q.Date_Bidding_Status__c = date.today();}
                        if(q.Date_Bid_Complete_Status__c == null){q.Date_Bid_Complete_Status__c = date.today();}
                        if(q.Date_Presented_Status__c == null){q.Date_Presented_Status__c = date.today();}
                        q.Date_Sent_For_Signature__c = date.today();
                        q.Date_Proposal_Signed__c = null;
                        q.Date_Approved_Status__c = null;
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Proposal Signed'{
                        if(q.Date_Draft_Status__c == null){q.Date_Draft_Status__c = date.today();}
                        if(q.Date_Bidding_Status__c == null){q.Date_Bidding_Status__c = date.today();}
                        if(q.Date_Bid_Complete_Status__c == null){q.Date_Bid_Complete_Status__c = date.today();}
                        if(q.Date_Presented_Status__c == null){q.Date_Presented_Status__c = date.today();}
                        if(q.Date_Sent_For_Signature__c == null){q.Date_Sent_For_Signature__c = date.today();}
                        q.Date_Proposal_Signed__c = date.today();
                        q.Date_Approved_Status__c = null;
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Approved'{
                        if(q.Date_Draft_Status__c == null){q.Date_Draft_Status__c = date.today();}
                        if(q.Date_Bidding_Status__c == null){q.Date_Bidding_Status__c = date.today();}
                        if(q.Date_Bid_Complete_Status__c == null){q.Date_Bid_Complete_Status__c = date.today();}
                        if(q.Date_Presented_Status__c == null){q.Date_Presented_Status__c = date.today();}
                        if(q.Date_Sent_For_Signature__c == null){q.Date_Sent_For_Signature__c = date.today();}
                        if(q.Date_Proposal_Signed__c == null){q.Date_Proposal_Signed__c = date.today();}
                        q.Date_Approved_Status__c = date.today();
                        q.Date_Rejected_Status__c = null;
                        q.Date_Superceded_Status__c = null;
                    }
                    when 'Rejected'{
                        q.Date_Rejected_Status__c = date.today();
                        //q.Date_Superceded_Status__c = null;
                    }
                    when 'Superceded'{
                        q.Date_Superceded_Status__c = date.today();
                    }
                }
            }
        }
    }*/
}