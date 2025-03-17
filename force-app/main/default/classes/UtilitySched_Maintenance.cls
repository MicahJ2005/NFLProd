global class UtilitySched_Maintenance implements Schedulable {
/**
*   {Purpose}  �  Schedules hourly cleanup tasks
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032
*
*   {EXECUTION}  �  System.schedule('Hourly Beacon Results Job', '0 0 * * * ?', new UtilitySched_Maintenance());
*              
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20141103  	Andy Boettcher DCS		Created
*	20150427	Andy Boettcher DCS 		Refactored to remove Data components to UtilitySched_MaintData
*   =============================================================================
*/
	global void execute(SchedulableContext sc) {
		
		// Beacon Sweeper
		UtilityBatch_DecipherSweeper batchSweeper = new UtilityBatch_DecipherSweeper();
		database.executeBatch(batchSweeper, 1);

	}
}