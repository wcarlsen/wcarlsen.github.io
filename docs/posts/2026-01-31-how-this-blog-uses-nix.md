---
date: 2026-01-31
tags:
  - nix
  - github
---

# How this blog uses Nix

 Nix is an advanced tool for building, packaging, and configuring software in a reliable, reproducible and declarative way, that has been gaining a lot of popularity over recent years. Nix first came up on my radar around the early 2020s, but it took a couple of years before I really started investing time on it other than just reading. It is really powerful but also very different from what I was used to. I now use NixOS as my daily driver (work and home) and use Nix Flakes to declare my development shells in various projects. In this post we will go over how I first started using Nix and how I have declared a development shell for this blog using Nix Flakes.

### The word Nix is used everywhere

The term "I use Nix" can have many meanings and is sometimes confusing. Let's go over some of them here.

* Nix the functional language
* Nix the package manager also known as nixpkgs
* Nix the operating system also known as NixOS

There are probably more, but I think this might illustrate where the confusion comes from. Just know that people tend to only use the word "Nix" and you have to guess the context.

### Home-manager is a great place to start

I started my practical journey with Nix with porting my dotfiles and packages into the Nix ecosystem using [Home-manager](https://github.com/nix-community/home-manager), a basic system for managing your user environment using the Nix package manager and Nix libraries. For me it was a great starting point and I can really recommend this approach. At that time I was using Archlinux, but Nix with home-manager could easily be set up on the side and I could slowly port my stuff when I felt like it. I also quickly found out that I almost don't have any system-level configuration, so I made the switch to NixOS after roughly a year and I have never looked back since. See my NixOS configuration here [github.com/wcarlsen/config](https://github.com/wcarlsen/config).

### Flakes and development shells

Flakes have at this point basically become the defacto standard, when using Nix. It adds a much needed `flake.lock` file (can be updated with `nix flake update`), making sure your configuration is reproducable. It is pretty simple to define a development shell using flakes. See look at "minimal" example.

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {
        inherit system;
      }; # this is just a fancy (but easy) way to define your system, e.g. x86_64-linux, aarch64_darwin, etc.
    in {
      devShells = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cowsay # add your dependencies here
          ];
          shellHook = ``
            cowsay "COWABUNGA!" # add your custom shell hooks here
          ``;
        };
      };
    });
}
```

Above flake consists of `inputs`, defining which branch of the Nix package manager to use and `flake-utils` as a way to define systems. The other part is `outputs`, where we are outputting `devShells`, but only defining one called `default` using `pkgs.mkShell` and its attribute `buildInputs` to define package dependencies. It should be noted that `mkShell` has other attributes as well, for example `shellHook`. You could imagine a simple Python project using UV as package manager, where `buildInputs` would contain Python and UV and the `shellHook` running `uv sync` installing all Python-specific dependencies. Another example would be an Opentofu project, where we install all providers with `tofu init` in the `shellHook`.

The `devShells` can be invoked with the following nix command: `nix develop`. I tend to use `direnv` and just put `use flake` in my `.envrc` file, to have it automatically set up my development shell.


### So how does this blog use Nix?

Now that we have some limited knowledge about Nix and Flakes, we can start looking at how this blog uses it. In the root of the [GitHub project](https://github.com/wcarlsen.github.io) you will find a `flake.nix` which specifies `MkDocs` and all the plugins used to create this blog, and, because I use `direnv`, it will automatically install all dependencies and drop me into a development shell so I can start writing and validate my changes locally. I find the "holy trinity" `flakes`, `direnv` and `make` really useful. So now we have a reproducible development setup; how do we use it in places other than locally? Let's look at GitHub Actions as an example.

### GitHub Actions and Flakes

Because we have defined all of our dependencies in a `Flake` it becomes really easy to utilize it in a GitHub Action.


```yaml
name: build
on:
  pull_request:
    branches:
      - main
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Nix
        uses: cachix/install-nix-action@v30
        with:
          extra_nix_config: |
            access-tokens = github.com=${{ secrets.GITHUB_TOKEN }}
      - name: Build
        run: nix develop --command make build
```

We see that it doesn't really require much effort at all, and changes to my local development don't require updates to my GitHub Actions workflow (unless I change the Makefile interface).
