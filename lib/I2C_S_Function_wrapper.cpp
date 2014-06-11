

/*
 * Include Files
 *
 */
#if defined(MATLAB_MEX_FILE)
#include "tmwtypes.h"
#include "simstruc_types.h"
#else
#include "rtwtypes.h"
#endif

/* %%%-SFUNWIZ_wrapper_includes_Changes_BEGIN --- EDIT HERE TO _END */
#ifndef MATLAB_MEX_FILE

#include <Arduino.h>
#include <math.h>
#include <Wire.h>
#include <Wire.cpp>

// I2C Address
#define SLAVE_ADDR 0x12

#endif
/* %%%-SFUNWIZ_wrapper_includes_Changes_END --- EDIT HERE TO _BEGIN */
#define u_width 12
#define y_width 1
/*
 * Create external references here.  
 *
 */
/* %%%-SFUNWIZ_wrapper_externs_Changes_BEGIN --- EDIT HERE TO _END */
/* extern double func(double a); */
#ifndef MATLAB_MEX_FILE
int canread;
uint8_t buf[12];
uint8_t rbuf[12];

extern "C" void sendData(){
    if (canread){
            Wire.write((uint8_t*)&buf[0],(size_t)sizeof(buf));
    }
}
extern "C" void receiveData(int bytes){
   if(bytes==12)
   {
      for(int i=0;i<12;i++) {
         if(Wire.available()) {
            rbuf[i] = Wire.read();
         }
      }
   }
} 
#endif
/* %%%-SFUNWIZ_wrapper_externs_Changes_END --- EDIT HERE TO _BEGIN */

/*
 * Output functions
 *
 */
extern "C" void I2C_S_Function_Outputs_wrapper(const uint8_T *u0,
			uint8_T *y0,
			const real_T *xD,
			const uint8_T  *Par, const int_T  p_width0)
{
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_BEGIN --- EDIT HERE TO _END */
if (xD[0] == 1){
    # ifndef MATLAB_MEX_FILE
    //int twbrback = TWBR;  //i2c specific and don't understand it
    //TWBR = 12; // 400 khz //i2c specific and it sets the comm freq.
    
    //Wire.beginTransmission(DAC_ADD); //tell the i2c device that data is comming to it
    
    //Wire.endTransmission(); //Tell device all instruction shave been trasnmitted
    //TWBR = twbrback;   //i2c specific
    
    //canread is used to be sure the buffer is not read
    //by senddata function, while it is being written here.
    canread = 0;
    for(int i=0;i<12;i++){
        buf[i]= u0[i];
    }
    canread = 1;
    //Wire.available()
    for(int i=0;i<12;i++){
        y0[i] = rbuf[i];
    }
    # endif
}
/* %%%-SFUNWIZ_wrapper_Outputs_Changes_END --- EDIT HERE TO _BEGIN */
}

/*
  * Updates function
  *
  */
extern "C" void I2C_S_Function_Update_wrapper(const uint8_T *u0,
			const uint8_T *y0,
			real_T *xD,
			const uint8_T  *Par,  const int_T  p_width0)
{
  /* %%%-SFUNWIZ_wrapper_Update_Changes_BEGIN --- EDIT HERE TO _END */
if (xD[0] != 1){

    # ifndef MATLAB_MEX_FILE
    Wire.begin(SLAVE_ADDR); //join i2c bus as slave
    Wire.onRequest(sendData);
    Wire.onReceive(receiveData);
    # endif
    
    xD[0] = 1;
}
/* %%%-SFUNWIZ_wrapper_Update_Changes_END --- EDIT HERE TO _BEGIN */
}
