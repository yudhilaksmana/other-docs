echo "" >> res-$(date +%F);
echo "-----------------------------------------------------------------------------------------------------------------" >> res-$(date +%F);
printf "| %-20s | %-20s | %-30s | %-30s |\n" "SERVICE NAME" "NAMESPACE" "BEFORE" "AFTER" >> res-$(date +%F)
echo "-----------------------------------------------------------------------------------------------------------------" >> res-$(date +%F);
oc project;
for i in $(cat list); do
	#NS=$(oc get svc --all-namespaces | awk '{print $1}' | grep "^$i$")
	NS=$(oc project -q)
	oc get svc $i -o yaml -n $NS >> yaml/$i-backup-$NS.yml;
	cat yaml/$i-backup-$NS.yml >> yaml/$i-mod-$NS.yml;
	svcNameBfr=$(cat yaml/$i-backup-$NS.yml | grep "name: [[:digit:]]" | sed 's/  - name: //g' | sed 's/  //g')
	for svc in $svcNameBfr; do
		if [ $(echo $svc | grep -e '[0-9]-[a-z]') ]; then # ex: 8080-tcp to http-8080
			x=$(echo $svc | sed 's/-/ /g' | awk '{print $1}'); #port
			y=$(echo $svc | sed 's/-/ /g' | awk '{print $2}');
		
			before=$(oc describe svc $i -n $NS | grep $x-$y | sed 's/Port:              //g')
			printf "| %-20s | %-20s | %-30s | %-30s |\n" "$i" "$NS" "$before" "after-http-$x" >> res-$(date +%F);
			sed -i "s/  - name: $x-$y/  - name: http-$x/g" yaml/$i-mod-$NS.yml;		
		elif [ $(echo $svc | grep -e '[a-z]-[0-9]') ]; then # ex: tcp-8080 to http-8080
			x=$(echo $svc | sed 's/-/ /g' | awk '{print $1}');
			y=$(echo $svc | sed 's/-/ /g' | awk '{print $2}'); #port
		
			before=$(oc describe svc $i -n $NS | grep $x-$y | sed 's/Port:              //g')
			printf "| %-20s | %-20s | %-30s | %-30s |\n" "$i" "$NS" "$before" "after-http-$y" >> res-$(date +%F);
			sed -i "s/  - name: $x-$y/  - name: http-$y/g" yaml/$i-mod-$NS.yml;
		fi
	done;

	oc apply -f yaml/$i-mod-$NS.yml;
	
	for svc in $(oc describe svc | grep "^Port:" | sed 's/Port:              //g' | awk '{print $1}'); do
		after=$(oc describe svc $i -n $NS | grep "^Port:" | grep $svc | sed 's/Port:              //g')
		sed -i "s@after-$svc@$after@g" res-$(date +%F)
	done
	
done;
echo "-----------------------------------------------------------------------------------------------------------------" >> res-$(date +%F);
cat res-$(date +%F)
