#!/bin/bash

logs="/home/ec2-user/log.$(date +%Y-%m-%d)"

# 1. Root user validation check
uid=$(id -u)
if [ "$uid" -ne 0 ]; then
    echo "execute script with sudo" | tee -a "$logs"
    exit 1
else
    echo "user validation done and proceeding with next steps" | tee -a "$logs"
fi

# 2. Log file initialization
if [ ! -f "$logs" ]; then
    touch "$logs"
fi

# 3. Success tracking validation function
validate(){
    if [ "$1" -eq 0 ]; then
        echo "$2 successful" | tee -a "$logs"
    else
        echo "$2 failed" | tee -a "$logs"
        exit 1
    fi
}

# 4. Node.js runtime installation
dnf list installed nodejs &>> "$logs"
if [ $? -ne 0 ]; then
    echo "Installing Node.js 20..." | tee -a "$logs"
    dnf module disable nodejs -y &>> "$logs"
    validate $? "disable old nodejs"
    
    dnf module enable nodejs:20 -y &>> "$logs"
    validate $? "enable new nodejs:20"

    dnf install nodejs -y &>> "$logs"
    validate $? "installing nodejs:20"
else
    echo "Node.js is already installed" | tee -a "$logs"
fi

# 5. Application runtime service user setup
cat /etc/passwd | grep "roboshop" &>> "$logs"
if [ $? -eq 0 ]; then
    echo "roboshop user already exists" | tee -a "$logs"
else
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$logs"
    validate $? "user creation"
fi

# 6. Artifact download and deployment extraction
echo "Downloading and extracting application artifacts..." | tee -a "$logs"
rm -rf /app/ /tmp/catalogue.zip
mkdir /app 

curl -s -L -o /tmp/catalogue.zip https://amazonaws.com &>> "$logs"
validate $? "Downloading catalogue source zip"

cd /app 
unzip -o /tmp/catalogue.zip &>> "$logs"
validate $? "Extracting catalogue artifacts"

# 7. Package dependency resolution
echo "Resolving node modules..." | tee -a "$logs"
npm install &>> "$logs"
validate $? "npm package installation"

# 8. Systemd daemon execution specification setup
echo "Configuring Systemd service block..." | tee -a "$logs"
cat <<EOF > /etc/systemd/system/catalogue.service
[Unit]
Description = Catalogue Service

[Service]
User=roboshop
Environment=MONGO=true
Environment=MONGO_URL="mongodb://mongodb.yokshithkumar.shop:27017/catalogue"
ExecStart=/bin/node /app/server.js
SyslogIdentifier=catalogue

[Install]
WantedBy=multi-user.target
EOF
validate $? "Systemd configuration file write"

# 9. Startup process execution controls
systemctl daemon-reload &>> "$logs"
systemctl enable catalogue &>> "$logs"
systemctl restart catalogue &>> "$logs"
validate $? "Catalogue background process initialization"

# 10. Database client package dependency routing
echo "Registering MongoDB repository infrastructure..." | tee -a "$logs"
cat <<EOF > /etc/yum.repos.d/mongo.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://mongodb.org
enabled=1
gpgcheck=0
EOF
validate $? "MongoDB Repository Generation"

dnf install mongodb-mongosh -y &>> "$logs"
validate $? "Mongosh client binary installation"

# 11. Core storage schema structural synchronization updates
echo "Synchronizing base cluster document model sets..." | tee -a "$logs"
mongosh --host mongodb.yokshithkumar.shop </app/db/master-data.js &>> "$logs"
validate $? "Master database document data load processing"
