# .zlogout – Professional and clean goodbye (24h format)

WIDTH=77
datetime=$(date '+%A, %d %B %Y – %H:%M:%S')

message="Goodbye Yitzhak | Session ended on $datetime"
farewell="Stay sharp. See you soon."

center() {
  local text="$1"
  [[ ${#text} -gt $((WIDTH - 4)) ]] && text="${text:0:$((WIDTH - 7))}..."
  local pad=$(( (WIDTH - 2 - ${#text}) / 2 ))
  printf "|%*s%s%*s|\n" $pad "" "$text" $((WIDTH - 2 - pad - ${#text})) ""
}

echo "+$(printf '%*s' $((WIDTH - 2)) '' | tr ' ' '-')+"
center "$message"
center "$farewell"
echo "+$(printf '%*s' $((WIDTH - 2)) '' | tr ' ' '-')+"
echo ""

