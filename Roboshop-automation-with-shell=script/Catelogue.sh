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
}
dnf list installed nodejs &>> "$logs"
if [ $? -ne 0 ]; then
dnf module disable nodejs -y &>> "$logs"
validate $? "disable old nodejs"
dnf module enable nodejs:20 -y &>> "$logs"
validate $? "enable new nodejs:20"

dnf install nodejs -y &>> "$logs"
validate $? "installing nodejs:20"

cat /etc/password | grep "roboshop"
if [ $? -eq 0 ]; then
echo "roboshop user already existed" | tee -a "$logs"
else

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop >> "$logs"
validate $? "user creation"
fi

rm -rf /app/
mkdir /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip

npm install

cat <<-EOF > /etc/systemd/system/catalogue.service
[Unit]
Description = Catalogue Service

[Service]
User=roboshop
Environment=MONGO=true
// highlight-start
Environment=MONGO_URL="mongodb://mongodb.yokshithkumar.shop:27017/catalogue"
// highlight-end
ExecStart=/bin/node /app/server.js
SyslogIdentifier=catalogue

[Install]
WantedBy=multi-user.target

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue

cat <<-EOF > /etc/yum.repos.d/mongo.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
enabled=1
gpgcheck=0
EOF

dnf install mongodb-mongosh -y
mongosh --host mongodb.yokshithkumar.shop </app/db/master-data.js




