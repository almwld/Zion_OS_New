---
name: defensive-network-inventory
description: Identify local security tools and plan low-impact checks for explicitly authorized targets.
---
# Defensive Network Inventory
1. Discover installed tools and versions before attempting to run them.
2. Establish the user's authorized scope and prefer lab or owned systems.
3. Begin with local interface, route, DNS, and service metadata checks.
4. Use the least intrusive test that answers the task and capture command output and exit status.
5. Explain scope and limitations in the result; do not infer a vulnerability from a tool banner alone.
A skill is not authorization to scan third-party systems.