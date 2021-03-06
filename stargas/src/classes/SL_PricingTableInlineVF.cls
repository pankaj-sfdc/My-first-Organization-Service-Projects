/**  
* \arg ClassName      : SL_PricingTableInlineVF
* \arg JIRATicket     : STARGAS-10
* \arg CreatedOn      : 16/JUL/2014
* \arg LastModifiedOn : 8/JUNE/2015
* \arg CreatedBy      : SRUTI
* \arg ModifiedBy     : Pankaj Ganwani
* \arg Description    : This is controller class for SL_PricingTableInlineVFRecords page.
*/
global without sharing class SL_PricingTableInlineVF
{
    public String strOpportunityId      {get;set;}//!< Hold the Opportunity Id.
    public String strsObjectName        {get;set;}//!< Hold the object name
    public String strfieldSetName       {get; private set;}//!< Hold the Fieldset name
    public String strfilter             {get;set;}//!< Hold the filter query
    public String strTankType           {get; private set;}//!< Hold the Tank ypeto be passed to Component displaying Price table Records
    public String strDivision           {get; private set;}//!< Hold the Division to be passed to Component displaying Price table Records
    public String strDivisionGroup      {get; private set;}//!< Hold the Division Group to be passed to Component displaying Price table Records
    public String strCustomerOwned		{get; set;}// This variable is used to hold the value of customer owner field that is to be passed to component for displaying price table records.
    public Opportunity oppty            {get; set;} //!< Hold the Opportunity Binded with the page
    public Boolean isCeiling            {get; set;} //!< Checks whether the Opportunity's Price type is of Type "Ceiling"
    
    enum PricingType{Fixed, Ceiling, Variable, Tier, yr}
    
    public SL_PricingTableInlineVF(ApexPages.StandardController stdController)
    {
        strOpportunityId = (Id)stdController.getRecord().Id;
        isCeiling = false;
        //Querying Opportunity
        oppty = [Select Id, RecordType.Name, Price_Gallon__c, Tank_Type_form__c, Fixed_Price__c, Sub_Level__c , Pricing_Type__c, Override__c, Override_Variable__c, Override_Ceiling_Initial__c,
                    Override_Ceiling_Limit__c, Override_Fixed_Price__c, Ceiling_Initial__c, Ceiling_Limit__c, Ceiling_Fee__c, Variable__c, ZL_Database__c, ZL_Division__c, Customer_Owned__c,
                    Territory__r.Division__r.Division_Oil_Pricing_Group__c,Enable_Override_Fields__c, Override_Reason__c, Territory__r.Division__r.Name , Territory__r.Division__r.Service_Company__c From Opportunity where Id =: strOpportunityId];
        String strRecordName = oppty.RecordType.Name;
        
        if(oppty.Pricing_Type__c != Null && oppty.Pricing_Type__c != '')
        {
            isCeiling = isCeilingTrue(oppty.Pricing_Type__c);
        }
        oppty.Enable_Override_Fields__c = false;
        //Initializing the variables 
        strTankType = strDivision = '';
        //Required values to be passed to Component
        strsObjectName = 'Price_Table__c';
        strfieldSetName = strRecordName == 'Oil'? 'Oil_Rec_Fieldset' : (strRecordName == 'Propane'? 'Propane_Rec_Fieldset' :'');
        strfilter = strRecordName == 'Oil'? (' where RecordType.Name = \'Oil\'') : (strRecordName == 'Propane'? (' where RecordType.Name = \'Propane\'') :'');
        String strFilterActiveRecords = ' IsActive__c = True';
        
        strfilter += strfilter == ''? (' WHERE'+strFilterActiveRecords) : (' AND '+strFilterActiveRecords);
        String strDivisionServiceCompany = oppty.Territory__r.Division__r.Service_Company__c;
        if(strRecordName == 'Propane' && strDivisionServiceCompany == 'Patriot Propane')
        {
        	strfilter += strfilter == ''? (' WHERE Division_Name__r.Name ='+'\''+oppty.Territory__r.Division__r.Name+'\'') : (' AND Division_Name__r.Name ='+'\''+oppty.Territory__r.Division__r.Name+'\'');
        }
        
        if(Oppty.Tank_Type_form__c != null && Oppty.Tank_Type_form__c != '')
            strTankType = Oppty.Tank_Type_form__c;
        
        if(Oppty.ZL_Division__c != null)
            strDivision = Oppty.ZL_Division__c;
            
        strDivisionGroup =  Oppty.Territory__r.Division__r.Division_Oil_Pricing_Group__c;
        strCustomerOwned = Oppty.Customer_Owned__c;
    }
     /** 
        * @Name      : isCeilingTrue()
        * @parameter : Opportunity Pricing type
        * @Description  : It will return true if Pricing Type comes under Ceiling
    */ 
    private Boolean isCeilingTrue(String strPricingType)
    {
        if(strPricingType == 'Ceiling with fee')
            return false;
        else
            return ((New set<String>{'Min Ceiling', 'Max Ceiling', 'Min Ceiling 3 Years', 'Ceiling','Max Ceiling 3 Years', '2nd Max Ceiling 3 Years','2yr Ceiling'}).contains(strPricingType));
    }

    /** 
        * @Name      : updateOpportunity()
        * @parameter : Opportunity Id, Selected Price table Id
        * @Description  : It will update the Opportunity based on the values of Price Table selected
    */
    @RemoteAction  
    global static String updateOpportunityRemote(String opportunityId, String strPriceTableId, String priceType) 
    {
        try
        {
            if(strPriceTableId != null)
            {
                Opportunity objOpportunity = [Select Id, RecordType.Name, RecordType.DeveloperName, Sub_Level__c ,ZL_Division__c, Tank_Type_form__c , Price_Gallon__c, Fixed_Price__c, Pricing_Type__c, Override__c, 
                Override_Fixed_Price__c, Ceiling_Initial__c, Ceiling_Limit__c, Ceiling_Fee__c, Variable__c,Override_Variable__c, Override_Ceiling_Initial__c, Customer_Owned__c, Is_Budget__c,
                Override_Ceiling_Limit__c, Override_Reason__c From Opportunity where Id =: opportunityId];
                
                Boolean isPropane = objOpportunity.RecordType.DeveloperName == 'Propane' ? true : false;
                
                String strQuery = 'select ID, Variable_Price__c, Price_Type__c, Override_Fixed_Price__c, Fixed_Price__c, Ceiling_Limit__c, Ceiling_Initial__c, Ceiling_Fee__c, Tier_Num__c, Propane_BPC__c '
                                        +' From Price_Table__c where Id= \''+strPriceTableId+'\' AND IsActive__c = true LIMIT 1'  ; 
                
                //Querying Price Table to update the values on Opportunity from     
                List<Price_Table__c> lst = database.query(strQuery);
                if(!lst.isEmpty())
                {                     
                    String strPriceType = lst[0].Price_Type__c;
                    //Updating price type, fixed price, variable price, ceiling initial, celing limit and ceiling fee on Opportunity
                    objOpportunity = new Opportunity(Pricing_Type__c = strPriceType,
                                                    Fixed_Price__c = lst[0].Fixed_Price__c, 
                                                    Ceiling_Initial__c = lst[0].Ceiling_Initial__c, 
                                                    Ceiling_Limit__c = lst[0].Ceiling_Limit__c,
                                                    Ceiling_Fee__c = lst[0].Ceiling_Fee__c ,
                                                    Id = opportunityId,
                                                    Is_Budget__c = objOpportunity.Is_Budget__c,
                                                    Override__c = false, Enable_Override_Fields__c = false);
                    
                    if(isPropane)
                    	objOpportunity.Propane_BPC__c = lst[0].Propane_BPC__c;
                    
                    if(strPriceType!=priceType)
                        objOpportunity.Override_Reason__c = null;
                    
                    if(lst[0].Variable_Price__c!=null)
                    	objOpportunity.Variable__c = lst[0].Variable_Price__c;
                    if(String.isNotEmpty(strPriceType))
                    {
                        if(strPriceType.contains(PricingType.Tier.name()) && strPriceType!=priceType)
                        {
                            objOpportunity.Override_Fixed_Price__c = null;
                            objOpportunity.Propane_Pricing_Sub_Level__c = lst[0].Tier_Num__c!=null ? Decimal.valueOf(lst[0].Tier_Num__c) : null;
                        }
                        else if(strPriceType.contains(PricingType.Fixed.name()))
                            objOpportunity.Override_Variable__c = objOpportunity.Override_Ceiling_Initial__c = objOpportunity.Override_Ceiling_Limit__c = null;
                        else if(strPriceType.contains(PricingType.Variable.name()))
                            objOpportunity.Override_Ceiling_Initial__c = objOpportunity.Override_Ceiling_Limit__c = objOpportunity.Override_Fixed_Price__c = null;
                        else if((strPriceType.contains(PricingType.Ceiling.name()) || strPriceType.contains(PricingType.yr.name())) && strPriceType!=priceType)
                            objOpportunity.Override_Ceiling_Initial__c = objOpportunity.Override_Ceiling_Limit__c = objOpportunity.Override_Fixed_Price__c =  objOpportunity.Override_Variable__c = null;                           
                    }                    
                    update objOpportunity;
                }
                return 'success';
            }
        }
        catch(Exception e)
        {
        	return e.getMessage();
        }
        return '';
    }
    
    /** 
        * @Name      : updateOpportunity()
        * @parameter : None 
        * @Description  : It will update the Opportunity based on the values of Price Table selected
    */  
    public void updateOpportunity()
    {
        try
        {
            oppty.Override__c = false;
            //Making all override fields as Null, when Override Checkbox is unchecked
            if(!oppty.Enable_Override_Fields__c && oppty.RecordType.Name == 'Oil')
            {
                oppty.Override_Variable__c = null;
                oppty.Override_Ceiling_Initial__c = null;
                oppty.Override_Ceiling_Limit__c = null;
                oppty.Override_Fixed_Price__c = null;
                oppty.Override_Reason__c = null;
                oppty.Override__c = false;
            }
            isCeiling = false;
            if(oppty.Pricing_Type__c!=NULL && (((oppty.Pricing_Type__c.contains('Fixed') || oppty.Pricing_Type__c.contains('Tier')) && oppty.Override_Fixed_Price__c!=NULL) || (oppty.Pricing_Type__c.contains('Variable') && oppty.Override_Variable__c!=NULL) || (oppty.Pricing_Type__c.contains('Ceiling') && (oppty.Override_Ceiling_Initial__c!=NULL || oppty.Override_Ceiling_Limit__c!=NULL))))
            {
            	oppty.Override__c = true;
            }
            try
            {
           	 	update oppty;
            }
            catch(Exception ex)
            {
            	return;
            }
            refreshOpportunity();
            
            if(oppty.Pricing_Type__c != Null && oppty.Pricing_Type__c != '')
                isCeiling = isCeilingTrue(oppty.Pricing_Type__c);
        }
        catch(Exception e)
        {
        }
    }
     
    /** 
        * @Name      : refreshOpportunity()
        * @parameter : None 
        * @Description: Refresh the Opportunity
    */  
    public void refreshOpportunity()
    {
        oppty = [Select Id, RecordType.Name, Price_Gallon__c, Fixed_Price__c, Tank_Type_form__c, Sub_Level__c, Pricing_Type__c, Override__c, Override_Variable__c, 
        Override_Ceiling_Initial__c, Override_Ceiling_Limit__c,ZL_Database__c ,ZL_Division__c,Territory__r.Division__r.Division_Oil_Pricing_Group__c,
                                            Override_Fixed_Price__c, Ceiling_Initial__c, Ceiling_Limit__c, Ceiling_Fee__c, Variable__c,Customer_Owned__c,Enable_Override_Fields__c,
                                            Override_Reason__c From Opportunity where Id =: strOpportunityId];
        
        //oppty.Enable_Override_Fields__c = false;
        isCeiling = false;
        if(oppty.Pricing_Type__c != Null && oppty.Pricing_Type__c != '')
            isCeiling = isCeilingTrue(oppty.Pricing_Type__c);
        if(Oppty.Tank_Type_form__c != null && Oppty.Tank_Type_form__c != '')
            strTankType = Oppty.Tank_Type_form__c;
        
        if(Oppty.ZL_Division__c != null)
            strDivision = Oppty.ZL_Division__c;
            
        strDivisionGroup =  Oppty.Territory__r.Division__r.Division_Oil_Pricing_Group__c;
        strCustomerOwned = Oppty.Customer_Owned__c;
    }
    
    public void dummy(){}
}