#!/bin/bash

logs="/home/ec2-user/log.$(date +%Y-%m-%d)"

uid=$(id -u)
if [ $uid -ne 0 ]; then
echo "execute script with sudo" | tee -a "$logs"
exit 1
else
echo "user validation done and proceeding with next steps" | tee -a "$logs"
fi

if [ ! -f "$logs" ]; then
touch $logs
fi

validate(){
    if [ $1 -eq 0 ]; then
    echo "$2 successfull" | tee -a "$logs"
    else
    echo "$2 failed" | tee -a "$logs"
    exit 1
    fi # FIX 1: Added the missing 'fi' that caused your syntax error
}

dnf list installed nodejs &>> "$logs"
if [ $? -ne 0 ]; then
dnf module disable nodejs -y &>> "$logs"
validate $? "disable old nodejs"
dnf module enable nodejs:20 -y &>> "$logs"
validate $? "enable new nodejs:20"

dnf install nodejs -y &>> "$logs"
validate $? "installing nodejs:20"
fi # FIX 2: Added missing closing 'fi' for the nodejs installation check block

# FIX 3: Fixed typo from '/etc/password' to '/etc/passwd'
cat /etc/passwd | grep "roboshop" &>> "$logs"
if [ $? -eq 0 ]; then
echo "roboshop user already existed" | tee -a "$logs"
else
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> "$logs"
validate $? "user creation"
fi

rm -rf /app/
mkdir /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$logs"
cd /app 
unzip /tmp/catalogue.zip &>> "$logs"
validate $? "Extracting catalogue artifacts"

npm install &>> "$logs"
validate $? "npm package installation"

# FIX 4: Removed code comment highlights that cause systemd to fail to parse the file
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
# FIX 5: Added the missing closing 'EOF' for the systemd service file definition

systemctl daemon-reload &>> "$logs"
systemctl enable catalogue &>> "$logs"
systemctl start catalogue &>> "$logs"
validate $? "Catalogue service setup"

cat <<EOF > /etc/yum.repos.d/mongo.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
enabled=1
gpgcheck=0
EOF

dnf install mongodb-mongosh -y &>> "$logs"
validate $? "Mongosh client installation"

# Schema loading execution
echo "Loading master database schema..." | tee -a "$logs"
mongosh --host mongodb.yokshithkumar.shop </app/db/master-data.js &>> "$logs"
validate $? "MongoDB schema loading"
