# wraps a command to notify on completion based on a completion message (for commands that run indefinitely)
# Example usage:
# notify_on_complete "yarn start" "Compiled successfully" "deploy_script.sh"

# The first argument is the command
cmd=($1)
# The second argument is the completion indication string
completion_msg="$2"
# The third argument is the callback command to execute upon completion
callback="$3"

{
	# Execute the command
	script -q /dev/null "${cmd[@]}" | while IFS= read -r line; do
		if [[ "$line" == *"$completion_msg"* ]]; then
			eval "$callback"
			clear
		fi
		echo "$line"
	done
} 2>&1

echo "Command has completed."
