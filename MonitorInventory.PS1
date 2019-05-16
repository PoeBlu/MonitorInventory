
# Site configuration
$SiteCode = "" # Site code 
$ProviderMachineName = "" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# Edit Query ID:
$Results = Invoke-CMQuery -Id 

$QueryResults = @()

Foreach ($Result in $Results)
{
    
    $Obj = [PSCustomObject]@{
    'Serial' = $($Result.SMS_G_System_WMIMONITORID.SerialNumberID);
    'Manufacturer' = $($Result.SMS_G_System_WMIMONITORID.ManufacturerName);
    'Model' = $($Result.SMS_G_System_WMIMONITORID.ProductCodeID);
    'Computer' = $($Result.SMS_R_System.Name);
    'HWInvDate' = $($Result.SMS_G_System_WORKSTATION_STATUS.LastHardwareScan);
    'lastLogonUser' = $($Result.SMS_R_System.LastLogonUserName);
    }
    If($Obj.Manufacturer -ne "LEN")
    {
        $QueryResults += $Obj
    }
    
}

# Put monitors from your preferred Asset DB in this variable:
# in my enviroment, serials is stored in a property called AssetSerial - adjust the script below to fit yours.
$Monitors = ""

Foreach ($QueryResult in $QueryResults)
{
    $Model = ""
    $Manufacturer = ""
    $CimaMonitor = ""
    If ($QueryResult.Manufacturer -eq "DEL")
    {
        $Partnumber = ($QueryResult.Serial).Substring(0,5)
        $DateCode = ($QueryResult.Serial).Substring(5,3)
        $ManufacturerCode = ($QueryResult.Serial).Substring(8,4)

        $FirstPart = $Partnumber
        $LastPart = $DateCode + "-" + $ManufacturerCode

        $Monitor = $Monitors | where {$_.AssetSerial -like "*$LastPart"}

        $Manufacturer = "Dell"
    }
    If ($QueryResult.Manufacturer -eq "PHL")
    {
        $FirstPart = ($QueryResult.Serial).Substring(0,3)
        $LastPart = ($QueryResult.Serial).Substring(3,10)

        $Monitor = $Monitors | where {$_.AssetSerial -like "*$FirstPart*$LastPart*"}
        $Manufacturer = "Philips"
    }
        If ($QueryResult.Manufacturer -eq "HWP")
    {
        $Monitor = $Monitors | where {$_.AssetSerial -eq "$($QueryResult.Serial)"}
        $Manufacturer = "HP"

    }
    
    #This is where you would put the code to store the last user in your DB
    $($Monitor)
    $($Manufacturer)
    $($QueryResult.HWInvDate)
    $($QueryResult.lastLogonUser)
     

}
