echo "" >> res-check-$(date +%F);
echo "--------------------------------------------------------------------------------" >> res-check-$(date +%F);
printf "| %-20s | %-20s | %-30s |\n" "SERVICE NAME" "NAMESPACE" "PORT NAME" >> res-check-$(date +%F)
echo "--------------------------------------------------------------------------------" >> res-check-$(date +%F);
project=$(oc project | awk {'print $3'} | sed 's/"//g')
echo "Checking port name service on project "$project" at $(date)"
svclist=$(oc get svc --no-headers | awk {'print $1'})
for svc in $svclist; do
        for i in $(oc describe svc | grep "^Port:" | sed 's/Port:              //g' | awk '{print $1}'); do
                before=$(oc describe svc $svc -n $project | grep "^Port:" | grep $i | sed 's/Port:              //g')
                printf "| %-20s | %-20s | %-30s |\n" "$svc" "$project" "$before" >> res-check-$(date +%F);
        done;
done;
echo "--------------------------------------------------------------------------------" >> res-check-$(date +%F);
cat res-check-$(date +%F);
