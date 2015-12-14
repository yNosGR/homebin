#!/bin/bash
for i in ` knife search chef_environment:$1 | grep FQDN| awk '{print $2}' ` ; do 
	revip=`nslookup $i | tail -2| grep . | awk '{print $2}'` ;
	ssh-keygen -R $revip 
	ssh-keygen -R $i
done

