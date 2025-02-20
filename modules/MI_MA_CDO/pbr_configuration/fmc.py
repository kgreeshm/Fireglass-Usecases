import requests
import json
import os
import argparse

def main(args):
    host = args.host
    token = args.token
    
    device_url =  "https://"+ host +"/api/fmc_config/v1/domain/e276abec-e0f2-11e3-8169-6d9ed49b625f/devices/devicerecords"
    eacl_url = "https://" + host + "/api/fmc_config/v1/domain/e276abec-e0f2-11e3-8169-6d9ed49b625f/object/extendedaccesslists"
    headers = {
    'accept': 'application/json',
    'Authorization': 'Bearer '+ token,
    'Content-Type': 'application/json'
    }
    payload = {}

    # GET DEVICE IDs
    device_response = requests.request("GET", device_url, headers=headers, data=payload)
    device_response = json.loads(device_response.text)
    ftd2_id = device_response["items"][0]["id"]
    ftd1_id = device_response["items"][1]["id"]
    
    phy_url = device_url + "/" + ftd1_id + "/physicalinterfaces?offset=1&limit=25"
    pbr_url = device_url + "/" + ftd1_id + "/policybasedroutes"
    
    print(ftd1_id)
    print(ftd2_id)
    print("--------------------------------")

    # Create EACL
    eacl_payload = json.dumps({
    "name": "ExtendedAccessListTest",
    "entries": [
        {
        "logLevel": "ERROR",
        "action": "PERMIT",
        "logging": "PER_ACCESS_LIST_ENTRY",
        "logInterval": 545,
        "sourceNetworks": {
            "literals": [
            {
                "type": "Network",
                "value": "172.16.3.0/24"
            }
            ]
        },
        "destinationNetworks": {
            "literals": [
            {
                "type": "Network",
                "value": "0.0.0.0/0"
            }
            ]
        }
        }
    ]
    })
    eacl_response = requests.request("POST", eacl_url, headers=headers, data=eacl_payload)
    print(eacl_response.text)
    eacl_response = json.loads(eacl_response.text)
    eaclId = eacl_response["id"]
    print(eaclId)

    #####Physical Interface ID
    phypayload = {}
    phyresponse = requests.request("GET", phy_url, headers=headers, data=phypayload, verify=False)
    json_phyinter = json.loads(phyresponse.text)
    phyID1 = json_phyinter["items"][0]["id"]
    phyID2 = json_phyinter["items"][1]["id"]
    phyID3 = json_phyinter["items"][2]["id"]
    print("----------------------Printing phyID--------------------------")
    print(phyID1)
    print(phyID2)
    print(phyID3) 

    # Configuring PBR
    pbr_payload = json.dumps({
        "ingressInterfaces": [
            {
                ### Inside Interface ###
                "id": f"{phyID3}"
            }
        ],
        "name": "PBR-req-test",
        "forwardingActions": [{
            "forwardingActionType": "SET_EGRESS_INTF_BY_ORDER",
            "matchCriteria": {
                "id": f"{eaclId}"
            },
            "defaultInterface": True,
            "egressInterfaces": [
                {
                    ### Outside2 Interface ###
                    "id": f"{phyID2}"
                },
                {
                    ### Outside Interface ###
                    "id": f"{phyID1}"
                }
            ]}
        ]
    })
    pbrresponse = requests.request("POST", pbr_url, headers=headers, data=pbr_payload, verify=False)
    json_pbr = json.loads(pbrresponse.text)

    print("----------------------Printing PBR ID--------------------------")
    print(json_pbr['id'])
   

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", required=True, help="Address of Cisco CDFMC")
    parser.add_argument("--token", required=True, help="Token of Cisco CDFMC")
    args = parser.parse_args()
    main(args)