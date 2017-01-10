#this is the script file used in the Java Usage Tracking Disable.cab.  
#This only for reference and is not needed otherwise.  This script is included in the .cab file.

$LogFile = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\SMS\Client\Configuration\Client Properties" -Name "Local SMS Path").'Local SMS Path' + "Logs\CM_JavaUsageLogging.log"
$LoggingEnable = $True

########################################################################################################## 
 
Function Log-ScriptEvent { 
#Thank you Ian Farr https://gallery.technet.microsoft.com/scriptcenter/Log-ScriptEvent-Function-ea238b85 
#Define and validate parameters 
[CmdletBinding()] 
Param( 
      #The information to log 
      [parameter(Mandatory=$True)] 
      [String]$Value, 
 
      #The severity (1 - Information, 2- Warning, 3 - Error) 
      [parameter(Mandatory=$True)] 
      [ValidateRange(1,3)] 
      [Single]$Severity 
      ) 
 
 
#Obtain UTC offset 
$DateTime = New-Object -ComObject WbemScripting.SWbemDateTime  
$DateTime.SetVarDate($(Get-Date)) 
$UtcValue = $DateTime.Value 
$UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21) 
 
 
#Create the line to be logged 
$LogLine =  "<![LOG[$Value]LOG]!>" +`
            "<time=`"$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)`" " +`
            "date=`"$(Get-Date -Format M-d-yyyy)`" " +`
            "component=`"Java Compliance`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Severity`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">" 
 
#Write the line to the passed log file 
Add-Content -Path $LogFile -Value $LogLine 
 
} 


IF ($LoggingEnable -eq $true) {Log-ScriptEvent -Value "Starting Java logging discovery." -Severity 1}

#Disable Java logging by enumerating the JREs from the registry
#using $_ because this could be run on PS 2.0 and $PSItem isn't a thing yet in PS2.0 
#32 bit  and 64 bit instances of Java on a 64 bit machine.
$JREPaths = "HKLM:\Software\WOW6432Node\JavaSoft\Java Runtime Environment","HKLM:\Software\JavaSoft\Java Runtime Environment"
$JREPaths | ForEach-Object {
     if(Test-Path $_)
    {
        $Keys = Get-ChildItem $_
        $JREs = $Keys | Foreach-Object {Get-ItemProperty $_.PsPath }
        ForEach ($JRE in $JREs) 
        {
            IF ($LoggingEnable -eq $true) {Log-ScriptEvent -Value "Interogating JRE path $($JRE.JavaHome)" -Severity 1}
            $JREPath = test-path "$($JRE.JavaHome)\lib\management"
            if ($JREPath) {
                $UTProps = test-path "$($JRE.JavaHome)\lib\management\usagetracker.properties"
                if ($UTProps) { #JUT is enabled
                    IF ($LoggingEnable -eq $true) {Log-ScriptEvent -Value "Deleting $($JRE.JavaHome)\lib\management\usagetracker.properties" -Severity 1}
                    Remove-Item -Path "$($JRE.JavaHome)\lib\management\usagetracker.properties" -Force
                    $true
                } Else {
                    IF ($LoggingEnable -eq $true) {Log-ScriptEvent -Value "$($JRE.JavaHome)\lib\management\usagetracker.properties does not exist" -Severity 1}
                    $true
            }
            }
        }
    }
}
