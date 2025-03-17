import {LightningElement, api, wire, track} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import apexGetMasterQuota from "@salesforce/apex/MasterQuotaDatatableController.getMasterQuota";
import apexSaveMasterQuota from "@salesforce/apex/MasterQuotaDatatableController.save";
import {refreshApex} from "@salesforce/apex";

const columns = [
    { label: 'Name', fieldName: "recordUrl", type: "url", typeAttributes: {label: {fieldName: "Name"}, target: "_self"}, sortable: true, cellAttributes: {alignment: "left"}},
    { label: 'Quota Summary', fieldName: 'Quota_Summary__c', type: 'text', sortable: true, editable: true },
    { label: 'Decipher Condition', fieldName: 'Beacon_Condition__c', type: 'text', sortable: true, editable: true  },
    { label: 'Minimum Respondents', fieldName: 'Minimum_Respondents__c', type: 'number', sortable: true, editable: true  },
    { label: 'Maximum Respondents', fieldName: 'Maximum_Respondents__c', type: 'number', sortable: true, editable: true  },
    { label: 'Tested Goal', fieldName: 'Tested_Goal__c', type: 'number', sortable: true, editable: true  },
    { label: 'Open for Recruiting', fieldName: 'IsOpen__c', type: 'boolean', sortable: true, editable: true, cellAttributes: {alignment: "center"}  },
    { label: 'Used for Scheduling', fieldName: 'IsScheduleEnabled__c', type: 'boolean', sortable: true, editable: true, cellAttributes: {alignment: "center"}  },
    { label: 'Secondary Quota', fieldName: 'IsTrackingOnly__c', type: 'boolean', sortable: true, editable: true, cellAttributes: {alignment: "center"}  },
    //{ label: 'Fill Weighting', fieldName: 'Fill_Weighting__c', type: 'number', sortable: true, editable: true  },
    { label: 'Master Quota Group', fieldName: 'MQG__c', type: 'number', sortable: true, editable: true  },
];

export default class MasterQuotaDatatable extends LightningElement {
    @api recordId;
    @track data = [];
    @track draftValues = [];
    lastSavedData = [];
    spinner = true;
    show = false;
    columns = columns;
    title = "Master Quota";
    sortDirection = "asc";
    sortedBy = "Name";

    _refreshTable;

    //Added to expand the size of the window when the button is clicked
    renderedCallback() {
        if(this.isLoaded) return;
        const STYLE = document.createElement("style");
        var myStyles =  '.uiModal--medium .modal-container {';
        myStyles += '    width: 100% !important;';
        myStyles += '    max-width: 100%;';
        myStyles += '    min-width: 480px;';
        myStyles += '    max-height: 100%;';
        myStyles += '    min-height: 480px;';
        myStyles += '}';
        STYLE.innerText = myStyles;
        this.template.querySelector('lightning-card').appendChild(STYLE);
        this.isLoaded = true;
    }

    @wire(apexGetMasterQuota, {recordId: "$recordId"})
    getRecords(value) {
        this._refreshTable = value;
        const {data, error} = value; // destructure the provisioned value
        if (data) {
            this.spinner = false;
            this.data = [];
            data.forEach((item) => {
                this.data.push(this.buildRow(item));
            });

            this.title = "Master Quota (" + this.data.length + ")";
            this.lastSavedData = this.proxyToObj(this.data);
            this.data.sort(this.sortBy(this.sortedBy, this.sortDirection === "asc" ? 1 : -1));
        } else if (error) {
            console.log(JSON.stringify(error, null, 4));
            this.spinner = false;
        }
    }

    handleClose(event) {
        this.show = false;
        this.refreshData();
    }

    onNewClick(event) {
        this.show = true;
    }

    updateDataValues(item) {
        let copyData = this.proxyToObj(this.data);
        var copyDataItem = copyData.find(({Id}) => Id === item.Id);
        Object.assign(copyDataItem, item);
        this.data = [...copyData];
    }

    updateDraftValues(item) {
        let copyDraft = this.proxyToObj(this.draftValues);
        var draftVaule = copyDraft.find(({Id}) => Id === item.Id);

        if (draftVaule) {
            Object.assign(draftVaule, item);
            this.draftValues = [...copyDraft];
        } else {
            this.draftValues = [...copyDraft, item];
        }
    }

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        this.updateDataValues(event.detail.draftValues[0]);
        this.updateDraftValues(event.detail.draftValues[0]);
    }

    handleSave(event) {
        var updateSet = [];
        var newSet = this.proxyToObj(this.draftValues);
        var oldSet = this.lastSavedData;

        newSet.forEach((newItem) => {
            var oldItem = oldSet.filter((obj) => {
                return obj.Id === newItem.Id;
            })[0];

            for (const [key, value] of Object.entries(newItem)) {
                if (oldItem[key] !== value) {
                    newItem.sobjectType = "Quota__c";
                    updateSet.push(newItem);
                    return;
                }
            }
        });
        this.saveRecords(updateSet);
    }

    saveRecords(records) {
        this.spinner = true;
        apexSaveMasterQuota({records: records})
            .then((result) => {
                this.lastSavedData = this.proxyToObj(this.data);
                this.draftValues = [];
                this.spinner = false;
                this.toast("Record Saved", "Save Successful", "success");
            })
            .catch((error) => {   //Fixed error body message so that it displays in toast message  JEA
                console.log('masterQuotadatatable.saveRecords Exception');
                console.log(JSON.stringify(error, null, 4));
                this.toast("Save Error", error.body.message , "error");
                this.spinner = false;
            });
    }

    handleCancel(event) {
        this.data = this.proxyToObj(this.lastSavedData);
        this.draftValues = [];
        this.refreshData();
    }

    proxyToObj(obj) {
        return JSON.parse(JSON.stringify(obj));
    }

    sortBy(field, reverse, primer) { 
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);

            if (typeof a !== "undefined" && typeof b !== "undefined") {
                return reverse * ((a > b) - (b > a));
            } else if (typeof a !== "undefined") {
                return -1;
            }
            return 1;
        };
    }

    onHandleSort(event) {
        const {fieldName: sortedBy, sortDirection} = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    //variant = warning,
    toast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: "dismissible"
        });
        this.dispatchEvent(evt);
    }

    refreshData() {
        return refreshApex(this._refreshTable);
    }

    buildRow(item) {
        var variable = Object.assign({}, item);
        variable["recordUrl"] = "/lightning/r/Quota__c/" + variable["Id"] + "/view";
        return variable;
    }
}