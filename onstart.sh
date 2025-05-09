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
echo "PUBLIC_IPADDR received: $PUBLIC_IPADDR"

# Assign the VAST_... port values to the NEKO_... specific environment variables.
# The 'export' command makes these variables available to subsequent processes,
# including the supervisord process we will 'exec' later.
export NEKO_WEBRTC_UDPMUX="$VAST_UDP_PORT_70000"
export NEKO_WEBRTC_TCPMUX="$VAST_TCP_PORT_70001"
export NEKO_NAT1TO1="$PUBLIC_IPADDR"


echo "NEKO_WEBRTC_UDPMUX set to: $NEKO_WEBRTC_UDPMUX"
echo "NEKO_WEBRTC_TCPMUX set to: $NEKO_WEBRTC_TCPMUX"
echo "PUBLIC_IPADDR set to: $PUBLIC_IPADDR"


# For debugging, you can uncomment the next line to see all environment variables
# echo "Current environment variables:"
# env
# echo "---"

# The "$@" variable contains all the arguments passed to this script.
# In Docker, if an ENTRYPOINT is defined, the CMD (either from the Dockerfile
# or overridden at runtime) is passed as arguments to the ENTRYPOINT.
# The original CMD for ghcr.io/m1k1o/neko/nvidia-firefox was:
# ["/usr/bin/supervisord", "-c", "/etc/neko/supervisord.conf"]
# So, "$@" will expand to: "/usr/bin/supervisord" "-c" "/etc/neko/supervisord.conf"

echo "Executing command: $@"
# 'exec' replaces the current shell process with the command that follows.
# This is important so that supervisord becomes the main process (PID 1 if possible)
# and receives signals correctly from Docker.
exec "$@"

echo "--- Startup Script (onstart.sh) Finished (should not be reached if exec succeeds) ---"
