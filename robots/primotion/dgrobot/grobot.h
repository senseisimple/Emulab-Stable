/* Garcia robot class
 *
 * Dan Flickinger
 *
 * 2004/10/04
 * 2004/12/09
 */

 
#ifndef GROBOT_H
#define GROBOT_H

#include "acpGarcia.h"
#include "acpValue.h"

class grobot;

#include "gcallbacks.h"
#include "gbehaviors.h"

#include <math.h>
#include <iostream>
#include <string>



// track width, in meters
#define TRACK_WIDTH 0.1778f

class grobot {
  public:
    grobot();
    ~grobot();
    
    void estop();
    void setWheels(float Vl, float Vr);
    void setvPath(float Wv, float Wr);
    
    void pbMove(float mdisplacement);
    void pbPivot(float pangle);
    void dgoto(float Dx, float Dy, float Rf);

    void resetPosition();
    void updatePosition();
    float getArclen();
    void getDisplacement(float &dxtemp, float &dytemp);
    
    int getGstatus();
    int getGOTOstatus();
    void sleepy();
    
    void setCBexec(int id);
    void setCBstatus(int id, int stat);

     
    acpGarcia garcia;
    
  private:
    void createNULLbehavior();
    void createPRIMbehavior();
    
    void set_gotocomplete();
    
        
    // Wheel odometry values
    float Vl;      // left wheel velocity
    float Vr;      // right wheel velocity
    
    float dleft;   // left wheel distance
    float dright;  // right wheel distance
    
    float dt_init; // initial pivot angle for a goto command
    float dx_est;  // estimated displacement x
    float dy_est;  // estimated displacement y

    
    
    // goto command administration shit
    int gotolock;      // nonzero if a goto command is executing
    int gotocomplete;  // 1 if a goto has completed, 0 otherwise
    
    int gotomexec;     // count for execute
    int gotomcomplete; // count for complete
    
    int gotop1;       // status for first pivot of a goto command
    int gotom1;       // status for move segment of a goto command
    int gotop2;       // status for second pivot of a goto command
    
    
    // Garcia stuff
    acpObject *pBehavior;         // Garcia behavior
     
    
    CallbackComplete *completeCB; // completion callback
    CallbackExecute *executeCB;   // execution callback
    
    acpValue completeCBacpV;      // acpValue completion callback
    acpValue executeCBacpV;       // acpValue execution callback
    
    aIOLib ioRef;                 // Garcia Input/Output reference
    aErr err;                     // Garcia Error
    

    
};


#endif


























