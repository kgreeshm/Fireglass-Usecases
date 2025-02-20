import requests
import argparse
import json

def main(args):
    host = args.host
    url = "https://" + host + "/api/rest/v1/inventory/devices"
    token = args.token
    serial_number = args.serial.split(',')
    device_id = []
    payload = {}
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        'Authorization': 'Bearer '+ token
    }

    # -------------------------------- Filter Devices ----------------------------------
    get_device = requests.request("GET", url, headers=headers, data=payload)
    get_device = json.loads(get_device.text)
    n = len(get_device["items"])
    for r in range(n):
        if get_device["items"][r]["serial"] == serial_number[r]:
            device_id.append(get_device["items"][r]["uid"])

    # -------------------------------- Delete Devices ----------------------------------
    for id in device_id:
        delete_url = url + "/ftds/cdfmcManaged/" + id + "/delete"
        print(delete_url)
        response = requests.request('POST', delete_url, headers=headers, data = payload)
        print(response.text)
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process some inputs.')
    parser.add_argument('--host', type=str, required=True, help='cdFMC host address')
    parser.add_argument('--token', type=str, required=True, help='SCC Token')
    parser.add_argument('--serial', type=str, required=True, help='Serial number')
    args = parser.parse_args()
    
    main(args)