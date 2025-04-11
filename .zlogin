# .zlogin – Classy and informative welcome (24h format)

WIDTH=77
datetime=$(date '+%A, %d %B %Y – %H:%M:%S')
hostname=$(hostname)
ip=$(hostname -I 2>/dev/null | awk '{print $1}')
uptime=$(uptime -p)

message="Welcome Yitzhak | $datetime"
hostinfo="Host: $hostname | IP: $ip | $uptime"

center() {
  local text="$1"
  [[ ${#text} -gt $((WIDTH - 4)) ]] && text="${text:0:$((WIDTH - 7))}..."
  local pad=$(( (WIDTH - 2 - ${#text}) / 2 ))
  printf "|%*s%s%*s|\n" $pad "" "$text" $((WIDTH - 2 - pad - ${#text})) ""
}

echo "+$(printf '%*s' $((WIDTH - 2)) '' | tr ' ' '-')+"
center "$message"
center "$hostinfo"
echo "+$(printf '%*s' $((WIDTH - 2)) '' | tr ' ' '-')+"
echo ""

