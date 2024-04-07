#!/bin/bash

######## constants and functions ########

# run tmux dedicated server
TMUX="tmux -L dev"

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# args: project path, followed by one or more dependency paths
PROJECT_PATH=$1
shift # Remove PROJECT_PATH from the arguments, leaving only DEP_PATHS
DEP_PATHS=("$@")

PROJECT_LOG="$PROJECT_PATH/src/.track_me"

APP_ROOT=$(dirname $PROJECT_PATH)

######## execution start ########

# initialize the project track_me file
echo 'start' >$PROJECT_LOG

tracked_dirs=()

# Get the JSON array of directory names from the DEP_PATHS + TARGET_PATH
for path in "${DEP_PATHS[@]}"; do
	tracked_dirs+=($(basename $path))
done
tracked_dirs+=($(basename $PROJECT_PATH))
tracked_dirs_json=$(printf '%s\n' "${tracked_dirs[@]}" | jq -R . | jq -s .)

# Start a new tmux session
# $TMUX new-session -d -s dev -n "build"
$TMUX -f $SCRIPT_PATH/tmux.conf new-session -d -s dev -n "build"

# Create a new window for tracking file commands
$TMUX new-window -n "trackers"

for DEP_PATH in "${DEP_PATHS[@]}"; do
	# Track src/TS(X) files
	FILES_TO_TRACK="find $DEP_PATH/src -type f \( -name '*.ts' -o -name '*.tsx' \)"

	# Create a new pane for each DEP_PATH in the "trackers" window, except for the first one
	if [[ $DEP_PATH != "${DEP_PATHS[0]}" ]]; then
		$TMUX split-window -t dev:trackers -h
	fi

	# Initialize the DEP_LOG for the current DEP_PATH
	DEP_LOG="$DEP_PATH/src/.track_me"
	echo 'start' >$DEP_LOG

	DEP_DIR=$(basename $DEP_PATH)

	# Get the list of tracked dependents for the current DEP_PATH
	dependents=$(jq --argjson trackedDirs "$tracked_dirs_json" -r \
		'.[] | select(.location == "'"$DEP_DIR"'") | .dependents[] | select(. as $dep | $trackedDirs | index($dep))' \
		"$APP_ROOT/dep-graph.json")

	# Command to modify the PROJECT_LOG file
	DEPENDENT_LOGS=()

	# Iterate over each dependent and create the DEPENDENT_LOG path
	for path in $dependents; do
		DEPENDENT_LOG="${APP_ROOT}/${path}/src/.track_me"
		if [[ $DEP_LOG != $DEPENDENT_LOG ]]; then
			DEPENDENT_LOGS+="$DEPENDENT_LOG "
		fi
	done

	UPDATE_DEPENDENT_LOGS="echo update | tee -a $DEPENDENT_LOGS > /dev/null"

	# Command to monitor yarn output and update the PROJECT_LOG file on compilation success
	NOTIFY_ON_BUILD="$SCRIPT_PATH/notify-on-complete.sh \"yarn start\" \"Compiled successfully\" \"$UPDATE_DEPENDENT_LOGS\""

	# Command to run monitored `yarn start` in a new pane of the build window
	RUN_YARN_IN_NEW_PANE="tmux split-window -t dev:build -h 'cd $DEP_PATH && $NOTIFY_ON_BUILD' && tmux select-layout -t dev:build tiled"

	# Get the index of the last pane to ensure commands are sent to the correct pane
	LAST_PANE_INDEX=$($TMUX list-panes -t dev:trackers -F '#{pane_index}' | tail -n1)

	# Initialize dependency tracker in the newly created pane
	$TMUX send-keys -t dev:trackers.$LAST_PANE_INDEX "$FILES_TO_TRACK | entr -z -p $RUN_YARN_IN_NEW_PANE && echo $DEP_LOG | entr $NOTIFY_ON_BUILD" C-m

	# Make sure the pane layout is balanced
	$TMUX select-layout -t dev:trackers tiled

done

# Switch back to the build window and start project build
$TMUX select-window -t dev:build

# Track the project track_me file to restart yarn
$TMUX send-keys -t dev:build.0 "cd $PROJECT_PATH && echo $PROJECT_LOG | entr -r yarn start" C-m

# Attach to the tmux session
$TMUX attach -t dev
