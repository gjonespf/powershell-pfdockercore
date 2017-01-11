# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
        $ProjectRoot = $ENV:BHProjectPath
        if(-not $ProjectRoot)
        {
            $ProjectRoot = $PSScriptRoot
        }

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if($ENV:BHCommitMessage -match "!verbose")
    {
        $Verbose = @{Verbose = $True}
    }
}

Task Default -Depends Deploy

Task Init {
    Set-Location $ProjectRoot
    $lines
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"

    Try
    {
        # Load the module, read the exported functions, update the psd1 FunctionsToExport
        Set-ModuleFunctions

        # Bump the module version
        Update-Metadata -Path $env:BHPSModuleManifest
        $Version = Get-Metadata -Path $ENV:BHPSModuleManifest -PropertyName ModuleVersion

        $Content = Get-Content "$ProjectRoot\CHANGELOG.md" | Select-Object -Skip 2
        $CommitMessage = (git log --format=%B -n 2) | Where-Object {$_}
        #Filter commands if starting line
        $CommitMessage = $CommitMessage | Where-Object { $_ -notmatch "^!deploy" -and $_ -notmatch "^!verbose"} 
        $NewContent = @('# $($ENV:BHProjectName) Release History','',"## $($Version)", "### $(Get-Date -Format MM/dd/yyy)", @($CommitMessage),'','',@($Content))
        $NewContent | Out-File -FilePath "$ProjectRoot\CHANGELOG.md" -Force -Encoding ascii

        # Update Release Notes
        Update-Metadata -Path $ENV:BHPSModuleManifest -PropertyName ReleaseNotes -Value @(Get-Content -Path "$ProjectRoot\CHANGELOG.md") 
    }
    Catch
    {
        Throw
    }
}

Task Test -Depends Init  {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $TestResults = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    If($ENV:BHBuildSystem -eq 'AppVeyor')
    {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            "$ProjectRoot\$TestFile" )
    }

    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends Test {
    $lines

    if ($ENV:BHBuildSystem -eq 'Unknown')
    {
        "$lines`n`n`tSTATUS: Building Local Module"

        Try 
        { 
            Invoke-PSDeploy @Verbose -Tags Local -Force 
        }
        Catch 
        { 
            Throw 
        }
    } 
}

Task Deploy -Depends Build {
    $lines

    $Params = @{
        Path = "$ProjectRoot"
        Force = $true
        Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
    }
    Invoke-PSDeploy @Verbose @Params
}