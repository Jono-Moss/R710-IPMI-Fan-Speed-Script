#!/bin/bash

# IPMI IP address
IPMIHOST=10.0.0.4
# IPMI Username
IPMIUSER=fan-admin
# IPMI Password
IPMIPW=y0urPassw0rd
# Your IPMI Encryption Key
IPMIEK=0000000000000000000000000000000000000000
# Fan Speed / utilisation in percentage, for example 9 for 9% utilisation
# Please note that each fan can have a different rpm and will not all be the same speed
FANSPEED=9

# TEMPERATURE
# Change this to the temperature in Celsius you are comfortable with.
# If the temperature goes above the set degrees it will send raw IPMI command to enable dynamic fan control
MAXTEMP=27

# This variable sends a IPMI command to get the temperature, and outputs it as two digits.
# Do not edit unless you know what you do.
# Side note, if you are running ipmitool on the system you are controlling, you don't need to specify -H,-U,-P - from the OS installed on the host, ipmitool is assumed permitted. You only need host/user/pass for remote access. 
TEMP=$(ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK sdr type temperature |grep Ambient |grep degrees |grep -Po '\d{2}' | tail -1)

# Dont edit this, this converts decimal to hex
SPEEDHEX=$( printf "%x" $FANSPEED )

if [[ $TEMP > $MAXTEMP ]];
  then
    printf "Warning: Temperature is too high! Activating dynamic fan control! ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    echo "Warning: Temperature is too high! Activating dynamic fan control! ($TEMP C)"
    # This sets the fans to auto mode, so the motherboard will set it to a speed that it will need do cool the server down
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x01
  else
    printf "Temperature is OK ($TEMP C)" | systemd-cat -t R710-IPMI-TEMP
    printf "Activating manual fan speeds! (1560 RPM)"
    # This sets the fans to manual mode
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x01 0x00
    # This is where we set the slower, quite speed
    ipmitool -I lanplus -H $IPMIHOST -U $IPMIUSER -P $IPMIPW -y $IPMIEK raw 0x30 0x30 0x02 0xff 0x$SPEEDHEX
fi
