# TPM Access in Docker and Kubernetes

## Overview
This document explains how to access TPM (Trusted Platform Module) devices from containerized applications running in Docker and Kubernetes environments.

## TPM Devices on Linux

Modern Linux systems expose TPM through character devices:
- `/dev/tpm0` - TPM device (direct access)
- `/dev/tpmrm0` - TPM Resource Manager (preferred, allows concurrent access)

### Check TPM Availability
```bash
# Check if TPM devices exist
ls -la /dev/tpm*

# Check TPM group
getent group tss

# Test TPM with tools
tpm2_getcap properties-fixed
```

## Docker Configuration

### Method 1: Docker Run Command
```bash
docker run -d \
  --name tl-service \
  --device=/dev/tpm0:/dev/tpm0 \
  --device=/dev/tpmrm0:/dev/tpmrm0 \
  --group-add tss \
  your-trustedlicensing-image
```

### Method 2: Docker Compose
```yaml
version: '3.8'

services:
  tl-license-manager:
    image: trustedlicensing:latest
    container_name: tl-service
    devices:
      - /dev/tpm0:/dev/tpm0
      - /dev/tpmrm0:/dev/tpmrm0
    group_add:
      - tss  # Add TPM Software Stack group (usually GID 113)
    ports:
      - "52014:52014"
    volumes:
      - tl-data:/app/data
    restart: unless-stopped

volumes:
  tl-data:
```

### Dockerfile Configuration
```dockerfile
FROM ubuntu:24.04

# Install TPM tools and dependencies
RUN apt-get update && apt-get install -y \
    tpm2-tools \
    libtss2-dev \
    libtss2-esys-3.0.2-0 \
    libtss2-tcti-device0 \
    && rm -rf /var/lib/apt/lists/*

# Add tss group with correct GID (match host GID, usually 113)
RUN groupadd -g 113 tss || true

# Add application user to tss group
RUN useradd -m -u 1000 appuser && \
    usermod -aG tss appuser

# Copy application files
COPY container_app/ /app/
WORKDIR /app

USER appuser
CMD ["./TLLicenseManager"]
```

## Kubernetes Configuration

### Method 1: Basic HostPath Volumes
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tl-license-manager
  labels:
    app: tl-service
spec:
  containers:
  - name: tl-app
    image: trustedlicensing:latest
    securityContext:
      # Add tss group (check GID with: getent group tss)
      supplementalGroups: [113]
      capabilities:
        add: ["IPC_LOCK"]
    volumeMounts:
    - name: tpm0
      mountPath: /dev/tpm0
    - name: tpmrm0
      mountPath: /dev/tpmrm0
    ports:
    - containerPort: 52014
      name: license-svc
  volumes:
  - name: tpm0
    hostPath:
      path: /dev/tpm0
      type: CharDevice
  - name: tpmrm0
    hostPath:
      path: /dev/tpmrm0
      type: CharDevice
  nodeSelector:
    # Ensure pod runs only on TPM-enabled nodes
    tpm-enabled: "true"
  # Optional: Use toleration if TPM nodes are tainted
  tolerations:
  - key: "tpm-required"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

### Method 2: Deployment with NodeSelector
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tl-license-manager
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tl-service
  template:
    metadata:
      labels:
        app: tl-service
    spec:
      containers:
      - name: tl-app
        image: trustedlicensing:latest
        securityContext:
          supplementalGroups: [113]  # tss group
        volumeMounts:
        - name: tpm0
          mountPath: /dev/tpm0
        - name: tpmrm0
          mountPath: /dev/tpmrm0
        resources:
          limits:
            memory: "512Mi"
            cpu: "500m"
          requests:
            memory: "256Mi"
            cpu: "250m"
      volumes:
      - name: tpm0
        hostPath:
          path: /dev/tpm0
          type: CharDevice
      - name: tpmrm0
        hostPath:
          path: /dev/tpmrm0
          type: CharDevice
      nodeSelector:
        tpm-enabled: "true"
```

### Method 3: Using Device Plugins (Production Recommended)

#### Install Intel Device Plugin for TPM
```bash
# Install using kustomize
kubectl apply -k https://github.com/intel/intel-device-plugins-for-kubernetes/deployments/tpm_plugin/overlays/nfd_labeled_nodes

# Or using Helm
helm repo add intel https://intel.github.io/helm-charts/
helm install tpm-plugin intel/intel-device-plugins-tpm
```

#### Pod Specification with Device Plugin
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tl-license-manager
spec:
  containers:
  - name: tl-app
    image: trustedlicensing:latest
    resources:
      limits:
        tpm.intel.com/tpm: 1
      requests:
        tpm.intel.com/tpm: 1
```

### Label Nodes with TPM
```bash
# Label nodes that have TPM hardware
kubectl label nodes <node-name> tpm-enabled=true

# Verify labels
kubectl get nodes -L tpm-enabled

# Optionally taint TPM nodes for dedicated use
kubectl taint nodes <node-name> tpm-required=true:NoSchedule
```

## Security Considerations

### TPM Access Control
- **Group Membership**: Container processes need `tss` group membership
- **Device Permissions**: `/dev/tpm0` requires proper permissions (usually `crw-rw----`)
- **Resource Manager**: Use `/dev/tpmrm0` for concurrent access instead of `/dev/tpm0`

### Docker Security
```yaml
services:
  tl-service:
    devices:
      - /dev/tpmrm0:/dev/tpmrm0
    group_add:
      - tss
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

### Kubernetes Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  supplementalGroups: [113]  # tss group
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
    add:
      - IPC_LOCK  # Only if needed for TPM operations
  readOnlyRootFilesystem: true
```

### Pod Security Policy (deprecated) / Pod Security Standards
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: tpm-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  volumes:
    - 'hostPath'
    - 'configMap'
    - 'secret'
  allowedHostPaths:
    - pathPrefix: "/dev/tpm0"
      readOnly: false
    - pathPrefix: "/dev/tpmrm0"
      readOnly: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      - min: 113
        max: 113
  fsGroup:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
```

## Testing TPM Access

### From Docker Container
```bash
# Run interactive container with TPM
docker run -it --rm \
  --device=/dev/tpm0 \
  --device=/dev/tpmrm0 \
  --group-add tss \
  ubuntu:24.04 bash

# Inside container - test TPM access
apt-get update && apt-get install -y tpm2-tools
tpm2_getcap properties-fixed
tpm2_getrandom 32 --hex
```

### From Kubernetes Pod
```bash
# Create test pod
kubectl run tpm-test --rm -it --restart=Never \
  --image=ubuntu:24.04 \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "tpm-test",
      "image": "ubuntu:24.04",
      "command": ["/bin/bash"],
      "stdin": true,
      "tty": true,
      "securityContext": {
        "supplementalGroups": [113]
      },
      "volumeMounts": [{
        "name": "tpm0",
        "mountPath": "/dev/tpm0"
      }, {
        "name": "tpmrm0",
        "mountPath": "/dev/tpmrm0"
      }]
    }],
    "volumes": [{
      "name": "tpm0",
      "hostPath": {
        "path": "/dev/tpm0",
        "type": "CharDevice"
      }
    }, {
      "name": "tpmrm0",
      "hostPath": {
        "path": "/dev/tpmrm0",
        "type": "CharDevice"
      }
    }],
    "nodeSelector": {
      "tpm-enabled": "true"
    }
  }
}'

# Inside pod - test TPM
apt-get update && apt-get install -y tpm2-tools
ls -la /dev/tpm*
tpm2_getcap properties-fixed
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
# Check device permissions on host
ls -la /dev/tpm*

# Verify tss group GID matches
getent group tss

# Check container has correct group
docker exec <container> id

# Ensure group_add or supplementalGroups is set correctly
```

#### 2. Device Not Found
```bash
# Verify TPM exists on host
ls /dev/tpm*

# Check kernel modules
lsmod | grep tpm

# Load TPM modules if needed
sudo modprobe tpm_tis
sudo modprobe tpm_crb
```

#### 3. Resource Busy
```bash
# Check what's using TPM
lsof /dev/tpm*

# Use /dev/tpmrm0 instead of /dev/tpm0 for concurrent access

# Kill processes holding exclusive access
sudo fuser -k /dev/tpm0
```

#### 4. Kubernetes Scheduling Issues
```bash
# Check node labels
kubectl get nodes -L tpm-enabled

# Verify pod events
kubectl describe pod <pod-name>

# Check if devices are available on node
kubectl debug node/<node-name> -it --image=ubuntu
```

### Verification Commands

```bash
# Check TPM version
cat /sys/class/tpm/tpm0/tpm_version_major

# Test TPM communication
tpm2_getcap properties-fixed

# Check TPM ownership
tpm2_getcap handles-persistent

# Verify PCR banks
tpm2_pcrread
```

## Best Practices

1. **Use TPM Resource Manager** (`/dev/tpmrm0`) for concurrent access
2. **Run as non-root** with supplemental group membership
3. **Label TPM-enabled nodes** in Kubernetes
4. **Use device plugins** in production for better resource management
5. **Implement health checks** that verify TPM availability
6. **Monitor TPM usage** and track cryptographic operations
7. **Backup TPM sealed data** using proper key migration
8. **Test failover** scenarios when TPM is unavailable
9. **Document TPM requirements** in deployment guides
10. **Use TPM 2.0** features (hierarchies, policy-based authorization)

## References

- [TPM 2.0 Tools](https://github.com/tpm2-software/tpm2-tools)
- [Intel Device Plugins for Kubernetes](https://github.com/intel/intel-device-plugins-for-kubernetes)
- [Kubernetes Device Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/)
- [Docker Device Mapping](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)
- [TPM 2.0 Specification](https://trustedcomputinggroup.org/resource/tpm-library-specification/)

## TrustedLicensing Specific Notes

### Project Structure
```
TL2/
├── TLTpm/              # TPM implementation
├── _Container/
│   └── Docker/
│       ├── Dockerfile
│       └── entrypoint.sh
└── TLLicenseManager/   # Service that uses TPM
```

### Build with TPM Support
```bash
# Configure CMake with TPM enabled
cmake -DTPM_ON=ON -B build

# Build
cmake --build build

# Copy artifacts to container staging
cp build/TLLicenseManager _Container/Docker/container_app/
```

### Container Deployment
```bash
# Build image
cd _Container/Docker
docker build -t trustedlicensing:latest .

# Run with TPM
docker run -d \
  --name tl-service \
  --device=/dev/tpm0 \
  --device=/dev/tpmrm0 \
  --group-add tss \
  -p 52014:52014 \
  trustedlicensing:latest
```
