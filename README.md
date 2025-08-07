# OpenAPI Servers Helm Chart

Kubernetes Helm chart for deploying OpenAPI server tools from the [open-webui/openapi-servers](https://github.com/open-webui/openapi-servers) repository.

## 🚀 Quick Start

### Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Container images built by [openapi-servers-builder](https://github.com/euh2/openapi-servers-builder)

### Install the Chart

```bash
# Add the repository (if published to a Helm repo)
helm repo add openapi-servers https://euh2.github.io/openapi-servers
helm repo update

# Install with default values
helm install my-api-tools openapi-servers/openapi-servers

# Or install from local directory
helm install my-api-tools ./charts/openapi-servers
```

## 📦 Available Tools

The chart can deploy the following OpenAPI server tools:

| Tool | Description | Default Port | Persistence |
|------|-------------|--------------|-------------|
| **filesystem** | File system operations with security controls | 8000 | Optional |
| **weather** | Weather information and forecasting | 8000 | No |
| **memory** | Memory and knowledge graph management | 8000 | Yes |
| **slack** | Slack integration and bot operations | 8000 | No |
| **time** | Date/time utilities and timezone handling | 8000 | No |
| **get-user-info** | User profile information retrieval | 8000 | No |

## ⚙️ Configuration

### Basic Configuration

```yaml
# values.yaml
global:
  registry: ghcr.io
  repository: euh2  # Your GitHub username
  tag: "latest"

# Enable/disable specific tools
tools:
  filesystem:
    enabled: true
  weather:
    enabled: true
  memory:
    enabled: false
  slack:
    enabled: false
```

### Environment-Specific Deployments

#### Development

```bash
helm install api-dev ./charts/openapi-servers -f environments/dev-values.yaml
```

#### Staging

```bash
helm install api-staging ./charts/openapi-servers -f environments/staging-values.yaml
```

#### Production

```bash
helm install api-prod ./charts/openapi-servers -f environments/prod-values.yaml
```

### Tool-Specific Configuration

#### Filesystem Tool

```yaml
tools:
  filesystem:
    enabled: true
    env:
      - name: ALLOWED_PATHS
        value: "/data,/tmp"
      - name: MAX_FILE_SIZE
        value: "52428800"  # 50MB
    
    # Persistent storage
    persistence:
      enabled: true
      storageClass: "fast-ssd"
      size: "10Gi"
    
    # Volume mounts
    volumeMounts:
      - name: data-volume
        mountPath: /data
```

#### Weather Tool

```yaml
tools:
  weather:
    enabled: true
    env:
      - name: WEATHER_API_KEY
        valueFrom:
          secretKeyRef:
            name: weather-secrets
            key: api-key
```

#### Memory Tool

```yaml
tools:
  memory:
    enabled: true
    persistence:
      enabled: true
      size: "5Gi"
    env:
      - name: MEMORY_BACKEND
        value: "file"
```

### Ingress Configuration

#### Individual Tool Ingress

```yaml
tools:
  filesystem:
    ingress:
      enabled: true
      className: "nginx"
      host: api.example.com
      path: /filesystem
      tls:
        - secretName: api-tls
          hosts:
            - api.example.com
```

#### Global Ingress (Recommended)

```yaml
globalIngress:
  enabled: true
  className: "nginx"
  host: api.example.com
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    enabled: true
    secretName: api-tls
```

## 🔐 Security Configuration

### Secrets Management

Create secrets for tools that need API keys:

```bash
# Weather API key
kubectl create secret generic weather-secrets \
  --from-literal=api-key="your-weather-api-key"

# Slack credentials
kubectl create secret generic slack-secrets \
  --from-literal=bot-token="xoxb-your-token" \
  --from-literal=signing-secret="your-signing-secret"
```

### Security Contexts

```yaml
# Production security settings
podSecurityContext:
  fsGroup: 2000
  runAsNonRoot: true
  runAsUser: 1000

securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
```

## 🔄 High Availability

### Multiple Replicas

```yaml
tools:
  filesystem:
    replicas: 3
    resources:
      requests:
        cpu: 200m
        memory: 256Mi
      limits:
        cpu: 1000m
        memory: 512Mi
```

### Pod Disruption Budget

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 50%
```

### Auto-scaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## 📊 Monitoring

### Prometheus ServiceMonitor

```yaml
serviceMonitor:
  enabled: true
  namespace: monitoring
  interval: 30s
  path: /metrics
```

### Health Checks

```yaml
tools:
  filesystem:
    healthCheck:
      path: "/health"
      initialDelaySeconds: 30
      periodSeconds: 10
```

## 🌐 Access Patterns

### Local Development (Port Forwarding)

```bash
# Forward individual tools
kubectl port-forward service/my-api-tools-filesystem 8001:8000
kubectl port-forward service/my-api-tools-weather 8002:8000

# Access tools
curl http://localhost:8001/docs  # Filesystem tool OpenAPI docs
curl http://localhost:8002/docs  # Weather tool OpenAPI docs
```

### Ingress Access

With global ingress enabled:

```bash
# Access via ingress paths
curl https://api.example.com/filesystem/docs
curl https://api.example.com/weather/current?city=Oslo
curl https://api.example.com/time/current
```

### Service Discovery

```bash
# Within cluster
curl http://my-api-tools-filesystem:8000/docs
curl http://my-api-tools-weather:8000/docs
```

## 🚀 Deployment Examples

### Minimal Development Setup

```bash
helm install dev-api ./charts/openapi-servers \
  --set tools.filesystem.enabled=true \
  --set tools.time.enabled=true \
  --set tools.weather.enabled=false
```

### Full Production Setup

```bash
helm install prod-api ./charts/openapi-servers \
  -f environments/prod-values.yaml \
  --set global.tag="v1.0.0" \
  --set globalIngress.host="api.yourcompany.com"
```

### Staging with Custom Configuration

```bash
helm install staging-api ./charts/openapi-servers \
  -f environments/staging-values.yaml \
  --set-file tools.filesystem.config=./custom-filesystem-config.yaml
```

## 🛠️ Maintenance

### Upgrading

```bash
# Update to latest images
helm upgrade my-api-tools ./charts/openapi-servers \
  --set global.tag="latest"

# Upgrade with new configuration
helm upgrade my-api-tools ./charts/openapi-servers \
  -f environments/prod-values.yaml
```

### Rollback

```bash
# Rollback to previous release
helm rollback my-api-tools 1
```

### Uninstall

```bash
# Remove the release
helm uninstall my-api-tools

# Clean up PVCs (if not using reclaim policy)
kubectl delete pvc -l app.kubernetes.io/instance=my-api-tools
```

## 🔧 Customization

### Custom Values Files

Create environment-specific value files:

```yaml
# custom-values.yaml
global:
  repository: your-registry/your-namespace

tools:
  # Only enable tools you need
  filesystem:
    enabled: true
    replicas: 2
  
  weather:
    enabled: false
    
  # Add custom environment variables
  memory:
    enabled: true
    env:
      - name: CUSTOM_CONFIG
        value: "production-mode"
```

### Adding New Tools

When new tools are added to the upstream repository:

1. **Images are automatically built** by the builder repository
2. **Add tool configuration** to `values.yaml`:

```yaml
tools:
  your-new-tool:
    enabled: false
    image:
      repository: openapi-servers-your-new-tool
      tag: ""
    service:
      port: 8000
      targetPort: 8000
    env: []
```

3. **Update environment files** as needed

## 📋 Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=my-api-tools

# Check pod logs
kubectl logs -l app.kubernetes.io/instance=my-api-tools -c filesystem

# Describe pod for events
kubectl describe pod <pod-name>
```

#### Image Pull Errors

```bash
# Check if images exist
docker pull ghcr.io/euh2/openapi-servers-filesystem:latest

# Verify image pull secrets
kubectl get secrets
kubectl describe secret ghcr-secret
```

#### Service Discovery Issues

```bash
# Check services
kubectl get services -l app.kubernetes.io/instance=my-api-tools

# Test internal connectivity
kubectl run debug --image=busybox --rm -it -- wget -qO- http://my-api-tools-filesystem:8000/health
```

#### Ingress Not Working

```bash
# Check ingress
kubectl get ingress
kubectl describe ingress my-api-tools-global

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Getting Help

- **Chart Issues**: Open an issue in this repository
- **Tool Issues**: Check the [upstream repository](https://github.com/open-webui/openapi-servers)
- **Image Issues**: Check the [builder repository](https://github.com/euh2/openapi-servers-builder)

## 📄 License

This project follows the same MIT License as the upstream repository.

---

## 🔗 Related Repositories

- 🔧 **Upstream**: [open-webui/openapi-servers](https://github.com/open-webui/openapi-servers)
- 🏗️ **Builder**: [euh2/openapi-servers-builder](https://github.com/euh2/openapi-servers-builder)
