({
    doInit : function(component) {
        component.set("v.isOpen", true);
        var actions = [
            { label: 'Delete', name: 'delete' }
        ];
        var headerActions = [];
        component.set('v.qwDataColumns', [
            {label: 'Summary', fieldName: 'Quota_Summary__c', type: 'text', editable : true,sortable:true ,actions:headerActions},
            {label: 'Decipher', fieldName: 'Beacon_Condition__c', type: 'text', editable : true,sortable:true,actions:headerActions},
            {label: 'Min', fieldName: 'Minimum_Respondents__c', type: 'number', editable : true,sortable:true,initialWidth:70},
            {label: 'Max', fieldName: 'Maximum_Respondents__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:90},
            {label: 'Scheduled', fieldName: 'Total_Scheduled__c', type: 'number', editable : false,sortable:true,actions:headerActions,initialWidth:70},
            {label: 'Master Quota Group', fieldName: 'MQG__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:70},
            {label: 'Open to Recruit', fieldName: 'IsOpen__c', type: 'boolean', editable : true,sortable:true,actions:headerActions},
            {label: 'Secondary Quota', fieldName: 'IsTrackingOnly__c', type: 'boolean', editable : true,sortable:true,actions:headerActions}
        ]);
    },
	openModal : function(component, event, helper) {
		//we are fetching parameters from event that calls this method.
		var params = event.getParam( 'arguments' ) || event.getParams();
		component.set('v.isOpen',params.openModal);
	},
 
	closeModal : function(component, event, helper) {
		component.set('v.isOpen',false);
	},
 
    handleOnSubmit_singleSession : function(component, event, helper){
        debugger;
        var fields = event.getParam('fields');
        var theSession = new Object();
        console.log(component.get("v.MSID"));
        theSession.Related_Test__c = component.get("v.MSID");
        for (let key in fields) {
            if (fields[key] != null) {
                theSession[key] = fields[key];
            }            
        }
        var currentSelectedRows = component.get('v.currentSelectedRows');
        var theSessionQuotaList = [];
        for(let key in currentSelectedRows) {
            var theSessionQuota = new Object();
            var currentRow = currentSelectedRows[key];
            for (let key2 in currentRow) {
                if (key2 == 'Maximum_Respondents__c') {
                    theSessionQuota[key2] = currentRow[key2];
                }
                if (key2 == 'Minimum_Respondents__c') {
                    theSessionQuota[key2] = currentRow[key2];
                }
                if (key2 == 'IsOpen__c') {
                    theSessionQuota[key2] = currentRow[key2];
                }
                if (key2 == 'MQG__c') {
                    theSessionQuota['SQGManual__c'] = currentRow[key2];
                }
                if (key2 == 'Id') {
                    theSessionQuota['Master_Quota__c'] = currentRow[key2];
                }
                
            }
            theSessionQuotaList.push(theSessionQuota);
        }

        var action = component.get("c.addSessionAndQuota");
		action.setParams({ 'theSession' : theSession , 'theSessionQuotaList' : theSessionQuotaList});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				debugger;
				//if update is successful
				if(response.getReturnValue() === true){
                    //this.showToast(component,"Record(s) Added",true);
                    //this.doInit(component);
                    //this.rfOnLoad(component);
                    //this.mqOnLoad(component);
                    debugger;
		            component.set('v.isOpen',false);
				}else{
					//this.showToast(component,"Failed to save lookup values",false);
				}
			}
			else if (state === "INCOMPLETE") {
				// do something
				debugger;
			}
			else if (state === "ERROR") {
				debugger;
				var errors = response.getError();
				if (errors) {
					helper.showToast(component,"Error in saving lookup values",false);
					if (errors[0] && errors[0].message) {
						console.log("Error message: " + 
									errors[0].message);
					}
				} else {
					console.log("Unknown error");
				}
			}
		});
		$A.enqueueAction(action);	
    },
    handleSaveSuccess: function(component, event, helper) {
        debugger;
		//Handle the action when save button is clicked you can write your custom logic here.
        alert('Hello World');
        // var data = component.get("v.qwData");
        // component.log(data);
	},
    handleOnError: function(component, event, helper) {
		//Handle the action when save button is clicked you can write your custom logic here.
        alert('Hello Failure');
	},
    selectEvent_singleSession : function(component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        component.set('v.currentSelectedRows', selectedRows);
    }
})