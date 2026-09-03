import json
import logging
import os

import boto3

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

EC2 = boto3.client("ec2")
TARGET_SECURITY_GROUP_ID = os.environ["TARGET_SECURITY_GROUP_ID"]

PUBLIC_IPV4 = "0.0.0.0/0"
PUBLIC_IPV6 = "::/0"


def lambda_handler(event, context):
    detail = event.get("detail", {})
    request = detail.get("requestParameters", {})
    group_id = request.get("groupId")

    LOGGER.info(
        json.dumps(
            {
                "message": "Received security group event",
                "event_name": detail.get("eventName"),
                "group_id": group_id,
                "request_id": detail.get("requestID"),
            }
        )
    )

    if detail.get("eventName") != "AuthorizeSecurityGroupIngress":
        return response("ignored", "Unexpected event type")

    if group_id != TARGET_SECURITY_GROUP_ID:
        return response("ignored", "Security group is outside project scope")

    permissions = request.get("ipPermissions", {}).get("items", [])
    dangerous_permissions = []

    for permission in permissions:
        dangerous_ipv4_ranges = [
            {"CidrIp": item["cidrIp"]}
            for item in permission.get("ipRanges", {}).get("items", [])
            if item.get("cidrIp") == PUBLIC_IPV4
        ]

        dangerous_ipv6_ranges = [
            {"CidrIpv6": item["cidrIpv6"]}
            for item in permission.get("ipv6Ranges", {}).get("items", [])
            if item.get("cidrIpv6") == PUBLIC_IPV6
        ]

        if not dangerous_ipv4_ranges and not dangerous_ipv6_ranges:
            continue

        revoke_permission = {
            "IpProtocol": permission["ipProtocol"],
        }

        if "fromPort" in permission:
            revoke_permission["FromPort"] = permission["fromPort"]

        if "toPort" in permission:
            revoke_permission["ToPort"] = permission["toPort"]

        if dangerous_ipv4_ranges:
            revoke_permission["IpRanges"] = dangerous_ipv4_ranges

        if dangerous_ipv6_ranges:
            revoke_permission["Ipv6Ranges"] = dangerous_ipv6_ranges

        dangerous_permissions.append(revoke_permission)

    if not dangerous_permissions:
        return response("ignored", "No public ingress ranges detected")

    EC2.revoke_security_group_ingress(
        GroupId=group_id,
        IpPermissions=dangerous_permissions,
    )

    LOGGER.warning(
        json.dumps(
            {
                "message": "Dangerous ingress remediated",
                "group_id": group_id,
                "revoked_permissions": dangerous_permissions,
                "actor": detail.get("userIdentity", {}).get("arn"),
                "source_ip": detail.get("sourceIPAddress"),
            }
        )
    )

    return response(
        "remediated",
        f"Revoked {len(dangerous_permissions)} public ingress permission(s)",
    )


def response(status, message):
    result = {
        "status": status,
        "message": message,
    }

    LOGGER.info(json.dumps(result))
    return result