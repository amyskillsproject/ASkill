//+------------------------------------------------------------------+
//|                                     Open two opposite orders.mq4 |
//|                                                           Skillz |
//|                                          https://www.oderafx.com |
//+------------------------------------------------------------------+
#property copyright "Skillz"
#property link      "https://www.oderafx.com"
#property version   "1.00"
#property strict
#property script_show_inputs

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
input double Lot_Size = 0.01;                  //Size of the trade
input int stop_loss = 150;                     //Stop loss in points 150 = 15 pips
input int take_profit = 300;                   //Take profit in points 300 = 30 pips
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   int ticket=OrderSend(NULL,OP_BUY,Lot_Size,Ask,3,0,0);       // Opens a market order and assigns the ticket id to the variable ticket
   bool order_modify=OrderModify(ticket,Ask,Ask-stop_loss*Point,Ask+take_profit*Point,0);   //Modifies the market order to add stop loss and take profit levels this is especially useful ECN accounts that do not allow stop levels with OrderSend function

   RefreshRates();
   int ticket2=OrderSend(NULL,OP_SELL,Lot_Size,Bid,3,0,0);           //Opens a market order and assigns the ticket id to the variable ticket
   bool order_modify2=OrderModify(ticket2,Bid,Bid+stop_loss*Point,Bid -take_profit*Point,0);   //Modifies the market order to add stop loss and take profit levels this is especially useful ECN accounts that do not allow stop levels with OrderSend function
  }
//+------------------------------------------------------------------+
