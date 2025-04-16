#!/bin/bash
PATH="app-test"
ROLE_NAME="app-test-role"
APP_SA="app-test"
APP_NS="app-test"
POLICY="app-test-policy"

echo "vault write auth/$PATH/role/$ROLE_NAME bound_service_account_names=$APP_SA bound_service_account_namespaces=$APP_NS policies=$POLICY ttl=24h"