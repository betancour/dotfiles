# .bash_logout

if [ -d "$HOME/tmp" ]; then
	rm -f "$HOME/tmp"
fi

history -c

cat /dev/null > ~/.bash_history


# Display a goodbye message
echo "+-----------------------------------------------------------------------------+"
echo "| Goodbye Yitzhak!  "Last login: $(date)"                   |"
echo "+-----------------------------------------------------------------------------+"
