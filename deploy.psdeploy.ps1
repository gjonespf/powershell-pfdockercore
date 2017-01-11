# Generic module deployment.
# This stuff should be moved to psake for a cleaner deployment view

# ASSUMPTIONS:

 # folder structure of:
 # - RepoFolder
 #   - This PSDeploy file
 #   - ModuleName
 #     - ModuleName.psd1

 # Nuget key in $ENV:NugetApiKey

#Deploy to local repo
if(
    $env:BHProjectName -and $env:BHProjectName.Count -eq 1 -and
    $env:BHBuildSystem -eq 'Unknown' -and
    $env:BHBranchName -eq "master"
)
{
    Deploy Module {
        By FileSystem {
            FromSource $ENV:BHProjectName
            To '$($ENV:BHProjectName)/../0Repo'
        }
    }
}

 # Set-BuildEnvironment from BuildHelpers module has populated ENV:BHProjectName

# Publish to gallery with a few restrictions
if(
    $env:BHProjectName -and 
    $env:BHBuildSystem -ne 'Unknown' -and
    $env:BHBranchName -match "master" -and
    $env:BHCommitMessage -match '!deploy'
)
{
    Deploy Module {
        By PSGalleryModule {
            FromSource $ENV:BHProjectName
            To PSGallery
            WithOptions @{
                ApiKey = $ENV:NugetApiKey
            }
        }
        # By PSGalleryModule {
        #     FromSource $ENV:BHProjectName
        #     To PSGallery
        #     WithOptions @{
        #         ApiKey = $ENV:NugetApiKey
        #     }
        # }
    }
}
else
{
    "Skipping gallery deployment: To deploy, ensure that...`n" +
    "`t* Project name is set (Current: $ENV:BHProjectName)`n" +
    "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
    "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
    "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)" |
        Write-Host
}
