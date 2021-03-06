//+-----------------------------------------------------------------------------------------------------------------+
//|                                                                                               VFX New Order.mq4 |
//|                                                                                       Copyright © 2017, Vini FX |
//|                                                                                             vini-fx@hotmail.com |
//+-----------------------------------------------------------------------------------------------------------------+

//|:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|
//|*****************************************************************************************************************|
//| Trader,                                                                                                         |
//|                                                                                                                 |
//| 1. If this code is useful to you and you want to collaborate with my work:                                      |
//|    * PayPal..: vinicius-fx@hotmail.com;                                                                         |
//|    * NETELLER: vini-fx@hotmail.com;                                                                             |
//|    * MQL5....: https://www.mql5.com/en/users/vinicius-fx/seller.                                                |
//|                                                                                                                 |
//| 2. If you implement updates in this application, please share.                                                  |
//|                                                                                                                 |
//| Thank you very much.                                                                                            |
//|*****************************************************************************************************************|
//|:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::|

//=== Properties
#property copyright   "Copyright © 2017, Vini FX"
#property description "This tool is designed to open positions in MetaTrader 4 terminals with absolute"
#property description "control of the risk / reward ratio, automatically calculating the lot size according"
#property description "to Risk and Stop Loss defined in the input parameters, with agility and precision,"
#property description "assisting in a fundamental way in the risk management strategy of user."
#property link        "https://www.mql5.com/en/market/product/10693"
#property version     "1.13"
#property strict
#property script_show_inputs

//=== Enumerations
enum ENUM_OP_TYPE
  {
   OpNo        = -1,             // Select...
   OpBuy       = OP_BUY,         // Buy
   OpSell      = OP_SELL,        // Sell
   OpBuyLimit  = OP_BUYLIMIT,    // Buy Limit
   OpSellLimit = OP_SELLLIMIT,   // Sell Limit
   OpBuyStop   = OP_BUYSTOP,     // Buy Stop
   OpSellStop  = OP_SELLSTOP     // Sell Stop
  };
enum ENUM_ENTRY_LEVEL_BY
  {
   EntryLevelPrice,    // Price
   EntryLevelPoints,   // Points
   EntryLevelNo        // None
  };
enum ENUM_RISK_BY
  {
   RiskPercentage,     // Percentage
   RiskAmount          // Amount
  };
enum ENUM_SL_BY
  {
   SL_Price,           // Price
   SL_Points           // Points
  };
enum ENUM_TP_BY
  {
   TP_Percentage,      // Percentage
   TP_Amount,          // Amount
   TP_Price,           // Price
   TP_Points           // Points
  };

//=== Global input variables
input ENUM_OP_TYPE        OpType       = OpNo;             // Order Operation Type
input ENUM_ENTRY_LEVEL_BY EntryLevelBy = EntryLevelNo;     // Set Pending Order Entry Level By
input double              EntryLevel   = 0.0;              // Pending Order Entry Level
input ENUM_RISK_BY        RiskBy       = RiskPercentage;   // Set Order Risk By
input double              Risk         = 0.0;              // Order Risk
input ENUM_SL_BY          StopLossBy   = SL_Price;         // Set Stop Loss By
input double              StopLoss     = 0.0;              // Stop Loss
input ENUM_TP_BY          TakeProfitBy = TP_Percentage;    // Set Take Profit By
input double              TakeProfit   = 0.0;              // Take Profit
input string              OrdComment   = "VFX";            // Order Comment
input int                 MagicNumber  = 0;                // Order Magic Number
input int                 Slippage     = 20;               // Maximum Price Slippage

//=== Global internal variables
string ErrMsg;
//+-----------------------------------------------------------------------------------------------------------------+
//| Script program start function                                                                                   |
//+-----------------------------------------------------------------------------------------------------------------+
void OnStart()
  {
   //--- Local variables
   double SL, TP, Price, TickValue, RISK, Lot, Profit;

   //--- Checks the input parameters
   if(OpType == OpNo)
     {Alert("Please select Order Operation Type."); return;}
   if((OpType == OpBuy || OpType == OpSell) && (EntryLevelBy != EntryLevelNo || EntryLevel != 0))
     {
      ErrMsg = "Please do not enter Set Pending Order Entry Level By or\n"
               "Pending Order Entry Level at the opening of an immediate\n"
               "execution order.";
      Alert(ErrMsg);
      return;
     }
   if(OpType != OpBuy && OpType != OpSell && (EntryLevelBy == EntryLevelNo || EntryLevel <= 0))
     {
      ErrMsg = "Please enter Set Pending Order Entry Level By and\n"
               "Pending Order Entry Level at the opening of an pending order.";
      Alert(ErrMsg);
      return;
     }
   if(Risk <= 0)
     {Alert("Please enter the Order Risk."); return;}
   if(StopLoss <= 0)
     {Alert("Please enter the Stop Loss."); return;}

   //--- Initializes stop loss and take profit
   SL = NormalizeDouble(StopLoss, Digits);
   TP = NormalizeDouble(TakeProfit, Digits);

   //--- Checks order buy
   if(OpType == OpBuy || OpType == OpBuyLimit || OpType == OpBuyStop)
     {
      //--- Price
      Price = Ask;
      if(OpType == OpBuyLimit)
        {
         if(EntryLevelBy == EntryLevelPoints) {Price = NormalizeDouble(Ask - EntryLevel * Point, Digits);}
         else {Price = EntryLevel;}
        }
      else if(OpType == OpBuyStop)
        {
         if(EntryLevelBy == EntryLevelPoints) {Price = NormalizeDouble(Ask + EntryLevel * Point, Digits);}
         else {Price = EntryLevel;}
        }
      //--- Stop Loss
      if(StopLossBy == SL_Points) {SL = NormalizeDouble(Price - StopLoss * Point, Digits);}
      //--- Risk
      RISK = Risk;
      if(RiskBy == RiskPercentage) {RISK = (AccountBalance() + AccountCredit()) * (Risk / 100);}
      //--- Volume
      TickValue = ((Price - SL) / Point) * MarketInfo(Symbol(), MODE_TICKVALUE);
      if(TickValue == 0.0) {Lot = 0.0;}
      else {Lot = NormalizeDouble(RISK / TickValue, 2);}
      if(!CheckVolume(Lot)) {Alert(ErrMsg); return;}
      //--- Take Profit
      if(TakeProfit > 0 && TakeProfitBy != TP_Price)
        {
         if(TakeProfitBy == TP_Points)
           {
            TP = NormalizeDouble(Price + TakeProfit * Point, Digits);
           }
         else
           {
            Profit = TakeProfit;
            if(TakeProfitBy == TP_Percentage) {Profit = (AccountBalance() + AccountCredit()) * (TakeProfit / 100);}
            TP = NormalizeDouble(Price + (Profit / (MarketInfo(Symbol(), MODE_TICKVALUE) * Lot)) * Point, Digits);
           }
        }
     }
   //--- Checks order sell
   else
     {
      //--- Price
      Price = Bid;
      if(OpType == OpSellLimit)
        {
         if(EntryLevelBy == EntryLevelPoints) {Price = NormalizeDouble(Bid + EntryLevel * Point, Digits);}
         else {Price = EntryLevel;}
        }
      else if(OpType == OpSellStop)
        {
         if(EntryLevelBy == EntryLevelPoints) {Price = NormalizeDouble(Bid - EntryLevel * Point, Digits);}
         else {Price = EntryLevel;}
        }
      //--- Stop Loss
      if(StopLossBy == SL_Points) {SL = NormalizeDouble(Price + StopLoss * Point, Digits);}
      //--- Risk
      RISK = Risk;
      if(RiskBy == RiskPercentage) {RISK = (AccountBalance() + AccountCredit()) * (Risk / 100);}
      //--- Volume
      TickValue = ((SL - Price) / Point) * MarketInfo(Symbol(), MODE_TICKVALUE);
      if(TickValue == 0.0) {Lot = 0.0;}
      else {Lot = NormalizeDouble(RISK / TickValue, 2);}
      if(!CheckVolume(Lot)) {Alert(ErrMsg); return;}
      //--- Take Profit
      if(TakeProfit > 0 && TakeProfitBy != TP_Price)
        {
         if(TakeProfitBy == TP_Points)
           {
            TP = NormalizeDouble(Price - TakeProfit * Point, Digits);
           }
         else
           {
            Profit = TakeProfit;
            if(TakeProfitBy == TP_Percentage) {Profit = (AccountBalance() + AccountCredit()) * (TakeProfit / 100);}
            TP = NormalizeDouble(Price - (Profit / (MarketInfo(Symbol(), MODE_TICKVALUE) * Lot)) * Point, Digits);
           }
        }
     }

   //--- Opens order
   if(OrderSend(Symbol(), OpType, Lot, Price, Slippage, SL, TP, OrdComment, MagicNumber, 0, clrNONE) == -1)
     {Alert(ErrorDescription(GetLastError()));}
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Check volume function                                                                                           |
//+-----------------------------------------------------------------------------------------------------------------+
bool CheckVolume(double Lot)
  {
   //--- Minimal allowed volume for trade operations
   double MinVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   if(Lot < MinVolume)
     {
      ErrMsg = StringConcatenate("Volume less than the minimum allowed. The minimum volume is ", MinVolume, ".");
      return(false);
     }

   //--- Maximal allowed volume of trade operations
   double MaxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   if(Lot > MaxVolume)
     {
      ErrMsg = StringConcatenate("Volume greater than the maximum allowed. The maximum volume is ", MaxVolume, ".");
      return(false);
     }

   //--- Get minimal step of volume changing
   double VolumeStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   int Ratio = (int)MathRound(Lot / VolumeStep);
   if(MathAbs(Ratio * VolumeStep - Lot) > 0.0000001)
     {
      ErrMsg = StringConcatenate("The volume is not multiple of the minimum gradation ", VolumeStep,
                                 ". Volume closest to the valid ", Ratio * VolumeStep, ".");
      return(false);
     }

   //--- Correct volume value
   return(true);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Error description function                                                                                      |
//+-----------------------------------------------------------------------------------------------------------------+
string ErrorDescription(int ErrorCode)
  {
   //--- Local variable
   string ErrorMsg;

   switch(ErrorCode)
     {
      //--- Codes returned from trade server
      case 0:    ErrorMsg="No error returned.";                                             break;
      case 1:    ErrorMsg="No error returned, but the result is unknown.";                  break;
      case 2:    ErrorMsg="Common error.";                                                  break;
      case 3:    ErrorMsg="Invalid trade parameters.";                                      break;
      case 4:    ErrorMsg="Trade server is busy.";                                          break;
      case 5:    ErrorMsg="Old version of the client terminal.";                            break;
      case 6:    ErrorMsg="No connection with trade server.";                               break;
      case 7:    ErrorMsg="Not enough rights.";                                             break;
      case 8:    ErrorMsg="Too frequent requests.";                                         break;
      case 9:    ErrorMsg="Malfunctional trade operation.";                                 break;
      case 64:   ErrorMsg="Account disabled.";                                              break;
      case 65:   ErrorMsg="Invalid account.";                                               break;
      case 128:  ErrorMsg="Trade timeout.";                                                 break;
      case 129:  ErrorMsg="Invalid price.";                                                 break;
      case 130:  ErrorMsg="Invalid stops.";                                                 break;
      case 131:  ErrorMsg="Invalid trade volume.";                                          break;
      case 132:  ErrorMsg="Market is closed.";                                              break;
      case 133:  ErrorMsg="Trade is disabled.";                                             break;
      case 134:  ErrorMsg="Not enough money.";                                              break;
      case 135:  ErrorMsg="Price changed.";                                                 break;
      case 136:  ErrorMsg="Off quotes.";                                                    break;
      case 137:  ErrorMsg="Broker is busy.";                                                break;
      case 138:  ErrorMsg="Requote.";                                                       break;
      case 139:  ErrorMsg="Order is locked.";                                               break;
      case 140:  ErrorMsg="Buy orders only allowed.";                                       break;
      case 141:  ErrorMsg="Too many requests.";                                             break;
      case 145:  ErrorMsg="Modification denied because order is too close to market.";      break;
      case 146:  ErrorMsg="Trade context is busy.";                                         break;
      case 147:  ErrorMsg="Expirations are denied by broker.";                              break;
      case 148:  ErrorMsg="The amount of open and pending orders has reached the limit.";   break;
      case 149:  ErrorMsg="An attempt to open an order opposite when hedging is disabled."; break;
      case 150:  ErrorMsg="An attempt to close an order contravening the FIFO rule.";       break;
      //--- Mql4 errors
      case 4000: ErrorMsg="No error returned.";                                             break;
      case 4001: ErrorMsg="Wrong function pointer.";                                        break;
      case 4002: ErrorMsg="Array index is out of range.";                                   break;
      case 4003: ErrorMsg="No memory for function call stack.";                             break;
      case 4004: ErrorMsg="Recursive stack overflow.";                                      break;
      case 4005: ErrorMsg="Not enough stack for parameter.";                                break;
      case 4006: ErrorMsg="No memory for parameter string.";                                break;
      case 4007: ErrorMsg="No memory for temp string.";                                     break;
      case 4008: ErrorMsg="Not initialized string.";                                        break;
      case 4009: ErrorMsg="Not initialized string in array.";                               break;
      case 4010: ErrorMsg="No memory for array string.";                                    break;
      case 4011: ErrorMsg="Too long string.";                                               break;
      case 4012: ErrorMsg="Remainder from zero divide.";                                    break;
      case 4013: ErrorMsg="Zero divide.";                                                   break;
      case 4014: ErrorMsg="Unknown command.";                                               break;
      case 4015: ErrorMsg="Wrong jump (never generated error).";                            break;
      case 4016: ErrorMsg="Not initialized array.";                                         break;
      case 4017: ErrorMsg="Dll calls are not allowed.";                                     break;
      case 4018: ErrorMsg="Cannot load library.";                                           break;
      case 4019: ErrorMsg="Cannot call function.";                                          break;
      case 4020: ErrorMsg="Expert function calls are not allowed.";                         break;
      case 4021: ErrorMsg="Not enough memory for temp string returned from function.";      break;
      case 4022: ErrorMsg="System is busy (never generated error).";                        break;
      case 4023: ErrorMsg="Dll-function call critical error.";                              break;
      case 4024: ErrorMsg="Internal error.";                                                break;
      case 4025: ErrorMsg="Out of memory.";                                                 break;
      case 4026: ErrorMsg="Invalid pointer.";                                               break;
      case 4027: ErrorMsg="Too many formatters in the format function.";                    break;
      case 4028: ErrorMsg="Parameters count exceeds formatters count.";                     break;
      case 4029: ErrorMsg="Invalid array.";                                                 break;
      case 4030: ErrorMsg="No reply from chart.";                                           break;
      case 4050: ErrorMsg="Invalid function parameters count.";                             break;
      case 4051: ErrorMsg="Invalid function parameter value.";                              break;
      case 4052: ErrorMsg="String function internal error.";                                break;
      case 4053: ErrorMsg="Some array error.";                                              break;
      case 4054: ErrorMsg="Incorrect series array using.";                                  break;
      case 4055: ErrorMsg="Custom indicator error.";                                        break;
      case 4056: ErrorMsg="Arrays are incompatible.";                                       break;
      case 4057: ErrorMsg="Global variables processing error.";                             break;
      case 4058: ErrorMsg="Global variable not found.";                                     break;
      case 4059: ErrorMsg="Function is not allowed in testing mode.";                       break;
      case 4060: ErrorMsg="Function is not allowed for call.";                              break;
      case 4061: ErrorMsg="Send mail error.";                                               break;
      case 4062: ErrorMsg="String parameter expected.";                                     break;
      case 4063: ErrorMsg="Integer parameter expected.";                                    break;
      case 4064: ErrorMsg="Double parameter expected.";                                     break;
      case 4065: ErrorMsg="Array as parameter expected.";                                   break;
      case 4066: ErrorMsg="Requested history data is in updating state.";                   break;
      case 4067: ErrorMsg="Internal trade error.";                                          break;
      case 4068: ErrorMsg="Resource not found.";                                            break;
      case 4069: ErrorMsg="Resource not supported.";                                        break;
      case 4070: ErrorMsg="Duplicate resource.";                                            break;
      case 4071: ErrorMsg="Custom indicator cannot initialize.";                            break;
      case 4072: ErrorMsg="Cannot load custom indicator.";                                  break;
      case 4073: ErrorMsg="No history data.";                                               break;
      case 4074: ErrorMsg="No memory for history data.";                                    break;
      case 4075: ErrorMsg="Not enough memory for indicator calculation.";                   break;
      case 4099: ErrorMsg="End of file.";                                                   break;
      case 4100: ErrorMsg="Some file error.";                                               break;
      case 4101: ErrorMsg="Wrong file name.";                                               break;
      case 4102: ErrorMsg="Too many opened files.";                                         break;
      case 4103: ErrorMsg="Cannot open file.";                                              break;
      case 4104: ErrorMsg="Incompatible access to a file.";                                 break;
      case 4105: ErrorMsg="No order selected.";                                             break;
      case 4106: ErrorMsg="Unknown symbol.";                                                break;
      case 4107: ErrorMsg="Invalid price.";                                                 break;
      case 4108: ErrorMsg="Invalid ticket.";                                                break;
      case 4109: ErrorMsg="Trade is not allowed in the Expert Advisor properties.";         break;
      case 4110: ErrorMsg="Longs are not allowed in the Expert Advisor properties.";        break;
      case 4111: ErrorMsg="Shorts are not allowed in the Expert Advisor properties.";       break;
      case 4112: ErrorMsg="Automated trading disabled by trade server.";                    break;
      case 4200: ErrorMsg="Object already exists.";                                         break;
      case 4201: ErrorMsg="Unknown object property.";                                       break;
      case 4202: ErrorMsg="Object does not exist.";                                         break;
      case 4203: ErrorMsg="Unknown object type.";                                           break;
      case 4204: ErrorMsg="No object name.";                                                break;
      case 4205: ErrorMsg="Object coordinates error.";                                      break;
      case 4206: ErrorMsg="No specified subwindow.";                                        break;
      case 4207: ErrorMsg="Graphical object error.";                                        break;
      case 4210: ErrorMsg="Unknown chart property.";                                        break;
      case 4211: ErrorMsg="Chart not found.";                                               break;
      case 4212: ErrorMsg="Chart subwindow not found.";                                     break;
      case 4213: ErrorMsg="Chart indicator not found.";                                     break;
      case 4220: ErrorMsg="Symbol select error.";                                           break;
      case 4250: ErrorMsg="Notification error.";                                            break;
      case 4251: ErrorMsg="Notification parameter error.";                                  break;
      case 4252: ErrorMsg="Notifications disabled.";                                        break;
      case 4253: ErrorMsg="Notification send too frequent.";                                break;
      case 4260: ErrorMsg="FTP server is not specified.";                                   break;
      case 4261: ErrorMsg="FTP login is not specified.";                                    break;
      case 4262: ErrorMsg="FTP connection failed.";                                         break;
      case 4263: ErrorMsg="FTP connection closed.";                                         break;
      case 4264: ErrorMsg="FTP path not found on server.";                                  break;
      case 4265: ErrorMsg="File not found in the Files directory to send on FTP server.";   break;
      case 4266: ErrorMsg="Common error during FTP data transmission.";                     break;
      case 5001: ErrorMsg="Too many opened files.";                                         break;
      case 5002: ErrorMsg="Wrong file name.";                                               break;
      case 5003: ErrorMsg="Too long file name.";                                            break;
      case 5004: ErrorMsg="Cannot open file.";                                              break;
      case 5005: ErrorMsg="Text file buffer allocation error.";                             break;
      case 5006: ErrorMsg="Cannot delete file.";                                            break;
      case 5007: ErrorMsg="Invalid file handle (file closed or was not opened).";           break;
      case 5008: ErrorMsg="Wrong file handle (handle index is out of handle table).";       break;
      case 5009: ErrorMsg="File must be opened with FILE_WRITE flag.";                      break;
      case 5010: ErrorMsg="File must be opened with FILE_READ flag.";                       break;
      case 5011: ErrorMsg="File must be opened with FILE_BIN flag.";                        break;
      case 5012: ErrorMsg="File must be opened with FILE_TXT flag.";                        break;
      case 5013: ErrorMsg="File must be opened with FILE_TXT or FILE_CSV flag.";            break;
      case 5014: ErrorMsg="File must be opened with FILE_CSV flag.";                        break;
      case 5015: ErrorMsg="File read error.";                                               break;
      case 5016: ErrorMsg="File write error.";                                              break;
      case 5017: ErrorMsg="String size must be specified for binary file.";                 break;
      case 5018: ErrorMsg="Incompatible file (for string arrays-TXT, for others-BIN).";     break;
      case 5019: ErrorMsg="File is directory, not file.";                                   break;
      case 5020: ErrorMsg="File does not exist.";                                           break;
      case 5021: ErrorMsg="File cannot be rewritten.";                                      break;
      case 5022: ErrorMsg="Wrong directory name.";                                          break;
      case 5023: ErrorMsg="Directory does not exist.";                                      break;
      case 5024: ErrorMsg="Specified file is not directory.";                               break;
      case 5025: ErrorMsg="Cannot delete directory.";                                       break;
      case 5026: ErrorMsg="Cannot clean directory.";                                        break;
      case 5027: ErrorMsg="Array resize error.";                                            break;
      case 5028: ErrorMsg="String resize error.";                                           break;
      case 5029: ErrorMsg="Structure contains strings or dynamic arrays.";                  break;
      case 5200: ErrorMsg="Invalid URL.";                                                   break;
      case 5201: ErrorMsg="Failed to connect to specified URL.";                            break;
      case 5202: ErrorMsg="Timeout exceeded.";                                              break;
      case 5203: ErrorMsg="HTTP request failed.";                                           break;
      default:   ErrorMsg="Unknown error.";
     }
   return(ErrorMsg);
  }
//+-----------------------------------------------------------------------------------------------------------------+
//| Script End                                                                                                      |
//+-----------------------------------------------------------------------------------------------------------------+