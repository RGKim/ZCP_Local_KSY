#!/bin/bash


tar -xvzf ./icp-openldap-0.1.5.tgz


helm install --name=openldap --namespace default icp-openldap --tls

sleep 30;

export LDAP_IP=$(kubectl describe svc/openldap | grep IP: | awk '{print $2;}')
echo "LDAP IP: "$LDAP_IP


cloudctl iam ldap-create ldap --basedn "dc=local,dc=io" --binddn "cn=admin,dc=local,dc=io" --binddn-password "admin" --server ldap://$LDAP_IP:389 --group-filter "(&(cn=%v)(objectclass=groupOfUniqueNames))" --user-filter "(&(uid=%v)(objectclass=person))" --user-id-map "*:uid" --group-id-map "*:cn" --group-member-id-map "groupOfUniqueNames:uniquemember"


cloudctl iam team-create test
cloudctl iam team-add-users test Viewer -u user1,user2,user3
