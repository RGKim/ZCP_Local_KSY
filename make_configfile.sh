#!/bin/bash

echo -n "Cluster Version: "
read version

echo -n "Cluster Name: "
read Name

echo -n "CA Domain(Default: .icp): "
read Domain
[ -z $Domain ] && Domain=icp

while true; do
    echo -n "Cluster Admin Password: "
    stty -echo
    read Password
    
    stty echo
    echo ""

    echo -n "Re-enter Cluster Admin Password: "
    stty -echo
    read confirm_pass

    stty echo
    echo ""

    [ $Password == $confirm_pass ] && break;

    echo -e "\033[31m"Password and password verification do not match."\033[0m"

    export Password
done 

stty echo
echo $Password

echo -n "Network Type(1. Calico 2. NSX-T): "
read NW_type
if [ $NW_type == 1 ]; then
    export nw=calico
    echo -n "Network CIDR(Default: 10.1.0.0/16): "
    read CIDR
    [ -z $CIDR ] && CIDR=10.1.0.0/16

    echo -n "Service Cluster IP Range(Default: 10.0.0.0/16): "
    read cluster_ip
    [ -z $cluster_ip ] && cluster_ip=10.0.0.0/16

    echo -n "Calico IPIP Mode(Always, CrossSubnet, Never): "
    read IPIP

    echo -n "Calico MTU(Default: 1430): "
    read MTU

    echo -n "IP Autodetection Method "
    echo -n "( example: interface=eth0, can-reach={{ groups['master'][0] }} ): "
    read IP_autodetection

elif [ $NW_type == 2 ]; then
    export nw=nsx-t
    echo "Write the network setting section in config.yaml on your own."
else
    printf "\033[31m%s\n\033[0m" "  Unsupported Network Type"
fi;

echo -n "Cluster External LB IP or Domain: "
read cluster_lb

echo -n "External LB(Proxy) IP or Domain: "
read proxy_lb

echo -n "Are you planning to have a high availability configuration?(Cluster&Proxy:1, Cluster Only:2, Proxy Only:3, NO:4): "
read ha
if [ $ha == 1 ]; then
    echo -n "VIP Manager(etcd or keepalived): "
    read vip_manager
    export vip_manager

    echo -n "Cluster VIP: "
    read cluster_vip
    export cluster_vip

    echo -n "Cluster VIP Interface: "
    read cluster_vip_if
    export cluster_vip_if

    echo -n "Proxy VIP: "
    read proxy_vip
    export proxy_vip

    echo -n "Proxy VIP Interface: "
    read proxy_vip_if
    export proxy_vip_if

elif [ $ha == 2 ]; then
    echo -n "VIP Manager(etcd or keepalived): "
    read vip_manager
    export vip_manager

    echo -n "Cluster VIP: "
    read cluster_vip
    export cluster_vip 
elif [ $ha == 3 ]; then
    echo -n "Proxy VIP: "
    read proxy_vip
    export proxy_vip

    echo -n "Proxy VIP Interface: "
    read proxy_vip_if
    export proxy_vip_if
elif [ $ha == 4 ]; then
    echo -e "No High Availability"
fi;

echo -e "Set Management Services(1: Enable, 2: Disable)"

echo -n "Monitoring: "
read Monitoring

echo -n "Service Catalog: "
read service_catalog

echo -n "Logging: "
read logging

echo -n "Metering: "
read metering

echo -n "Image Security Enforcement: "
read image_security_enforcement

echo -n "Istio: "
read Istio

echo -n "Vulnerability Advisor: "
read va

echo -n "Storage GlusterFS: "
read glusterfs

echo -n "Storage Minio: "
read minio

echo -e "For more management services,  write the management_services section in config.yaml on your own."

function change_answer(num){
    if [ $num == 1 ]; then
        num = "enabled"
    else
        num = "disabled"
    fi;
}


if [ $version == "3.2.0" ]; then
    