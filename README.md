# `mise-oxc`

A [`mise` backend plugin](https://mise.jdx.dev/plugins.html#backend-plugins) to install recent
standalone versions of CLIs from the [JavaScript Oxidation Compiler
(`oxc`)](https://github.com/oxc-project/oxc) project.

## Requirements

Assumes that you have [`gh`](https://cli.github.com/) installed (ideally via `mise`) and you are
logged into GitHub.

```shell
mise use --global github-cli # for gh
```

## Install

```shell
mise plugin install oxc https://github.com/malept/mise-oxc.git
```

## Usage

```shell
# List available versions
mise ls-remote oxc:oxlint

# Install
mise install oxc:oxlint
```

## Supported CLIs

* `oxlint` (since `1.29.0`)
* `oxfmt` (since `0.14.0`)

> [!NOTE]
> If you need `oxlint` versions 1.16.0 or earlier, use `aqua:oxc-project/oxc/oxlint`.

> [!WARN]
> Installing `oxlint` in this manner will not allow you to use [type-aware
> linting](https://oxc.rs/docs/guide/usage/linter/type-aware.html) or [JS
> plugins](https://oxc.rs/docs/guide/usage/linter/js-plugins.html). To do that,
> you will need to install it outside of `mise`, via `package.json`.

## License

Licensed under the [Apache-2.0 license](https://www.apache.org/licenses/LICENSE-2.0).
