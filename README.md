# Example to build a puppeteer docker image
This example shows how to build a puppeteer docker image using a nix flake.
The process allows the embedded of your node program in a reproducible way,
i.e., you provide your source code and your `package.json` (and potentially
lock file) and you get a from scratch image with puppeteer.

## Embed your node project
Copy the `flake.nix` file to your existing puppeteer project.

### Adjust your project
Ensure that your `package.json` file has `bin` set to your entrypoint.
Furthermore, ensure that your entrypoint has a shebang set:

```bash
#!/usr/bin/env node
```

### Adjust the flake.nix file
Change puppeteer-example to your project's name consistently int the
`flake.nix` file.

### Generate nix files
To generate the `node*.nix` files for node18 run:

```bash
nix shell nixpkgs#node2nix -c node2nix -18 -c node2nix.nix
```

Afterwards generate the `flake.lock` file using:

```bash
nix flake update
```

## Building and loading the image
To build and load the image, run:

```bash
nix build .#docker
```

Followed by:

```bash
docker load < result
```

Or:

```bash
podman load < result
```

## Running the image
Running the image using docker may require the `--cap-add=SYS_ADMIN` for the
chromium sandbox to work.
