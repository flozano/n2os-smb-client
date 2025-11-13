# n2os-smb-client

This is a custom smb/cifs client with libsmb2 statically linked.

## Building

Initialize submodules before configuring so the bundled dependencies are available:
```bash
git submodule update --init --recursive
```
The libsmb2 and json-c libraries are built from those submodules on every platform.

KRB_IMPL env variable must be defined (MIT, HEIMDAL, or NONE).
Use NONE to skip Kerberos/GSSAPI detection entirely (only NTLM/Basic auth will be available).
HEIMDAL is currently not working.

### Static ARM32 (Docker, musl)

Binaries for ARM32 (hard-float + soft-float) can be produced inside a musl-based Docker builder that cross-compiles the bundled dependencies:
```bash
docker build -f Dockerfile.arm32 -t smb-arm32 .
```
If you want the artifacts on the host, use BuildKit's export:
```bash
docker build -f Dockerfile.arm32 --output ./arm32-static .
ls arm32-static
```
This yields `n2os_smb_client.linux_armhf_static_musl` and `n2os_smb_client.linux_armel_static_musl`, both built against musl for fully static deployment. (Kerberos is currently disabled for musl builds.)

Use Docker-based emulation to sanity check the binaries (requires Docker Desktop or binfmt-qemu on Linux):
```bash
./scripts/test.arm32.static.sh arm32-static
```
The script launches arm32 Debian containers (arm/v7 for hard-float, arm/v5 for soft-float) and runs `--help` inside each so you can verify the executables start correctly.

-DHAVE_LIBKRB5 is generating a warning in Linux build with MIT because we are forcing libsmb2 to compile with krb5 support.

### FreeBSD version

A build script is provided in [build.bsd.sh](build.bsd.sh).
only MIT kerberos compatible (pkg "krb5").

### Linux version

A build script is provided in [build.linux.sh](build.linux.sh).
only MIT kerberos compatible.
see Dockerfile.linux for dependecies.

A [Dockerfile](Dockerfile.linux) is also provided.
Build and usage examples are provided in the [Dockerfile](Dockerfile.linux) itself.

### MacOS version

A build script is provided in [build.macos.debug.sh](build.macos.debug.sh).

Kerberos builds require Homebrew Heimdal:
```bash
brew install heimdal
```

Currently supports only ntlmssp auth.

## Usage

Usage is pretty simple. This client right now can just do four simple
operations: ls, del, get and put.

<!-- markdownlint-disable-next-line MD036 -->
**Note that connection password can be passed using env variable N2OS_SMB_PASSWORD**

```text
n2os-smb-client v.0.3.7-flozano - (c) 2020-present Nozomi Networks Inc.; patches (c) 2025 Francisco A. Lozano.

Usage:
n2os-smb-client ls <smb2-url>
n2os-smb-client del <smb2-url>
n2os-smb-client get <smb2-url> [<local-filename>]
n2os-smb-client put <local-filename> <smb2-url>

Password can be passed using the N2OS_SMB_PASSWORD environment variable.
URL format: smb://[<domain;][<username>@]<host>[:<port>]/<share>/<path>

Exit codes:
4 - Cmd line error
5 - SMB init error
6 - SMB parse error
7 - SMB connect error
8 - SMB opendir error
9 - Invalid path error
10 - SMB open error
11 - SMB pread error
12 - Local filesystem error
13 - Local filesystem write error
14 - SMB write error
15 - SMB unlink error
```

## Test Env

For a complete test env launch compose file: ```docker compose -f smb_test_env.yml up```

For a client-only env launch compose file: ```docker compose -f smb_nn_env.yml up```
In this case, a nn_krb5.conf file must be present, with the correct configuration.

### Basic Auth

You can use n2os-smb-client in /usr/bin folder. ex:
```/usr/bin/n2os_smb_client.linux ls "smb://Administrator@samba-ad.example.com/sysvol"```

### Kerberos

Execute ```kinit Administrator@EXAMPLE.COM```
on client (using the password defined in compose file)

Now you can use n2os-smb-client in /usr/bin folder. ex:
```/usr/bin/n2os_smb_client.linux ls "smb://Administrator@samba-ad.example.com/sysvol/?sec=krb5"```
