#!/bin/bash

BASTION_ID="ocid1.bastion.oc1.ap-sydney-1.amaaaaaacmsjdpiatormvnlwrgrvxh7k3kzycukvhq3oom2iax2yy5jgzvpa"
TARGET_RESOURCE_ID="ocid1.instance.oc1.ap-sydney-1.anzxsljrcmsjdpichv5labxct3niwbvlpub6g6ig4ejgwneo6ibei7ibcm3q"
PUBLIC_KEY_FILE="/Users/shadab/Downloads/shadablenovo.pub"
PRIVATE_KEY_FILE="/Users/shadab/Downloads/mydemo_vcn.priv"
PROFILE="EEOCI"
USERNAME="opc"

oci setup repair-file-permissions --file $PRIVATE_KEY_FILE

SESSION_ID=$(oci bastion session create-managed-ssh \
    --bastion-id $BASTION_ID \
    --session-ttl 10800 \
    --profile $PROFILE \
    --target-port 22 \
    --target-resource-id $TARGET_RESOURCE_ID \
    --target-os-username $USERNAME \
    --ssh-public-key-file $PUBLIC_KEY_FILE \
    --query 'data.id' --raw-output)

echo "Created session with ID: $SESSION_ID"

echo "Waiting for session to be active..."
until [ "$(oci bastion session get --session-id $SESSION_ID --profile $PROFILE --query 'data."lifecycle-state"' --raw-output)" == "ACTIVE" ]; do
    sleep 2
done

echo "Session is active!"

SSH_COMMAND=$(oci bastion session get --session-id $SESSION_ID --profile $PROFILE --query 'data."ssh-metadata"."command"' --raw-output)

SSH_COMMAND=$(echo "$SSH_COMMAND" | sed "s|<privateKey>|$PRIVATE_KEY_FILE|g")

echo "################################################################"
echo ""
echo "$SSH_COMMAND"
echo ""
echo "################################################################"

echo "Connecting via SSH..."
eval $SSH_COMMAND
