#!/bin/bash

BASTION_ID="ocid1.bastion.oc1.ap-sydney-1.amaaaaaacmsjdpiatormvnlwrgrvxh7k3kzycukvhq3oom2iax2yy5jgzvpa"
TARGET_RESOURCE_ID="ocid1.instance.oc1.ap-sydney-1.anzxsljrcmsjdpichv5labxct3niwbvlpub6g6ig4ejgwneo6ibei7ibcm3q"
TARGET_PRIVATE_IP="10.208.21.136"
TARGET_PORT="8000"
LOCAL_PORT="8000"
PUBLIC_KEY_FILE="/Users/shadab/Downloads/shadablenovo.pub"
PRIVATE_KEY_FILE="/Users/shadab/Downloads/mydemo_vcn.priv"
PROFILE="EEOCI"

oci setup repair-file-permissions --file $PRIVATE_KEY_FILE

SESSION_ID=$(oci bastion session create-port-forwarding \
    --bastion-id $BASTION_ID \
    --session-ttl 10800 \
    --profile $PROFILE \
    --target-private-ip $TARGET_PRIVATE_IP \
    --target-port $TARGET_PORT \
    --target-resource-id $TARGET_RESOURCE_ID \
    --ssh-public-key-file $PUBLIC_KEY_FILE \
    --query 'data.id' --raw-output)

if [ -z "$SESSION_ID" ]; then
    echo "Failed to create Bastion session"
    exit 1
fi

echo "Created Port-Forwarding session with ID: $SESSION_ID"

echo "Waiting for session to be active..."
until [ "$(oci bastion session get --session-id $SESSION_ID --profile $PROFILE --query 'data."lifecycle-state"' --raw-output)" == "ACTIVE" ]; do
    sleep 3
done

echo "Session is active!"

SSH_COMMAND=$(oci bastion session get --session-id $SESSION_ID --profile $PROFILE --query 'data."ssh-metadata"."command"' --raw-output)

SSH_COMMAND=$(echo "$SSH_COMMAND" | sed "s|<privateKey>|$PRIVATE_KEY_FILE|g" | sed "s|<localPort>|$LOCAL_PORT|g")

echo "################################################################"
echo ""
echo "$SSH_COMMAND"
echo ""
echo "################################################################"

echo "Adding private key to SSH agent..."
eval "$(ssh-agent -s)"
ssh-add $PRIVATE_KEY_FILE

echo "Port-Forwarding Tunnel Command for OCI Bastion Service for $TARGET_PRIVATE_IP:$TARGET_PORT..."
echo ""
echo "Copy and Paste Command in New Terminal Window"
