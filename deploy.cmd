# Install Composer

IF NOT EXIST composer.phar (
mkdir "%APPDATA%\Composer"
mkdir "%LOCALAPPDATA%\Composer"
php -r "readfile('https://getcomposer.org/installer');" | php
)

php composer.phar config discard-changes true
php composer.phar install -n

SET ARTIFACTS=%~dp0%artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
)
)

::custom deployment fixes for TYPO3 CMS v8 on azure
echo Custom TYPO3 CMS deployment starting.

:: The composer site extension is overwriting the APPSETTINGS_COMMAND and we cannot easily
:: fix that from within the git repository nor online config, but the online config/arm template can
:: set the KUDU_SYNC_COMMAND to this script, the composer deployment script will then call us.
:: we do the real kudusync and after/before are able to run custom TYPO3 scripts needed.
echo Installing TYPO3 CMS deployments dependencies.
:: just having some nice packages instead of not that comfortable bat scripting
call npm install kudusync replace -g --silent

:: fix autoload paths for the entry points
:: as these paths are different when not symlinked (why?)
call replace "(\.\./)*vendor/autoload.php" "../../../../../../../vendor/autoload.php" web\typo3\sysext\backend\Resources\Private\Php\backend.php web\typo3\sysext\backend\Resources\Private\Php\cli.php web\typo3\sysext\frontend\Resources\Private\Php\frontend.php
call replace "(\.\./)*vendor/autoload.php" "../../../../../vendor/autoload.php" web\typo3\sysext\install\Start\Install.php
call replace "(\.\./)*vendor/autoload.php" "../../../../../vendor/autoload.php" web\typo3\sysext\core\bin\typo3
call replace "(\.\./)*vendor/autoload.php" "../../../vendor/autoload.php" web\typo3\install\index.php
call replace "(\.\./)+vendor/autoload.php" "../../vendor/autoload.php" vendor\helhum\typo3-console\Scripts\typo3cms.php

:: stuff to be done BEFORE copying to live site
:: basically everything we are able to do without db access
:: like platform.sh build step
echo Building TYPO3 CMS.
call vendor/bin/typo3cms install:fixfolderstructure
call vendor/bin/typo3cms install:generatepackagestates --activate-default=true

:: move stuff from D:\home\site\repository to D:\home\site\wwwroot
:: pass all arguments we are called with from the composer extension
:: not nice but works so far
echo Moving TYPO3 CMS to wwwroot.
:: call kuduSync -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
:: FIXME: add git to exclude again
call kuduSync -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i "'

:: stuff to be done AFTER copying to live site
:: basically everything with db access
:: like platform.sh deploy step
echo Running TYPO3 CMS deployment hooks.

cd %HOME%\site\wwwroot
call vendor\bin\typo3cms install:setup --non-interactive --useExistingDatabase --admin-user-name="admin" --admin-password="password" --site-setup-type="site" --site-name="TYPO3 on Azure"

:: cmd script handling - ignore
:: everything fine end is at the bottom of file
goto end

:: something bad did happen, that should not be
:error
echo An error has occurred during custom TYPO3 CMS deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul
:: signal composer extension that something is awry
:exitSetErrorLevel
exit /b 1
:exitFromFunction
()

:end
echo Custom TYPO3 CMS deployment finished.
:: signal composer extension that everything is fine
EXIT /b 0
