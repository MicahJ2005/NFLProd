({
	doInit: function (component, event, helper) {
		helper.doInit(component);
        component.set("v.breakTime",{});
        component.set("v.displayBulkSaveConfirm",false);
		helper.mqOnLoad(component);
        //helper.getInitBulksubmitCreatePreview(component);
	},
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var rows = component.get('v.smData');
        switch (action.name) {
            case 'show_details':
				var selectedId = row.Id;
				component.set("v.editSessionModalID",selectedId);
				component.set("v.selectedMTestRecord",component.get("v.smMasterTest"));
				component.set("v.inputTestType",row.Test_Type__c);
				component.set("v.inputResearchType",row.Research_Type__c);
				debugger;
				//component.set("v.selectedTestLocRecord",rows[rows.indexOf(row)].Testing_Location__c);
				helper.getTestLocObj(component,row.Testing_Location__c);
				helper.getLinkedSessionObj(component,row.Linked_Session__c);
                helper.rfOnLoadEdit(component, selectedId);
				helper.showIt(component,'editSessionModal');
                break;
			case 'add_before':
				var selectedId = row.Id;
				helper.addSessionBA(component,'before',selectedId);
				break;
			case 'add_after':
				var selectedId = row.Id;
				helper.addSessionBA(component,'after',selectedId);
				break;
            case 'delete':
                //var rowIndex = rows.indexOf(row);
                //rows.splice(rowIndex, 1);
                //component.set('v.smData', rows);
				var selectedId = row.Id;
				helper.deleteSession(component,selectedId);
                break;
            case 'edit_lookup_location':
                helper.handleLookupModal(component, row.Id, 'Testing_Location__c');   
        		break;
            case 'edit_picklist_testtype':
                helper.handleLookupModal(component, row.Id, 'Test_Type__c');   
        		break;
			case 'edit_picklist_researchtype':
					helper.handleLookupModal(component, row.Id, 'Research_Type__c');   
					break;
        }
	},
    handleQWRowAction: function (component, event, helper) {
		debugger;
        var action = event.getParam('action');
        var row = event.getParam('row');
        var rows = component.get('v.qwData');
        switch (action.name) {
            case 'delete':
				var selectedId = rows[rows.indexOf(row)].Id
				helper.deleteMQuota(component,selectedId);
                break;
        }
	},
    handleQuotasRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var rows = component.get('v.smQuotasData');
        switch (action.name) {
            case 'delete':
				var selectedId = rows[rows.indexOf(row)].Id
				helper.deleteSQuota(component,selectedId);
                break;
        }
	},
	closeDetailsModal: function(component,event,helper){
		helper.hideIt(component,'editSessionModal');
	},
	closeBulkSessionsModal: function(component,event,helper){
		helper.hideIt(component,'createBulkSessionsModal');
	},
	closeQuotaWizardModal: function(component,event,helper){
		helper.hideIt(component,'masterQuotaWizardModal');
	},


	closeAddSessionQuotasModal: function(component,event,helper){
		helper.hideIt(component,'addSessionQuotasModal');
		helper.showIt(component,'editSessionModal');
	},


	openQuickDetailsModal: function(component,event,helper){
		var cmpSessions = component.find("dtSessions");
		helper.showIt(component,'quickEditSessionModal');
		var selectedRows = cmpSessions.getSelectedRows();
		component.set("v.smQuickEditData",selectedRows);
	},
	openBulkSessionsModal: function(component,event,helper){
		component.set('v.bShowPreview',false);
        component.set("v.breakTime",{});
		helper.getInitBulkSessions(component);
		helper.mqOnLoad(component);
		helper.showIt(component,'createBulkSessionsModal');
	},
	openQuotaWizardModal: function(component,event,helper){
		helper.mqOnLoad(component);
		helper.showIt(component,'masterQuotaWizardModal');
	},


	openAddSessionQuotasModal: function(component,event,helper){
		//helper.mqOnLoad(component);
		helper.getInitBulkSessions(component);
		helper.hideIt(component,'editSessionModal');
		helper.showIt(component,'addSessionQuotasModal');
	},


	closeQuickDetailsModal: function(component,event,helper){
		helper.hideIt(component,'quickEditSessionModal');
	},
	rfOnLoad: function(component,event,helper){
		helper.rfOnLoad(component, event);
	},
	addNew: function(component,event,helper){
		debugger;
		component.set("v.editSessionModalID",null);
		component.set("v.addNewSession", true);
		//clear test loc 
		component.set("v.selectedTestLocRecord",null);
		component.set("v.selectedLinkedSession",null);
		//set Master Test
		component.set("v.selectedMTestRecord",component.get("v.smMasterTest"));
		//component.find('inputMasterTest').set('v.value',component.get('v.MasterTestID'));
		helper.showIt(component,'editSessionModal');
	},
	addBreak: function(component,event,helper){
        var breakTime = component.get("v.breakTime");
        if($A.util.isEmpty(breakTime) || $A.util.isEmpty(breakTime.name)){
        	helper.showToast(component,"The Break Name field is required to add a break.",false);
			return;
		}
        
        //if($A.util.isEmpty(breakTime.startTime) || $A.util.isEmpty(breakTime.endTime) || breakTime.startTime > breakTime.endTime){
        //	helper.showToast(component,"Break start and end times are required.  Break start time needs to be before break end time.",false);
		//	return;
		//}

		if($A.util.isEmpty(breakTime.startDateTime) || $A.util.isEmpty(breakTime.endDateTime) || breakTime.startDateTime > breakTime.endDateTime){
			helper.showToast(component,"Break start and end times are required.  Break start time needs to be before break end time.",false);
			return;
		}
        
        //breakTime.startTimeLabel = $A.localizationService.formatTime(breakTime.startTime,"hh:mm a");
        //breakTime.endTimeLabel = $A.localizationService.formatTime(breakTime.endTime,"hh:mm a");
        breakTime.startTimeLabel = $A.localizationService.formatTime(breakTime.startDateTime,"hh:mm a");
        breakTime.endTimeLabel = $A.localizationService.formatTime(breakTime.endDateTime,"hh:mm a");

        var bulkSessionsObject = component.get("v.bulkSessionsObject");
        bulkSessionsObject.breaks.push(breakTime);
        component.set("v.bulkSessionsObject",bulkSessionsObject);
        component.set("v.breakTime",{});
    },
	deleteBreak: function(component,event,helper){
        debugger;
		var bulkSessionsObject = component.get("v.bulkSessionsObject");
        var breakIndex = event.getSource().get("v.name");
        bulkSessionsObject.breaks.splice(breakIndex,1);
        component.set("v.bulkSessionsObject",bulkSessionsObject);
	},
    submitCreatePreview : function(component, event, helper){
    	component.find("bulkSession").submit();
	},
	createPreview: function(component, event, helper){
        var record = event.getParam("fields");
		debugger;		
        var bulkSessionsObj = component.get('v.bulkSessionsObject');
		//var bulkStart = component.get("v.bulkStart");
		//var bulkEnd = component.get("v.bulkEnd");
		var bulkStartDateTime = component.get("v.bulkStartDateTime");
		var bulkEndDateTime = component.get("v.bulkEndDateTime");

		//bulkSessionsObj.sessionStart = bulkStart;
		//bulkSessionsObj.sessionEnd = bulkEnd;
		bulkSessionsObj.sessionStart = bulkStartDateTime;
		bulkSessionsObj.sessionEnd = bulkEndDateTime;

        bulkSessionsObj.session = record;
        bulkSessionsObj.session.Check_Amount__c = component.get("v.checkAmount");
		bulkSessionsObj.testType = component.get('v.inputTestType');
		bulkSessionsObj.researchType = component.get('v.inputResearchType');
		helper.getBulkSessionsPreview(component,bulkSessionsObj);
	},
    showBulkConfirm : function(cpmponent){
        component.set("v.displayBulkSaveConfirm",true);
    },
    cancelBulkConfirm : function(component, event, helper){
        component.set("v.displayBulkSaveConfirm",false);
    },
	saveBulkSessions: function(component,event,helper){
		var bulkSessionsObj = component.get('v.bulkSessionsObject');
		//bulkSessionsObj.testType = component.get('v.inputTestType');
		//debugger;
		//bulkSessionsObj.researchType = component.get('v.inputResearchType');
		//set unselected row's max value to -1
		var selectedRows = component.find("dtSessionQuotaWizard").getSelectedRows();
		if(selectedRows.length == 0){
			if(confirm("No Session Quotas have been selected. Are you sure you want to build the sessions without any Session Quotas?") == false){
				return;
			}
		}
		var i;
		var ii;
		for (i = 0; i < bulkSessionsObj.masterQuotas.length; i++) {
			var bFoundInSelected = false;
			for (ii = 0; ii < selectedRows.length; ii++) {
				if(bulkSessionsObj.masterQuotas[i].Id == selectedRows[ii].Id){
					bFoundInSelected = true;
					break;
				}
			}
			if( ! bFoundInSelected ){
				bulkSessionsObj.masterQuotas[i].Maximum_Respondents__c = -1; //disqualify it from being created
			}
		}
		//save
		helper.saveBulkSessions(component,bulkSessionsObj);
	},
	updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.smSortedBy", fieldName);
        component.set("v.smSortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
	},
	updateQuotasColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.smQuotasSortedBy", fieldName);
        component.set("v.smQuotasSortedDirection", sortDirection);
        helper.sortQuotasData(component, fieldName, sortDirection);
	},
	updateMasterQuotasColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.smMasterQuotasSortedBy", fieldName);
        component.set("v.smMasterQuotasSortedDirection", sortDirection);
        helper.sortMasterQuotasData(component, fieldName, sortDirection);
    },
	smSave: function(component, event, helper){
		debugger;
		var updatedValues = event.getParam('draftValues');
		console.log(component.get("v.smQuotasData"));
		console.log(component.get("v.smQuotasData"));
		
		helper.saveDataTableValues(component,updatedValues);
	},
	saveQuickDetails: function(component, event, helper){
		//helper.saveQuickDetails(component, event);
		var qeData = component.get("v.smQuickEditData");
		helper.saveDataTableValues(component,qeData);
	},
	saveDetails: function(component, event, helper){
		debugger;
		var SessionId = component.get("v.editSessionModalID");
		var TestLoc = component.get("v.selectedTestLocRecord");
		var LinkedSession = component.get("v.selectedLinkedSession");
		var TestLocId;
		var LinkedSessionId;
		if(TestLoc){
			TestLocId = TestLoc.Id;
		}
		if(LinkedSession){
			LinkedSessionId = LinkedSession.Id;
		}
		helper.saveSessionDetailsLookups(component,SessionId,TestLocId,LinkedSessionId);
	},
	handleSaveSuccess: function(component, event, helper){
        debugger;
		var rEditForm = component.find('refDetails');
		component.set("v.editSessionModalID",rEditForm.get("v.recordId"));
		helper.doInit(component);
		helper.rfOnLoad(component);
        helper.showToast(component,"Record Saved",true);
        helper.hideIt(component,"editSessionModal");
	},
	//Does anything reference this???
	copyToEnd: function(component, event, helper){
		//????
		component.set("v.bulkSessionsObject.endDateTime" , component.get("v.bulkSessionsObject.startDateTime"));
	},
	addNewMQ: function(component,event,helper){
		debugger;
		helper.addNewMQ(component);
		//helper.mqOnLoad(component);
	},
	addSelectedQuotas: function(component,event,helper){
		debugger;
		var selectedRows = component.find("dtAddSessionQuotas").getSelectedRows();
		if(selectedRows.length == 0){
			alert("No Session Quotas have been selected.")
			return;
		}
		var ii;
		var sSelectedQuotaIDs = '';
		for (ii = 0; ii < selectedRows.length; ii++) {
			sSelectedQuotaIDs = sSelectedQuotaIDs + selectedRows[ii].Id + ",";
		}
		helper.addSelectedQuotas(component,component.get("v.editSessionModalID"),sSelectedQuotaIDs);
		helper.hideIt(component,'addSessionQuotasModal');
		helper.showIt(component,'editSessionModal');
	},
	doCellChange: function(component,event,helper){
		var i;
		var data = component.get("v.bulkSessionsObject.masterQuotas");
		for (i = 0; i < event.getParam("draftValues").length; i++) {
			//get the next draft record
			var draftRecord = event.getParam("draftValues")[i];
			var Id = draftRecord.Id;
			var iNewMax = draftRecord.Maximum_Respondents__c;
			var iNewMin = draftRecord.Minimum_Respondents__c;
			var iNewTotal = draftRecord.Total_Scheduled__c;
			var iNewMQG = draftRecord.MQG__c;
			var bNewOpen = draftRecord.IsOpen__c;
			var bNewTrk = draftRecord.IsTrackingOnly__c;
			var ii;
			for (ii = 0; ii < data.length; ii++) {
				//find the matching data source record and set the new value(s).
				if(data[ii].Id == Id){
					if(iNewMax){
						data[ii].Maximum_Respondents__c = iNewMax;
					}
					if(iNewMin){
						data[ii].Minimum_Respondents__c = iNewMin;
					}
					if(iNewTotal){
						data[ii].Total_Scheduled__c = iNewTotal;
					}
					if(iNewMQG){
						data[ii].MQG__c = iNewMQG;
					}
					if(bNewOpen != undefined){
						data[ii].IsOpen__c = bNewOpen;
					}
					if(bNewTrk != undefined){
						data[ii].IsTrackingOnly__c = bNewTrk;
					}
					break; //should only be one match
				}
			}
		}
		component.set("v.bulkSessionsObject.masterQuotas",data); //save the draft values to the source data.
		var dTable = component.find("dtSessionQuotaWizard");
		dTable.set("v.draftValues", null); //clear draft values - gets rid of the Cancel/Save buttons.
	},
    handleTimezoneChange : function(component, event){
        if($A.util.isEmpty(component.find('timezoneSelect').get('v.value'))){
            component.find("timezoneSelect").set("v.value",$A.get("$Locale.timezone"));
        }
    },
    goToMasterTest : function(component){
        window.location.href = '/' + component.get("v.recordId");
    },
	handleSaveDetailsClick : function(component, event, helper) {
		//Had to move the Session Quota grid OUTSIDE of the recordEditForm; and with that - the Save Details button is also outside of the recordEditForm
		// updated the Save Details button to call this method that then submits the recordEditForm
		component.find('refDetails').submit();
	}, 
    handleOnSubmit : function(component, event){
        debugger;
		var addNewSession = component.get('v.addNewSession');
        var fields = event.getParam('fields');
		var a = event.getSource();
		var id = a.getLocalId();
		console.log(id);
		if (!addNewSession) {
			if(!$A.util.isEmpty(fields.Linked_Session_Temp__c)){
				event.preventDefault();    
				fields.Linked_Session__c = fields.Linked_Session_Temp__c;
				delete fields.Linked_Session_Temp__c;
				component.find('refDetails').submit(fields);
			}
		}
		debugger;
    },
	handleSuccess : function(component, event, helper) {
		var addNewSession = component.get('v.addNewSession');
		if (!addNewSession) {
			var record = event.getParam("response");
			var apiName = record.apiName;
			var myRecordId = record.id;
			console.log(myRecordId);
		}
 // ID of updated or created record
    },
    handleSaveError: function(component, event){
        debugger;
    },
    handleEditLookup : function(component, event, helper){
        helper.handleEditLookup(component, event);
    },
	handleSaveSession: function(component, event, helper) {
		console.log(component.get('v.smData'));
	},
	addNewSession : function(component, event, helper) {
        var MasterTestID = component.get("v.recordId");
		$A.createComponent(
            "c:SM_SingleSession",
            {
                "aura:id": "SM_SingleSession",
				"editSessionModalFields": component.get("v.editSessionModalFields"),
				"qwData": component.get("v.qwData"),
				"MSID": MasterTestID,
				"smMasterTest": component.get("v.smMasterTest")

            },
            function(newButton, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newButton);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                else if (status === "ERROR") {
                    console.log("Error: " + errorMessage);
                    // Show error message
                }
            }
        );
	}
})