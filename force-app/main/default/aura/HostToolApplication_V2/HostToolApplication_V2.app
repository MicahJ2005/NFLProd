<!-- v2 version created so two Host Tools can run side by side
    The team can use V2 and test in production; but if there are issues - they can go back to using V1-->
<aura:application extends="force:slds" controller="HostToolLightning_V2">
    <aura:attribute name="MasterTestId" type="String"/>
	<aura:attribute name="badBehaviorText" type="String"/>
	<aura:attribute name="successMessages" type="String[]"/>
    <div class="slds">
        <div class="slds-page-header">
          <div class="slds-grid">
            <div class="slds-col slds-has-flexi-truncate">
              <p class="slds-text-heading--label">Host Tool (v2)</p>
              <div class="slds-grid">
                <div class="slds-grid slds-no-space slds-size--7-of-8">
                  <h1 class="slds-text-heading--medium slds-truncate" title="Host Tool">Host Tool</h1>
                </div>
				<aura:if isTrue="{!v.MasterTestId}">
					<div class="slds-size--1-of-8">
						<div class="slds-text-align--center">
							Bad Behavior<br />
							<span class="slds-icon_container slds-type-focus slds-icon_container--circle" onclick="{!c.openHelpModal}">
								<lightning:icon iconName="utility:dislike" size="smalll" alternativeText="Help Needed"/>
							</span>
							<span class="slds-assistive-text">Help</span>
						</div>
					</div>
				</aura:if>
                
              </div>
            </div>
          </div>
        </div>
        
        <div aura:id="mainHostTool" class="slds-col--padded slds-p-top--large">
            <c:HostTool_V2 MasterTestId="{!v.MasterTestId}" successMessages="{!v.successMessages}"/>
        </div>
    </div>
    
    <div aura:id="HelperModal" class="slds-hide" style="width: 100px">
		<div role="dialog" tabindex="-1" class="slds-modal slds-fade-in-open" aria-labelledby="header43">
			<div class="slds-modal__container" style="width: 75%">
				<div class="slds-modal__header">
					<div align="right">
						<lightning:buttonIcon iconName="utility:close" variant="bare" onclick="{!c.closeHelpModal}" alternativeText="Close window."/>
					</div>
					<h2 id="header43" class="slds-text-heading--medium">Bad Behavior</h2>
				</div>
				<div class="slds-box sldx-box--small slds-theme--shade">
					<lightning:textarea name="bad-behavior-input" label="Description" value="{!v.badBehaviorText}" placeholder="type details here..."/><br/>
					<lightning:button variant="brand" label="Submit" title="Submit" onclick="{! c.sendBadBehaviorEmail }" />
				</div>
			</div>
		</div>
		<div class="slds-backdrop slds-backdrop--open"></div>
	</div>
</aura:application>