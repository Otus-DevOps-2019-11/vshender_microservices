#!/bin/bash

function get_gcp_host_ips {
    echo $(cd ../terraform && terraform show -json | jq ".values.outputs.app_instance_ips.value")
}

case "$1" in
"--list")
    cat<<EOF
{
  "app": {
    "hosts": $(get_gcp_host_ips)
  }
}
EOF
    ;;

"--host")
    cat<<EOF
{
  "_meta": {
    "hostvars": {}
  }
}
EOF
    ;;

*)
    echo "{}"
    ;;
esac
