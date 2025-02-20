import requests
import argparse
import json
import sys

def main(args):
    host = args.host
    acp = args.acp
    token = args.token
    password = args.password
    serial_number = args.serial.split(',')
    
    url = "https://"+ host +"/api/rest/v1/inventory/devices/ftds/ztp"
    n = len(serial_number)
    
    for i in range(n):
        print("--------------------------------Running--------------------------------")
        name = "FTD" + str(i+1)
        payload = json.dumps({
            "name": name,
            "serialNumber": serial_number[i],
            "adminPassword": password,
            "fmcAccessPolicyUid": acp,
            "licenses": ["BASE"]
        })
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
            'Authorization': 'Bearer '+ token
        }

        response = requests.request('POST', url, headers=headers, data = payload)
        print(response)
    

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process some inputs.')
    parser.add_argument('--host', type=str, required=True, help='cdFMC host address')
    parser.add_argument('--token', type=str, required=True, help='SCC Token')
    parser.add_argument('--password', type=str, required=True, help='FTD new password')
    parser.add_argument('--acp', type=str, required=True, help='ID of ACP')
    parser.add_argument('--serial', type=str, required=True, help='Serial number')
    args = parser.parse_args()
    
    main(args)