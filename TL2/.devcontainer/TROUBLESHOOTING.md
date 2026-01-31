# Devcontainer Troubleshooting

If you're experiencing issues opening the devcontainer, try these solutions:

## Solution 1: Use Simple Configuration (Recommended if docker-compose fails)

1. Rename current `devcontainer.json` to `devcontainer.compose.json`:
   ```bash
   cd /DEV/TrustedLicensing2/TL2/.devcontainer
   mv devcontainer.json devcontainer.compose.json
   ```

2. Rename the simple version:
   ```bash
   mv devcontainer.simple.json devcontainer.json
   ```

3. Rebuild the container in VS Code:
   - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
   - Select "Dev Containers: Rebuild Container"

## Solution 2: Check Docker Compose Version

The error might be due to Docker Compose version. Check your version:

```bash
docker compose version
```

If you're using an older version (docker-compose with hyphen), update the devcontainer.json:

```json
"dockerComposeFile": ["docker-compose.yml"],
```

## Solution 3: Remove Build Args

Edit `docker-compose.yml` and remove the args section:

```yaml
build: 
  context: .
  dockerfile: Dockerfile
  # Remove these lines:
  # args:
  #   USER_UID: 1000
  #   USER_GID: 1000
```

## Solution 4: Rebuild Without Cache

From your host terminal:

```bash
cd /DEV/TrustedLicensing2/TL2/.devcontainer
docker compose build --no-cache
```

Then try opening in VS Code again.

## Solution 5: Check Docker Socket Permissions

Ensure Docker socket is accessible:

```bash
ls -la /var/run/docker.sock
sudo chmod 666 /var/run/docker.sock
```

## Solution 6: Clean Docker State

If all else fails, clean Docker state:

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove devcontainer images
docker images | grep devcontainer | awk '{print $3}' | xargs docker rmi -f

# Prune everything
docker system prune -af --volumes
```

Then rebuild the container in VS Code.

## Solution 7: Use Dockerfile Only (No Docker Compose)

If docker-compose continues to fail, create this minimal `devcontainer.json`:

```json
{
	"name": "TrustedLicensing2 Dev",
	"build": {
		"dockerfile": "Dockerfile"
	},
	"workspaceFolder": "/workspaces/TL2",
	"workspaceMount": "source=${localWorkspaceFolder},target=/workspaces/TL2,type=bind",
	"mounts": [
		"source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
	],
	"remoteUser": "vscode"
}
```

## Checking Logs

View detailed logs:

1. Open Command Palette (`Ctrl+Shift+P`)
2. Select "Dev Containers: Show Container Log"

Or check from terminal:
```bash
docker logs <container-id>
```

## Common Issues

### "Cannot read properties of undefined"
- Usually caused by malformed JSON or incompatible docker-compose syntax
- Try the simple configuration (Solution 1)

### TPM Device Not Found
- TPM devices are optional and commented out by default
- No action needed unless you specifically need TPM hardware access

### Permission Denied on Docker Socket
- Run: `sudo chmod 666 /var/run/docker.sock`
- Or add your user to docker group: `sudo usermod -aG docker $USER`

### vcpkg Install Fails
- This is non-critical during container creation
- You can manually run `vcpkg install` after container starts

## Getting Help

If issues persist:
1. Check the container log for specific errors
2. Verify Docker is running: `docker ps`
3. Test Dockerfile builds manually: `docker build -t test .`
4. Check VS Code Remote-Containers extension version (should be 0.300+)
