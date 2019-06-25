#!/bin/bash

kubectl version -o json | sed '4d' >> version.json
version=$(cat version.json | grep -i minor | awk -F '"' '{print $4}')

rm -rf version.json

echo -n "Cluster Master IP: "
read url

cloudctl login -a https://$url:8443 --skip-ssl-validation

datetime=`date +%Y%m%d-%H%M%S`

DIR=~/zcp-verification/$datetime
mkdir -p $DIR


###### Count ######
kubectl get images --all-namespaces >> $DIR/private_docker_registry.log
Docker_l=$(cat $DIR/private_docker_registry.log | wc -l)
Docker_l=$((Docker_l-1))

cloudctl catalog charts -s >> $DIR/helm_chart.log
Catalog=$(cat $DIR/helm_chart.log | wc -l)
Catalog=$((Catalog-1))

kubectl get ns >> $DIR/namespaces.log
Namespace=$(cat $DIR/namespaces.log | wc -l)
Namespace=$((Namespace-1))

kubectl get pod --all-namespaces >> $DIR/pod.log
Pod=$(cat $DIR/pod.log | wc -l)
Pod=$((Pod-1))

kubectl get ds --all-namespaces >> $DIR/daemonset.log
DaemonSet=$(cat $DIR/daemonset.log | wc -l)
DaemonSet=$((DaemonSet-1))


kubectl get deploy --all-namespaces >> $DIR/deployment.log
Deployment=$(cat $DIR/deployment.log | wc -l)
Deployment=$((Deployment-1))

helm list --tls >> $DIR/helm_release.log
helm_release=$(cat $DIR/helm_release.log | wc -l)
helm_release=$((helm_release-1))

kubectl get job --all-namespaces >> $DIR/job.log
Jobs=$(cat $DIR/job.log | wc -l)
Jobs=$((Jobs-1))

kubectl get cronjob --all-namespaces >> $DIR/cronjob.log
CronJob=$(cat $DIR/cronjob.log | wc -l)
CronJob=$((CronJob-1))

kubectl get sts --all-namespaces >> $DIR/statefulset.log
StatefulSet=$(cat $DIR/statefulset.log | wc -l)
StatefulSet=$((StatefulSet-1))

kubectl get rs --all-namespaces >> $DIR/replicaset.log
ReplicaSet=$(cat $DIR/replicaset.log | wc -l)
ReplicaSet=$((ReplicaSet-1))

kubectl get svc --all-namespaces >> $DIR/services.log
Services=$(cat $DIR/services.log | wc -l)
Services=$((Services-1))

kubectl get ing --all-namespaces >> $DIR/ingress.log
Ingress=$(cat $DIR/ingress.log | wc -l)
Ingress=$((Ingress-1))

kubectl get cm --all-namespaces >> $DIR/configmaps.log
ConfigMaps=$(cat $DIR/configmaps.log | wc -l)
ConfigMaps=$((ConfigMaps-1))

kubectl get hpa --all-namespaces >> $DIR/scaling_policies.log
ScalingPolicies=$(cat $DIR/scaling_policies.log | wc -l)
ScalingPolicies=$((ScalingPolicies-1))

kubectl get secrets --all-namespaces >> $DIR/secrets.log
Secret=$(cat $DIR/secrets.log | wc -l)
Secret=$((Secret-1))

###### DaemonSet ######
sed "1d" $DIR/daemonset.log >> out.txt

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


###### Deployment ###### Version Check
sed "1d" $DIR/deployment.log >> out.txt

echo -e "\t\033[33m"=========== CHECK  Deployment ==========="\033[0m"
deploy_error=0

if [ $version == 12 ]; then
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
                ((deploy_error++));
            fi;
        else
            printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
            ((deploy_error++));
        fi;

    done < out.txt
elif [ $version == 13 ]; then
    while read line; do
        export NAME=$(echo $line | awk '{print $2;}')
        export DESIRED=$(echo $line | awk '{print $3;}' | cut -f 1 -d'/')
        export CURRENT=$(echo $line | awk '{print $3;}' | cut -f 2 -d'/')
        export AVAILABLE=$(echo $line | awk '{print $5;}')

        if [ $DESIRED == $CURRENT ]; then
            if [ $CURRENT == $AVAILABLE ]; then
                printf "%-50s\033[32m %s\n\033[0m" "$NAME" "READY"
            else
                printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
                ((deploy_error++));
            fi;
        else
            printf "%-50s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
            ((deploy_error++));
        fi;

    done < out.txt
else
    printf "\033[31m%s\n\033[0m" "  Unsupported Kubernetes Version"
fi;
echo " "
rm -rf out.txt

###### Helm Release ######
sed "1d" $DIR/helm_release.log >> out.txt

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
sed "1d" $DIR/job.log >> out.txt

echo -e "\t\033[33m"=================== CHECK Jobs ==================="\033[0m"
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

###### StatefulSet ###### version check
sed "1d" $DIR/statefulset.log >> out.txt

echo -e "\t\033[33m"=============== CHECK StatefulSet ==============="\033[0m"
sts_error=0
if [ $version == 12 ]; then
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
elif [ $version == 13 ]; then
    while read line; do
        export NAME=$(echo $line | awk '{print $2;}')
        export DESIRED=$(echo $line | awk '{print $3;}' | cut -f 1 -d'/')
        export CURRENT=$(echo $line | awk '{print $3;}' | cut -f 2 -d'/')

        if [ $DESIRED == $CURRENT ]; then
            printf "%-60s\033[32m %s\n\033[0m" "$NAME" "READY"
        else
            printf "%-60s\033[31m %s\n\033[0m" "$NAME" "NOT READY"
            ((sts_error++));
        fi;

    done < out.txt
else
    printf "\033[31m%s\n\033[0m" "  Unsupported Kubernetes Version"
fi;
echo " "
rm -rf out.txt

###### ReplicaSet ######
sed "1d" $DIR/replicaset.log >> out.txt

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
echo -e "\033[33m"======================================"\033[0m"
printf "\033[33m%s\n\033[0m" "  Verification Result(Resource Count)"
echo -e "\033[33m"======================================"\033[0m"
printf "%-30s\033[32m %d\n\033[0m" "Private Docker Registry" "$Docker_l"
printf "%-30s\033[32m %d\n\033[0m" "Helm Chart(Catalog)" "$Catalog"
printf "%-30s\033[32m %d\n\033[0m" "DaemonSet" "$DaemonSet"
printf "%-30s\033[32m %d\n\033[0m" "Deployment" "$Deployment"
printf "%-30s\033[32m %d\n\033[0m" "Helm Release" "$helm_release"
printf "%-30s\033[32m %d\n\033[0m" "Jobs" "$Jobs"
printf "%-30s\033[32m %d\n\033[0m" "CronJob" "$CronJob"
printf "%-30s\033[32m %d\n\033[0m" "StatefulSet" "$StatefulSet"
printf "%-30s\033[32m %d\n\033[0m" "ReplicaSet" "$ReplicaSet"
printf "%-30s\033[32m %d\n\033[0m" "Services" "$Services"
printf "%-30s\033[32m %d\n\033[0m" "Ingress" "$Ingress"
printf "%-30s\033[32m %d\n\033[0m" "ConfigMaps" "$ConfigMaps"
printf "%-30s\033[32m %d\n\033[0m" "Scaling Policies" "$ScalingPolicies"
printf "%-30s\033[32m %d\n\033[0m" "Secret" "$Secret"
echo " "

echo -e "\033[33m"======================================"\033[0m"
printf "\033[33m%s\n\033[0m" "   Verification Result(Status Check)"
echo -e "\033[33m"======================================"\033[0m"
if [ $ds_error == 0 ]; then
    printf "%-30s\033[32m %s\n\033[0m" "DaemonSet" "OK"
else
    printf "%-30s\033[31m %s\n\033[0m" "DaemonSet" "NOT OK"
fi;

if [ $deploy_error == 0 ]; then
    printf "%-30s\033[32m %s\n\033[0m" "Deployment" "OK"
else
    printf "%-30s\033[31m %s\n\033[0m" "Deployment" "NOT OK"
fi;

if [ $helm_error == 0 ]; then
    printf "%-30s\033[32m %s\n\033[0m" "Helm release" "OK"
else
    printf "%-30s\033[31m %s\n\033[0m" "Helm release" "NOT OK"
fi;

if [ $job_error == 0 ]; then
    printf "%-30s\033[32m %s\n\033[0m" "Jobs" "OK"
else
    printf "%-30s\033[31m %s\n\033[0m" "Jobs" "NOT OK"
fi;

if [ $sts_error == 0 ]; then
    printf "%-30s\033[32m %s\n\033[0m" "StatefulSet" "OK"
else
    printf "%-30s\033[31m %s\n\033[0m" "StatefulSet" "NOT OK"
fi;

if [ $rs_error == 0 ]; then
   printf "%-30s\033[32m %s\n\033[0m" "ReplicaSet" "OK"
else
    printf "%-30s\033[31m %s\n\033[0m" "ReplicatSet" "NOT OK"
fi;
echo " "

echo -e "\033[33m"--------------------------------------"\033[0m"
printf "\033[33m%s\n\033[0m" "for more details '~/zcp_verification/'"
echo -e "\033[33m"--------------------------------------"\033[0m"