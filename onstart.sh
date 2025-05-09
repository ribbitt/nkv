#!/bin/sh
# onstart.sh
# This script is intended to be used as the ENTRYPOINT for the Docker image.
# It sets up environment variables and then executes the image's CMD.

# Exit immediately if a command exits with a non-zero status.
set -e

# These VAST_... environment variables are expected to be set in the container's
# environment by Vast.ai (e.g., via --env VAST_UDP_PORT_70000=12345).
echo "--- Startup Script (onstart.sh) Starting ---"
echo "VAST_UDP_PORT_70000 received: $VAST_UDP_PORT_70000"
echo "VAST_TCP_PORT_70001 received: $VAST_TCP_PORT_70001"

# Assign the VAST_... port values to the NEKO_... specific environment variables.
# The 'export' command makes these variables available to subsequent processes,
# including the supervisord process we will 'exec' later.
export NEKO_WEBRTC_UDPMUX="$VAST_UDP_PORT_70000"
export NEKO_WEBRTC_TCPMUX="$VAST_TCP_PORT_70001"

echo "NEKO_WEBRTC_UDPMUX set to: $NEKO_WEBRTC_UDPMUX"
echo "NEKO_WEBRTC_TCPMUX set to: $NEKO_WEBRTC_TCPMUX"

# The "$@" variable contains all the arguments passed to this script.
# In Docker, if an ENTRYPOINT is defined, the CMD (either from the Dockerfile
# or overridden at runtime) is passed as arguments to the ENTRYPOINT.
# The original CMD for ghcr.io/m1k1o/neko/nvidia-firefox was:
# ["/usr/bin/supervisord", "-c", "/etc/neko/supervisord.conf"]
# So, "$@" should expand to: "/usr/bin/supervisord" "-c" "/etc/neko/supervisord.conf"

echo "--- Pre-exec Debugging ---"
echo "Arguments received (\$@): $@"
echo "Number of arguments passed to script (\${#@}): ${#@}" # Displays count of arguments in $@
echo "Argument \$0 (script name itself): $0"
echo "Argument \$1 (intended command for exec): $1"
echo "Argument \$2 (first arg to command): $2"
echo "Argument \$3 (second arg to command): $3"


# Check if $1 (the command to be executed) is empty
if [ -z "$1" ]; then
  echo "ERROR: No command provided to exec (argument \$1 is empty)."
  echo "This means the Docker CMD was likely not passed to this ENTRYPOINT script."
  echo "Exiting to prevent script continuation after failed exec attempt."
  exit 1 # Explicitly exit if no command
fi

# Check if the command in $1 exists and is executable
# 'command -v' checks if the command is found in PATH or if it's a known function/builtin.
if ! command -v "$1" > /dev/null 2>&1; then
    echo "DEBUG: Command '$1' not found using 'command -v'."
    # If $1 is an absolute or relative path, check it directly
    if [ -f "$1" ]; then
        echo "DEBUG: '$1' exists as a file."
        if [ -x "$1" ]; then
            echo "INFO: Command '$1' exists and is executable (checked file path)."
        else
            echo "ERROR: Command '$1' exists but is NOT executable (checked file path)."
            ls -l "$1" # Show permissions and details of the file
            echo "Exiting due to non-executable command."
            exit 1
        fi
    else
        echo "ERROR: Command '$1' does not exist as a file (checked file path) AND was not found in PATH via 'command -v'."
        echo "Current PATH is: $PATH"
        echo "Exiting due to command not found."
        exit 1
    fi
else
    echo "INFO: Command '$1' was found using 'command -v'. Assuming it's executable if found this way."
fi

echo "Attempting to execute command: $@"
# 'exec' replaces the current shell process with the command that follows.
# This is important so that supervisord becomes the main process (PID 1 if possible)
# and receives signals correctly from Docker.
exec "$@"

# If exec fails (e.g., command not found, or permissions error that 'command -v' or '-x' didn't catch),
# the script will continue from here. This line should ideally not be reached.
echo "--- Startup Script (onstart.sh) Finished (ERROR: This line indicates 'exec \"\$@\"' FAILED or the executed command exited immediately) ---"
exit 1 # Exit with an error code if exec "falls through"
