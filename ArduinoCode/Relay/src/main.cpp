#include <Arduino.h>

char Incoming_value = 0;                //Variable for storing Incoming_value
int relay1 = 13;
int relay2 = 7;


void setup() 
{
  Serial.begin(9600);         //Sets the data rate in bits per second (baud) for serial data transmission
  pinMode(relay1, OUTPUT);        //Sets digital pin 13 as output pin
  pinMode(relay2, OUTPUT);        //Sets digital pin 7 as output pin
}
void loop()
{
  if(Serial.available() > 0)  
  {
    Incoming_value = Serial.read();      //Read the incoming data and store it into variable Incoming_value
    Serial.print(Incoming_value);        //Print Value of Incoming_value in Serial monitor
    Serial.print("\n");        //New line 
    if(Incoming_value == '1')            //Checks whether value of Incoming_value is equal to 1 
   {  
      digitalWrite(relay1, HIGH);  //If value is 1 then LED turns ON
      }
    else if(Incoming_value == '0')       //Checks whether value of Incoming_value is equal to 0
     { 
       digitalWrite(relay1, LOW);   //If value is 0 then LED turns OFF
      }
    else if(Incoming_value == '2')       //Checks whether value of Incoming_value is equal to 2
      { 
        digitalWrite(relay2, HIGH);   //If value is 2 then LED turns ON
        }
      else if(Incoming_value == '3')       //Checks whether value of Incoming_value is equal to 3
      { 
        digitalWrite(relay2, LOW);   //If value is 3 then LED turns OFF
        }


  }                            
 
}                 

// sudo chmod 666 /dev/ttyACM0