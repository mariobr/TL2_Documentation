# Poor Man's Auto-Unseal for HashiCorp Vault in Docker

This guide explains how to set up a simple automatic unseal mechanism
for HashiCorp Vault running in Docker **without** using a cloud KMS or
another Vault instance.

> ⚠️ **Warning:**\
> This method is less secure because the unseal key must be stored
> somewhere accessible. Use only for development or non-production
> environments.

------------------------------------------------------------------------

## 0. PreReq (WSL)

```bash
sudo chown -R $USER:$USER /path/to/dir
sudo chmod -R 755 /path/to/dir   # or 777 if you just want dev access
sudo chown -R 100:100 /path/to/data
```


## 1. Vault Configuration

Create a file named `vault.hcl`:

``` hcl
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

storage "file" {
  path = "/vault/data"
}

ui = true
```

------------------------------------------------------------------------

## 2. Start Vault for Initialization

Run Vault in Docker:

``` bash
docker run --name vault   -p 8200:8200   -e VAULT_ADDR=http://127.0.0.1:8200   -v $(pwd)/vault.hcl:/vault/config/vault.hcl   -v $(pwd)/data:/vault/data   -d hashicorp/vault server
```

Initialize Vault:

``` bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -key-shares=1 -key-threshold=1 > init-output.txt
```

Extract the **Unseal Key 1** and store it somewhere safe --- e.g., in
`unseal-key.txt` or a Docker secret.

------------------------------------------------------------------------

## 3. Auto-Unseal Script

Create `unseal.sh`:

``` sh
#!/usr/bin/env sh
set -e

vault server -config=/vault/config/vault.hcl &
VAULT_PID=$!

echo "Waiting for Vault to start..."
until curl -s http://127.0.0.1:8200/v1/sys/health >/dev/null 2>&1; do
  sleep 1
done

if [ -n "$VAULT_UNSEAL_KEY" ]; then
  echo "Unsealing Vault..."
  vault operator unseal "$VAULT_UNSEAL_KEY"
else
  echo "ERROR: VAULT_UNSEAL_KEY not set"
  kill $VAULT_PID
  exit 1
fi

wait $VAULT_PID
```

Make it executable:

``` bash
chmod +x unseal.sh
```

------------------------------------------------------------------------

## 4. Dockerfile

Create a Dockerfile:

``` dockerfile
FROM hashicorp/vault:latest

COPY vault.hcl /vault/config/vault.hcl
COPY unseal.sh /usr/local/bin/unseal.sh

ENTRYPOINT ["/usr/local/bin/unseal.sh"]
```

Build and run:

``` bash
docker build -t my-vault-auto-unseal .

docker run --name vault   -p 8200:8200   -e VAULT_ADDR=http://127.0.0.1:8200   -e VAULT_UNSEAL_KEY="PUT_YOUR_UNSEAL_KEY_HERE"   -v $(pwd)/data:/vault/data   my-vault-auto-unseal
```

Vault will start and unseal itself automatically using the provided key.

------------------------------------------------------------------------

## Notes

-   For better security, pass the unseal key via **Docker secrets** or
    environment variables encrypted by your runtime.
-   This setup works well for development machines, CI pipelines, or
    demos.
