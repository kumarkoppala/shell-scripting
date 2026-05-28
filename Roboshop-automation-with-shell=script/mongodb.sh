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
    fi
}



echo "adding mongodb repo"
cat <<-EOF > /etc/yum.repos.d/mongo.repo
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
enabled=1
gpgcheck=0
EOF

dnf list installed mongodb-org &>> $logs
if [ $? -ne 0 ]; then
echo "mongod installation started"
dnf install mongodb-org -y &>> "$logs"
validate $? "mongod Service installation"
else
echo "mongod already installed" | tee -a "$logs"
fi

systemctl enable mongod &>> "$logs"
systemctl start mongod &>> "$logs"

validate $? "Mongod service starting status"

echo "changing mongod.conf file to give internet access" | tee -a "$logs"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod 

validate $? "Mongod service starting status"



