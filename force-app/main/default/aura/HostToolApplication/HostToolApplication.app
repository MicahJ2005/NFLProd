<aura:application extends="force:slds" controller="HostToolLightning">
    <aura:attribute name="MasterTestId" type="String"/>
    <div class="slds">
        <div class="slds-page-header">
          <div class="slds-grid">
            <div class="slds-col slds-has-flexi-truncate">
              <p class="slds-text-heading--label">Host Tool</p>
              <div class="slds-grid">
                <div class="slds-grid slds-type-focus slds-no-space slds-size--7-of-8">
                  <h1 class="slds-text-heading--medium slds-truncate" title="Host Tool">Host Tool</h1>
                </div>
                <div class="slds-size--1-of-8">
                    <div class="slds-text-align--center">
                        Request Help<br />
                        <span class="slds-icon_container slds-icon-action-announcement slds-icon_container--circle" onclick="{!c.openHelpModal}">
                            <lightning:icon iconName="action:announcement" size="smalll" alternativeText="Help Needed"/>
                        </span>
                        <span class="slds-assistive-text">Help</span>
                    </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div aura:id="mainHostTool" class="slds-col--padded slds-p-top--large">
            <c:HostTool MasterTestId="{!v.MasterTestId}"/>
        </div>
    </div>
    
    <div aura:id="HelperModal" class="slds-hide" style="width: 100px">
		<div role="dialog" tabindex="-1" class="slds-modal slds-fade-in-open" aria-labelledby="header43">
			<div class="slds-modal__container" style="width: 75%">
				<div class="slds-modal__header">
					<div align="right">
						<lightning:buttonIcon iconName="utility:close" variant="bare" onclick="{!c.closeHelpModal}" alternativeText="Close window."/>
					</div>
					<h2 id="header43" class="slds-text-heading--medium">Help Menu</h2>
				</div>
				<div class="slds-box sldx-box--small slds-theme--shade">
					<div class="slds-box sldx-box--small slds-text-align--center">
						Need another Host<br />
						<div class="slds-icon_container slds-icon-action-new_lead slds-icon_container--circle" onclick="{!c.emailRequest}" data-type="AnotherHost" data-whatId="{!v.MasterTestId}">
							<lightning:icon iconName="action:new_lead" size="medium" alternativeText="Done Checking In"/>
						</div>
					</div>
					<div class="slds-box sldx-box--small slds-text-align--center">
						Respondent Concern<br />
						<div class="slds-icon_container slds-icon-action-question_post_action slds-icon_container--circle" onclick="{!c.emailRequest}" data-type="RespondentConcern" data-whatId="{!v.MasterTestId}">
							<lightning:icon iconName="action:question_post_action" size="medium" alternativeText="Done Checking In"/>
						</div>
					</div>
					<div class="slds-box sldx-box--small slds-text-align--center">
						All Hands Call<br />
						<div class="slds-icon_container slds-icon-action-new_group slds-icon_container--circle" onclick="{!c.emailRequest}" data-type="AllHands" data-whatId="{!v.MasterTestId}">
							<lightning:icon iconName="action:new_group" size="medium" alternativeText="Done Checking In"/>
						</div>
					</div>
				</div>
			</div>
		</div>
		<div class="slds-backdrop slds-backdrop--open"></div>
	</div>
</aura:application>