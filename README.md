# Drupal Example

[![JIRA Project](https://img.shields.io/badge/JIRA-Project-blue.svg?logo=jira)](https://uceapit.atlassian.net/browse/UOS)
[![github Codespaces](https://img.shields.io/badge/GitHub-Codespaces-black.svg?logo=github)](https://codespaces.new/uceap/drupal-example)
[![pantheon Dashboard](https://img.shields.io/badge/Pantheon-Dashboard-yellow.svg?logo=pantheon)](https://dashboard.pantheon.io/sites/b7553ca9-57c9-419b-aeb3-8107cbda2704#dev/code)
[![drupal-example QA](https://img.shields.io/badge/example-QA-violet.svg)](https://qa-drupal-example.pantheonsite.io/)
[![drupal-example LIVE](https://img.shields.io/badge/example-LIVE-teal.svg)](https://live-drupal-example.pantheonsite.io/)

## Getting Started 🚀

There are several options for getting started working on a UCEAP project. The first option is the simplest, then they increase in complexity and control:

1. [☁️ **Cloud**](#option-1-cloud-%EF%B8%8F): quickly start editing code on a fresh copy of this project running live in the cloud
2. [🖼️ **Hybrid**](#option-2-hybrid-%EF%B8%8F): connect your local editor to this project running live in the cloud
3. [📦 **Local**](#option-3-local-): get this project running on your local workstation
4. [💻 **Metal**](#option-4-metal-): the way we all used to do things back in the good ol' days

Once you're up and running, check out the [`uceap/drupal-dev` README](https://github.com/UCEAP/drupal-dev) for helpful tips about using these environments.

## Option 1: Cloud ☁️ 
The quickest way to start is to run the browser version of Visual Studio Code connected to a cloud container running the server on GitHub Codespaces.

> ### When to use this option
> This is a great temporary option if you are new to the project, and is also suitable if you are away from your personal workstation using a different computer or an iPad. For everyday work, look at the options below.

1. Go to the GitHub repository for the project, click the green “<> Code” dropdown, select the "Codespaces" tab, then click the green “Create codespace on qa” button
2. OR visit a pull request you want to review, click the green “<> Code” dropdown, select the "Codespaces" tab, then click the green “Create codespace on \<branch\>” button
3. Wait several seconds while the Codespace is created
4. When the bottom panel opens up showing “Terminal”, wait for the “postStart.sh” command to finish running
5. Then click on the “Ports” tab in the bottom panel
6. Hover over the line for port 8080 and click the 🌐 globe icon to open the site in a new tab
7. Return to the original tab and start coding. You can check out other branches, create your own branch, and generally do anything you would if you were working locally.

## Option 2: Hybrid 🖼️ 
For more control over your development environment, you can run your favorite IDE locally, connected to a cloud container running the server on GitHub Codespaces. These instructions assume you want to use Visual Studio Code. If you want to use PhpStorm instead then use the [GitHub Codespaces plugin](https://plugins.jetbrains.com/plugin/20060-github-codespaces) from the IntelliJ IDE Plugin Marketplace.

> ### When to use this option
> This is an ideal solution if you are reviewing a pull request and need to interact with a running version of the code, but don’t want to interrupt any in-progress work you may be doing on your local environment. This is also a great option if you want to give someone else access to a web server to test your work in progress. For the best long-term solution for local development, look at the next option.

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install [GitHub Codespaces](https://marketplace.visualstudio.com/items?itemName=GitHub.codespaces) extension for Visual Studio Code
3. (OPTIONAL) Set your TERMINUS_TOKEN secret[^1]
3. Press F1 (on Windows) or Shift-Command-P (on macOS) to open the command palette
4. Type “create new codespace”
5. Start typing the name of the project you are working on and select the matching autocomplete result
6. Select the branch you want to work on
7. Select the smallest instance type option (for this project, it’s 4 core 8gb ram)
8. Wait several seconds while the “Setting up remote connection” notification is displayed
9. When the bottom panel opens up showing “Terminal”, wait for the “postStart.sh” command to finish running
10. Then click on the “Ports” tab in the bottom panel
11. Hover over the line for port 8080 and click the 🌐 globe icon to open the site in your browser
12. Return to Visual Studio Code and start coding.

## Option 3: Local 📦 
For minimal latency you can run the server locally in a container using Docker, which also lets you work while offline. These instructions assume you want to use Visual Studio Code. If you want to use PhpStorm instead then use the [Dev Containers plugin](https://plugins.jetbrains.com/plugin/21962-dev-containers) from the IntelliJ IDE Plugin Marketplace.

> ### When to use this option
> This should be your standard choice for long term work on this project. It is faster than Codespaces and almost as convenient.

1. If you haven’t already, [generate a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [add the new SSH key to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) [^2]
2. Set your GH_TOKEN environment variable [^3]
3. (OPTIONAL) Setup Terminus [^4]
6. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
7. Install [Visual Studio Code](https://code.visualstudio.com/)
8. Install [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension for Visual Studio Code
9. Press F1 (on Windows) or Shift-Command-P (on macOS) to open the command palette
10. Type “dev container clone repo” and select the first result
11. Select GitHub as the source
12. Start typing the name of the project you are working on and select the matching autocomplete result
13. Select the branch you want to work on
14. Wait several seconds while the container is built
15. Once it is complete. press Shift-Command-P and “remote install local extensions” (select all and install)
16. Then click on the “Ports” tab in the bottom panel
17. Hover over the line for port 8080 and click the 🌐 globe icon to open the site in your browser
18. Return to Visual Studio Code and start coding.

> ### Want to access these files from your regular tools?
> Using "Clone Repository in Container Volume" as described above keeps your working copy inside the container. This is great for keeping things isolated (e.g. if you're working on multiple branches simultaneously you can easily do so using multiple containers), but it makes the files inaccessible to applications running on your local system such as Tower or Kaleidoscope. If you want your working copy to be accessible to your local operating system, then checkout the repository (perhaps using <a href="https://desktop.github.com">GitHub Desktop</a>[^5]) and open the directory in VS Code. You should get a VS Code notification prompting you to "Reopen in a container". Do that and you'll have the best of both worlds: easy containerized development environment, with files accessible to all your favorite local tools. 

## Option 4: Metal 💻 
If you want to go old-school then you can run the project on bare metal rather than in a container.

> ### When to use this option
> Because everyone’s local environment is unique, this option comes without support. Proceed only if you are fully comfortable with figuring everything out on your own.

Follow the steps in [Setup local development with Valet from scratch](https://github.com/UCEAP/myeap2/wiki/Setup-local-development-with-Valet-from-scratch). These instructions are out of date and you will need to tweak them extensively.

[^1]: <a href="https://docs.pantheon.io/machine-tokens">Create a Terminus machine token</a> then add it to <a href="https://github.com/settings/codespaces">your personal Codespaces secrets</a>
[^2]: Note that if you are [using 1Password for your ssh-agent](https://developer.1password.com/docs/ssh/agent/), you’ll also need to [set the SSH_AUTH_SOCK env var](https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client)
[^3]: Follow <a href="https://docs.github.com/en/github-cli/github-cli/quickstart">GitHub CLI quickstart</a> then edit your `~/.zprofile` to add:
    ``` zsh
    export GH_TOKEN=`gh auth token`
    ```
[^4]: Add an <a href="https://docs.pantheon.io/ssh-keys">SSH key for Pantheon</a> and set a TERMINUS_TOKEN environment variable, perhaps by <a href="https://docs.pantheon.io/machine-tokens">create a Terminus machine token</a> then edit your `~/.zprofile` to add:
    ``` zsh
    export TERMINUS_TOKEN='YOUR_TOKEN_HERE'
    ```
[^5]: Note that on macOS, GitHub Desktop defaults to checking out repositories in your Documents folder. If you keep your Documents in iCloud Drive, this will cause problems with bind mounts in Docker! So choose a different parent directory for your working copy.
