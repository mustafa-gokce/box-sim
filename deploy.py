import sys
import time
import threading

if sys.version_info.major == 3 and sys.version_info.minor >= 10:
    import collections
    from collections.abc import MutableMapping
    setattr(collections, "MutableMapping", MutableMapping)

import dronekit

# configurations
TOTAL_VEHICLE_COUNT = 10
RELAY_PORT_START = 10000

# global variables
vehicles = []
telemetry_threads = []


# deploy vehicle
def deploy_vehicle(vehicle):
    while True:
        vehicle.parameters["SIM_SPEEDUP"] = 20
        if vehicle.home_location is not None:
            if vehicle.mode != "TAKEOFF":
                vehicle.mode = "TAKEOFF"
            if not vehicle.armed:
                vehicle.armed = True
            else:
                vehicle.parameters["SIM_SPEEDUP"] = 1
                break
        else:
            vehicle.wait_ready()
        time.sleep(0.1)


# connect to vehicles
for i in range(1, TOTAL_VEHICLE_COUNT + 1):
    vehicle = dronekit.connect(ip=f"udpin:127.0.0.1:{RELAY_PORT_START + i * 10}", wait_ready=False)
    vehicles.append(vehicle)

# run telemetry threads
for vehicle in vehicles:
    telemetry_thread = threading.Thread(target=deploy_vehicle, args=(vehicle,))
    telemetry_threads.append(telemetry_thread)
    telemetry_threads[-1].start()
