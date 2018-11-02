//+------------------------------------------------------------------+
//|                                        Market Short by Steve.mq4 |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Steve Wilson "
#property link      ""
#property show_inputs
#include <stdlib.mqh>
// Version 1.4 //


extern string  ins0="Number orders to place";   
extern int     Number_of_order = 1;
extern bool    UseExistingStops = true;
extern double  Lots=0;
extern string  ins1="Risk Percent. 0=Disabled";
extern double  Risk=0.5;
extern string  ins2="Stop loss and take profit as price";    
extern double  SlAsPrice;
extern double  TpAsPrice;
extern string  ins3="Stop loss and take profit as pips";    
extern double  SlAsPips=25;
extern double  TpAsPips=50;
extern double  Slippage = 1;
extern int     MagicNumber=7077;
extern string  TradeComment = "";

int Width = 1376;
int Height = 768;
double takeprofit,StopLoss,StopLossPips, Slip;
int Divisor=1, ticket=0, sellOrders, totalOrders;

double MinLotSize,MaxLotSize,point,AmountAtRisk,PointCostValue,LotSize;
double FirstOrderTicket,FirstOrderTakeProfit, FirstOrderStopLoss,FirstOrderOpenPrice;
string Currency="";
string SymbolExtra="";
string Lot="";

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
{
  
  int err ;
  int i = 0;
  Slip = Slippage;
  double     FiveDigitM;
//----

  if(StringFind(Symbol(), "JPY",0) > 0)
         FiveDigitM = 100 ;
      else  
         FiveDigitM = 10000 ;

   point=Point;
   if(Digits == 5 || Digits == 3 || Symbol() == "XAUUSD") 
   {
      point = Point * 10 ; 
      Slip = Slippage * 10;
      Divisor = 10;
   } 

   sellOrders = CountOrders(Symbol(), MagicNumber, OP_SELL);
         
   if (TpAsPrice==0 && TpAsPips==0) takeprofit=0;
   if (!TpAsPips==0) takeprofit = Bid - TpAsPips / FiveDigitM;
   if (!TpAsPrice==0) takeprofit=TpAsPrice;
   
   if (SlAsPrice==0 && SlAsPips==0) StopLoss=0;
   if (!SlAsPips==0) StopLoss = Bid + SlAsPips / FiveDigitM ;    
   if (!SlAsPrice==0) StopLoss=SlAsPrice;
   
   StopLossPips = (StopLoss - Bid) / point;
 
   if(UseExistingStops && sellOrders>0)
   {
      FirstOrderTicket=GetFirstTicketBymagic(MagicNumber); 
      StopLossPips = (FirstOrderStopLoss-Bid) / point;
   }
 
 
    PointCost();
    if(Lots==0) Calc();
 
if(!UseExistingStops || sellOrders==0)
{       
   ticket=0;
   for(i = 0; i < Number_of_order; i++)
   {
      ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slip,0,0,TradeComment,MagicNumber,0,Red);
      
      err = GetLastError() ;
      
      if ( err  != 0)
             Alert("Failed to create Order. Error = ",ErrorDescription(err)) ;
      else
      {
 
         OrderModify(ticket ,OrderOpenPrice(), StopLoss,takeprofit,0,CLR_NONE);
         err = GetLastError() ;
   
         if ( err  != 0)
                Alert("Failed to Modify Order. Error = ",ErrorDescription(err), " Order Id:, ", ticket, " Limit = ", takeprofit, " Stop loss = ", StopLoss ) ;
         else
                PlaySound("ok.wav") ;
      }
      
      WindowScreenShot("ScreenShots\\"+Symbol()+"_M"+Period()+"\\"+Symbol()+"_M"+ Period()+"_"+TimeToStr(iTime(NULL, 0, 0),TIME_DATE)+"_"+TimeHour(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+".png",Width,Height);
   }
}

if(UseExistingStops && sellOrders>0)
{       
   ticket=0;
   for(i = 0; i < Number_of_order; i++)
   {
      ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slip,0,0,TradeComment,MagicNumber,0,Red);
      
      err = GetLastError() ;
      
      if ( err  != 0)
             Alert("Failed to create Order. Error = ",ErrorDescription(err)) ;
      else
      {
 
         OrderModify(ticket ,OrderOpenPrice(), FirstOrderStopLoss,FirstOrderTakeProfit,0,CLR_NONE);
         err = GetLastError() ;
   
         if ( err  != 0)
                Alert("Failed to Modify Order. Error = ",ErrorDescription(err), " Order Id:, ", ticket, " Limit = ", takeprofit, " Stop loss = ", StopLoss ) ;
         else
                PlaySound("ok.wav") ;
      }
      
      WindowScreenShot("ScreenShots\\"+Symbol()+"_M"+Period()+"\\"+Symbol()+"_M"+ Period()+"_"+TimeToStr(iTime(NULL, 0, 0),TIME_DATE)+"_"+TimeHour(TimeCurrent())+"_"+TimeMinute(TimeCurrent())+"_"+TimeSeconds(TimeCurrent())+".png",Width,Height);
   }
}
    

   OrderPrint();

   return(0);
}


 
double PointCost() 
{
   double LotCost;
   Currency=AccountCurrency(); 
   LotCost = MarketInfo(Symbol(), MODE_TICKVALUE) * Divisor;   
   return (LotCost);
}

void Calc()
{

AmountAtRisk=AccountBalance()*Risk*0.01;
PointCostValue=PointCost();
Lots=AmountAtRisk/StopLossPips/PointCostValue;


   if(Lots < MarketInfo(Symbol(), MODE_MINLOT)) 
   Lots = MarketInfo(Symbol(), MODE_MINLOT);
   if(Lots > MarketInfo(Symbol(), MODE_MAXLOT)) 
   Lots = MarketInfo(Symbol(), MODE_MAXLOT);
   Lot=DoubleToStr(Lots,2);
   Lot=Lots;

return;   
}




int GetFirstTicketBymagic(int magicNumber)
{
	return (GetFirstTicket(Symbol(), magicNumber, -1));
}

int GetFirstTicket(string symbol="", int magicNumber=-1, int cmd=-1)
{
string   t_symbol = Symbol();
int      t_magicNumber = magicNumber;
int	t_cmd = cmd;
	
	int CurrPositions = OrdersTotal();
	for (int t_index=CurrPositions-1; t_index>=0; t_index--)
	{
		OrderSelect(t_index, SELECT_BY_POS, MODE_TRADES);
		if ((t_symbol=="" || OrderSymbol()==t_symbol) &&
			  (t_magicNumber==-1 || OrderMagicNumber()==t_magicNumber) &&
			  (t_cmd==-1 || OrderType()==t_cmd))
		{			
         FirstOrderTakeProfit = OrderTakeProfit();
         FirstOrderStopLoss = OrderStopLoss();			
			FirstOrderOpenPrice = OrderOpenPrice();
			return (OrderTicket());
		}	
	}
	return (0);
}

int CountOrders(string symbol="", int magicNumber=-1, int cmd=-1)
{
	totalOrders = 0;
	int CurrPositions = OrdersTotal();
	for (int i=0; i<CurrPositions; i++)
	{
		OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
		if ((symbol=="" || OrderSymbol()==symbol) &&
			  (magicNumber==-1 || OrderMagicNumber()==magicNumber) &&
			  (cmd==-1 || OrderType()==cmd)) 
		{
			totalOrders++;	
		}
	}
	
	return (totalOrders);
}




//+------------------------------------------------------------------+-+