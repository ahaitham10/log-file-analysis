#!/bin/bash

LOG_FILE="access.log"

echo "----- LOG FILE ANALYSIS -----"

# 1. Request Counts
echo -e "\n1. Request Counts"
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep -c "GET" "$LOG_FILE")
post_requests=$(grep -c "POST" "$LOG_FILE")
echo "Total requests: $total_requests"
echo "GET requests: $get_requests"
echo "POST requests: $post_requests"

# 2. Unique IP Addresses
echo -e "\n2. Unique IP Addresses"
unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq | wc -l)
echo "Unique IPs: $unique_ips"

echo -e "\nRequests per IP (GET/POST):"
awk '{print $1, $6}' "$LOG_FILE" | grep -E "\"GET|\"POST" | \
awk '{count[$1][$2]++} END {for (ip in count) print ip, "GET:", count[ip]["\"GET"], "POST:", count[ip]["\"POST"]}'

# 3. Failure Requests
echo -e "\n3. Failure Requests"
failures=$(awk '$9 ~ /^[45]/ {count++} END {print count}' "$LOG_FILE")
fail_percent=$(awk -v f="$failures" -v t="$total_requests" 'BEGIN {printf "%.2f", (f/t)*100}')
echo "Failed requests: $failures"
echo "Failure percentage: $fail_percent%"

# 4. Top User (Most Active IP)
echo -e "\n4. Top User"
awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1

# 5. Daily Request Averages
echo -e "\n5. Daily Request Averages"
days=$(awk -F: '{print $1}' "$LOG_FILE" | awk -F'[' '{print $2}' | sort -u | wc -l)
avg_per_day=$(awk -v total="$total_requests" -v days="$days" 'BEGIN {print int(total/days)}')
echo "Average per day: $avg_per_day"

# 6. Days with Most Failures
echo -e "\n6. Failure Requests by Day"
awk '$9 ~ /^[45]/ {split($4, date, ":"); gsub("\\[", "", date[1]); count[date[1]]++}
     END {for (day in count) print day, count[day]}' "$LOG_FILE" | sort -k2 -nr | head

# 7. Requests by Hour
echo -e "\n7. Requests by Hour"
awk -F: '{print $2}' "$LOG_FILE" | sort | uniq -c

# 8. Status Code Breakdown
echo -e "\n8. Status Codes"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr

# 9. Most Active IP by Method
echo -e "\n9. Most Active IP by Method"
for method in "GET" "POST"; do
  echo "$method:"
  grep "$method" "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1
done

# 10. Failure Patterns by Hour
echo -e "\n10. Failure Patterns by Hour"
awk '$9 ~ /^[45]/ {split($4, a, ":"); print a[2]}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -5
