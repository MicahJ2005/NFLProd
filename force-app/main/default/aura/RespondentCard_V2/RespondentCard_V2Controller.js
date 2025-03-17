({
    doInit : function(component, event, helper) {
        component.set("v.message", null);
        component.set("v.errorMessages", []);
        helper.setPairvisibility(component, event);
         helper.getDOTChecksForTest(component, event);
         helper.getOtherTRs(component, event);
         helper.getTestRespondentPicklist(component, event);
         helper.getQuotaInfoForTR(component, event);
         helper.setCommValues(component, event);
    },
    openDotModal : function(component, event, helper){
        var modal = component.find("DotCheckrModal");
        $A.util.removeClass(modal,"slds-hide");
    },
    closeDotModal : function(component, event, helper){
        var modal = component.find("DotCheckrModal");
        $A.util.addClass(modal,"slds-hide");
    },
    checkin : function(component, event, helper){
        helper.toggleSpinner(component, event);
        helper.CheckinRespondent(component, event, helper);
    },
    quickCheckin : function(component, event, helper){
        helper.toggleSpinner(component, event);
        helper.QuickCheckinRespondent(component, event, helper);
    },
    notifyCSAllergy : function(component, event, helper){
        //helper.toggleSpinner(component, event);
        //TODO: we want to open a MODAL
        var modal = component.find("AllergyModal");
        $A.util.removeClass(modal,"slds-hide");
    },
    notifyCSBadBehavior : function(component, event, helper){
        //helper.toggleSpinner(component, event);
        //TODO: we want to open a MODAL
        //helper.CreateBadBehaviorCase(component, event);
        var modal = component.find("BadBehaviorModal");
        $A.util.removeClass(modal,"slds-hide");
    },
    closeAllergyModal : function(component, event, helper){
        var modal = component.find("AllergyModal");
        $A.util.addClass(modal,"slds-hide");
    },
    saveAllergyCase : function(component, event, helper) {
        debugger;
        helper.toggleSpinner(component, event);
        helper.createAllergyCase(component, event);
    },
    closeBadBehaviorModal : function(component, event, helper){
        var modal = component.find("BadBehaviorModal");
        $A.util.addClass(modal,"slds-hide");
    },
    saveBadBehaviorCase : function(component, event, helper) {
        debugger;
        helper.toggleSpinner(component, event);
        helper.createBadBehaviorCase(component, event);
    },
    openPOModal : function(component, event, helper){
        helper.getPeelOffData(component, event);
        var modal = component.find("PeelOffModal");
        $A.util.removeClass(modal,"slds-hide");
    },
    closePOModal : function(component, event, helper){
        var modal = component.find("PeelOffModal");
        $A.util.addClass(modal,"slds-hide");
    },
    clearMessage : function(component, event, helper){
        helper.clearMessage(component, event);
    },
    schedulePO : function(component, event, helper){
        debugger;
        helper.toggleSpinner(component, event);
        helper.schedulePeelOff(component, event);
    },
    assignDotCheck : function(component, event, helper){
        debugger;
        //in cases where they ALREADY have a check number assigned; we want to make sure 
        // the host users know they are overwriting that.
        var curCheckNumber = component.get("v.Respondent.tr.Check_Number__c");
        var doAssignCheck = false;
        if(curCheckNumber == "" || curCheckNumber == undefined) {
            doAssignCheck = true;
        } else {
            var doConfirm = confirm("This respondent has already been assigned a Check Number.  Click OK if you want to over-write it.");
            if(doConfirm) {
                doAssignCheck = true;
            } 
        }

        debugger;
        helper.toggleSpinner(component, event);
        if(doAssignCheck) {
            helper.assignDOTcheck(component, event);
        } else {
            helper.toggleSpinner(component, event);
        }
        var modal = component.find("DotCheckrModal");
        $A.util.addClass(modal,"slds-hide");


    }//,
    //assignPsaCheck : function(component, event, helper){
        //right now - do nothing
        //helper.assignPSAcheck(component, event);
        //var modal = component.find("DotCheckrModal");
        //$A.util.addClass(modal,"slds-hide");
    //}
})