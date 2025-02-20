import requests
import argparse

# python3 clear_cdfmc.py --token YOUR_BEARER_TOKEN --host https://your-cdfmc-host

# Disable SSL warnings if using self-signed certificates (optional)
requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

def delete_item(bearer_token, cdfmc_host, endpoint, item_name, security_zone=False):
    """
    Deletes an item by name at the specified API endpoint using Bearer token authorization.
    """
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {bearer_token}'
    }
    
    # Step 1: Get the item by name
    if security_zone:
        url = f"{cdfmc_host}{endpoint}?name={item_name}"
    else:
        url = f"{cdfmc_host}{endpoint}?filter=nameOrValue:{item_name}"
    response = requests.get(url, headers=headers, verify=False)

    if response.status_code == 200:
        item_data = response.json()
        if "items" in item_data and len(item_data["items"]) > 0:
            item_id = item_data["items"][0]["id"]
            
            # Step 2: Delete the item using the ID
            delete_url = f"{cdfmc_host}{endpoint}/{item_id}"
            delete_response = requests.delete(delete_url, headers=headers, verify=False)
            
            if delete_response.status_code == 200:
                print(f"Deleted {item_name} successfully.")
            else:
                print(f"Failed to delete {item_name}: {delete_response.status_code} {delete_response.text}")
        else:
            print(f"{item_name} not found.")
    else:
        print(f"Failed to search for {item_name}: {response.status_code} {response.text}")

def delete_nat_policies(bearer_token, cdfmc_host, nat_policy_names):
    print("Deleting NAT policies...")
    for nat_policy_name in nat_policy_names:
        delete_item(bearer_token, cdfmc_host, "/api/fmc_config/v1/domain/default/policy/ftdnatpolicies", nat_policy_name)

def delete_extended_acls(bearer_token, cdfmc_host, acl_names):
    print("Deleting Extended ACLs...")
    for acl_name in acl_names:
        delete_item(bearer_token, cdfmc_host, "/api/fmc_config/v1/domain/default/object/extendedaccesslists", acl_name)

def delete_network_objects(bearer_token, cdfmc_host, object_names):
    print("Deleting Network Objects...")
    for obj_name in object_names:
        delete_item(bearer_token, cdfmc_host, "/api/fmc_config/v1/domain/default/object/networks", obj_name)

def delete_host_objects(bearer_token, cdfmc_host, object_names):
    print("Deleting Host Objects...")
    for obj_name in object_names:
        delete_item(bearer_token, cdfmc_host, "/api/fmc_config/v1/domain/default/object/hosts", obj_name)

def delete_security_zones(bearer_token, cdfmc_host, security_zone_names):
    print("Deleting Security Zones...")
    for zone_name in security_zone_names:
        delete_item(bearer_token, cdfmc_host, "/api/fmc_config/v1/domain/default/object/securityzones", zone_name, True)

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Delete NAT policies, ACLs, objects, and security zones from CDFMC.")
    parser.add_argument('--token', required=True, help="Bearer token for authentication")
    parser.add_argument('--host', required=True, help="CDFMC host URL (e.g., https://your-cdfmc-host)")
    args = parser.parse_args()

    # List of items to delete
    nat_policy_names = ["NAT_Policy01", "NAT_Policy02"]
    acl_names = ["ExtendedAccessListTest"]
    network_object_names = ["Inside-subnet-01", "Inside-subnet-02", "Outside-subnet-01", "Outside-subnet-02", "Public-subnet-01", "Public-subnet-02"]
    host_object_names = ["Outside01-GW", "Outside02-GW"]
    security_zone_names = ["InZone", "OutZone01", "OutZone02"]

    # Delete NAT policies
    delete_nat_policies(args.token, args.host, nat_policy_names)

    # Delete Extended ACLs
    delete_extended_acls(args.token, args.host, acl_names)

    # Delete Objects
    delete_network_objects(args.token, args.host, network_object_names)
    delete_host_objects(args.token, args.host, host_object_names)

    # Delete Security Zones
    delete_security_zones(args.token, args.host, security_zone_names)

if __name__ == "__main__":
    main()
