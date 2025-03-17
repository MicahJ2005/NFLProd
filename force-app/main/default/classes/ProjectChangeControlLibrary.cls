//5.18.2020 - Added Recruiting dollars - Sophia Murphy (Demand Chain)
public with sharing class ProjectChangeControlLibrary {
    public static void doNothing() {}
    /** Commented out - PCCs are no longer in use 

    /**
     * when a PCC is entered or edited, 
     * Step 1) add up all PCCs estimated hours by dept NOT 'approved' or 'DECLINED', 
     * Step 2) then find the estimated hours per dept from the approved quote. 
     * Step 3) add all estimated hours per dept (from approved quote and ALL PCCs) and update the opportunity
     * Step 4) place all values from CQ PCC onto the PCC  
     * 
    
    public static void PCCupdate(List<Project_Change_Control__c> lstPCCs){
        
        Set<Id> setOpportunityIds = new Set<Id>();
        for(Project_Change_Control__c objPCC : lstPCCS) {
            setOpportunityIds.add(objPCC.Opportunity__c);
        }
        
        // search for the total PCCs that are NOT approved or NOT declined.
		System.Debug('Starting search for ' + setOpportunityIds);
        
        Set<String> setApprovalsStatus = new Set<String>();
        setApprovalsStatus.add('Approved');
        setApprovalsStatus.add('Declined');
        //step 1
        List<AggregateResult> lstPCCEstimatedHours = [
            							SELECT 
            								sum(Total_CSD_Estimated_hours__c) TCSD,
                                        	sum(Total_Fielding_Office_Estimated_hours__c) TFO,
                                        	sum(Total_Fielding_Site_Estimated_hours__c) TFS,
                                        	sum(Total_PM_Estimated_hours__c) TPM,
                                        	sum(Total_Recruiting_Estimated_hours__c) TREC,
                                        	sum(Total_Stats_Estimated_hours__c) TSTATS,
                                        	sum(Total_STeam_Estimated_hours__c) TSTEAM,
                                        	sum(Total_Recruiting__c) TRECDLRS,
            								Opportunity__c
                                        FROM Project_Change_Control__c
                                                     Where Opportunity__c IN :setOpportunityIds AND Client_Approval__c NOT IN :setApprovalsStatus
            								GROUP BY Opportunity__c
        								];
        
        Map<Id, AggregateResult> mapOpportunityTotals = new Map<Id, AggregateResult>();
        for(AggregateResult objAR : lstPCCEstimatedHours) {
            mapOpportunityTotals.put((Id)objAR.get('Opportunity__c'), objAR);
        }
        //search for the approved quote and get the hours from that quote.
        //Step 2
        List<AggregateResult> lstqtOhrs = [
            							SELECT
                                            sum(Quote_CSD_Estimated_Hours__c) QTCSD,
                                            sum(Quote_Fielding_Office_Estimated_hours__c) QTFO,
                                            sum(Quote_Fielding_Site_Estimated_hours__c) QTFS,
                                            sum(Quote_PM_Estimated_hours__c) QTPM,
                                            sum(Quote_Recruiting_Estimated_hours__c) QTREC,
                                            sum(Quote_Stats_Estimated_hours__c) QTSTATS,
                                            sum(Quote_STeam_Estimated_hours__c) QTSTEAM,
                                            sum(Quote_Recruiting_Estimated__c) QTRECDLRS,
            								OpportunityId
                                       FROM Quote
                                         WHERE OpportunityId IN :setOpportunityIds AND status = 'Approved'
            							 GROUP BY OpportunityId
        								];
        Map<Id, AggregateResult> mapQuoteTotals = new Map<Id, AggregateResult>();
        for(AggregateResult objAR : lstqtOhrs) {
            mapQuoteTotals.put((Id)objAR.get('OpportunityId'), objAR);
        }
        
        // Do Results Stuff
        List<Opportunity> lstUpdateOpps = new List<Opportunity>();
        for(Id objId : setOpportunityIds) {
            Opportunity objOpp = new Opportunity(Id=objId);
            
            // Step 3
            // Instantiate math stuff
            Decimal intCSD = 0;
            Decimal intFO = 0;
            Decimal intSite = 0;
            Decimal intPM = 0;
            Decimal intREC = 0;
            Decimal intSTATS = 0;
            Decimal intSTEAM = 0;
            Decimal intRECDLRS = 0;
            
            // Get PCC Sums
            //accounnt for blank values and not throw errors for null values
            if(mapOpportunityTotals.containsKey(objId)) {
                if(mapOpportunityTotals.get(objId).get('TCSD') != null)
                {
                    intCSD = intCSD + (Decimal)mapOpportunityTotals.get(objId).get('TCSD');
                }
                if(mapOpportunityTotals.get(objId).get('TFO') != null)
                {
                    intFO = intFO + (Decimal)mapOpportunityTotals.get(objId).get('TFO');
                }
                if(mapOpportunityTotals.get(objId).get('TFS') != null)
                {
                    intSite = intSite + (Decimal)mapOpportunityTotals.get(objId).get('TFS');
                }
                if(mapOpportunityTotals.get(objId).get('TPM') != null)
                {
                    intPM = intPM + (Decimal)mapOpportunityTotals.get(objId).get('TPM');
                }
                if(mapOpportunityTotals.get(objId).get('TREC') != null)
                {
                    intREC = intREC + (Decimal)mapOpportunityTotals.get(objId).get('TREC');
                }
                if(mapOpportunityTotals.get(objId).get('TSTATS') != null)
                {
                    intSTATS = intSTATS + (Decimal)mapOpportunityTotals.get(objId).get('TSTATS');
                }
                if(mapOpportunityTotals.get(objId).get('TSTEAM') != null)
                {
                    intSTEAM = intSTEAM + (Decimal)mapOpportunityTotals.get(objId).get('TSTEAM');
                }
                if(mapOpportunityTotals.get(objId).get('TRECDLRS') != null)
                {
                    intRECDLRS = intRECDLRS + (Decimal)mapOpportunityTotals.get(objId).get('TRECDLRS');
                }
                
            }
            // Get Quote Sums
            //accounnt for blank values and not throw errors for null values
            if(mapQuoteTotals.containsKey(objId)) {
                if(mapQuoteTotals.get(objId).get('QTCSD') != null)
                {
                    intCSD = intCSD + (Decimal)mapQuoteTotals.get(objId).get('QTCSD');
                }
                if(mapQuoteTotals.get(objId).get('QTFO') != null)
                {
                    intFO = intFO + (Decimal)mapQuoteTotals.get(objId).get('QTFO');
                }
                if(mapQuoteTotals.get(objId).get('QTFS') != null)
                {
                    intSite = intSite + (Decimal)mapQuoteTotals.get(objId).get('QTFS');
                }
                if(mapQuoteTotals.get(objId).get('QTPM') != null)
                {
                    intPM = intPM + (Decimal)mapQuoteTotals.get(objId).get('QTPM');
                }
                if(mapQuoteTotals.get(objId).get('QTREC') != null)
                {
                    intREC = intREC + (Decimal)mapQuoteTotals.get(objId).get('QTREC');
                }
                if(mapQuoteTotals.get(objId).get('QTSTATS') != null)
                {
                    intSTATS = intSTATS + (Decimal)mapQuoteTotals.get(objId).get('QTSTATS');
                }
                if(mapQuoteTotals.get(objId).get('QTSTEAM') != null)
                {
                    intSTEAM = intSTEAM + (Decimal)mapQuoteTotals.get(objId).get('QTSTEAM');
                }
                if(mapQuoteTotals.get(objId).get('QTRECDLRS') != null)
                {
                    intRECDLRS = intRECDLRS + (Decimal)mapQuoteTotals.get(objId).get('QTRECDLRS');
                }
                
            }
            
            //set all values we just calculated to the Opportunity fields.
            objOpp.Total_CSD_Estimated_hours__c = intCSD;
            objOpp.Total_Fielding_Office_Estimated_hours__c = intFO;
            objOpp.Total_Fielding_Site_Estimated_hours__c = intSite;
            objOpp.Total_PM_Estimated_hours__c = intPM;
            objOpp.Total_Recruiting_Estimated_hours__c = intREC;
            objOpp.Total_Stats_Estimated_hours__c = intSTATS;
            objOpp.Total_STeam_Estimated_hours__c = intSTEAM;
            objOpp.Total_Recruiting__c = intRECDLRS;
             
            lstUpdateOpps.add(objOpp);
            
        }
        
        if(!lstUpdateOpps.isEmpty()) {
            update lstUpdateOpps;
        }
    }
    
    // END OF CLASS
    */
}