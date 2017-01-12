#TODO: Test for requisite tools, e.g. docker command

function Update-DockerInfraNetworks
{
  param(
    [Parameter(Position=0)]
    $Cfg = $(throw "The parameter -Cfg is required.")
  )

    $dockerNetworksTxt=$(docker network ls)
    $dockerNetworks = Convert-TextColumnsToObject $dockerNetworksTxt
    $cfgnets = $Cfg.Network.psobject.properties | Where-Object {$_.MemberType -eq 'NoteProperty'} | Select-Object -ExpandProperty Value

    foreach($net in $cfgnets)
    {
        if(!($dockerNetworks | Where-Object{ $_.NAME -eq $net.Name })) {
            $netname=$net.Name
            Write-Host "Creating missing network '$netname'"
            $test=(docker network create --driver $net.Driver $net.Name)
        }
    }
}

function Update-DockerInfraVolumes
{
  param(
    [Parameter(Position=0)]
    $Cfg = $(throw "The parameter -Cfg is required.")
  )

    $dockerVolumesTxt=$(docker volume ls)
    $dockerVolumes = Convert-TextColumnsToObject $dockerVolumesTxt
    $cfgvols = $Cfg.Volume.psobject.properties | Where-Object {$_.MemberType -eq 'NoteProperty'} | Select-Object -ExpandProperty Value

    foreach($vol in $cfgvols)
    {
        if( !($dockerVolumes | Where-Object{ $_."VOLUME NAME" -eq $vol.Name}) )  {
            $volname=$vol.Name
            if($vol.Options) {
                Write-Host "Creating missing volume '$volname' options '$($vol.Options)'"
                $tmp=(docker volume create --name $vol.Name --driver $vol.Driver -o $vol.Options)
            } else {
                Write-Host "Creating missing volume '$volname'"
                $tmp=(docker volume create --name $vol.Name --driver $vol.Driver)
            }

        }
    }
}

function Test-DockerRunningInContainer()
{
    if(Test-Path "/.dockerenv") {
        return $true
    }
    return $false
}

Export-ModuleMember -function Update-DockerInfraNetworks
Export-ModuleMember -function Update-DockerInfraVolumes
Export-ModuleMember -function Test-DockerRunningInContainer



