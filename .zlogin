# .zlogin – Classy and informative welcome (24h format)

WIDTH=77
datetime=$(date '+%A, %d %B %Y – %H:%M:%S')
hostname=$(hostname)

# Get IP address: try hostname -I for Linux, fallback to ipconfig/ifconfig for macOS
if [[ $(uname) == "Linux" ]]; then
  ip=$(hostname -I 2>/dev/null | awk '{print $1}')
elif [[ $(uname) == "Darwin" ]]; then
  ip=$(ipconfig getifaddr en0 2>/dev/null || ifconfig en0 | grep 'inet ' | awk '{print $2}' | head -n 1)
else
  ip="unknown"
fi
[[ -z "$ip" ]] && ip="none"

# Handle uptime differently for Linux and macOS
if [[ $(uname) == "Linux" ]]; then
  uptime=$(uptime -p 2>/dev/null || echo "uptime not available")
elif [[ $(uname) == "Darwin" ]]; then
  # macOS uptime parsing
  uptime=$(uptime | awk '{print $3 " " $4 " " $5}' | sed 's/,//')
else
  uptime="uptime not available"
fi

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
