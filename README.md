# TYPO3 CMS Template for the Microsoft Azure Cloud

Maintained by the TYPO3 Community Interest Group (CIG) Azure Cloud.

# Installation
0. `git clone https://github.com/ksjogo/azure-typo3-template.git`
1. Use our resouce template TYPO3.json to create the required resource inside your [portal](https://portal.azure.com).
2. Setup your deployment credentials inside the portal.
3.  `git remote add origin URL`
4. `git push` this repository.

# Status
## Working
* CmsComposerInstaller fixed to work with Azure.
* deployment.bat using composer and typo3_console for setup

## Failing
* Installer will error out with some mssql errors (WIP)

# Debugging
Add key "PHP_ZENDEXTENSIONS" with value "bin\php_xdebug.dll" to your Application settings.

# Discovered Azure PHP Problems
* PHP Extensions are not loaded in console environment: e.g. redis, wincache
