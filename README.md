# hashicorp-vault-integrate-k8s
HashiCorp Vault integrate K8S via Vault Agent Injector

### Create policy
```
root@vault-1:~/app-test# vault policy write app-test-policy ./policy/app-test-policy.hcl
Success! Uploaded policy: app-test-policy
```

```
root@vault-1:~/app-test# vault policy read app-test-policy
path "secret/data/app-test/*" {
  capabilities = ["read","list"]
}
```

### Enable the Kubernetes authentication method
>[!TIP] Replace "path" with name preferred option
```
root@vault-1:~/app-test# vault auth enable -path=app-test kubernetes
Success! Enabled kubernetes auth method at: app-test/
```

### Deploy Vault Agent Injector in K8S (Deploy with Helm)
```
# kubectl create ns vault-injector

# helm install vault hashicorp/vault --namespace vault-injector\
    --set "global.externalVaultAddr=http://vault-1.vault.local:8200"

NAME: vault
LAST DEPLOYED: Wed Apr 16 16:15:18 2025
NAMESPACE: vault-injector
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://developer.hashicorp.com/vault/docs


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get manifest vault 
```

```
# kubectl config set-context --current --namespace vault-injector

# kubectl apply -f vault-sa-secret.yaml
secret/vault-token-agent created
```

### Apply kubernetes authentication method
**Run script to generate vault command**
```
# ./generate_k8s_auth.sh

vault write auth/app-test/config token_reviewer_jwt="XXXXX" kubernetes_host="https://172.31.38.98:6443" kubernetes_ca_cert="YYYYYYY"
```
**Copy output return from script and apply to vault server**
```
root@vault-1:~# vault write auth/app-test/config token_reviewer_jwt="XXXXX" kubernetes_host="https://172.31.38.98:6443" kubernetes_ca_cert="YYYYYYY"

Success! Data written to: auth/app-test/config
```

### Create a Kubernetes authentication role
**Create Namespace & Service Account bound with Role
```
# kubectl create ns app-test

# kubectl create sa app-test -n app-test
```

**Generate vault create role command**
```
# ./generate_create_role_command.sh
vault write auth/app-test/role/app-test-role bound_service_account_names=app-test bound_service_account_namespaces=app-test policies=app-test-policy ttl=24h
```

**Copy output return from script and apply to vault server**
```
root@vault-1:~# vault write auth/app-test/role/app-test-role bound_service_account_names=app-test bound_service_account_namespaces=app-test policies=app-test-policy ttl=24h
Success! Data written to: auth/app-test/role/app-test-role
```