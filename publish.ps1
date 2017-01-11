#Simple bootstrap deploy for testing
Import-Module PowerShellGet
$PSFeedName="potential-terminator-archer"
$PSRepoName="PowerFarming.Test"
$PSGalleryPublishUri = "https://www.myget.org/F/${PSFeedName}/api/v2/package"
$PSGallerySourceUri = "https://www.myget.org/F/${PSFeedName}/api/v2"
$APIKey = $env:NugetApiKey

#Write-Host $PSGalleryPublishUri

Register-PSRepository -Name $PSRepoName -SourceLocation $PSGallerySourceUri -PublishLocation $PSGalleryPublishUri
Publish-Module -Path ./PFDockerCore -NuGetApiKey $APIKey -Repository $PSRepoName -Verbose

Pause
