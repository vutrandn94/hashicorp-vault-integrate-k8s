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
### Test Deployment
**Put secret test**
```
root@vault-1:~# vault kv put secret/app-test/app-test DB_USER="username" DB_PASSWORD="password" DB_NAME="test-vault-db" MSG="This is secret get from vault."
======== Secret Path ========
secret/data/app-test/app-test

======= Metadata =======
Key                Value
---                -----
created_time       2025-04-16T09:55:13.927426817Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
```
**Schedule application and mount service account similar info Kubernetes authentication role**
```
# kubectl apply -f ./k8s-deployment/deployment.yaml

# kubectl get all -n app-test -o wide
NAME                                         READY   STATUS    RESTARTS   AGE   IP             NODE           NOMINATED NODE   READINESS GATES
pod/test-vault-changepath-78b8f6599b-df54k   2/2     Running   0          47s   10.42.69.239   k8s-worker02   <none>           <none>

NAME                                    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS              IMAGES   SELECTOR
deployment.apps/test-vault-changepath   1/1     1            1           47s   test-vault-changepath   nginx    app=test-vault-changepath

NAME                                               DESIRED   CURRENT   READY   AGE   CONTAINERS              IMAGES   SELECTOR
replicaset.apps/test-vault-changepath-78b8f6599b   1         1         1       47s   test-vault-changepath   nginx    app=test-vault-changepath,pod-template-hash=78b8f6599b
```
**Verify secret mounted to Pod**
```
# kubectl exec -it pod/test-vault-changepath-78b8f6599b-df54k -n app-test  -- cat /vault/secrets/config.py
Defaulted container "test-vault-changepath" out of: test-vault-changepath, vault-agent, vault-agent-init (init)
DB_USERNAME="test-vault-db"
DB_PASSWORD="password"
DB_NAME="test-vault-db"
MSG="This is secret get from vault."
```