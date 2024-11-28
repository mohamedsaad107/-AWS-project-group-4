#!/bin/bash

# Set AWS region (optional)
# aws configure

# Task 1: Create a VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Lab VPC}]' --query 'Vpc.VpcId' --output text)
echo "Created VPC with ID: $VPC_ID"

# Enable DNS Hostnames for the VPC
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "Enabled DNS Hostnames for VPC"

# Task 2.1: Create Public Subnet
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet}]' --query 'Subnet.SubnetId' --output text)
echo "Created Public Subnet with ID: $PUBLIC_SUBNET_ID"

# Enable Auto-assign Public IP Addresses for Public Subnet
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch
echo "Enabled Auto-assign Public IP for Public Subnet"

# Task 2.2: Create Private Subnet
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/23 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet}]' --query 'Subnet.SubnetId' --output text)
echo "Created Private Subnet with ID: $PRIVATE_SUBNET_ID"

# Task 3: Create and Attach Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Lab IGW}]' --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Created and attached Internet Gateway with ID: $IGW_ID"

# Task 4: Create Public Route Table and Route for Internet Traffic
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]' --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Created Public Route Table and added route to IGW"

# Associate Public Subnet with Public Route Table
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET_ID
echo "Associated Public Subnet with Public Route Table"

# Task 5: Create Security Group for Application Server
SG_ID=$(aws ec2 create-security-group --group-name App-SG --description "Security group for app server" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Created Security Group and allowed HTTP access from anywhere"

# Task 6: Create Key Pair (optional, if SSH access is needed)
aws ec2 create-key-pair --key-name LabKey --query 'KeyMaterial' --output text > LabKey.pem
chmod 400 LabKey.pem
echo "Created Key Pair: LabKey"

# Create a simple User Data script to install and configure a web server
cat <<EOT >> userdata.sh
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Inventory Application Running</h1>" > /var/www/html/index.html
EOT
echo "User data script created"

# Launch EC2 Instance in Public Subnet
AMI_ID=ami-0c55b159cbfafe1f0 # Change this to your specific AMI ID
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t2.micro --key-name LabKey --security-group-ids $SG_ID --subnet-id $PUBLIC_SUBNET_ID --user-data file://userdata.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=App Server}]' --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 instance with ID: $INSTANCE_ID"

# Fetch Public DNS for the EC2 Instance
PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicDnsName' --output text)
echo "Application server is running at: http://$PUBLIC_DNS"

