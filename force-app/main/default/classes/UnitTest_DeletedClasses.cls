/**
 * Calls the "doNothing" methods of commented out classes
 */
@isTest
private class UnitTest_DeletedClasses {

    @isTest
    static void myUnitTest() {
        UtilitySoundex.doNothing();
        flowQuoteController.doNothing();
        Quote_Methods.doNothing();
        QuoteClone_Flow.doNothing();
        QuoteCloneController.doNothing();
        QuoteCloneClass.doNothing();
        QuoteSyncUtil.doNothing();
    }
}