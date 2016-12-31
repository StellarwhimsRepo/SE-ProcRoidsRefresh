<#
    Tostito's Space Engineers Procedural Asteroid Refresh Script
    ============================================
    
    DESCRIPTION:
    Refreshes Procedural Asteroids. Thanks to Spyder for the original roid refresh script.
    Find things near Asteroids! (findThingsNearRoids 500) Thanks psycore!

    INFO:
    Without adjustment this script will not do anything!
    I normally use it within the PowerShell ISE so I can hit play, issue commands directly, then saveIt

    GENERAL USAGE:
    First, edit the powershell .ps1 file and change the saveLocation to suit your server's save path.

    COMMAND USAGE:

    proceduralrefreshroids Command. This refreshes any procedural roid meeting the parameters you specify.
    Syntax:    proceduralrefreshroids [distance required from player ship/station grids] [Total Files Size]
    
    Example:   proceduralrefreshroids 500 8   -Refresh any roid if player grids farther than 500 and if total roid cache in folder is greater than 8MB
    
    saveIt command. Saves your changes.

    Example:   proceduralrefreshroids 500 8
               saveit
#>

Param(
    # I've changed how this works. Now you just need to point it to your entire save folder. It is assumed that all your .vx2, .sbc and .sbs files are in here
    [string]$saveLocation = "your save path here",
    $regex = "([^_]+$)"
)

function quit! {EXIT}

function saveIt {
    $saveFile = "$saveLocation\SANDBOX_0_0_0_.sbs"
    $smallFile = "$saveLocation\Sandbox.sbc"
    $mapXML.Save($saveFile)
    $configXML.Save($smallFile)
    Write-Host -ForegroundColor Green "SAVED!!"

  Write-Host -ForegroundColor DarkYellow ""
  Write-Host -ForegroundColor DarkYellow "For a command list use - 'listcommands'"
}

function listcommands {
    write-output "
    
    COMMAND USAGE:

    proceduralrefreshroids Command. This refreshes procedural asteroids.
    Syntax:    proceduralrefreshroids [distance from grids] [Total Files Size (MB)]

    Save it Command. This commits changes you have made to the save file.
    Syntax:    saveIt

    quit! / exit Command, Quits this tool.

    "
  Write-Host -ForegroundColor DarkYellow ""
  Write-Host -ForegroundColor DarkYellow "For a command list use - 'listcommands'"
}


function findThingsNear {
    [decimal]$x = $args[0]; [decimal]$y = $args[1]; [decimal]$z = $args[2]; [decimal]$dist = $args[3] #Set and Clear Variables
    $desc = $args[1] ; $onOff = $args[0]  #Set and Clear Variables
    if ($x -eq $null) {
        Write-Output "No X passed to findThingsNear command.." | Out-Null
    } elseif ($y -eq $null) {
        Write-Output "No Y passed to findThingsNear command.." | Out-Null
    } elseif ($z -eq $null) {
        Write-Output "No Z passed to findThingsNear command.." | Out-Null
    } elseif ($dist -eq $null) {
        Write-Output "No distance passed to findThingsNear command.." | Out-Null
    } else {
        $cubeGrids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]" ,$mapNS)
        foreach ($cubeGrid in $cubeGrids) {
            #Just for readability sake, not really nessessary...
            [decimal]$checkX = $cubeGrid.PositionAndOrientation.Position.x; [decimal]$xLo = ($x - $dist); [decimal]$xHi = ($dist + $x)
            [decimal]$checkY = $cubeGrid.PositionAndOrientation.Position.y; [decimal]$yLo = ($y - $dist); [decimal]$yHi = ($dist + $y)
            [decimal]$checkZ = $cubeGrid.PositionAndOrientation.Position.z; [decimal]$zLo = ($z - $dist); [decimal]$zHi = ($dist + $z)
            if ($checkX -gt $xLo -and $checkX -lt $xHi) {
                # X coord in range
                if ($checkY -gt $yLo -and $checkY -lt $yHi) {
                    # Y coord in range
                    if ($checkZ -gt $zLo -and $checkZ -lt $zHi) {
                        #Z coord in range - we have a winner!
                        $cubeGrid
                    }
                    #else{$null}
                }
                #else{$null}
            }
            #else{$null}
        }
    }
  Write-Host -ForegroundColor DarkYellow ""
  Write-Host -ForegroundColor DarkYellow "For a command list use - 'listcommands'"
}
function proceduralrefreshroids {
$dist = $args[0] #Set and Clear Variables
$filesize = $args[1]
$roidsfiles = Get-ChildItem -recurse -include *.vx2 $saveLocation
$totalSize = ($roidsfiles | Measure-Object -Sum Length).Sum / 1MB
if ($totalSize -gt $filesize){
    if ($dist -gt 0) {
        $roids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_VoxelMap')]" ,$mapNS)
        foreach ($roid in $roids) {
        #IF($roid.StorageName -eq 'Asteroid_*'){
            $response = $null
            $response = @(findThingsNear $roid.PositionAndOrientation.Position.x $roid.PositionAndOrientation.Position.y $roid.PositionAndOrientation.Position.z $args[0])
            ForEach($found in $response){
            $found.DisplayName
            }
            [decimal]$response.count
            if ($response.count -eq 0 <#-or $response.count -eq $null#>) {
                Write-Output "Nothing found near $($roid.StorageName)"
                $removeRoid = "$saveLocation\$($roid.StorageName).vx2"
                $removeRoidOld = "$saveLocation\$($roid.StorageName).vox"
                #$originalRoid = "$origLocation\$($roid.StorageName).vx2"
                
                    Write-Output "Refreshing Roid $($roid.StorageName)"
                    Remove-Item $removeRoid -Force
                    Remove-Item $removeRoidOld -Force -ea SilentlyContinue
                    $roid.ParentNode.RemoveChild($roid)
                
            } else {
                Write-Output "Blocking structures found, skipped $($roid.StorageName)"
            }
        #}
        }
    #check session components for seed parameterdata. cleans up previously left over data as well.
    $count = 0

    $asteroidseedparms = $configXML.SelectNodes("//SessionComponents/MyObjectBuilder_SessionComponent[(@xsi:type='MyObjectBuilder_WorldGenerator')]/ExistingObjectsSeeds/MyObjectSeedParams/Seed" , $confNS)
    $existingroids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_VoxelMap')]/StorageName" , $mapNS) 
    
    $groups = $asteroidseedparms | Group-Object InnerText #| ForEach-Object{$_.Group[0]}
        #purge duplicate seeds
        ForEach($dupegroup in $groups){
                        $next = 0
                        $next = ($dupegroup.group.count) - 1
                ForEach($dupenode in $dupegroup.Group){
                    If($dupegroup.group.count -gt 1){
                        If($next -ne 0){
                        $dupenode.ParentNode.ParentNode.RemoveChild($dupenode.ParentNode)
                        $next --
                        #$dupenode.ParentNode.ParentNode
                        }
                }
            }
        }
    $asteroidseedparms = $configXML.SelectNodes("//SessionComponents/MyObjectBuilder_SessionComponent[(@xsi:type='MyObjectBuilder_WorldGenerator')]/ExistingObjectsSeeds/MyObjectSeedParams/Seed" , $confNS)

    ForEach($parm in $asteroidseedparms){

        $preserve = 0
        ForEach($roid in $existingroids){
            $extract = $null
            $extract = $roid.InnerText
            $extract = [regex]::match($extract,$regex)
            If($parm.InnerText -eq $extract){
                Write-Host -ForegroundColor Green " roid parms preserved "
                #sleep -Seconds 5
                $preserve = 1
                $count ++
            }
        }
        If($preserve -eq 0){
            Write-Host -ForegroundColor Yellow " removed old roid parm "
            #Write-Host -ForegroundColor Green " roid parms preserved "
            $parm.ParentNode.ParentNode.RemoveChild($parm.ParentNode)
        }
        

    }

    } else {
        Write-Output "No Distance passed to proceduralrefreshroids command"
    }
  saveIt
  Write-Host -ForegroundColor DarkYellow ""
  Write-Host -ForegroundColor DarkYellow "For a command list use - 'listcommands'"
}
}


#Load files...
Write-Output "Loading Map XML from $saveLocation... Please hold"
$mapXML = $null #Ditch previous map 
if ([xml]$mapXML = Get-Content $saveLocation\SANDBOX_0_0_0_.sbs -Encoding UTF8) {
    $mapNS = New-Object System.Xml.XmlNamespaceManager($mapXML.NameTable)
    $mapNS.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    Write-Output "Map loaded! Loading Config XML from $saveLocation... Please hold"
    $configXML = $null #Ditch previous config 
    if ([xml]$configXML = Get-Content $saveLocation\Sandbox.sbc -Encoding UTF8) {
        $confNS = New-Object System.Xml.XmlNamespaceManager($configXML.NameTable)
        $confNS.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
        Write-Output "Config loaded! Ready to work`n"
        Write-Host -ForegroundColor DarkYellow "For a command list use - 'listcommands'"

<#
 ==================================
 = BEGIN AUTOMATIC ACTION SECTION =
 ==================================
 Make your changes from here
#>

#refreshroids. uncomment this and the below saveIt to automatically refresh roids when this is run.
#proceduralrefreshroids 500 8

#Commit changes, uncomment this if you want changes to be saved when the script is run
#saveIt


<#
  ================================
  = END AUTOMATED ACTION SECTION =
  ================================
  Make no changes past this point
#>


    } else {
        Write-Output "Config Load failed :( Check your saveLocation is correct? I attempted to load:"
        Write-Output "$saveLocation\Sandbox.sbc"
    }
} else {
    Write-Output "Map Load failed :( Check your saveLocation is correct? I attempted to load:"
    Write-Output "$saveLocation\SANDBOX_0_0_0_.sbs"
}

