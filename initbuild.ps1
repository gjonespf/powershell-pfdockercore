#Stuff to be run to initialise the build server, probably must be run as admin...

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

#PSDepend
Install-Module PSDepend
