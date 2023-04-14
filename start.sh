#!/bin/bash

# initial configurations
TOTAL_VEHICLE_COUNT=10

# clear previous run
sudo rm -r logs*
sudo rm -r terrain*
sudo rm eeprom.bin

# update binary permission
sudo chmod +x arduplane

# mavproxy screen command
command="mavproxy.py --state-basedir logs --console --map"

# start firmwares
for i in $(seq 1 $TOTAL_VEHICLE_COUNT); do
  command+=" --master=127.0.0.1:$((10200 + i * 10)) "
  screen -S vehicle_$((i)) -d -m bash -c "./arduplane -w -S -I$((i - 1)) --model plane --speedup 10 --defaults plane.parm --sysid $((i)) --home 39.813354,30.519278,784.5,0"
done

# start proxies
for i in $(seq 1 $TOTAL_VEHICLE_COUNT); do
  screen -S proxy_$((i)) -d -m bash -c "mavproxy.py --state-basedir logs --aircraft vehicle_$((i)) --master tcp:127.0.0.1:$((5750 + i * 10)) --out udp:127.0.0.1:$((10000 + i * 10)) --out udp:127.0.0.1:$((10100 + i * 10)) --out udp:127.0.0.1:$((10200 + i * 10)) --daemon"
done

# run deploy
screen -S deploy -d -m bash -c "/usr/bin/python3 deploy.py"

# wait for vehicles to be fully deployed
until ! screen -list | grep -q "deploy"; do
  sleep 1
done

# open MAVProxy
screen -S mavproxy -d -m bash -c "$command"
