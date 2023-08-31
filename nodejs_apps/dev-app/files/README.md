# Ansible Project: Infrastructure Automation

Welcome to the Ansible Project for Infrastructure Automation. This detailed guide will walk you through the various components of the project, ensuring you understand each file and its functionality.

## Table of Contents

- [Ansible Project: Infrastructure Automation](#ansible-project-infrastructure-automation)
  - [Table of Contents](#table-of-contents)
  - [Directory Structure](#directory-structure)
    - [Configurations](#configurations)
    - [Playbooks](#playbooks)
    - [Roles Overview](#roles-overview)
  - [Node.js Application Overview](#nodejs-application-overview)
    - [Nginx Configuration Overview](#nginx-configuration-overview)
    - [Vault and Secrets](#vault-and-secrets)
    - [Usage](#usage)
    - [Comprehensive Step-by-Step Tutorial](#comprehensive-step-by-step-tutorial)
      - [Prerequisites](#prerequisites)
      - [1. Cloning the Repository](#1-cloning-the-repository)
      - [2. Understanding Directory Structure](#2-understanding-directory-structure)
      - [3. Setting Up the Environment](#3-setting-up-the-environment)
      - [4. Running Playbooks](#4-running-playbooks)
      - [5. Working with Roles](#5-working-with-roles)
      - [6. Modifying Configurations](#6-modifying-configurations)
      - [7. Deploying Node.js Application](#7-deploying-nodejs-application)
      - [8. Handling Secrets with Vault](#8-handling-secrets-with-vault)
      - [9. Concluding Notes](#9-concluding-notes)
    - [Feedback and Contributions](#feedback-and-contributions)
    - [License](#license)


## Directory Structure

The Ansible project directory is meticulously organized, housing a variety of configurations, playbooks, roles, application files, and more. Let's delve into each of these components:

- 'ansible/':
  - 'configs/': Configuration files that determine how parts of the infrastructure are set up.
  - 'dev-app/': Home to our Node.js application, containing source files, controllers, models, and views.
  - 'group_vars/': Used to define variables that are applicable to the entire group.
  - 'html/': HTML configurations tailored for our Nginx setups.
  - 'inventories/': Organizes and segregates our infrastructure into development, production, and staging.
  - 'json/': Holds JSON files detailing realms, roles, and users.
  - 'kyc_files/': Contains the KYC service configuration.
  - 'nginx_files/': Configuration and deployment specifics for Nginx.
  - 'playbooks/': A collection of our playbooks, which are sequences of tasks to be executed.
  - 'roles/': Task bundles segmented by their roles in our infrastructure.
  - 'vault/': Encrypted files live here, ensuring the confidentiality of our secrets.

### Configurations

The 'configs/' directory is a crucial part of our setup. It contains YAML files that dictate how different parts of the infrastructure behave and interact. Let's look at some of these configurations:

- 'kind-dev-config.yaml': Configures the development environment specifics when working with KIND. Here's a brief snippet:
  'apiVersion: kind.x-k8s.io/v1alpha4'
  'kind: Cluster'
  'nodes:'
  '  - role: control-plane'
  '  - role: worker'

  In this file, we define a KIND cluster with one control plane node and one worker node.

- 'kyc-cluster-config.yaml': A file that contains the necessary configurations to set up the KYC cluster. 
  'apiVersion: v1'
  'kind: Config'
  'clusters:'
  '  - cluster:'
  '      server: http://kyc-cluster.local:8080'
  '    name: kyc-cluster'

  This snippet showcases the endpoint where our KYC cluster service can be reached.

... and many more configurations that we will delve into in subsequent sections.

### Playbooks

'playbooks/' is a directory that contains ordered lists of tasks to execute. These tasks help in automating the process of configuring and managing our infrastructure. Some essential playbooks include:

- 'create_clusters.yml': As the name suggests, this playbook is instrumental in setting up various clusters in our infrastructure. 
  '---'
  '- hosts: localhost'
  '  tasks:'
  '    - name: Set up KYC cluster'
  '      command: kubectl apply -f configs/kyc-cluster-config.yaml'

  This playbook uses the 'kubectl apply' command to apply configurations and set up the KYC cluster using the provided YAML configuration.

... We will delve deeper into other playbooks and their significance in the subsequent sections.
### Roles Overview

The 'roles/' directory is segmented by the functionality each role provides in our infrastructure. Each role houses its tasks, typically found within a 'tasks/' sub-directory.

- 'keycloak/':
  The role responsible for setting up and configuring Keycloak.
  - 'tasks/main.yml':
    '---'
    '- name: Setup Keycloak service'
    '  command: ./keycloak-setup.sh'

    This task automates the Keycloak service setup using the provided shell script.

- 'kind/':
  Handling the setup and configuration for KIND.
  - 'tasks/main.yml':
    '---'
    '- name: Deploy KIND cluster'
    '  command: kind create cluster --config configs/kind-dev-config.yaml'

    This snippet demonstrates the deployment of a KIND cluster using our development configuration.

- 'kyc/':
  Task definitions for setting up the KYC service.
  - 'tasks/main.yml':
    '---'
    '- name: Setup KYC service'
    '  command: kubectl apply -f kyc_files/kyc-svc.yml'

    The KYC service setup task deploys the service using 'kubectl' with the provided configuration.

... similar structures for Nginx and Node.js roles, each with their respective tasks.

## Node.js Application Overview

Located in the 'dev-app/' directory, our Node.js application is structured with:

- **app.js**: The main entry point of our Node.js application. It initializes the Express.js server, sets up middleware, and defines routes to handle HTTP requests. This file also listens on a specified port for incoming requests.

- **controllers/**: This directory contains route handling logic for different URL paths and associated actions. The `index.js` file within this directory defines routes for various calendar and RabbitMQ functionalities. It handles message consumption and publication using RabbitMQ.
- 
The 'views/' directory contains EJS templates that define various views for the Node.js application. These templates are used to render dynamic content on the client side. Below are the descriptions and usages of the available EJS files:

- **views/**: This directory contains EJS templates for rendering different views in the application. Notable views include:

- **calendar-day.ejs**: Renders a daily calendar view using the FullCalendar library. It displays events and appointments for a single day.

- **calendar-month.ejs**: Displays a monthly calendar view using FullCalendar. It shows events and schedules for an entire month.

- **calendar-year.ejs**: Provides an annual calendar view using FullCalendar. It presents events and schedules for a full year.

- **index.ejs**: The main template that serves as the homepage of the application. It provides an overview of the application's purpose, technologies used, and links to different sections.

- **list-gen.ejs**: Renders a generic list view using FullCalendar. It displays a list of items, events, or tasks.

- **list-week.ejs**: Presents a weekly list view using FullCalendar. It shows a list of items, events, or tasks for a week.

- **multi-month.ejs**: Displays a multi-month calendar view using FullCalendar. It presents events and schedules for multiple months.

- **publisher.ejs**: Provides a view for message publishing. Users can trigger the publishing of a message through RabbitMQ using a button.

- **time-day.ejs**: Renders a daily time-based view using FullCalendar. It displays time-specific events or appointments for a single day.

- **time-week.ejs**: Shows a weekly time-based view using FullCalendar. It presents time-specific events or appointments for a week.

- **calendar-gen.ejs**: Renders a generic calendar view using FullCalendar. It displays events and schedules for various time periods.

- **calendar-week.ejs**: Provides a weekly calendar view using FullCalendar. It shows events and schedules for a week.

- **consumer.ejs**: Renders a view for message consumption. Users can initiate the consumption of messages from RabbitMQ using a link.

- **list-day.ejs**: Presents a daily list view using FullCalendar. It displays a list of items, events, or tasks for a single day.

- **list-month.ejs**: Displays a monthly list view using FullCalendar. It shows a list of items, events, or tasks for an entire month.

- **message.ejs**: Provides a form for submitting messages. Users can input messages and submit them using the form. It also displays the most recent messages.

- **multi-month-year.ejs**: Offers a multi-month calendar view spanning a year. It presents events and schedules for multiple months within a year.

- **readme.ejs**: Dynamically renders the content of the README.md file in a user-friendly format. It uses Markdown rendering to present the contents of the README in an organized manner.

- **time-gen.ejs**: Renders a generic time-based view using FullCalendar. It displays time-specific events or appointments for various time periods.

- **files/README.md**: This README file, which is then rendered in 'readme.ejs', using 'readmeContent' we created in 'contollers/index.js:132'(this may change and may not be updated, but the route for'/readme' will provide the 'readmeContent' creation). This directory ('files/') is also a misc placeholder for any files not specifically defined anywhere else[meaning I just haven't gotten around to redistributing them correctly yet]
---
Feel free to explore these files to understand how the Node.js application interacts with the rest of the infrastructure and how it handles different functionalities.

### Nginx Configuration Overview

The 'html/' and 'nginx_files/' directories hold configurations related to our Nginx setup:

- 'html/':
  - 'nginx-dev.html': HTML content for our development Nginx server.
  - 'nginx-stg.html': Tailored for our staging setup.
  
- 'nginx_files/':
  - 'deploy.yaml': Automates the deployment of Nginx.
  - 'nginx-dev-svc.yml': Service definition for our development Nginx setup.
  - 'nginx-stg-svc.yml': Staging setup specifics for Nginx.

### Vault and Secrets

All our encrypted data, like passwords or API keys, is stored in the 'vault/' directory:

- 'secrets.yml': Encrypted secrets that can only be decrypted with the appropriate vault password.

### Usage

To use this Ansible setup:

1. Ensure you have Ansible installed.
2. Navigate to the root directory: 'cd /home/bzarch/ansible'.
3. Run the desired playbook: 'ansible-playbook playbooks/<YOUR_PLAYBOOK>.yml'.

### Comprehensive Step-by-Step Tutorial

Welcome to the comprehensive guide to get you started with our Ansible project. By the end of this tutorial, you'll have an in-depth understanding of the project's structure, components, and usage.

#### Prerequisites

1. Ensure you have Ansible installed. If not, install it using:
    'sudo apt update && sudo apt install ansible'

2. Familiarity with basic terminal commands and Ansible concepts.

#### 1. Cloning the Repository

To get started, you'll first need a local copy of the repository.

'git clone [repository-url] /home/bzarch/ansible'
Navigate to the root directory: 'cd /home/bzarch/ansible'.

#### 2. Understanding Directory Structure

Before diving into tasks and playbooks, understand the directory layout:
- 'configs/': Houses configurations for different environments and services.
- 'roles/': Segregated by functionality. Each role contains tasks specific to its purpose.
- 'playbooks/': Contains playbooks that combine different roles and tasks to automate larger processes.

#### 3. Setting Up the Environment

Based on the environment you wish to set up (development, staging, or production), navigate to the respective inventory directory under 'inventories/'.

For instance, for development:
'cd inventories/development'

#### 4. Running Playbooks

To deploy a specific service or application, run its respective playbook. For example, to set up Keycloak:

'ansible-playbook playbooks/setup_keycloak.yml'

Always ensure you're in the root directory when running playbooks.

#### 5. Working with Roles

Roles are modular components in Ansible. To modify a role or its tasks:
- Navigate to the desired role under 'roles/'.
- Edit the 'tasks/main.yml' file as per your requirements.

For instance, to adjust the KYC role, you'd edit:
'roles/kyc/tasks/main.yml'

#### 6. Modifying Configurations

To change the configuration of a specific service or environment, adjust the respective YAML file in the 'configs/' directory.

#### 7. Deploying Node.js Application

Navigate to the 'dev-app/' directory:
'cd dev-app'

Run the Node.js application:
'node app.js'

Your app will be accessible on the specified port.

#### 8. Handling Secrets with Vault

When working with encrypted secrets in 'vault/secrets.yml':
- To edit or view secrets, use:
  'ansible-vault edit vault/secrets.yml'
- You'll be prompted for the vault password. Once provided, you can modify or view the secrets.

#### 9. Concluding Notes

This Ansible project is modular and scalable. You can add more roles, configurations, and playbooks as per your requirements. Ensure to test in a development or staging environment before making changes to production.

### Feedback and Contributions

If you have suggestions, feedback, or would like to contribute to the project, please create an issue or pull request on the GitHub repository. Your insights and contributions are valuable to us!


### License

This project is licensed under the MIT License. For more details, refer to the LICENSE file in the root directory.


