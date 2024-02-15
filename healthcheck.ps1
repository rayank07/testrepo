# This is v3 master bot with report name passed from $healthCheckName  variable and report name back ground colour is changed from white to Blue 
#Attributes used - WHCIP (windows Health check In progress) , SNR ( Server Not Rechable), WHCC(Windows health check Completed) , SR(Server rechable),SB_WHCI(StandaloneBots windowsHealthCheck In progress),SB_WHCS(StandaloneBots windowsHealthCheck success)

#Made change on  1) Previously we use to get the health check config data from a table , but now we will getting it in a single cell of config data table in json form , 
#This script we have remove the reporting part so that it can be merge with AD health check - 17-02-2023
#changed made on 20-02-23 - while calling the function(callDbApi) we are now passing (-sqlQuery) instead of (-query) , just the name has changed 
<#
$dbServerName = "localhost"
$dbPort = "3306"
$dbUsername = "root"
$dbPassword = "root"
$dbDatabaseName = "bib_clientv1"
#$dbSqlDllPath = "C:\Program Files (x86)\MySQL\MySQL Connector Net 8.0.20\Assemblies\v4.5.2\MySql.Data.dll"
$dbSqlDllPath = "C:\Program Files (x86)\MySQL\Connector NET 8.0\Assemblies\v4.5.2\MySql.Data.dll"#>

$serverListPath="C:\ADC_Automation\ADC2023-4948 BIB_V2_windows_HealthCheck\bots\Windows-HealthChecks\Healthcheck\PrePostChecks-without-BIB\InputFiles\ServerListFile.csv"
$serverList = Import-Csv $serverListPath 






<#################### The below value will be getting from Mfoo ###############

$serverList = "localhost","newServer"
$username = "rayank-rishi.goswami@capgemini.com"
$password = " " | ConvertTo-SecureString -AsPlainText -Force
$client_id = '1'
$bot_id = '1004'
$bot_version = "1.0"
#>


$MyCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password 
#$runID = "WHC"+$runID 
#################### Below variable are use in ENE API calling ###############




#$botName ="Windows HealthCheck"
#$region  = "UK"
$healthCheckName = "Windows Healthcheck Report"
$currentDate = Get-Date
#$runID = "WHC"+$currentDate.ToString("yyyyMMddHHmmss")
#$runIdInitial = "WHC20230210025108"



####################### Getting basefolder path from script itself  ############################
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework
$drive=(gwmi win32_operatingsystem).systemdrive
$curr_date = Get-Date -Format "yyyyMMdd_HHmmss"
if ([System.IO.Path]::GetExtension($PSCommandPath) -eq '.ps1') {
    $psScriptPath = $PSCommandPath
} 
else 
{
    # This enables the script to be compiles and get the directory of it.
    $psScriptPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}
$basefolder = $psScriptPath | Split-Path | Split-Path
#$basefolder = "C:\Users\tmulani\PrePostChecks"
$microbotFolder = "$baseFolder\MicroBots"


########## Prepost Check intialization #############################################################
$todayMonth = (Get-Date).ToString("MMMM yyyy",[CultureInfo]::CreateSpecificCulture("en-IN"))
$baseFolder = $baseFolder
$microbotFolder = "$baseFolder\MicroBots"
$currentDate = (Get-Date).ToString("dd-MM-yyyy",[CultureInfo]::CreateSpecificCulture("en-IN"))
$currentTime = (Get-Date).ToString("hh-mm",[CultureInfo]::CreateSpecificCulture("en-IN"))
$currentMonthYear = (get-date).ToString("MMMM yyyy",[CultureInfo]::CreateSpecificCulture("en-IN"))
$outPutFolder = "$baseFolder\Output Files\$currentDate"
if (!(Test-Path $outputFolder))
{ $newFolder = New-Item $outputFolder -Force -ItemType Directory }
$htmlFilePath = "$outPutFolder\$healthCheckName"+"_"+$currentDate+"_"+$currentTime+".html"
#$comparisonhtmlFilePath = "$baseFolder\Output Files\$currentDate\PrePostCheck_Comparision_$currentDate_$currentTime.html"


################### Initialisting variables ########################## 
$requiredColumns = $null
$failedServers = $null
$colNameHTML = $null
$colNamesHTML = $null
$rowValsHTML = $null
$outputString = $null
$functionStack = @{}
$scriptString = $null
$rowValsFinalHTML = $null
$rowValsHTML = $null
$rowValsFinalHTMLfailed = $null
$rowvalsfinalhtml2 = $null
$rowValsFinalHTML = $null
$rowval = $null
$finalrequiredColumns = $null
#$prePostCheck = $prePostCheck
$comparisonColumns = $null
$colourCodeCols = $null
$finalrequiredColumns = $null
$finalrequiredPrePostChecksValues = $null

$emailBotSmtpAddress = $null
$emailBotFromAddress = $null
$emailBotToAddress = $null
$emailBotCcAddress = $null
$emailBotSubject = $null
$comparisonHtml = $null
$execution_start_time = $null
$execution_end_time = $null
$insertMasterStarted = $null


$redColor = "#ff0000"
$yellowColor = "#FFFF00"
$greenColor = "#00b300"





$coldelimiter = ";"
$rowdelimiter="~"
$reportHeading = "$healthCheckName Report"






############# For importing Crypto Module ##########################

$crptoPath="$baseFolder"+"\LicenceAndCryptoModule\crypto.psm1"
Import-Module $crptoPath

################# Script Key ######################################

$secKey=(1..32)

$licensekey="76492d1116743f0423413b16050a5345MgB8AHgAYgBIAHIAaQBWADYANQA3ADYAQQBzAFQAMQBTAEYAYwBiAEgAZABYAGcAPQA9AHwAMwBlADkAMwBhADMANgBkAGYAOQA1ADcAOQBlADYANgAwADIANABlADUANQBlAGMAMwA0ADYAMABiAGEAZAA5ADEAMAAwAGEAZgAxADEAYgBiADgAYwAyADMAZABiAGMAOQBhADIAMwBhADgAMAAxADAAMwBkAGYANgBkADQANwA4ADEAOQBjADAAMAA1AGUAYwA2ADQAZgBiAGYAMwAwAGYANgA1ADEAYwBlAGIANABiAGMAYgA1ADQANAA2ADcAYwAzADAAZQAzADMAZAA5ADAANgA3AGUAZQAzADYANwBkADQAYQA1AGIAOQBkAGYANwBmAGQAOQAxADgAMwA3AGUAZQBjADgAZABlADUANgAwADMAMQAyADEANgBlAGQAMgAwADQAYgA0ADkAOAAxAGEANgBjADkAZAA4AGYAYgA2ADEAYgAyAGQAMwA5AGIAMAAxAGUAYwBjADMANAA2AGEAZgA3ADcANwA1AGYAMQBmAGUAMwAwADEAOAAzADYA"|ConvertTo-SecureString -Key $secKey
$scriptkey="76492d1116743f0423413b16050a5345MgB8AGgAdQAyAHAAbgBzADIASwAwAHMAYQBEAGgAZAArAGwAOABKAEQAUwBYAEEAPQA9AHwAMQA2AGEANgAwADAANgA1ADYAMwA2AGUAYgAyADgAYgA5AGYANABlADkANABhADcAYwA5AGUAMgAxADgAMgAyADkAMABiAGEAZQAyADUANgAzADUAMwA3ADAAYgAzADQANAA5AGUAOQA2AGEANAA1AGYAYgA4ADkAMABkAGQAZgBhADkANQA2AGMAMQBiAGQAMwA0AGYAYgAxAGEANwA2ADcAMwA5ADMAOQBmADgAYQBmADUAYwA4ADIAYgAyAGIANwBjADAAZABlAGIAZgAxADIAYwA2ADAAOQA0ADgANQA4AGIAZgAyADMAMQBhADAAMQAxADIAYgAwAGIAMgA5ADcAZQA0AGEAZQBhADEAZgA2AGMAOQBlADQANQAxAGIAZgAxADEANQA4ADkANAA4AGEAYQAzADMAMgAxAGUAOAA4ADIANQA1AGYAMwBkAGMAZgA2AGUAZABkADUAZgAzADYAZAA1AGUAOABlADQAOQAxAGIAZQBlADgAOQAwADcA"|ConvertTo-SecureString -key $secKey


####################################################################

##### decrypting and importing microbots
foreach($file in (get-childitem -Path $microbotFolder| Where-Object {$_.Extension -Like '.AES'}))
{

    Unprotect-File $file.FullName -Algorithm AES -Key $scriptkey -ErrorAction Stop|Out-Null 
    
   $powershellFile = ($file.FullName).Replace('.AES','')
   #$powershellFile
   . $powershellFile
  Remove-Item -Path $powershellFile

}




$botName = "Windows Health Check"




$emailBotFromAddress = "tasmiya.mulani@capgemini.com"
$region = "UK"
$emailBotSmtpAddress = "smtp.office365.com"
$customer = "CSL"




$emailBotToAddress = "tasmiya.mulani@capgemini.com"
$emailBotCcAddress = "tasmiya.mulani@capgemini.com"


$source_system = hostName
$target_endPoint = "RAS"









$credname = "OS_Patching_TargetCreds"

$todayDate = ((Get-Date).AddDays(0)).ToString('dd-MM-yyyy',[CultureInfo]::CreateSpecificCulture("en-IN"));

$emailBotSubject = " $customer Wintel $healthCheckName Report - $todayDate "

$mail_content = @"
         <!doctype html>
                <html>
                <head>
                
        </head>
        <div>
            <p style="font-family: 'Calibri';font-size: 12pt";font-weight:normal><span class='notbold'>Hello Team,</span></p>
            <p style="font-family: 'Calibri';font-size: 12pt";font-weight:normal>Please find the attached $healthCheckName Report .</p>
        </div>
         <div>
             <p style='margin:0cm;margin-bottom:.0001pt;font-size:15px;font-family:"Calibri",sans-serif;margin-top:6.0pt;'><span style="color:black;">Thanks &amp; Regards,</span></p>
<p style='margin-right:0cm;margin-left:0cm;font-size:15px;font-family:"Calibri",sans-serif;margin:0cm;margin-bottom:.0001pt;'><span style='font-size:13px;color:black;'>Automation Team</span></p>
        </div>
        </html> 

"@

########################################################################################################

### Code Level Variables ###
$todayShortDate = (Get-Date).ToString("dd-MM-yyyy",[CultureInfo]::CreateSpecificCulture("en-IN"))
$todayDate = (Get-Date).ToString("dd_MM_yyyy__hh_mm",[CultureInfo]::CreateSpecificCulture("en-IN"))
$serverLogFolder = "$baseFolder\Logfiles"




$logFileName  = $healthCheckName

$logFolderWithCurrentDate = "$serverLogFolder\$todayShortDate"
$create = createNewFolderOrFile -path $logFolderWithCurrentDate
$logPath = "$logFolderWithCurrentDate\$logFileName.log"

$create = createNewFolderOrFile -path $logPath  #logfileCreation



######## db config intialization  ################################
$columnNames = $null
$requiredColumns = [ordered]@{}

$colorCodingColumns = $null
$requiredColorCodeColumns = [ordered]@{}

$comparisonColumns = $null
$requiredComparisonColumns = [ordered]@{}

$specialValuesColumns = $null
$requiredSpecialValuesColumns = [ordered]@{}




######################## Getting PrepostConfig Details from updated table (windowsHealthCheck ) where all the functionality is coming from a single column in Json form  #########################
################## Getting table details via dpAbi #########

#$configQuery = "SELECT * From windowsHealthCheckConfig"

$windowsHealthCheckConfig = Get-Content -Path "C:\ADC_Automation\ADC2023-4948 BIB_V2_windows_HealthCheck\bots\Windows-HealthChecks\Healthcheck\PrePostChecks-without-BIB\InputFiles\PrePostCheck.txt"
#$windowsHealthCheckConfig

### Below line use to get functionality details from from windowsHealthCheckConfigTable
if($windowsHealthCheckConfig)
{
$availableDbData  = $windowsHealthCheckConfig | ConvertFrom-Json 
"This details we are getting from windowsHealthCheckConfig table which are in json form "
$availableDbData 
}

#$availableDbData >> "C:\Automation\test.txt"



#$columnNames = $availableDbData.Columns.ColumnName
$columnNames = $availableDbData.psobject.properties.name

foreach($Column in $columnNames){

if (($availableDbData."$Column" -eq 'Y') -and !($Column.EndsWith("Comp"))){


$requiredColumns.Add("$Column",$availableDbData."$Column")

}
else{
    "$column ends with Comp"
}

}




$colorCodingColumns = $columnNames | Where-Object {$_.EndsWith("CC")} 

#$requiredColorCodeColumns = [ordered]@{}

$requiredColumns.Keys | ForEach-Object{


$configColumn = $_


$colorCodingColumns | ForEach-Object { 


    if(($availableDbData."$_" -ne 'N') -or ($availableDbData."$_" -ne 'NA'))
     {

        if($_.Contains($configColumn)){



            $singleCcValues = @{}
            
            $successValue = $availableDbData."$_".Split(":")[0] 
            $failureValue = $availableDbData."$_".Split(":")[1] 

            $finalCcCoulmn = $_

            switch($finalCcCoulmn){


        
        cpuUsagePercentCC{
        
        $singleCcValues.Add("success","$successValue")
        $singleCcValues.Add("Failure","$failureValue")
        $singleCcValues.Add("operator","le")
        
        }
        
        cpuCoresCC{
        
        $singleCcValues.Add("success","$successValue")
        $singleCcValues.Add("Failure","$failureValue")
        $singleCcValues.Add("operator","ge")
        
        }
    
        CDriveFreeSpaceGBCC{

        $singleCcValues.Add("success","$successValue")
        $singleCcValues.Add("Failure","$failureValue")
        $singleCcValues.Add("operator","ge")
        
        }
        
        totalMemoryGBCC{
        $singleCcValues.Add("success","$successValue")
        $singleCcValues.Add("Failure","$failureValue")
        $singleCcValues.Add("operator","ge")
        
        }
    
        freeMemoryGBCC{

        $singleCcValues.Add("success","$successValue")
        $singleCcValues.Add("Failure","$failureValue")
        $singleCcValues.Add("operator","ge")
        
        } 

            
        usedMemoryPercentCC{
        $singleCcValues.Add("success","$successValue")
        $singleCcValues.Add("Failure","$failureValue")
        $singleCcValues.Add("operator","ge")
        
        }

        
        }
            
             $requiredColorCodeColumns.Add("$configColumn",$singleCcValues)
            }   

        }
    
}

}




#Getting special values and creating dictionary

$specialValuesColumns = $columnNames | Where-Object {$_.EndsWith("SV")} 
$requiredSpecialValuesColumns = [ordered]@{}


$requiredColumns.Keys | ForEach-Object {

$configColumn = $_


$specialValuesColumns | ForEach-Object{

        if(($availableDbData."$_" -ne 'N') -or ($availableDbData."$_" -ne 'NA'))
     {


        if($_.Contains($configColumn)){
        

        
        $requiredSpecialValuesColumns.Add("$configColumn",$availableDbData."$_")   
        
        
        }

     }   
}

}



############################# Script Start ######################################################


########################### Function Declarations ####################################################################


#Funct
Function Build-FunctionStack 
{
    param([ref]$dict, [string]$FunctionName)
   
   ($dict.Value).Add((Get-Item "Function:${FunctionName}").Name, (Get-Item "Function:${FunctionName}").Scriptblock)
}






$finalRequiredColumns =($requiredColumns.Keys) -join ";"
$FinalColumns = "ServerName;"+$finalRequiredColumns
#"final required columns $finalRequiredColumns"
$colourCodeCols = $requiredColorCodeColumns.Keys -join ";"
#$comparisonColumns = $requiredComparisonColumns.Keys -join ";"
#$finalComparisionColumns = "SeverName;"+$comparisonColumns


if($FinalColumns.contains("allDriveDetails")){

$FinalColumns = $FinalColumns.Replace("allDriveDetails;","driveName;totalSpaceGB;freeSpaceGB;freeSpacePercent;")

}






################## get success and Failure values from DB ############



$scriptString += "`n"+'param([Hashtable]$FunctionStack)'+"`n"



foreach($colName in $finalRequiredColumns.Split(";"))
{


    if( ($colName.Contains("mandatoryServices")) -or ($colName.Contains("restartServices"))-or ($colName.Contains("portCheck"))){ #-or ($colName.Contains("pathSpaceGB")) -or ($colName.Contains("CdiskCleanUp")) 
        $specialValue = $null
        $specialValue = $requiredSpecialValuesColumns.$colName
        $colName
        Build-FunctionStack -dict ([ref]$functionStack) -FunctionName "$colName"
        $scriptString += '$'+ $colName + '=([Scriptblock]::Create($functionStack["'+ $colName +'"])).invoke(' +"'"+ "$specialValue" +"'" + ')'
        $scriptString += "`n"+'$'+ $colName +"`n"

       
       
    
    }
    elseif($colName.Contains("extraCommands")){
    
    $commandList = $availableDbData."extraCommandsSV"
    
    Build-FunctionStack -dict ([ref]$functionStack) -FunctionName "$colName"
    $scriptString += '$'+ $colName + '=([Scriptblock]::Create($functionStack["'+ $colName +'"])).invoke(' +"'"+ "$commandList" +"'" + ')'
    $scriptString += "`n"+'$'+ $colName +"`n"
    
    }


    else{
    
    
    Build-FunctionStack -dict ([ref]$functionStack) -FunctionName "$colName"
    $scriptString += '$'+ $colName + '=([Scriptblock]::Create($functionStack["'+ $colName +'"])).invoke()'
    $scriptString += "`n"+'$'+ $colName +"`n"
    
    }


}


$StringToSB = $ExecutionContext.InvokeCommand.NewScriptBlock($scriptString)
#$StringToSB.GetType()
#$StringToSB.Invoke()

#logging -Message " ################################# $healthCheckName  ################################## " -Path $logPath -Level Info


$keys = $functionStack.Keys

$MaxThreads = 10
$allJobs = @()


foreach($server in $serverList.Name){
    
   
    
      $jobNamePrecheck= $server + $healthCheckName


    While (@(Get-Job | Where { $_.State -eq "Running" }).Count -ge $MaxThreads)
       {  #Write-Host "Waiting for open thread...($MaxThreads Maximum)"
          Start-Sleep -Seconds 3
         
       }
     # Get-job completed | split serverName to update the E&E table exceutionTime ( will get server wise details for health check ) 
    # may need to call Dbapi to update E&E table 
    
    $alljobs += Invoke-Command -ComputerName $server  -ScriptBlock $StringToSB -ArgumentList $functionStack -AsJob -JobName $jobNamePrecheck -EnableNetworkAccess #-Credential $MyCredential
}





While (@(Get-Job | Where { $_.State -eq "Running" }).Count -ne 0)
{  #Write-Host "Waiting for background jobs..."
   #Get-Job    #Just showing all the jobs
   Start-Sleep -Seconds 3
}

Start-Sleep -Seconds 10

foreach($server in $serverList.Name)
{

   <# if($prePostCheck -match 'post')
    {
         $jobNamePrecheck = $server + 'Postcheck'
        
    }
    else
    {
        $jobNamePrecheck = $server + 'Precheck'
        
    }#>
    $jobNamePrecheck = $server + $healthCheckName
    if(((Get-Job) | Where { $_.Name -eq "$jobNamePrecheck" }).State -eq "Failed")
    {
        $rowval += "$server;"

        ################################ Update ENE serverwise for failure condition #############################################
            $job = Get-Job -Name "$jobNamePrecheck"
            #$startTime = $job.StartTime
            #$endTime = $job.Finished
            #$s = $job.PSBeginTime
            #$e = $job.PSEndTime
            $job_execution_start_time = ($job.PSBeginTime).ToString("dd-MM-yyyy HH:mm:ss")
            $job_execution_end_time = ($job.PSEndTime).ToString("dd-MM-yyyy HH:mm:ss")
            $job_execution_status ="Failed"
            $job_subexec_status = "SB_WHC_SNR"
            
            logging -Message  " Server wise failure condition for server $server" -Path $logPath -Level Info

            logging -Message  "Job Execution start time is : $job_execution_start_time and Job Execution end time is : $job_execution_end_time" -Path $logPath -Level Info
 
           
            






        
        

        logging -Message " ################################# $server ################################## " -Path $logPath -Level Info
        
        foreach($colName in $finalRequiredColumns.Split(";"))
        {
            
            if($colName -eq "Reachable")
            {
                $rowval+="No;"
                continue
            }
            $rowval+="-;"
            
            
        }
        $rowval = $rowval -replace ".$"
        logging -Message "$server Fail to access" -Path $logPath -Level Error
        ((Get-Job) | Where {$_.Name -eq "$jobNamePrecheck" }) | Remove-Job
        
    }
    
    else
    {
       
     ################################ Update ENE table serverwise for Success condition #############################################

        
         $job = Get-Job -Name "$jobNamePrecheck"
            #$startTime = $job.StartTime
            #$endTime = $job.Finished
            #$s = $job.PSBeginTime
            #$e = $job.PSEndTime
         $job_execution_start_time = ($job.PSBeginTime).ToString("dd-MM-yyyy HH:mm:ss")
         $job_execution_end_time = ($job.PSEndTime).ToString("dd-MM-yyyy HH:mm:ss")
         $job_execution_status ="Success"
         $job_subexec_status = "SB_WHC_SR"
         
         
         logging -Message  " Server wise success condition for server $server" -Path $logPath -Level Info

         logging -Message  "Job Execution start time is : $job_execution_start_time and Job Execution end time is : $job_execution_end_time" -Path $logPath -Level Info

         



        #$jobNamePrecheck = $server + 'Precheck'
        $rowValsHTML = ((Get-Job) | Where { $_.Name -eq "$jobNamePrecheck"}) | Receive-Job -erroraction SilentlyContinue
        ((Get-Job) | Where {$_.Name -eq "$jobNamePrecheck" }) | Remove-Job
        #$rowValsHTML
        $rowVal+=$server + ";"
        $insertPrePostQuery = $null
        $updatePrePostQuery = $null
        $prePostResults = [ordered]@{}
        #$prePostCheck = 'Pre'
        $prePostResults.Add("serverName",$server)
        
        logging -Message " ################################# $server ################################## " -Path $logPath -Level Info


#########################################################   Correct value till here    ####################################################################################################        
      
      
      
      
        for ($i=0; $i -lt ($rowValsHTML).length;$i++)
        {
  
            $successThreshold = $null
            $failureThreshold = $null
            $comparisionOperator = $null
            $flagColValue = $null
            $totalCc = $null
            
            if($i % 2 -eq 0)
            {

                
                if(!($rowValsHTML[$i+1]).Contains("error"))
                {
            
            
                    $flagColValue = ($rowValsHTML[$i+1].split(":")[0]).trim()
            
                    #$flagColValue.Contains("Services")
            
                    if($colourCodeCols.Contains($flagColValue))
                    {
                        
              
                        $totalCc = $requiredColorCodeColumns."$flagColValue"
            
            
                        $successThreshold = $totalCc.'success'
                        $failureThreshold = $totalCc.'Failure'
                        $comparisionOperator = $totalCc.'operator'
                        $actualValue = (($rowValsHTML[$i]).replace(";","")).trim()


                        <###############
                         $actualValue
                         $successThreshold
                         $failureThreshold
                         $comparisionOperator
                        ##########>
            
            
            
                        $rowVal += htmlColorCoding -actualValue $actualValue -success $successThreshold -failure $failureThreshold -comparisionOperator $comparisionOperator 
                        
                        $rowVal += ";"
            
                    }
            
                    elseif($flagColValue -match "Services")
                    {
            
                            $j = 0
                            $servicesHtml = $null
                            $services = $rowValsHTML[$i].split(",")
                            $services = $services.replace(";","")
            
                            for($j = 0; $j -lt ($services).length)
                            {

                                $temp = $j+5

                                $servicesHtml += "<p>"

                                while($j -lt $temp)
                                {

                                    if($services[$j])
                                    {
                                    
                                        $servicesHtml += $services[$j] +","
                                    
                                    }
                                    
                                    $j= $j+1

                                                
                                }

                                $servicesHtml = $servicesHtml -replace ".$"

                                $servicesHtml += "</p>"


                            }
            
                            $rowVal+= $servicesHtml +";"
                    }
                    else
                    {
            
                            $rowVal+= $rowValsHTML[$i]
                            #$rowVal
            
                    }
            
                    ##comparision db updation
            
                    $functionName = $rowValsHTML[$i+1].split(":").trim()[0]        
                    $ErrorActionPreference = 'silentlycontinue'  
                     
                    <#if($comparisonColumns.Contains($functionName))
                    {

                        $prePostResults.Add($functionName, $rowValsHTML[$i].replace(";",""))

                    }

                }
                else
                {
                    $rowVal+= $rowValsHTML[$i]
                }#>
            }
            
            else
            {
            
            
                if(!($rowValsHTML[$i]).Contains("error"))
                {
                $rowVal+= $rowValsHTML[$i]
                logging -Message $rowValsHTML[$i+1] -Path $logPath -Level Info
                
                    
                }
                else
                {
                 $rowVal+= $rowValsHTML[$i]
                 logging -Message $rowValsHTML[$i+1] -Path $logPath -Level Error
                    
                
                }

                
                
            }
            
            
        }

      
   }   
     #$rowval
      $rowVal = $rowVal -replace ".$"

   }
   $rowval+="~"
   }


$rowValsFinalHTML = $rowval
$rowValsFinalHTML = $rowValsFinalHTML -replace ".$"


$finalHtml = HtmlReport -columnValues $FinalColumns -rowvalues $rowValsFinalHTML -rowvaldelimiter $rowdelimiter -columndelimiter $coldelimiter -reportName $reportHeading

$finalHtml | Out-File -FilePath $htmlFilePath




<#
 $mailerror = $null
    try
    {
        $sendMail = Send-MailMessage -from $emailBotFromAddress -to $emailBotToAddress.split(",") -Cc $emailBotCcAddress.split(",") -Bcc $emailBotBccAddress.split(",")  -subject $emailBotSubject -bodyAsHtml $mail_content -smtpserver $emailBotSmtpAddress -port 25 -Attachments $htmlFilePath -Credential $MyCredential -UseSsl -ErrorVariable mailerror -ErrorAction SilentlyContinue
        if(!$mailerror)
        {
        logging -Message "Mail Sent" -Path $logPath -Level Info
        }
        else
        {
        logging -Message "Failed to send Mail and the error is : $mailerror" -Path $logPath -Level Error
        
        }
    }
    catch
    {
        $errorValue = $_
        logging -Message "Failed to send Mail with exception : $errorValue "  -Path $logPath -Level Error
    }
#>      
   



<#
$creds = Get-Credential

$a = Send-MailMessage -from $emailBotFromAddress -to $emailBotToAddress.split(",") -cc $emailBotCcAddress.Split(",")  -subject $emailBotSubject -bodyAsHtml $mail_content -smtpserver $emailBotSmtpAddress -port 25 -Credential $creds -UseSsl -Attachments $htmlFilePath #-ErrorVariable mailerror -ErrorAction SilentlyContinue

#>


$rowValsFinalHTML = $rowval

 
$Table1
$Column1
$reportName1 
$htmlFilePath
$logPath
$emailDetail
