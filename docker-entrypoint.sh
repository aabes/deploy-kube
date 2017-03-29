#!/bin/bash
set -e

#AWS_PROFILE
#export KOPS_STATE_STORE=s3://clusters.dev.example.com

# deal with time drift
hwclock -s

exec "$@"
