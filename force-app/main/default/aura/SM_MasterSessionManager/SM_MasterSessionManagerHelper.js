({
	doInit: function (component) {
		//this.showToast(component,'Hello!',true);
		//get the data
		var action = component.get("c.getSessions");
		action.setParams({ masterTestID : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var retVal = response.getReturnValue();
				component.set("v.smMasterTest",retVal.MasterTest);
                component.set("v.smData",retVal.lSessions);
				component.set("v.smTestLocations",retVal.TestLocNames);
                component.set("v.bulkSessionsObject",retVal.initialBulkSessionsObj);
				
				var actions = [
					{ label: 'Edit Details', name: 'show_details' },
					{ label: 'Add Before', name: 'add_before' },
					{ label: 'Add After', name: 'add_after' },
				    { label: 'Delete', name: 'delete' }
		        ];
				var headerActions = [];
					/*
					{
						label: 'All',
						checked: true,
						name:'All'
					},
					{
						label: 'Completed',
						checked: false,
						name:'Completed'
					},
					{
						label: 'In Completed',
						checked: false,
						name:'In Completed'
					},
					{
						label: 'Pre Order',
						checked: false,
						name:'Pre Order'
					}
				]; 
				*/
				component.set('v.smDataColumns', [
				    { type: 'action', typeAttributes: { rowActions: actions } } ,
					{label: 'Name', fieldName: 'Name', type: 'text', editable : true,sortable:true,initialWidth:260 ,actions:headerActions},
		            //{label: 'Link', fieldName: 'Id', type: 'url', typeAttributes: { target: '_blank', label: 'View'}, editable:false, sortable:false, actions:headerActions},
                    {label: 'Start', fieldName: 'Session_Start__c', type: 'date', editable : true, initialWidth: 198, typeAttributes:{year:'numeric', month:'numeric', day:'numeric', hour:'2-digit', minute:'2-digit', timeZoneName:'short'},sortable:true,actions:headerActions},
                    {label: 'End', fieldName: 'Session_End__c', type: 'date', editable : true, initialWidth: 198, typeAttributes:{year:'numeric', month:'numeric', day:'numeric', hour:'2-digit', minute:'2-digit', timeZoneName:'short'},sortable:true},
				    {label: 'Min', fieldName: 'Min_to_Show__c', type: 'number', editable : true,sortable:true,initialWidth:60},
				    {label: 'Max', fieldName: 'Max_to_Show__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:60},
				    {label: 'Goal', fieldName: 'Recruits_Per_Session__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:60},
                    {label: 'Test Type', initialWidth: 220, fieldName: 'Test_Type__c', type: 'button', editable : true,sortable:true, typeAttributes : { label : {fieldName : 'Test_Type__c'}, name: 'edit_picklist_testtype', iconName : 'utility:edit', class:'data-table-button slds-truncate'}},
                    {label: 'Research Type', initialWidth: 220, fieldName: 'Research_Type__c', type: 'button', editable : true,sortable:true, typeAttributes : { label : {fieldName : 'Research_Type__c'}, name: 'edit_picklist_researchtype', iconName : 'utility:edit', class:'data-table-button slds-truncate'}},
                    {label: 'Test Location', initialWidth: 220, fieldName: 'Testing_Location_Name__c', type: 'button', editable : true,sortable:true, typeAttributes : { label : {fieldName : 'Testing_Location_Name__c'}, name: 'edit_lookup_location', iconName : 'utility:edit', class:'data-table-button slds-truncate'}},
				    {label: 'Incentive', fieldName: 'Check_Amount__c', type: 'currency', editable : true,sortable:true,actions:headerActions,initialWidth:100},
				    {label: 'Linked?', fieldName: 'Is_Linked__c', type: 'boolean', editable : false,sortable:true,actions:headerActions,initialWidth:60},
				    {label: 'Articulation?', fieldName: 'IsArticulationNeeded__c', type: 'boolean', editable : true,sortable:true,actions:headerActions,initialWidth:60},
					{label: 'Recruiting?', fieldName: 'IsAvailableToRecruit__c', type: 'boolean', editable : true,sortable:true,actions:headerActions,initialWidth:60},
		        	{label: 'Recruiting Notes', fieldName: 'Recruiting_Notes__c', type: 'text', editable : true,sortable:true ,actions:headerActions,initialWidth:200},
		        	{label: 'Spec. Instruc. for Resp.', fieldName: 'Special_Instructions_for_Respondents__c', type: 'text', editable : true,sortable:true ,actions:headerActions,initialWidth:200}
				]);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
		var bulkSession = component.get('v.bulkSessionsObject');
		console.log(bulkSession);
		// bulkSession.sessionStart = '8:00 AM';
		// component.set('v.bulkSessionsObject', bulkSession);
		$A.enqueueAction(action);
	},
	sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.smData");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.smData", data);
    },
	showIt: function(component,componentId) {
	    var modal = component.find(componentId);
		console.log(modal);
		console.log(Object.keys(modal));
		console.log(Object.values(modal));
	    $A.util.removeClass(modal,'slds-hide');
	    $A.util.addClass(modal,'slds-open');
	},
	hideIt: function(component,componentId) {
	    var modal = component.find(componentId);
	    $A.util.addClass(modal,'slds-hide');
	    $A.util.removeClass(modal,'slds-open');
	},
	rfOnLoad: function(component, event){
		//get the Quotas data
		var action = component.get("c.getSessionQuotas");
		action.setParams({ sessionID : component.get("v.editSessionModalID") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.smQuotasData",response.getReturnValue());
				var actions = [
				    { label: 'Delete', name: 'delete' }
		        ];
				var headerActions = [];
				component.set('v.smQuotasDataColumns', [
				    { type: 'action', typeAttributes: { rowActions: actions } } ,
		            {label: 'MQ Description', fieldName: 'Master_Quota_Description__c', type: 'text', editable : false,sortable:true ,actions:headerActions},
				    {label: 'Open for Recruiting', fieldName: 'IsOpen__c', type: 'boolean', editable : true, typeAttributes:{year:'numeric', month:'numeric', day:'numeric', hour:'2-digit', minute:'2-digit', timeZoneName:'short'},sortable:true,actions:headerActions},
				    {label: 'Scheduled Respondents', fieldName: 'Scheduled_Respondents__c', type: 'number', editable : true, typeAttributes:{year:'numeric', month:'numeric', day:'numeric', hour:'2-digit', minute:'2-digit', timeZoneName:'short'},sortable:true},
				    {label: 'Min', fieldName: 'Minimum_Respondents__c', type: 'number', editable : true,sortable:true,initialWidth:70},
				    {label: 'Max', fieldName: 'Maximum_Respondents__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:90},
				    {label: 'MQ Group', fieldName: 'MQG__c', type: 'number', editable : false,sortable:true,actions:headerActions}
				]);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
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
	rfOnLoadEdit: function(component, editRecordID){
		//get the Quotas data
		var action = component.get("c.getSessionQuotas");
		action.setParams({ sessionID : editRecordID });
        action.setCallback(this, function(response) {
			debugger;
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.smQuotasData",response.getReturnValue());
				console.log(response.getReturnValue());
				var actions = [
				    { label: 'Delete', name: 'delete' }
		        ];
				var headerActions = [];
				component.set('v.smQuotasDataColumns', [
				    { type: 'action', typeAttributes: { rowActions: actions } } ,
		            {label: 'MQ Description', fieldName: 'Master_Quota_Description__c', type: 'text', editable : false,sortable:true ,actions:headerActions},
				    {label: 'Open for Recruiting', fieldName: 'IsOpen__c', type: 'boolean', editable : true, typeAttributes:{year:'numeric', month:'numeric', day:'numeric', hour:'2-digit', minute:'2-digit', timeZoneName:'short'},sortable:true,actions:headerActions},
				    {label: 'Scheduled Respondents', fieldName: 'Scheduled_Respondents__c', type: 'number', editable : true, typeAttributes:{year:'numeric', month:'numeric', day:'numeric', hour:'2-digit', minute:'2-digit', timeZoneName:'short'},sortable:true},
				    {label: 'Min', fieldName: 'Minimum_Respondents__c', type: 'number', editable : true,sortable:true,initialWidth:70},
				    {label: 'Max', fieldName: 'Maximum_Respondents__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:90},
				    {label: 'MQ Group', fieldName: 'MQG__c', type: 'number', editable : false,sortable:true,actions:headerActions}
				]);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
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
	sortQuotasData: function (component, fieldName, sortDirection) {
        var data = component.get("v.smQuotasData");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.smQuotasData", data);
    },
	mqOnLoad: function(component){
		//get the Quotas data
		var action = component.get("c.getSessionMasterQuotas");
		action.setParams({ masterTestID : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				component.set("v.qwData",response.getReturnValue());
				var actions = [
				    { label: 'Delete', name: 'delete' }
		        ];
				var headerActions = [];
				component.set('v.qwDataColumns', [
				    { type: 'action', typeAttributes: { rowActions: actions } } ,
		            {label: 'Summary', fieldName: 'Quota_Summary__c', type: 'text', editable : true,sortable:true ,actions:headerActions},
				    {label: 'Decipher', fieldName: 'Beacon_Condition__c', type: 'text', editable : true,sortable:true,actions:headerActions},
				    {label: 'Min', fieldName: 'Minimum_Respondents__c', type: 'number', editable : true,sortable:true,initialWidth:70},
				    {label: 'Max', fieldName: 'Maximum_Respondents__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:90},
				    {label: 'Scheduled', fieldName: 'Total_Scheduled__c', type: 'number', editable : false,sortable:true,actions:headerActions,initialWidth:70},
				    {label: 'Master Quota Group', fieldName: 'MQG__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:70},
				    {label: 'Open to Recruit', fieldName: 'IsOpen__c', type: 'boolean', editable : true,sortable:true,actions:headerActions},
				    {label: 'Secondary Quota', fieldName: 'IsTrackingOnly__c', type: 'boolean', editable : true,sortable:true,actions:headerActions}
				]);
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
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
	sortMasterQuotasData: function (component, fieldName, sortDirection) {
        var data = component.get("v.qwData");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.qwData", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
	showToast : function(component,msg,bGood){
		//var toastEvent = component.find(toastId);
		component.set("v.toastVisible",true);
		component.set("v.toastMsgText",msg);
		var toastMgs = component.find("toastMain");
		var i;
		if(bGood){
			for(i = 0; i < toastMgs.length; i++){
				$A.util.addClass(toastMgs[i],'goodToast');
			}
		}else{
			for(i = 0; i < toastMgs.length; i++){
				$A.util.removeClass(toastMgs[i],'goodToast');
			}
		}
		setTimeout($A.getCallback(function(){ component.set("v.toastVisible",false);}), 3000);
    },
	saveDataTableValues: function(component,valueListOfMaps){
		var totalRecordEdited = valueListOfMaps.length;
		//save the changed values
		var action = component.get("c.SaveDTValues");
		action.setParams({ 'newVals' : valueListOfMaps });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
				//if update is successful
                if(response.getReturnValue() === true){
                    this.showToast(component, totalRecordEdited+" Records Updated",true);
                    this.doInit(component);
					this.rfOnLoad(component);
					this.mqOnLoad(component);
				}
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                   this.showToast(component,"Error in update",false);
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
	addSessionBA: function(component,sMode,targetID){
		if(confirm("Create a session " + sMode + " the selected session?") === true){
			var action = component.get("c.addSession");
			//action.setParams({ 'sMode' : sMode });
			action.setParams({ 'sMode' : sMode , 'targetID' : targetID });
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					//if update is successful
					if(response.getReturnValue() === true){
						this.showToast(component,"1 Record created " + sMode,true);
						this.doInit(component);
						//this.rfOnLoad(component);
						//this.mqOnLoad(component);
					}
				}
				else if (state === "INCOMPLETE") {
					// do something
				}
				else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
					   this.showToast(component,"Error in insert",false);
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
		}
	},
	deleteSession: function(component,targetID){
		if(confirm("Are you sure you want to DELETE this session?") === true){
			var action = component.get("c.deleteSession");
			//action.setParams({ 'sMode' : sMode });
			action.setParams({ 'targetID' : targetID });
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					//if update is successful
					if(response.getReturnValue() === true){
						this.showToast(component,"1 Record Deleted",true);
						this.doInit(component);
						//this.rfOnLoad(component);
						//this.mqOnLoad(component);
					}
				}
				else if (state === "INCOMPLETE") {
					// do something
				}
				else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
					   this.showToast(component,"Error in Delete",false);
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
		}
	},
	deleteMQuota: function(component,targetID){
		if(confirm("Are you sure you want to DELETE this quota?") === true){
			var action = component.get("c.deleteMasterQuota");
			//action.setParams({ 'sMode' : sMode });
			action.setParams({ 'targetID' : targetID });
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					//if update is successful
					if(response.getReturnValue() === true){
						this.showToast(component,"1 Record Deleted",true);
						//this.doInit(component);
						//this.rfOnLoad(component);
						this.mqOnLoad(component);
					}
				}
				else if (state === "INCOMPLETE") {
					// do something
				}
				else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
					   this.showToast(component,"Error in Delete",false);
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
		}
	},
	deleteSQuota: function(component,targetID){
		if(confirm("Are you sure you want to DELETE this quota?") === true){
			var action = component.get("c.deleteSessionQuota");
			//action.setParams({ 'sMode' : sMode });
			action.setParams({ 'targetID' : targetID });
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					//if update is successful
					if(response.getReturnValue() === true){
						this.showToast(component,"1 Record Deleted",true);
						//this.doInit(component);
						this.rfOnLoad(component);
						//this.mqOnLoad(component);
					}
				}
				else if (state === "INCOMPLETE") {
					// do something
				}
				else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
					   this.showToast(component,"Error in Delete",false);
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
		}
	},
	getInitBulkSessions: function(component){
		var mtId = component.get("v.recordId");
		var action = component.get("c.getNewBulkSessions");
		action.setParams({ 'masterTestId' : mtId });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				//if update is successful 
				component.set("v.bulkSessionsObject",response.getReturnValue());
				var bso = component.get("v.bulkSessionsObject");
				bso.MasterTestID = component.get("v.recordId");
				//bso.sessionStart = "8:00 AM";
				//bso.sessionEnd = "3:00 PM";
				component.set("v.bulkSessionsObject",bso);
				var actions = [];
				var headerActions = [];
				component.set('v.bulkSessionQuotasDataColumns', [
				    //{ type: 'action', typeAttributes: { rowActions: actions } } ,
		            {label: 'Summary', fieldName: 'Quota_Summary__c', type: 'text', editable : true,sortable:true ,actions:headerActions},
				    {label: 'Decipher', fieldName: 'Beacon_Condition__c', type: 'text', editable : true,sortable:true,actions:headerActions},
				    {label: 'Min', fieldName: 'Minimum_Respondents__c', type: 'number', editable : true,sortable:true,initialWidth:70},
				    {label: 'Max', fieldName: 'Maximum_Respondents__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:90},
				    {label: 'Scheduled', fieldName: 'Total_Scheduled__c', type: 'number', editable : false,sortable:true,actions:headerActions,initialWidth:70},
				    {label: 'Master Quota Group', fieldName: 'MQG__c', type: 'number', editable : true,sortable:true,actions:headerActions,initialWidth:70},
				    {label: 'Open to Recruit', fieldName: 'IsOpen__c', type: 'boolean', editable : true,sortable:true,actions:headerActions},
				    {label: 'Secondary Quota', fieldName: 'IsTrackingOnly__c', type: 'boolean', editable : true,sortable:true,actions:headerActions}
				]);
				component.set('v.bulkSessionQuotasDataColumns2', [
				    //{ type: 'action', typeAttributes: { rowActions: actions } } ,
		            {label: 'Summary', fieldName: 'Quota_Summary__c', type: 'text', editable : false,sortable:true ,actions:headerActions},
				    {label: 'Decipher', fieldName: 'Beacon_Condition__c', type: 'text', editable : false,sortable:true,actions:headerActions},
				    {label: 'Min', fieldName: 'Minimum_Respondents__c', type: 'number', editable : false,sortable:true,initialWidth:70},
				    {label: 'Max', fieldName: 'Maximum_Respondents__c', type: 'number', editable : false,sortable:true,actions:headerActions,initialWidth:90},
				    {label: 'Scheduled', fieldName: 'Total_Scheduled__c', type: 'number', editable : false,sortable:true,actions:headerActions,initialWidth:70},
				    {label: 'Master Quota Group', fieldName: 'MQG__c', type: 'number', editable : false,sortable:true,actions:headerActions,initialWidth:70},
				    {label: 'Open to Recruit', fieldName: 'IsOpen__c', type: 'boolean', editable : false,sortable:true,actions:headerActions},
				    {label: 'Secondary Quota', fieldName: 'IsTrackingOnly__c', type: 'boolean', editable : false,sortable:true,actions:headerActions}
				]);
				//this.doInit(component);
				//this.rfOnLoad(component);
				//this.mqOnLoad(component);
			}
			else if (state === "INCOMPLETE") {
				// do something
			}
			else if (state === "ERROR") {
				var errors = response.getError();
				if (errors) {
					this.showToast(component,"Error in getting an initial bulk sessions object",false);
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
		// var bso = component.get("v.bulkSessionsObject");
		
		// component.set("v.bulkSessionsObject",bso);			
		
	},
	getBulkSessionsPreview: function(component,bulkSessionsObj){
        //if($A.util.isEmpty(bulkSessionsObj.sessionDay)){
        //    this.showToast(component,"Session day is required.",false);
        //    return;
        //}
        
        if($A.util.isEmpty(bulkSessionsObj.sessionStart) || $A.util.isEmpty(bulkSessionsObj.sessionStart)){
            this.showToast(component,"Session start and end times are required.",false);
            return;
        }
        
        if($A.util.isEmpty(bulkSessionsObj.sessionLength)){
            this.showToast(component,"Session length is required.",false);
        	return;
        }
        
        if($A.util.isEmpty(bulkSessionsObj.timezone)){
            bulkSessionsObj.timezone = $A.get("$Locale.timezone");
            component.set("v.bulkSessionsObj",bulkSessionsObj);
        }
        
		debugger;
        var breaks = bulkSessionsObj.breaks;
        if(!$A.util.isEmpty(breaks)){
            for(var i=0; i < breaks.length; i++){
				//?? I don't think I want to format these... I want them as-is??
            	//breaks[i].startTime = $A.localizationService.formatTime(breaks[i].startTime,"HH:mm");
                //breaks[i].endTime = $A.localizationService.formatTime(breaks[i].endTime,"HH:mm");
            }
        }
        /** SOPHIA: Commented out 
        if(!$A.util.isEmpty(bulkSessionsObj.sessionStart)){

			
			//DAYLIGHT SAVINGS LOGIG///////
				var printTime =  $A.localizationService.formatTime(bulkSessionsObj.sessionStart,"HH:mm");
				var sessionStartArray = bulkSessionsObj.sessionStart.split(':');////////////////////////////////////////////////////////
				// var hour = $A.localizationService.formatTime(bulkSessionsObj.sessionStart,"HH");
				var min = $A.localizationService.formatTime(bulkSessionsObj.sessionStart,"mm");

				var hour = parseInt(sessionStartArray[0]);
				hour = hour -1;
				if (hour < 10) {
					hour = '0'+hour;
				}
				var newTime = hour+':'+min;
				bulkSessionsObj.sessionStart = newTime;

			//bulkSessionsObj.sessionEnd = $A.localizationService.formatTime(bulkSessionsObj.sessionStart,"HH:mm");
			//DAYLIGHT SAVINGS LOGIG////////////////////////////////////////////////////////////////

			

        }
        
        if(!$A.util.isEmpty(bulkSessionsObj.sessionEnd)){

			var min = $A.localizationService.formatTime(bulkSessionsObj.sessionEnd,"mm");
			var sessionStartArray = bulkSessionsObj.sessionEnd.split(':');///
			var hour = parseInt(sessionStartArray[0]);
			hour = hour -1;
			if (hour < 10) {
				hour = '0'+hour;
			}
			var newTime = hour+':'+min;
			bulkSessionsObj.sessionEnd = newTime;
            // bulkSessionsObj.sessionEnd = $A.localizationService.formatTime(bulkSessionsObj.sessionEnd,"HH:mm");
        }
		*/
		debugger;
        
        try{
            var action = component.get("c.getBulkSessionsSchedule");
            var jsonStr = JSON.stringify(bulkSessionsObj);
			console.log(bulkSessionsObj);
            action.setParams({ 'bsJSON' : jsonStr });
            action.setCallback(this, function(response) {
                try{
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        //if update is successful 
                        
                        var bulkSessionsObject = response.getReturnValue();
						console.log(bulkSessionsObject);
                        
                        //The times come back in a number format instead of HH:mm a, so this logic corrects that before re-rendering the component.
                        var currentWrapper = component.get("v.bulkSessionsObject");
                        currentWrapper.scheduledSessions = bulkSessionsObject.scheduledSessions;
						/** SOPHIA: Commented out
						//DAYLIGHT SAVINGS LOGIG////////////////////////////////////////////////////////////////
							var hour = $A.localizationService.formatTime(currentWrapper.sessionStart,"HH");
							var min = $A.localizationService.formatTime(currentWrapper.sessionStart,"mm");
				
							var hourInt = parseInt(hour);
							console.log(hour);
							hourInt = hourInt +1;
							if (hourInt < 10) {
								hour = '0'+hourInt;
							}
							console.log(hour);
							currentWrapper.sessionStart = hour+':'+min;
						// currentWrapper.sessionStart = $A.localizationService.formatTime(currentWrapper.sessionStart,"HH:mm");
						//DAYLIGHT SAVINGS LOGIG////////////////////////////////////////////////////////////////

                        
                        currentWrapper.sessionEnd = $A.localizationService.formatTime(currentWrapper.sessionEnd,"HH:mm");
                         */
                        
                        component.set("v.bulkSessionsObject",currentWrapper);
                        
                        
                        
                        component.set('v.bShowPreview',true);
                        this.showToast(component,"New preview created. (" + currentWrapper.scheduledSessions.length + ")",true);
                        //once more for good measure?
                        component.set("v.bShowPreview", true);
                    }
                    else if (state === "INCOMPLETE") {
                        // do something
                    }
                    else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            component.set('v.bShowPreview',false);
                            var msg = 'Error in creating the Bulk Sessions Preview';
                            if (errors[0] && errors[0].message) {
                                console.log("Error message: " + errors[0].message);
                                msg += ': ' + errors[0].message;
                            }
                            this.showToast(component,msg,false);
                            
                        } else {
                            console.log("Unknown error");
                        }
                    }
                }catch(ex){
                    this.showToast(component,"Error in creating the Bulk Sessions Preview: " + ex,false);
                }
            });
            $A.enqueueAction(action);
        }catch(ex){
            this.showToast(component,"Error in creating the Bulk Sessions Preview: " + ex,false);
        }
	},
	saveBulkSessions: function(component,bulkSessionsObj){
        
		if(confirm("Are you sure you want to SAVE ALL SESSIONS?") === true){
			var action = component.get("c.saveBulkSessionsCtrl");
			var jsonStr = JSON.stringify(bulkSessionsObj);
			debugger;
			action.setParams({ 'bsJSON' : jsonStr });
			action.setCallback(this, function(response) {
				var state = response.getState();
				if (state === "SUCCESS") {
					//if update is successful
					if(response.getReturnValue() === true){
						this.showToast(component,"Sessions Saved Successfully",true);
						this.doInit(component);
						//this.rfOnLoad(component);
						//this.mqOnLoad(component); 
						this.hideIt(component,'createBulkSessionsModal');
					}
				}
				else if (state === "INCOMPLETE") {
					// do something 
				}
				else if (state === "ERROR") {
					var errors = response.getError();
					if (errors) {
					   this.showToast(component,"Error in Saving Sessions",false);
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
		}		
	},
	addNewMQ: function(component){
		debugger;
		var mtId = component.get("v.recordId");
		var action = component.get("c.addNewMasterQuota");
		action.setParams({ 'MasterTestId' : mtId });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				debugger;
				//if update is successful
				if(response.getReturnValue() === true){
					this.showToast(component,"1 Record Added",true);
					//this.doInit(component);
					//this.rfOnLoad(component);
					this.mqOnLoad(component);
				}else{
					this.showToast(component,"Adding Record Failed",false);
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
					this.showToast(component,"Error in Delete",false);
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
	getTestLocObj: function(component,testLocId){
		debugger;
		var action = component.get("c.getTestLocById");
		action.setParams({ 'testLocId' : testLocId });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				debugger;
				//if update is successful
				component.set("v.selectedTestLocRecord", response.getReturnValue());
				component.set("v.selectedLinkedSession", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") {
				// do something
				debugger;
			}
			else if (state === "ERROR") {
				debugger;
				component.set("v.selectedTestLocRecord",null);
				/*
				var errors = response.getError();
				if (errors) {
					this.showToast(component,"Error retrieving the Testing Location.",false);
					if (errors[0] && errors[0].message) {
						console.log("Error message: " + 
									errors[0].message);
					}
				} else {
					console.log("Unknown error");
				}
				*/
			}
		});
		$A.enqueueAction(action);			
	},
	getLinkedSessionObj: function(component,linkedSessionId){
		debugger;
		var action = component.get("c.getSessionById");
		action.setParams({ 'sessionId' : linkedSessionId });
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				debugger;
				//if update is successful
				component.set("v.selectedLinkedSession", response.getReturnValue());
			}
			else if (state === "INCOMPLETE") {
				// do something
				debugger;
			}
			else if (state === "ERROR") {
				debugger;
				component.set("v.selectedLinkedSession",null);
				/*
				var errors = response.getError();
				if (errors) {
					this.showToast(component,"Error retrieving the Linked Session.",false);
					if (errors[0] && errors[0].message) {
						console.log("Error message: " + 
									errors[0].message);
					}
				} else {
					console.log("Unknown error");
				}
				*/
			}
		});
		$A.enqueueAction(action);			
	},
	saveSessionDetailsLookups: function(component,SessionId,TestLocId,LinkedSessionId){
		debugger;
		var action = component.get("c.saveSessionDetailLookups");
		action.setParams({ 'SessionId' : SessionId , 'TestLocId' : TestLocId , 'LinkedSessionId' : LinkedSessionId});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				debugger;
				//if update is successful
				if(response.getReturnValue() === true){
					//this.showToast(component,"1 Record Added",true);
					this.doInit(component);
                    this.hideIt(component,"editSessionModal");
					//this.rfOnLoad(component);
					//this.mqOnLoad(component);
				}else{
					this.showToast(component,"Failed to save lookup values",false);
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
					this.showToast(component,"Error in saving lookup values",false);
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
	addSelectedQuotas: function(component,sessionId,selectedQuotaIds){
		debugger;
		var action = component.get("c.addQuotasToSession");
		action.setParams({ 'SessionId' : sessionId , 'QuotaIds' : selectedQuotaIds});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				debugger;
				//if update is successful
				if(response.getReturnValue() === true){
					this.showToast(component,"Record(s) Added",true);
					//this.doInit(component);
					this.rfOnLoad(component);
					//this.mqOnLoad(component);
				}else{
					this.showToast(component,"Failed to save lookup values",false);
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
					this.showToast(component,"Error in saving lookup values",false);
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
    handleLookupModal : function(component, recordId, relationshipName) {
        // open modal 
        var modalBody;
        
        var that = this;
        
        $A.createComponent(
            "c:Lookup",
            {
                "recordId": recordId,
                "sObjectName" : 'Session__c',
                "field" : relationshipName,
                "showApplyAll": true
            },
            function(content, status) {
                if (status === "SUCCESS") {
                	component.set("v.lookupComponent",content);
                    that.showIt(component,'lookupModal');
                 } 
            }
        );
    },
    handleEditLookup : function(component, event){
        var parms = event.getParams();
        if($A.util.isEmpty(parms) || $A.util.isEmpty(parms.recordId) || 'CANCEL' === parms.status ){
            this.hideIt(component, 'lookupModal');
            return;
        }
        
        var recordIds = [];
        recordIds.push(parms.recordId);
        
        if(parms.applyAll){
            var selectedRows = component.find("dtSessions").get("v.selectedRows");
            if(!$A.util.isEmpty(selectedRows)){
                for(var i=0; i < selectedRows.length; i++){
                    recordIds.push(selectedRows[i]);
                }
            }
        }
        
        var methodName = 'c.updateTestingLocation';
        if('Test_Type__c' === parms.relationshipName){
            methodName = 'c.updateTestType';
        }
        if('Research_Type__c' === parms.relationshipName){
            methodName = 'c.updateResearchType';
        }
        
        var action = component.get(methodName);
		action.setParams({ 'val' : parms.newParentId , 'recordIds' : recordIds});
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (state === "SUCCESS") {
				this.showToast(component,"Record(s) Added",true);
				this.doInit(component);//rfOnLoad(component);
            }
            else if (state === "ERROR") {
				this.showToast(component,"Error in saving lookup values",false);
			}
            this.hideIt(component, 'lookupModal');
		});
		$A.enqueueAction(action);
    }
})