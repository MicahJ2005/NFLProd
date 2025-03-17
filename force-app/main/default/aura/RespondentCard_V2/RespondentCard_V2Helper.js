({
    getDOTChecksForTest :function(component, event){
        var action = component.get("c.listDOTChecksForTest");
        action.setParams({masterTestId : component.get("v.MasterTestId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.TestRespondentDOTCheck", response.getReturnValue());
            }             
        });
        $A.enqueueAction(action);
    },
    getOtherTRs :function(component, event){
        var action = component.get("c.upcomingTest");
        action.setParams({respondentID : component.get("v.Respondent.tr.Respondent__c"), sessionId : component.get("v.Session.Id")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.TestRespondentOtherTest", response.getReturnValue());
            }             
        });
        $A.enqueueAction(action);
    },
    getTestRespondentPicklist : function(component, event){
        var action = component.get("c.getStatusValues");
        component.set("v.rNumber", "");
        action.setCallback(this, function(response){
         var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.TestStatus", response.getReturnValue());
                component.set("v.tStatus", component.get("v.Respondent.tr.Tested_Status__c"));
                component.set("v.rNumber", component.get("v.Respondent.tr.Respondent_Number__c"));
            }             
        });
        $A.enqueueAction(action); 
    },
    CheckinRespondent : function(component, event, helper){
        //debugger;
        var action = component.get("c.CheckinRespondent");
        var tstatus = component.get("v.tStatus");
        var rNumber = component.get("v.rNumber");
        var tId = component.get("v.Respondent.tr.Id");
        var children = component.get("v.TestRespondentChild");
        if(typeof rNumber == "undefined"){
            rNumber = "";
        }
        action.setParams({trStatus : tstatus, trRepNum : rNumber.toString(), trID : tId, child : children});
        action.setCallback(this, function(response){
            debugger;
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                debugger;
                this.toggleSpinner(component, event);
                var returnVal = response.getReturnValue();
                var successOrError = returnVal.status;
                var messages = returnVal.messages;
                if(successOrError === 'Success' || successOrError === 'JustSave') {
                    component.set("v.successMessages", messages);
                    this.closeRespondentModal(component, event);
                } else if (successOrError === 'Error') {
                    component.set("v.errorMessages", messages);
                }
            } else if (state === "ERROR" || state === "INCOMPLETE") {
                component.set("v.errorMessages", ['There was an issue with checking the respondent in']);
            }
        });
        $A.enqueueAction(action);
    },
    QuickCheckinRespondent : function(component, event, helper){
        //Called from teh "new" check in button.  
        var action = component.get("c.QuickCheckinRespondent");
        var tstatus = component.get("v.tStatus");
        var rNumber = component.get("v.rNumber");
        var tr = component.get("v.Respondent.tr");
        var children = component.get("v.TestRespondentChild");
        debugger;
        if(typeof rNumber == "undefined"){
            rNumber = "";
        }
        action.setParams({trStatus : tstatus, trRepNum : rNumber.toString(), tr : tr, children : children});
        action.setCallback(this, function(response){
            debugger;
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                debugger;
                this.toggleSpinner(component, event);
                var returnVal = response.getReturnValue();
                var successOrError = returnVal.status;
                var messages = returnVal.messages;
                if(successOrError === 'Success' || successOrError === 'JustSave') {
                    component.set("v.successMessages", messages);
                    this.closeRespondentModal(component, event);
                } else if (successOrError === 'Error') {
                    component.set("v.errorMessages", messages);
                }
            } else if (state === "ERROR" || state === "INCOMPLETE") {
                component.set("v.errorMessages", ['There was an issue with checking the respondent in']);
            }
        });
        $A.enqueueAction(action);
    },
    createAllergyCase : function(component, event){
        debugger;
        var action = component.get("c.CreateAllergyCase");
        action.setParams({cntID : component.get("v.Respondent.tr.Respondent__c")});
        action.setCallback(this, function(response){
            debugger;
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                this.toggleSpinner(component, event);
                component.set("v.message", response.getReturnValue());

                var myModal = component.find("AllergyModal");
            	$A.util.addClass(myModal,"slds-hide");
            }
        });
        $A.enqueueAction(action); 
    },
    createBadBehaviorCase : function(component, event){
        debugger;
        var action = component.get("c.CreateBadBehaviorCase");
        action.setParams({cntID : component.get("v.Respondent.tr.Respondent__c")});
        action.setCallback(this, function(response){
            debugger;
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                this.toggleSpinner(component, event);
                component.set("v.message", response.getReturnValue());

                var myModal = component.find("BadBehaviorModal");
            	$A.util.addClass(myModal,"slds-hide");
            }
        });
        $A.enqueueAction(action); 
    },
    getQuotaInfoForTR : function(component, event){
        var action = component.get("c.getQuotaInfo");
        action.setParams({trID : component.get("v.Respondent.tr.Id")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.lstQuota", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getPeelOffData : function(component, event){
        var action = component.get("c.getPeelOffs");
        action.setParams({masterTestId : component.get("v.Session.Related_Test__c")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.PeelOffs", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    assignDOTcheck : function(component, event){
        debugger;
        var selectedItem = event.currentTarget;
        var action = component.get("c.updateTRWithDOTCheck");
        var respId = component.get("v.Respondent.tr.Id");
        var checkID = selectedItem.getAttribute('data-checkId');
        action.setParams({passTRDot : checkID, passTR : respId});
        action.setCallback(this, function(response){
            debugger;
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                this.toggleSpinner(component, event);
                component.set("v.message", response.getReturnValue());
                this.getDOTChecksForTest(component, event);
            }
        });
        $A.enqueueAction(action);
    },
    /**assignPSAcheck : function(component, event){
        var selectedItem = event.currentTarget;
        var action = component.get("c.assignPSACheck");
        //var action = component.get("c.updateTRWithDOTCheck");
        var respId = component.get("v.Respondent.tr.Id");
        var checkID = selectedItem.getAttribute('data-checkId');
        action.setParams({passTRPSA : checkID, passTR : respId});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.message", response.getReturnValue());
                //this.getDOTChecksForTest(component, event);
            }
        });
        $A.enqueueAction(action);
    },*/
    setCommValues :function(component, event){
        console.log('respondent: ' + component.get("v.Respondent.tr.Respondent__r.Communication__c"));
        console.log('Test respondent: ' + component.get("v.Respondent.tr.Respondent__r.Communication__c"));

        if(component.get("v.Respondent.tr.Respondent__r.Communication__c") == null){
            component.set("v.rComm", "No Respondent Notes");
        }
        else{
            component.set("v.rComm", component.get("v.Respondent.tr.Respondent__r.Communication__c"));
        }
        if(component.get("v.Respondent.tr.Communication__c") == null){
            component.set("v.trComm", "No Respondent Notes");
        }
        else{
            component.set("v.trComm", component.get("v.Respondent.tr.Communication__c"));
        }

    },
    clearMessage : function(component, event){
        window.setTimeout(
            $A.getCallback(function(){
                console.log('clear message');
                component.set("v.message", null);
            }), 10000
        );
    },
    schedulePeelOff : function(component, event){
        var action = component.get("c.ScheduledPeelOffs");
        var poId = event.currentTarget.getAttribute('data-fldname');
        //action.setParams({masterTestId : component.get("v.Session.Related_Test__c"), respondentId : component.get("v.Respondent.tr.Respondent__c"), sessionId : component.get("v.Session.Id")});
        action.setParams({masterTestId : component.get("v.Session.Related_Test__c"), respondentId : component.get("v.Respondent.tr.Respondent__c"), sessionId : poId});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                this.toggleSpinner(component, event);

                component.set("v.message", response.getReturnValue());
                
            	var poModal = component.find("PeelOffModal");
            	$A.util.addClass(poModal,"slds-hide");
            }
        });
        $A.enqueueAction(action);
    },
    setPairvisibility : function(component, event){
        var pair = component.get("v.Respondent.strPairStyle");
        var pairlist = component.find("pairTesting");
        var children = component.get("v.Respondent.lstPairs");
        if(children.length > 0){
            var childinfo = component.find("ChildInfo");
            $A.util.removeClass(childinfo,"slds-hide");
            component.set("v.TestRespondentChild", children);
            $A.util.removeClass(pairlist,"slds-hide");
        }
        else{
            component.set("v.TestRespondentChild", []);
            var childinfo = component.find("ChildInfo");
            $A.util.addClass(childinfo,"slds-hide");
        }
    },
    toggleSpinner : function(component, event){
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    }, 
    closeRespondentModal : function(component, event) {
        component.set("v.modalOpen", false);
    },
    showToast : function(component, event, variant, title, message) {
        debugger;
        let toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been updated successfully."
        });
        toastEvent.fire();
        /*
        component.find('notifLib').showToast({
            "variant" : variant,
            "title": title,
            "message": message
        });
        */
    }
})