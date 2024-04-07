#!/usr/bin/env node

const { exec } = require('child_process');
const fs = require('fs');

// Execute the yarn workspaces list command
exec('yarn workspaces list -R -v --json', (error, stdout, stderr) => {
    if (error) {
        console.error(`exec error: ${error}`);
        return;
    }
    if (stderr) {
        console.error(`stderr: ${stderr}`);
        return;
    }

    // Process the command output
    const workspaces = stdout.trim().split('\n').map(line => JSON.parse(line));

    // Map to store workspace dependencies (key: workspace location, value: array of dependents' locations)
    const workspaceDependenciesMap = workspaces.reduce((map, workspace) => {
      return {...map, [workspace.location]: []};
    }, {});

    workspaces.forEach(workspace => {
      const {workspaceDependencies, location} = workspace;
      workspaceDependencies.forEach(dependencyName => {
        if (workspaceDependenciesMap[dependencyName]) {
          workspaceDependenciesMap[dependencyName].push(location);
        }
      });
    });

    // Helper function to find a workspace by its name
    const findWorkspaceByLocation = (location) => workspaces.find(ws => ws.location === location);

    // Recursive function to get all unique transitive dependencies for a given workspace
    const getAllDependencies = (workspace, visited = new Set()) => {
        // Avoid cycles in the dependency graph
        if (visited.has(workspace.location)) {
            return [];
        }
        visited.add(workspace.location);

        let allDependencies = [...workspace.workspaceDependencies];
        workspace.workspaceDependencies.forEach(dep => {
            const depWorkspace = findWorkspaceByLocation(dep);
            if (depWorkspace) {
                const transitiveDeps = getAllDependencies(depWorkspace, visited);
                allDependencies = [...allDependencies, ...transitiveDeps];
            }
        });

        // Return unique dependencies
        return [...new Set(allDependencies)];
    };

    // Generate the output array with dependents information
    const output = workspaces.map(workspace => ({
      location: workspace.location,
      dependencies: getAllDependencies(workspace),
      dependents: workspaceDependenciesMap[workspace.location] || []
    }));


    // Save the output to graph.json
    fs.writeFile('dep-graph.json', JSON.stringify(output, null, 2), 'utf8', err => {
        if (err) {
          console.error('Error writing dep-graph.json:', err);
        } 
    });
});
