###########################################################################
### Author : Shadab Mohammad, Master Principal Cloud Architect@Oracle ###
# Check_AWS_RDS_DB_Instances_Details
### Centre of Excellence, JAPAC
###########################################################################

now=$(date)

output_file="rds_db_instances_details.csv"


echo "Engine,DBIdentifier,EngineVersion,MultiAZ,AllocatedStorage,MaxAllocatedStorage,DBInstanceClass,DBInstanceStatus,BackupRetentionPeriod,InstanceCreateTime,Endpoint,PreferredBackupWindow,PreferredMaintenanceWindow,IAMDatabaseAuthenticationEnabled,StorageType,StorageEncrypted,StorageLeftPct,AttentionStorage,AttentionMultiAZ" > "$output_file"

echo ".................................................................."
echo "Check AWS RDS DB Instances Details"
echo "Date: $now"

echo ".................................................................."

tot_val=0
nStorageAllocationWatermarkPctg="25"

for region in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do
    printf "Region: %15s\n" "$region"
    
    db_counter_in_reg_val=0
    
    db_instances=$(aws rds describe-db-instances --region "${region}" --query 'DBInstances[*].[DBInstanceIdentifier]' --output text)
    
    for db_ident in $db_instances; do
        details=$(aws rds describe-db-instances --region "${region}" --db-instance-identifier "${db_ident}" \
        --query 'DBInstances[*].[Engine,DBInstanceIdentifier,EngineVersion,MultiAZ,AllocatedStorage,MaxAllocatedStorage,DBInstanceClass,DBInstanceStatus,BackupRetentionPeriod,InstanceCreateTime,Endpoint.Address,PreferredBackupWindow,PreferredMaintenanceWindow,IAMDatabaseAuthenticationEnabled,StorageType,StorageEncrypted]' \
        --output text)

        
        read -r strEngine strDBIdent strEngineVersion strMultiAZ strAllocatedStorage strMaxAllocatedStorage strDBInstanceClass strDBInstanceStatus strBackupRetentionPeriod strInstanceCreateTime strEndpoint strBackupWindow strMaintenanceWindow strIAMAuthEnabled strStorageType strStorageEncrypted <<< "$details"

        strAttention1="Ok"
        strAttention2="Ok"
        storage_left_pct="N/A"

        if [ "$strMaxAllocatedStorage" = "None" ]; then
            strAttention1="Bad"
        else
            storage_left=$((strMaxAllocatedStorage - strAllocatedStorage))
            storage_left_pct=$((100 * storage_left / strMaxAllocatedStorage))

            if [ "$storage_left_pct" -lt "$nStorageAllocationWatermarkPctg" ]; then
                strAttention1="Bad"
            fi
        fi

        if [ "$strMultiAZ" = "False" ]; then
            strAttention2="Bad"
        fi

        
        printf "#%-3s | eng: %-8s | ver: %-8s | ident: %-50s | class: %-15s | mAZ: %-6s %-3s | status: %-12s | allocStorage: %-8s (left %-3s pct) | maxAllocStorage: %-8s %-3s | backup: %-3d | createTime: %-20s | endpoint: %-40s | backupWin: %-10s | maintWin: %-10s | IAMAuth: %-3s | storageType: %-12s | storageEncrypted: %-3s\n" \
            $((db_counter_in_reg_val + 1)) "$strEngine" "$strEngineVersion" "$strDBIdent" "$strDBInstanceClass" "$strMultiAZ" "$strAttention2" "$strDBInstanceStatus" "$strAllocatedStorage" "$storage_left_pct" "$strMaxAllocatedStorage" "$strAttention1" "$strBackupRetentionPeriod" "$strInstanceCreateTime" "$strEndpoint" "$strBackupWindow" "$strMaintenanceWindow" "$strIAMAuthEnabled" "$strStorageType" "$strStorageEncrypted"

       
        echo "$strEngine,$strDBIdent,$strEngineVersion,$strMultiAZ,$strAllocatedStorage,$strMaxAllocatedStorage,$strDBInstanceClass,$strDBInstanceStatus,$strBackupRetentionPeriod,$strInstanceCreateTime,$strEndpoint,$strBackupWindow,$strMaintenanceWindow,$strIAMAuthEnabled,$strStorageType,$strStorageEncrypted,$storage_left_pct,$strAttention1,$strAttention2" >> "$output_file"

        db_counter_in_reg_val=$((db_counter_in_reg_val + 1))
        tot_val=$((tot_val + 1))
    done
done

echo ".................................................................."
printf "TOTAL:                                                  %10s\n" "$tot_val"
echo ".................................................................."

echo "Details have been written to: $output_file"

