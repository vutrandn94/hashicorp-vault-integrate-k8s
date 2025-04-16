#!/bin/bash
VAULT_SA_SECRET="vault-token-agent"
K8S_AUTH_PATH="app-test"

TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_SA_SECRET --output='go-template={{ .data.token }}' | base64 --decode)
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST="https://172.31.38.98:6443"

echo "vault write auth/$K8S_AUTH_PATH/config token_reviewer_jwt=\"$TOKEN_REVIEW_JWT\" kubernetes_host=\"$KUBE_HOST\" kubernetes_ca_cert=\"$KUBE_CA_CERT\"