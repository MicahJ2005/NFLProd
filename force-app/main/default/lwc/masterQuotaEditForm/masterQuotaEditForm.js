import {LightningElement, api} from "lwc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class MasterQuotaEditForm extends LightningElement {
    @api related;
    spinner = false;
   
    onSubmitClick() {
        this.spinner = true;
        this.template.querySelector("lightning-record-edit-form").submit();
    }

    onSubmitHandler(event) {}

    onSuccessHandler(event) {
        this.spinner = false;
        this.showToast("Saved", "Record was saved successfully.", "success");
        this.close(event);
    }

    onErrorHandler(event) {
        this.spinner = false;
        this.showToast("Error saving record", event.detail.message + " : " + event.detail.detail, "error");
        console.log(JSON.parse(JSON.stringify(event, null, 4)));
    }

    showToast(title, message, type) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: "dismissible"
        });
        this.dispatchEvent(evt);
    }

    close(event) {
        const evnt = new CustomEvent("close", {
            detail: this.record
        });
        this.dispatchEvent(evnt);
    }

    
}