({
    getUserSetting : function(component, event){
        var action = component.get("c.manageUserViewPreference");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.selectedView", response.getReturnValue());
                this.setInitalView(component, event);
            }            
        });
        $A.enqueueAction(action);
    },
    getMasterTestData : function(component, event){
        var action = component.get("c.getMasterTest");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.tests", response.getReturnValue());
                this.toggleSpinner(component, event);
            }             
        });
        $A.enqueueAction(action);
    },
    getSessionRecords : function(component, event){
        var action = component.get("c.fillRespondentList");
        action.setParams({idMasterTest : component.get("v.MasterTestId"), idSession: component.get("v.SessionId"), strRespSearch: component.get("v.SearchRespondent")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.sessions", response.getReturnValue());
                this.getSessionRecordsDisplay(component, event);
            }             
        });
        $A.enqueueAction(action);
    },
    getSessionRecordsDisplay : function(component, event){
        var that = this;
        component.set("v.respondentList",[]);
        var action = component.get("c.fillRespondentList");
        var refreshT = component.get("v.refreshTime");
        action.setParams({idMasterTest : component.get("v.MasterTestId"), idSession: component.get("v.SessionId"), strRespSearch: component.get("v.SearchRespondent"), strViewType: component.get("v.selectedView")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.sessionDisplays", response.getReturnValue());
                this.buildRespondentList(component, event);
                this.toggleSpinner(component, event);
            }             
        });
        $A.enqueueAction(action);
        if(refreshT == '5'){
            window.setTimeout(
                $A.getCallback(function(){
                    console.log('calling');
                    that.toggleSpinner(component, event);
                    that.getSessionRecordsDisplay(component, event);
                    }), 300000
            );
        }
        if(refreshT == '3'){
            window.setTimeout(
                $A.getCallback(function(){
                    console.log('calling');
                    that.toggleSpinner(component, event);
                    that.getSessionRecordsDisplay(component, event);
                    }), 180000
            );
        }
        if(refreshT == '1'){
            window.setTimeout(
                $A.getCallback(function(){
                    console.log('calling');
                    that.toggleSpinner(component, event);
                    that.getSessionRecordsDisplay(component, event);
                    }), 60000
            );
        }
    },
    getLatestDashboard : function(component, event){
        var action = component.get("c.updateTrackerStats");
        action.setParams({masterTestId : component.get("v.MasterTestId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.Dashboard", response.getReturnValue());
            }             
        });
        $A.enqueueAction(action);
    },
    setRespondentRecord : function(component, event){
        var selectedItem = event.currentTarget;
        var testRespID = selectedItem.getAttribute('data-respondentID');
        var sessionID = selectedItem.getAttribute('data-sessionID');
        var allSessions = component.get("v.sessionDisplays");
        var lenSes = allSessions.length;
        console.log('testResp: ' + testRespID);
        console.log('SesId: ' + sessionID);
        console.log('allSessions length: ' + lenSes); 
        for(var i=0; i<allSessions.length; i++){
            console.log(allSessions[i].ses.Id);
            if(allSessions[i].ses.Id === sessionID){
                for(var j=0; j<allSessions[i].lstTR.length; j++){
                    if(allSessions[i].lstTR[j].tr.Id === testRespID){
                        console.log(allSessions[i].lstTR[j].tr.Respondent__r.Name);
                        component.set("v.Respondent",allSessions[i].lstTR[j]);
                        component.set("v.RespondentSession",allSessions[i].ses)
                        var Rname = allSessions[i].lstTR[j].tr.Respondent__r.Name + ' - ' + allSessions[i].lstTR[j].tr.Respondent__r.PID__c + ' - ' + allSessions[i].lstTR[j].tr.Respondent__r.Gender__c;
                        component.set("v.RespondentName",Rname);
                        component.set("v.RespondentContactId", allSessions[i].lstTR[j].tr.Respondent__r.Id)
                    }
                }
            }
        }
    },
    getRespondentSearch : function(component, event){
        var action = component.get("c.fillRespondentList");
        action.setParams({idMasterTest : component.get("v.MasterTestId"), idSession: component.get("v.SessionId"), strRespSearch: component.get("v.SearchRespondent")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.sessionDisplays", response.getReturnValue());
                component.set("v.respondentList",[])
                this.buildRespondentList(component, event);
            }             
        });
        $A.enqueueAction(action); 
    },
    setUserSetting : function(component, event){
        var action = component.get("c.updateUserViewPreference");
        action.setParams({strViewType : component.get("v.selectedView")});
        action.setCallback(this, function(response){
            this.setView(component, event);           
        });
        $A.enqueueAction(action);
    },
    setInitalView : function(component, event){
        var vt = component.get("v.selectedView");
        if(vt === 'List View'){ 
            var viewType = component.find("SessionDiv");
        }
        else{
            var viewType = component.find("ListDiv");
        }
        $A.util.addClass(viewType,"slds-hide");
    },
    setView : function(component, event){
        var vt = component.get("v.selectedView");
        if(vt === 'List View'){
            var CurrentView = component.find("ListDiv");
            var OldView = component.find("SessionDiv");
        }
        else{
            var CurrentView = component.find("SessionDiv");
            var OldView = component.find("ListDiv");
        }
        $A.util.addClass(OldView,"slds-hide");
        $A.util.removeClass(CurrentView,"slds-hide");
    },
    sendEmailNotice : function(component, event){
        var emailType = event.currentTarget.getAttribute('data-type');
        var whatId = event.currentTarget.getAttribute('data-whatId');
        console.log('emailType: ' + emailType);
        var action = component.get("c.sendemailMessage");
        action.setParams({emailType : emailType, whatId : whatId});
        action.setCallback(this, function(response){
            component.set("v.message", response.getReturnValue());           
        });
        $A.enqueueAction(action);
    },
    getCommunications : function(component, event){
        var action = component.get("c.getcomms");
        action.setParams({masterTestId : component.get("v.MasterTestId"), sessionId: component.get("v.SessionId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                component.set("v.comms", response.getReturnValue());
            }             
        });
        $A.enqueueAction(action);
    },
    clearMessage : function(component, event){
        window.setTimeout(
            $A.getCallback(function(){
                console.log('clear message');
                component.set("v.message", null);
            }), 10000
        );
    },
    toggleSpinner : function(component, event){
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },
    buildRespondentList : function(component, event){
        var rlist = component.get("v.respondentList");
        var allSessions = component.get("v.sessionDisplays");
        for(var i=0; i<allSessions.length; i++){
            for(var j=0; j<allSessions[i].lstTR.length; j++){
                rlist.push(allSessions[i].lstTR[j]);
            }
        }
        component.set("v.respondentList", rlist);
    },
    sortData : function(component, event){
        debugger;
        var fldName = event.currentTarget.getAttribute('data-fldName');
        var sort = component.get("v.arrowAsc");
        var rlist = component.get("v.respondentList");
        var compare1 = 1;
        var compare2 = -1
        if(sort){
            sort = false;
            component.set("v.arrowAsc", false);
            compare1 = -1;
            compare2 = 1;
        } else{
            sort = true;
            component.set("v.arrowAsc", true);
            compare1 = 1;
            compare2 = -1;
        }
        if(fldName === 'tr.Session_Name__c'){
            rlist.sort(function(a,b){
                var aFld = String(a.tr.Session_Name__c);
                var bFld = String(b.tr.Session_Name__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent_Number__c'){
            debugger;
            rlist.sort(function(a,b){
                var aFld = a.tr.Respondent_Number__c;
                var bFld = b.tr.Respondent_Number__c;
                if(aFld === undefined) return 1;
                if(bFld === undefined) return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Tested_Status__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Tested_Status__c);
                var bFld = String(b.tr.Tested_Status__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent__r.FirstName'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Respondent__r.FirstName);
                var bFld = String(b.tr.Respondent__r.FirstName);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent__r.LastName'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Respondent__r.LastName);
                var bFld = String(b.tr.Respondent__r.LastName);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent__r.PID__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Respondent__r.PID__c);
                var bFld = String(b.tr.Respondent__r.PID__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent__r.Gender__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Respondent__r.Gender__c);
                var bFld = String(b.tr.Respondent__r.Gender__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent__r.Age__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Respondent__r.Age__c);
                var bFld = String(b.tr.Respondent__r.Age__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Respondent__r.IVRPhone__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Respondent__r.IVRPhone__c);
                var bFld = String(b.tr.Respondent__r.IVRPhone__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'strPairStyle'){
            rlist.sort(function(a,b){  
                var aFld = String(a.strPairStyle);
                var bFld = String(b.strPairStyle);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Donation_Amount_Per_Event__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Donation_Amount_Per_Event__c);
                var bFld = String(b.tr.Donation_Amount_Per_Event__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Organization__r.Name'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Organization__r.Name);
                var bFld = String(b.tr.Organization__r.Name);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }
        if(fldName === 'tr.Check_Number__c'){
            rlist.sort(function(a,b){  
                var aFld = String(a.tr.Check_Number__c);
                var bFld = String(b.tr.Check_Number__c);
                if(aFld === "undefined") return 1;
                if(bFld === "undefined") return -1;
                if(aFld < bFld) return compare1;
                if(aFld > bFld) return compare2;
                return 0;
            });
        }

        component.set("v.selectedColSort", fldName);
        component.set("v.respondentList", rlist);
    }
})