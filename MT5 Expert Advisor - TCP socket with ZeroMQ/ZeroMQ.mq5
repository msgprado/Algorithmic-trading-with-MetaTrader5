#include <Zmq/Zmq.mqh>
//+------------------------------------------------------------------+
//| ZeroMQ TCP socket                                       
//| Connects REQ socket to tcp://IP:5555                      
//| Sends data via TCP socket                    
//+------------------------------------------------------------------+
//Pre conditions
//https://www.mql5.com/en/forum/2617 //Allow DLL


//+------------------------------------------------------------------+
// Prepare our context and socket
Context context("MT5 ZeroMQ connection");
Socket socket(context,ZMQ_REQ);
string strAddr = "tcp://192.168.0.133:5555"; //<----------------------------Need to configure!!!!!
//+------------------------------------------------------------------+
bool connect(string strAddr)
   {
   
   Print("Connecting to server…");
   bool connectingResult = socket.connect(strAddr);
   if(connectingResult == true)
     {
      Print("Connection established");
      ZmqMsg msg("MT5 connected - " + TimeCurrent());
      socket.send(msg);
     }
     return connectingResult;
   }
   
 bool disconnect(string strAddr)
   {  
      Print("Disconnecting from server…");
      ZmqMsg msg2("!!!MT5 disconnecting!!! - " + TimeCurrent());
      socket.send(msg2);
      bool result =  socket.disconnect(strAddr);
      return result;
   }
   
//+------------------------------------------------------------------+
// Send data functions
//+------------------------------------------------------------------+
 bool sendKeyValue(string key, float value)
   {
      ZmqMsg request("{'" + key +"' :" + DoubleToString(value) + "}");
      bool sendResult = socket.send(request);
      return sendResult;
   }
   
 bool sendTickData(float bid, float ask)
   {   
      ZmqMsg request("{'bid price' :" + DoubleToString(bid) + ",'ask' :" + DoubleToString(ask) + "}");
      bool sendResult = socket.send(request);
      return sendResult;
   }   

 bool sendRateData(datetime currentTime, uint tickcount, float open, float high, float low, float close)
   {   
      ZmqMsg request("{'time' :'" + TimeToString(currentTime) + "','open' :" + DoubleToString(open) +",'tick count' :" 
         + IntegerToString(tickcount) + ",'high' :"  + DoubleToString(high) +",'low' :" + DoubleToString(low) 
         +",'close' :" + DoubleToString(close) + "}");
      bool sendResult = socket.send(request);
      return sendResult;
   }      
//+------------------------------------------------------------------+
// Receive data function
//+------------------------------------------------------------------+
 string reciveMsg()
   {
      //Get the reply.
      //Print("Get message");
      ZmqMsg reply;
      socket.recv(reply,true);
      return reply.getData();
   }
//+------------------------------------------------------------------+
// Main 
//+------------------------------------------------------------------+
void OnInit()
   {
      connect(strAddr);
   }

void OnTick()
   {
   //Tick data
   double ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   double spread = ask - bid;
   
   //Get tick rates
   MqlRates PriceInfo[];
   ArraySetAsSeries(PriceInfo,true);
   int PriceData =CopyRates(Symbol(),Period(),0,1,PriceInfo);  
   float open = PriceInfo[0].open;
   float high = PriceInfo[0].high;
   float low = PriceInfo[0].low;
   float close = PriceInfo[0].close;
   uint tickcount = GetTickCount();
   //Print(tickcount);
   //##################################
   
   int spread_points = (int)MathRound(spread/SymbolInfoDouble(Symbol(),SYMBOL_POINT)); 
   
   bool spreadfloat=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD_FLOAT); 
   string calcSpreat = StringFormat("Spread %s = %I64d points\r\n", 
                            spreadfloat?"floating":"fixed", 
                            SymbolInfoInteger(Symbol(),SYMBOL_SPREAD)); 
   datetime currentTime =  TimeCurrent();
   
//###################################################################################   
 
   //Call send functions
   //bool sendResult = sendKeyValue("bid", bid);
   //bool sendResult = sendKeyValue("ask", ask);
   //bool sendResult = sendTickData(bid, ask);
   bool sendResult = sendRateData(currentTime, tickcount, open, high, low, close);
   if(sendResult == false)
     {
      //Print("Send failed - reconnect");
      //disconnect(strAddr);
      //connect(strAddr);
     }
   
   //Call receive function
   reciveMsg();
   //PrintFormat(reciveMsg());
   
   }

//+------------------------------------------------------------------+
void OnDeinit()
   {
      disconnect(strAddr);
   }  
//+------------------------------------------------------------------+