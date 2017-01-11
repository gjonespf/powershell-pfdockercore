#Load ps1 scripts in current dir
Get-ChildItem $psscriptroot\PFDockerCore-*.ps1 | ForEach-Object { . $_.FullName }
