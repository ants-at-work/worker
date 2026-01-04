# Security

Security is Priority 1. This document describes the security architecture of ants-worker.

## Threat Model

### What We Protect

1. **Private Keys** - If a collision is found, the private key MUST stay local
2. **Worker Tokens** - Bearer tokens that authenticate workers
3. **Database Credentials** - Workers never see these
4. **Compute Resources** - Prevent abuse of contributor machines

### Trust Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│                     UNTRUSTED ZONE                               │
│                                                                  │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│   │  Worker A    │    │  Worker B    │    │  Worker N    │     │
│   │  (Your PC)   │    │  (Cloud VM)  │    │  (Volunteer) │     │
│   └──────┬───────┘    └──────┬───────┘    └──────┬───────┘     │
│          │                   │                   │              │
│          │ Bearer Token      │ Bearer Token      │ Bearer Token │
│          │ (only auth)       │ (only auth)       │ (only auth)  │
│          ▼                   ▼                   ▼              │
└──────────┼───────────────────┼───────────────────┼──────────────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TRUSTED ZONE                                │
│                                                                  │
│   ┌──────────────────────────────────────────────────────┐     │
│   │           Gateway (api.ants-at-work.com)              │     │
│   │           - Validates tokens                          │     │
│   │           - Rate limits requests                      │     │
│   │           - Collision detection                       │     │
│   └──────────────────────┬───────────────────────────────┘     │
│                          │                                      │
│                          │ DB Credentials                       │
│                          │ (server-side only)                   │
│                          ▼                                      │
│   ┌──────────────────────────────────────────────────────┐     │
│   │           TypeDB Cloud (ants-colony)                  │     │
│   │           - Permanent storage                         │     │
│   │           - Pattern analysis                          │     │
│   └──────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Security Audit Results

Last audit: 2025-12-25

| Check | Status | Details |
|-------|--------|---------|
| Hardcoded secrets | PASS | All credentials via environment variables |
| Command injection | PASS | All subprocess calls use list format |
| Deserialization | PASS | No pickle/yaml.load/marshal |
| SSRF | PASS | Only connects to fixed, known URLs |
| Private key handling | PASS | Never transmitted over network |
| Backdoors | PASS | No raw sockets or covert channels |
| Data exfiltration | PASS | Only sends work results |

## Credential Handling

### What Workers Have Access To

```python
# Workers only have a bearer token
GATEWAY_TOKEN=abc123...  # Can only submit work results
```

### What Workers Do NOT Have Access To

```python
# These stay server-side
TYPEDB_PASSWORD=***      # Database credentials
ADMIN_KEY=***            # Administrative access
```

### Token Scope

Worker tokens can ONLY:
- `GET /health` - Health check
- `GET /target` - Get puzzle target
- `GET /regions` - Get cold regions
- `POST /dp` - Submit distinguished points
- `POST /intention` - Mark working intention
- `POST /exploration` - Mark exploration
- `GET /collision` - Check for collision

Worker tokens CANNOT:
- Access admin endpoints
- Modify other workers' data
- Read database directly
- Change puzzle configuration

## Private Key Protection

**CRITICAL**: If a collision is found, the private key is computed locally and NEVER transmitted.

```python
# From api_client.py - lines 192-204
async def deposit_solution(self, private_key: int):
    """
    Handle solution found.

    SECURITY: Never log or transmit the private key!
    This should trigger local sweep only.
    """
    # SECURITY: Do NOT print or log the private key
    # The key should be used locally for immediate sweep
    print("[green]SOLUTION FOUND![/green]")
    print("[yellow]SWEEP FUNDS IMMEDIATELY - Key in memory only[/yellow]")
    # NEVER send private_key over network or store in database
```

### Why This Matters

If a worker finds the solution:
1. Private key is computed in worker memory
2. Worker alerts user locally
3. User sweeps funds using their own wallet
4. Private key never leaves the machine

**The colony helps find the key. The finder keeps the reward.**

## Subprocess Security

All external process calls use safe patterns:

```python
# SAFE - List format prevents shell injection
subprocess.run(["vastai", "search", query], ...)

# UNSAFE - Never used
subprocess.run(f"vastai search {query}", shell=True)  # ✗ NOT IN CODE
```

### External Binaries

| Binary | Source | Verification |
|--------|--------|--------------|
| `kangaroo` | JeanLucPons/Kangaroo | User compiles from source |
| `vastai` | Official Vast.ai CLI | pip install vastai |

## Network Security

### Allowed Endpoints

| Endpoint | Purpose | Required |
|----------|---------|----------|
| `api.ants-at-work.com` | Gateway API | Yes |
| `cloud.lambdalabs.com` | Lambda Labs cloud | Optional |
| `cr0mc4-0.cluster.typedb.com` | TypeDB (direct mode) | Optional |

### TLS

All connections use HTTPS/TLS. No plaintext credentials.

### Rate Limiting

Gateway enforces:
- 100 requests/minute on `/register`
- Token-based rate limiting on all endpoints

## File System Access

### Files Read

| Path | Purpose |
|------|---------|
| `~/.ants/config.json` | Worker configuration |
| `/proc/cpuinfo` | CPU detection (Linux) |
| `/proc/meminfo` | Memory detection (Linux) |

### Files Written

| Path | Purpose |
|------|---------|
| `~/.ants/config.json` | Save worker token |

No other file system access.

## What We Don't Do

- No keyloggers or input capture
- No screen capture
- No file scanning beyond config
- No network scanning
- No persistence mechanisms
- No privilege escalation
- No code execution from remote sources
- No auto-updates without user consent

## Reporting Security Issues

If you find a security vulnerability:

1. **DO NOT** open a public issue
2. Email: security@ants-at-work.com
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact

We will respond within 48 hours.

## Verification

You can verify the security of ants-worker:

```bash
# Check for hardcoded secrets
grep -r "password\|secret\|api.key" ants_worker/

# Check subprocess calls
grep -r "shell=True" ants_worker/  # Should return nothing

# Check deserialization
grep -r "pickle\|yaml.load\|marshal" ants_worker/  # Should return nothing

# Review network calls
grep -r "requests\|urllib\|httpx" ants_worker/
```

## Dependencies

Minimal dependencies, all from PyPI:

```
click>=8.0      # CLI framework
rich>=13.0      # Terminal formatting
httpx>=0.25.0   # HTTP client
```

Optional:
```
cupy-cuda12x    # NVIDIA GPU (user installs)
torch           # AMD GPU (user installs)
```

No native code. No compiled extensions. Pure Python.
