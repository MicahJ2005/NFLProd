public inherited sharing class ProjectTrackerController {
    
    //public List<String> milestones {get; set;}
    //public Map<String, List<milestoneLine>> milestoneDataMap {get; set;}
    public void doNothing() {}
/** 
    public Map<Decimal, Map<Id, milestoneLine>> milestoneNumToProjIdToLine {get; set;}
    public Map<Decimal, String> milestoneNumToMilestone {get; set;}
    public Map<Id, String> projectIdToProject {get; set;}
    public Map<Id, milestoneLine> projectIdToApprovalDate { get; set; }
    public Map<Id, milestoneLine> projectIdToOppOwner { get; set; }
    public Map<Id, milestoneLine> projectIdToProjCoord { get; set; }

    public String[] selectedOppOwners = new String[]{};
    public List<String> ownerIds = new List<String>();

    public Set<Decimal> milestoneKeySet {get; set;}
    public Set<Id> projectKeySet {get; set;}
    public Map<Id, Id> oppIdToProjId {get; set;}

    public Boolean showTable { get; set; }
    

    public List<SelectOption> getOwners() {
        loadOwners();
        List<SelectOption> options = new List<SelectOption>();
        Map<Id, String> idToOwnerMap = new Map<Id, String>();
    
        for(User u : [SELECT Id, Name FROM User 
                        WHERE Id IN (SELECT UserOrGroupId 
                                        FROM GroupMember 
                                        WHERE Group.Name = 'Project Tracker - Opp Owners')
                        ORDER BY Name]) {
            idToOwnerMap.put(u.Id, u.Name);
        }            

        for(Id ownerId : idToOwnerMap.keySet()) {
            options.add(new SelectOption(ownerId,idToOwnerMap.get(ownerId)));
        }
        return options;
    }
        
    public String[] getSelectedOppOwners() {
        return selectedOppOwners;
    }
        
    public void setSelectedOppOwners(String[] selectedOppOwners) {
        this.selectedOppOwners = selectedOppOwners;
    }

    public PageReference doFilter() {
        PageReference filterPage = new PageReference('/apex/ProjectTracker?oppowners=' + this.selectedOppOwners);
        filterPage.setRedirect(true);
        return filterPage;
    }

    public PageReference showAll() {
        PageReference showAllPage = new PageReference('/apex/ProjectTracker');
        showAllPage.setRedirect(true);
        return showAllPage;
    }

    public ProjectTrackerController() {
        showTable = false;
        loadOwners();
        loadTable();
    }

    private void loadOwners() {
        //get owner Ids from the URL
        String ownerIds_Str = ApexPages.currentPage().getParameters().get('oppowners');
        if(ownerIds_Str != null && ownerIds_Str != '') {
            //trim off the parenthesis
            ownerIds_Str = ownerIds_Str.replace('(', '').replace(')', '');
        }
        //is it empty now?  That we stripped off the parens?
        if(ownerIds_Str != null && ownerIds_Str != '') {
            ownerIds = ownerIds_Str.split(', ');
            system.debug('DC: ownerIds: ' + ownerIds);
            setSelectedOppOwners(ownerIds);
        }
    }

    private void loadTable() {
                //Query for Milestone names and order in the Project Tracker metadata
                milestoneNumToMilestone = new Map<Decimal, String>();
                milestoneNumToProjIdToLine = new Map<Decimal, Map<Id, milestoneLine>>();
                
                List<String> uniqueMilestoneNames = new List<String>();
                Map<String, String> milestoneAlternates = new Map<String, String>();
                Map<String, Decimal> milestoneNameToOrder = new Map<String, Decimal>();
                
                for(Project_Tracker_Milestones__mdt ptm : [SELECT MasterLabel, Alternate_Name_1__c, Order__c 
                                                            FROM Project_Tracker_Milestones__mdt 
                                                            ORDER BY Order__c]) {
                    uniqueMilestoneNames.add(ptm.MasterLabel);
                    milestoneNameToOrder.put(ptm.MasterLabel, ptm.Order__c);
                    if(ptm.Alternate_Name_1__c != '' && ptm.Alternate_Name_1__c != null) {
                        uniqueMilestoneNames.add(ptm.Alternate_Name_1__c);
                        milestoneAlternates.put(ptm.Alternate_Name_1__c, ptm.MasterLabel);
                        milestoneNameToOrder.put(ptm.Alternate_Name_1__c, ptm.Order__c);
                    }
                    milestoneNumToMilestone.put(ptm.Order__c, ptm.MasterLabel);
                }
        
                //Query for all Milestones under open Projects
                projectIdToProject = new Map<Id, String>();
                projectKeySet = new Set<Id>();
                projectIdToApprovalDate = new Map<Id, milestoneLine>();
                projectIdToOppOwner = new Map<Id, milestoneLine>();
                projectIdToProjCoord = new Map<Id, milestoneLine>();

                oppIdToProjId = new Map<Id, Id>();
        
                List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
                
                if(ownerIds.size() <= 0) {
                    milestoneList = [SELECT Id, Name, pse__Target_Date__c, pse__Actual_Date__c, pse__Status__c
                    , pse__Project__r.pse__Opportunity__c
                    , pse__Project__c, pse__Project__r.Name, pse__Project__r.pse__Opportunity__r.OwnerId
                    , pse__Project__r.pse__Opportunity__r.Owner.Name 
                    FROM pse__Milestone__c   
                    WHERE pse__Project__r.Include_in_Project_Tracker__c = true
                    AND Name IN :uniqueMilestoneNames
                    ORDER BY pse__Project__r.pse__Start_Date__c
                    LIMIT 1000];
                } else {
                    system.debug('DC: in the else');
                    milestoneList = [SELECT Id, Name, pse__Target_Date__c, pse__Actual_Date__c, pse__Status__c
                    , pse__Project__r.pse__Opportunity__c
                    , pse__Project__c, pse__Project__r.Name, pse__Project__r.pse__Opportunity__r.OwnerId
                    , pse__Project__r.pse__Opportunity__r.Owner.Name 
                    FROM pse__Milestone__c  
                    WHERE pse__Project__r.Include_in_Project_Tracker__c = true
                    AND Name IN :uniqueMilestoneNames
                    AND pse__Project__r.pse__Opportunity__r.OwnerId IN :ownerIds
                    ORDER BY pse__Project__r.pse__Start_Date__c
                    LIMIT 1000];
                }
                system.debug('DC: milestoneList: ' + milestoneList);

                for(pse__Milestone__c m : milestoneList) {
        
                    projectIdToProject.put(m.pse__Project__c, m.pse__Project__r.Name);
                    projectKeySet.add(m.pse__Project__c);
                    projectIdToApprovalDate.put(m.pse__Project__c, new milestoneLine(m.Id, null, ''));
                    projectIdToOppOwner.put(m.pse__Project__c, new milestoneLine(m.Id, null, ''));
                    projectIdToProjCoord.put(m.pse__Project__c, new milestoneLine(m.Id, null, ''));

                    oppIdToProjId.put(m.pse__Project__r.pse__Opportunity__c, m.pse__Project__c);
        
                } //end first loop against milestoneList
        
                //Get the opportunity Approval Dates for each project
                for(pse__Proj__c proj : [SELECT Id, pse__Opportunity__c, pse__Opportunity__r.Approval_Date__c, pse__Opportunity__r.Owner.Name FROM pse__Proj__c WHERE Id IN :projectKeySet]) {
                    projectIdToApprovalDate.put(proj.Id, new milestoneLine(null, proj.pse__Opportunity__r.Approval_Date__c, ''));
                    projectIdToOppOwner.put(proj.Id, new milestoneLine(null, proj.pse__Opportunity__r.Owner.Name));
                }

                //Get the Proj. Coordinators from the Master Test
                for(AggregateResult ar : [SELECT Opportunity__c, MAX(Field_Coordinator_Name__c) projCoordName
                                            FROM Master_Test__c
                                            WHERE Opportunity__c IN :oppIdToProjId.keySet()
                                            GROUP BY Opportunity__c]) {
                    Id tmpProjId = oppIdToProjId.get((Id)ar.get('Opportunity__c'));
                    projectIdToProjCoord.put(tmpProjId, new milestoneLine(null, (String)ar.get('projCoordName')));           
                }

        
                //for each Milestone in the metadata and project in the keyset - we need to have at least a blank milestoneLine
                for(Decimal milestoneNum : milestoneNumToMilestone.keySet()) {
                    Map<Id, milestoneLine> tmpMap = new Map<Id, milestoneLine>();
                    for(Id projId : projectKeySet) {
                        tmpMap.put(projId, new milestoneLine(null, null, ''));
                    }
                    milestoneNumToProjIdToLine.put(milestoneNum, tmpMap);
                }
        
                for(pse__Milestone__c m : milestoneList) {
        
                    //Build our milestoneLine with the date/color
                    milestoneLine ml = new milestoneLine(m.Id, getDate(m.pse__Target_Date__c, m.pse__Actual_Date__c), getColor(m.pse__Status__c, m.pse__Target_Date__c));
        
                    //Based on the Milestone Name; get the Milestone Order
                    Decimal mOrder = milestoneNameToOrder.get(m.Name);
                    if(mOrder != null) {
                        //Make the project ID map
                        Map<Id, milestoneLine> tmpProjToML = milestoneNumToProjIdToLine.get(mOrder);
                        tmpProjToML.put(m.pse__Project__c, ml);
                        milestoneNumToProjIdToLine.put(mOrder, tmpProjToML);
                    }
                }
        
                milestoneKeySet = milestoneNumToProjIdToLine.keySet();
                showTable = true;
    }

    public PageReference export() {
        PageReference expPage = new PageReference('/apex/ProjectTracker_Export?oppowners=' + this.selectedOppOwners);
        expPage.setRedirect(true);
        return expPage;
    }

    private String getColor(String status, Date target) {
        String returnVal = 'white';
        if(status == 'Completed') {
            returnVal = '#99DE97'; //green
        }
        else if(status == 'Canceled') {
            returnVal = '#C4C4C4'; //grey
        }
        else {
            if(target < Date.today()) {
                returnVal = '#ED6D6D'; //red
            } else if(target <= Date.today().addDays(7)) {
                returnVal = '#FFFEAC'; //yellow
            }
        }
        return returnVal;
    }

    private Date getDate(Date target, Date actual) {
        Date returnVal = actual;
        if(actual == null) {
            returnVal = target;
        }
        return returnVal;
    }

    public class milestoneLine {
        public String Id {get; set;}
        public String displayText {get; set;}
        public Date displayDate {get; set;}
        public String color {get; set;}
        public Boolean showDate {get; set;}

        public milestoneLine( String mId, String dText) {
            Id = mId;
            displayText = dText;
            displayDate = null; 
            color = '';
            showDate = false;
        }

        public milestoneLine( String mId, Date dDate, String clr) {
            Id = mId;
            displayText = '';
            displayDate = dDate; 
            color = clr;
            showDate = true;
        }
    }
    */
}