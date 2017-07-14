#!/bin/bash

# Note: get from amazon docs:
# https://aws.amazon.com/es/blogs/compute/using-amazon-efs-to-persist-data-from-amazon-ecs-containers/
# http://docs.aws.amazon.com/efs/latest/ug/getting-started.html

# Logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sleep 30 # workaround -> nat dependency. TODO: fix modules dependencies
#Join the default ECS cluster
echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
PATH=$PATH:/usr/local/bin
# Instance should be added to an security group that allows HTTP outbound
yum -y update
#Install jq, a JSON parser
yum -y install jq
#Install NFS client
if ! rpm -qa | grep -qw nfs-utils; then
    yum -y install nfs-utils
fi
if ! rpm -qa | grep -qw python27; then
	yum -y install python27
fi
#Install pip
yum -y install bind-utils
yum -y install python27-pip
pip install --upgrade pip
#Install awscli
/usr/local/bin/pip install awscli
#Upgrade to the latest version of the awscli
/usr/local/bin/pip install --upgrade awscli
#Add support for EFS to the CLI configuration
aws configure set preview.efs true
#Get region of EC2 from instance metadata
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
#Create mount point
#mkdir /mnt/efs
mkdir -p ${service_data_dir}
chown ec2-user:ec2-user ${service_data_dir}
#Get EFS FileSystemID attribute
#Instance needs to be added to a EC2 role that give the instance at least read access to EFS
EFS_FILE_SYSTEM_ID=`/usr/local/bin/aws efs describe-file-systems --region $EC2_REGION | jq '.FileSystems[]' | jq 'select(.Name=="${efs_name}")' | jq -r '.FileSystemId'`
#Check to see if the variable is set. If not, then exit.
if [ -z "$EFS_FILE_SYSTEM_ID" ]; then
	echo "ERROR: variable not set" 1> /etc/efssetup.log
	exit
fi
#Instance needs to be a member of security group that allows 2049 inbound/outbound
#The security group that the instance belongs to has to be added to EFS file system configuration
#Create variables for source and target
DIR_SRC=$EC2_AVAIL_ZONE.$EFS_FILE_SYSTEM_ID.efs.$EC2_REGION.amazonaws.com
DIR_TGT=${service_data_dir}
EFS_FILE_SYSTEM_ID=``

# EFS check section
EFS_STATE="unknown"
until [ "$EFS_STATE" == "available" ]; do
  EFS_STATE=$(aws efs describe-file-systems \
    --region $EC2_REGION | jq '.FileSystems[]' | jq 'select(.Name=="${efs_name}")' | jq -r '.LifeCycleState')

  sleep 5
done

EFS_IP=$DIR_SRC
ip=`dig +short $EFS_IP`
until [ "$ip" ]; do
    sleep 5
    ip=`dig +short $EFS_IP`
done

#Mount EFS file system
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $DIR_SRC:/ $DIR_TGT
#Backup fstab
cp -p /etc/fstab /etc/fstab.back-$(date +%F)
#Append line to fstab
echo -e "$DIR_SRC:/ \t\t $DIR_TGT \t\t nfs4 \t\t nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev \t\t 0 \t\t 0" | tee -a /etc/fstab

#ECS-Optimized AMI filesystem mount will not propagate to the Docker daemon until it's restarted
#because the Docker daemon's mount namespace is unshared from the host's at launch.
service docker restart
stop ecs
start ecs
