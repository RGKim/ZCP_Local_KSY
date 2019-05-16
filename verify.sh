#!/bin/bash

###### DaemonSet ###### 
kubectl get ds --all-namespaces >> output.txt
sed "1d" output.txt >> out.txt

rm -rf output.txt

echo -e "\t\033[33m"============ CHECK  DaemonSet ============"\033[0m"
ds_error=0
while read line; do
    export NAME=$(echo $line | awk '{print $2;}')
    export DESIRED=$(echo $line | awk '{print $3;}')
    export CURRENT=$(echo $line | awk '{print $4;}')
    export READY=$(echo $line | awk '{print $5;}')
    export AVAILABLE=$(echo $line | awk '{print $7;}')

    if [ $DESIRED == $CURRENT ]; then 
        if [ $CURRENT == $READY ]; then
            if [ $READY == $AVAILABLE ]; then
                #echo -e $(echo $line | awk '{print $2;}') is "\033[32m"READY"\033[0m";
                printf "%-50s\033[32m %s\n\033[0m" "$NAME" "READY" 
            else
                #echo -e $(echo $line | awk '{print $2;}') is "\033[31m"NOT READY"\033[0m";
                printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
                ((ds_error++));
            fi;
        else
            printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
            ((ds_error++));
        fi;
    else
        printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
        ((ds_error++));
    fi;
   
done < out.txt
echo " "
rm -rf out.txt


###### Deployment ######
kubectl get deploy --all-namespaces >> output.txt
sed "1d" output.txt >> out.txt

rm -rf output.txt

echo -e "\t\033[33m"=========== CHECK  Deployment ==========="\033[0m"
deploy_error=0

while read line; do
    export NAME=$(echo $line | awk '{print $2;}')
    export DESIRED=$(echo $line | awk '{print $3;}')
    export CURRENT=$(echo $line | awk '{print $4;}')
    export AVAILABLE=$(echo $line | awk '{print $6;}')

    if [ $DESIRED == $CURRENT ]; then 
        if [ $CURRENT == $AVAILABLE ]; then
            printf "%-50s\033[32m %s\n\033[0m" "$NAME" "READY" 
        else
            printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
            ((deploy++));
        fi;
    else
        printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
        ((deploy++));
    fi;
   
done < out.txt
echo " "
rm -rf out.txt


###### Helm Release ###### 
helm list --tls >> output.txt
sed "1d" output.txt >> out.txt

rm -rf output.txt

echo -e "\t\033[33m"========== CHECK Helm release =========="\033[0m"
helm_error=0

while read line; do
    export NAME=$(echo $line | awk '{print $1;}')
    export STATUS=$(echo $line | awk '{print $8;}')

    if [ "$STATUS" = "DEPLOYED" ]; then 
        printf "%-50s\033[32m %s\n\033[0m" "$NAME" "READY"
    else
        printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
        ((helm_error++))
    fi;
   
done < out.txt
echo " "
rm -rf out.txt

###### Job ###### 
kubectl get job --all-namespaces >> output.txt
sed "1d" output.txt >> out.txt

rm -rf output.txt

echo -e "\t\033[33m"=================== CHECK Job ==================="\033[0m"
job_error=0

while read line; do
    export NAME=$(echo $line | awk '{print $2;}')
    export COMPLETIONS=$(echo $line | awk '{print $3;}')

    if [ "$COMPLETIONS" = "1/1" ]; then 
        printf "%-60s\033[32m %s\n\033[0m" "$NAME" "READY"
    else
        printf "%-60s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
        ((job_error++));
    fi;
   
done < out.txt
echo " "
rm -rf out.txt

###### StatefulSet ###### 
kubectl get sts --all-namespaces >> output.txt
sed "1d" output.txt >> out.txt

rm -rf output.txt

echo -e "\t\033[33m"=============== CHECK StatefulSet ==============="\033[0m"
sts_error=0

while read line; do
    export NAME=$(echo $line | awk '{print $2;}')
    export DESIRED=$(echo $line | awk '{print $3;}')
    export CURRENT=$(echo $line | awk '{print $4;}')

    if [ $DESIRED == $CURRENT ]; then 
        printf "%-60s\033[32m %s\n\033[0m" "$NAME" "READY"
    else
        printf "%-60s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
        ((sts_error++));
    fi;
   
done < out.txt
echo " "
rm -rf out.txt

###### ReplicaSet ###### 
kubectl get rs --all-namespaces >> output.txt
sed "1d" output.txt >> out.txt

rm -rf output.txt

echo -e "\t\033[33m"================ CHECK  ReplicaSet ==============="\033[0m"
rs_error=0

while read line; do
    export NAME=$(echo $line | awk '{print $2;}')
    export DESIRED=$(echo $line | awk '{print $3;}')
    export CURRENT=$(echo $line | awk '{print $4;}')
    export READY=$(echo $line | awk '{print $5;}')

    if [ $DESIRED == $CURRENT ]; then 
        if [ $CURRENT == $READY ]; then
            printf "%-60s\033[32m %s\n\033[0m" "$NAME" "READY"
        else
            printf "%-60s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
            ((rs_error++));
        fi;
    else
        printf "%-60s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
        ((rs_error++));
    fi;
   
done < out.txt
echo " "
rm -rf out.txt


##### RESULT #####
echo -e "\033[33m"===================================="\033[0m"
printf "\033[33m\t%s\n\033[0m" "Verification Result"
echo -e "\033[33m"===================================="\033[0m"
if [ $ds_error == 0 ]; then
    echo -e DaemonSet"\t\t\033[32m"OK"\033[0m"
else
    echo -e DaemonSet"\t\t\033[31m"NOT OK"\033[0m"
fi;

if [ $deploy_error == 0 ]; then
    echo -e Deployment"\t\t\033[32m"OK"\033[0m"
else
    echo -e Deployment"\t\t\033[31m"NOT OK"\033[0m"
fi;

if [ $helm_error == 0 ]; then
    echo -e Helm release"\t\t\033[32m"OK"\033[0m"
else
    echo -e Helm release"\t\t\033[31m"NOT OK"\033[0m"
fi;

if [ $job_error == 0 ]; then
    echo -e Job"\t\t\t\033[32m"OK"\033[0m"
else
    echo -e Job"\t\t\t\033[31m"NOT OK"\033[0m"
fi;

if [ $sts_error == 0 ]; then
    echo -e StatefulSet"\t\t\033[32m"OK"\033[0m"
else
    echo -e StatefulSet"\t\t\033[31m"NOT OK"\033[0m"
fi;

if [ $rs_error == 0 ]; then
    echo -e ReplicaSet"\t\t\033[32m"OK"\033[0m"
else
    echo -e ReplicaSet"\t\t\033[31m"NOT OK"\033[0m"
fi;
echo " "


