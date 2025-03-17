global class QuoteClone_Flow /**implements Process.Plugin*/{
	public static void doNothing() {}
/** NO LONGER NEEDED
    
    public Id QuoteID;
    public Id OpportunityID;
    public String ClonedQuoteID;
   // public List<Profile_Attributes__c> PACloneList = new List<Profile_Attributes__c>();


    global Process.PluginResult invoke(Process.PluginRequest request) {
        Id QuoteID = (Id) request.inputParameters.get('QuoteID');
        Id OpportunityID = (Id) request.inputParameters.get('OpportunityID');
        
        //Quote qOrig = [SELECT Id, Name, ExpirationDate, Assumptions__c, Description, Pass_Thru__c, Test_Admin__c FROM Quote WHERE Id = :QuoteID];
        Quote qOrig = [SELECT 
                       		Assumptions__c,
                       		Cost_of_Sales__c,
                       		Description,
                       		Discount,
                       		Discount__c,
                       		Display_in_Proposal__c,
                       		Estimated_Expenses__c,
                       		ExpirationDate,
                       		Gross_Margin_Amt__c,
                       		Gross_Margin_Pct__c,
                       		Incentives__c,
                       		Name,
                       		Net_Test_Admin__c,
                       		OpportunityId,
                       		Pass_Thru__c,
                       		Status,
                       		Test_Admin__c,
                       		Time_Spent_Open__c,
                       		Total_Price__c,
                       		Vendor_Partners__c,
							Pricebook2Id
                      	FROM Quote 
                       WHERE Id = :QuoteID];
        //Quote qClone = new Quote();
        Quote qClone = qOrig.clone();
            qClone.Name = qOrig.Name.left(70) + ' - Clone';
            qClone.OpportunityId = OpportunityID;
        	qClone.Status = 'Draft';
            //qClone.ExpirationDate = qOrig.ExpirationDate;
            //qClone.Description = qOrig.Description;
            //qClone.Pass_Thru__c = qOrig.Pass_Thru__c;
            //qClone.Test_Admin__c = qOrig.Test_Admin__c;
        	//qClone.Assumptions__c = qOrig.Assumptions__c;
        insert qClone;

        System.Debug(qClone);
        
        ClonedQuoteID = qClone.Id;

		// CLONE QUOTE LINE ITEMS
		List<QuoteLineItem> lstCloneItems = new List<QuoteLineItem>();
		for(QuoteLineItem objQLI : [SELECT PricebookEntryId,Quantity,UnitPrice,Discount,Description,ServiceDate,Envelope_ID__c,Site__c,Total_Price_Calc__c,Discount_Total__c,Non_Discounted_Total__c,Comments__c,Section_Free__c FROM QuoteLineItem WHERE QuoteId = :QuoteID]) {
			QuoteLineItem objQLIClone = objQLI.clone();
			objQLIClone.QuoteId = ClonedQuoteID;
			lstCloneItems.add(objQLIClone);
		}

		if(!lstCloneItems.isEmpty()) {
			insert lstCloneItems;
		}

        
        
        // Return Value
        Map<String,Object> result = new Map<String,Object>();
            result.put ('ClonedQuoteID',ClonedQuoteID); 

        System.Debug(result);

        return new Process.PluginResult(result); 
    }

   
    global Process.PluginDescribeResult describe() {
        Process.PluginDescribeResult result = new Process.PluginDescribeResult(); 
            result.inputParameters = new List<Process.PluginDescribeResult.InputParameter>{ 
                new Process.PluginDescribeResult.InputParameter('QuoteID', 
                Process.PluginDescribeResult.ParameterType.ID, true),
                new Process.PluginDescribeResult.InputParameter('OpportunityID', 
                Process.PluginDescribeResult.ParameterType.ID, true)
            };
        result.outputParameters = new List<Process.PluginDescribeResult.OutputParameter>{ 
                new Process.Plugindescriberesult.Outputparameter(
                'ClonedQuoteID',
                Process.PluginDescribeResult.ParameterType.ID)
        }; 
        return result;
    }
    */
}