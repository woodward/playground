---
name: phoenix-project-setup
description: Performs post-generation setup steps for a new Phoenix project created with mix phx.new. Use when the user creates a new Phoenix project, scaffolds a Phoenix app, or asks to run their standard Phoenix setup steps.
---

# Phoenix Project Setup

Post-generation setup steps to run after `mix phx.new`. Execute these steps in order, committing after each step.

## Step 1: Set formatter line length to 120

1. In `.formatter.exs`, add `line_length: 120` to the keyword list
2. Run `mix format` to reformat the entire project with the new line length

## Step 2: Alphabetize mix.exs dependencies

1. Sort the dependency tuples in the `deps/0` function in `mix.exs` alphabetically by package name

## Step 3: Update all dependencies

1. Run `mix deps.update --all` to update all mix dependencies
2. Look up the latest stable versions of **esbuild** and **Tailwind CSS**
3. Update the `version` values in `config/config.exs` for both `:esbuild` and `:tailwind`

## Step 4: Sync dependency version specs

1. Run `mix deps` to see the actual installed versions
2. Update each dependency in `mix.exs` to:
   - Use 2-digit version specs (e.g., `"~> 1.10"` not `"~> 1.10.2"`)
   - Match the currently installed minor version (e.g., if `telemetry_poller 1.3.0` is installed, use `"~> 1.3"` not `"~> 1.0"`)
3. Run `mix deps.get` to verify all deps still resolve cleanly

## Step 5: Replace vendored daisyUI with npm package

1. Delete `assets/vendor/daisyui.js` and `assets/vendor/daisyui-theme.js`
2. Initialize npm in the `assets/` directory if no `package.json` exists: `npm init -y` (run from within `assets/`)
3. Install daisyui: `npm install daisyui` (run from within `assets/`)
4. Update `assets/css/app.css`:
   - Change `@plugin "../vendor/daisyui"` to `@plugin "daisyui"`
   - Change all `@plugin "../vendor/daisyui-theme"` to `@plugin "daisyui/theme"`
5. Add `"cmd npm i --prefix assets"` to the `assets.setup` alias in `mix.exs`
6. Ensure `assets/node_modules/` is in `.gitignore` (it should already be)
7. Commit both `assets/package.json` and `assets/package-lock.json`
