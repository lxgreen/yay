# yay

![yay](https://github.com/user-attachments/assets/58f993c9-911f-415c-99ab-eb11bd90511a)

## Overview

`yay` is a development tool designed to enhance workflow efficiency in projects that use a monorepo structure with multiple interdependent packages. It simplifies the challenges associated with concurrently running and managing several `yarn start` processes for local development of various applications and their dependencies within a monorepo environment.

## Key Features

* Automated process management: `yay` automatically handles `yarn start` processes for different packages, allowing developers to concentrate on writing code instead of managing processes.
* Dependency-aware hot reloading: tracks file changes throughout the repository to automatically restart dependent `yarn start` processes, ensuring updates are propagated across all relevant applications without the need for manual restarts.
* Integrated terminal output: provides a consolidated view of all `yarn start` process outputs, supporting split-window output for simpler navigation and quicker error analysis.
* File tracking: identifies file changes within the repository, restarting only the necessary processes to conserve time and resources.

## Usage

```sh
git clone git@github.com:lxgreen/yay.git ./yay
cd ./yay
./yay YOUR_MONOREPO_ROOT
```

## How it works

### Monorepo Management
`yay` operates within `yarn`-based monorepos, utilizing the `yarn workspaces` command to construct the dependency graph. It assumes each package offers a `start` script for local development (here, a "`yarn` process" denotes the `yarn start` task).

### Dependency Graph

The dependency graph, outlining the locations and dependency/dependent lists for each workspace in JSON format, is queried using the `jq` CLI tool. This graph is generated once and saved at the monorepo's root as `dep-graph.json`. To ensure accuracy, this graph must be deleted and regenerated whenever the monorepo's structure changes.

### Source Change Tracking

Upon initialization with a monorepo root path, `yay` prompts the user to select an application for development and its necessary transitive dependencies for monitoring. It's vital to choose only essential dependencies due to the resource intensity of each `yarn` process. The selected application's dev server starts immediately, with all chosen dependencies monitored for source changes. The `entr` CLI tool is used to track file changes, triggering the respective dependency's `yarn start` upon any source modification.

#### Package Build Monitoring

Outputs from each `yarn` process are monitored, a necessity due to `yarn` lacking an API for task progress tracking. The monitoring detects a build's completion message (e.g., 'Compiled successfully'), triggering a callback. This callback updates the tracking log files (located at `/src/.track_me` within each workspace) of dependent packages. Updating these tracking logs serves two functions:
1. It triggers a restart of any running dependent package `yarn start` processes (interpreted as a source code change by `yarn`).
2. It marks the dependent package as 'dirty' for other `yarn` processes reliant on that package's source.

Potential Improvement: Consider exploring alternative IPC mechanisms for enhanced reliability.

### Process Output

`tmux` is used to organize the output of multiple processes, with each `yarn` process running in its dedicated `tmux` pane. `yay` starts a separate `tmux` server with a custom configuration to avoid possible interference with the local environment. 

The session is divided into two windows:

1. The `build` window, which displays the `yarn` process panes.
2. The `trackers` window, which is hidden by default and shows the panes for source change tracking commands. When a tracker initiates a new `yarn` process, it is displayed in a new pane within the `build` window.

## Dependencies

- node
- yarn
- fzf
- jq
- entr
- tmux
