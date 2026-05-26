log_file="/home/ec2-user/bash.logs"
touch 

uid=0
if [  -ne 0 ]; then
echo "please execute script with super user" | tee -a 
exit 1
fi

validate(){
    if [ 0 = 0 ]; then
    echo " installed successfully" | tee -a 
    else
    echo " failed" | tee -a 
    fi
}
for service in 
do
dnf list installed  >> "" 2>&1
if [ 0 -eq 0 ]; then
dnf install  -y >> "" 2>&1
validate "" 0
else
echo "package is already installed" >> ""
fi
done
