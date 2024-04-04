#!/bin/bash

set -ux

rm kubeconfig

gcloud container clusters delete $CLUSTER_NAME --async