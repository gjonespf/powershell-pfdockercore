Import-Module PSDepend
Invoke-PSDepend -Path .\requirements.psd1 -Target .\PSDeps -Force -Install -Import

Set-BuildEnvironment

Invoke-psake .\build\psake.ps1
exit ( [int]( -not $psake.build_success ) )