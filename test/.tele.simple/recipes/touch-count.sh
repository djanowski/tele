touch /tmp/tele/touch-count
echo $(($(cat /tmp/tele/touch-count) + 1)) > /tmp/tele/touch-count
