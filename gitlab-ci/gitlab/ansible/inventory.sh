#!/bin/bash

function get_output_var {
    echo $(cd ../terraform && terraform show -json | jq ".values.outputs.$1.value")
}

case "$1" in
"--list")
    cat<<EOF
{
  "gitlab": {
    "hosts": [
      $(get_output_var gitlab_ip)
    ]
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
