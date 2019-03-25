# This module is designed to offer tools to better acquire hardware inventory of computers which are PS Remoting enabled. 

Function New-Inventory {
	<#
		.SYNOPSIS
		A function to create an inventory of hardware. 

		.DESCRIPTION
		A function which utilizes multithreading to build a new, or append an existing, csv file with inventory information.	

		.PARAMETER ComputerNames
		Enter the full file path of a .txt file containing a list of computer names.	

		.PARAMETER Credentials 
		A parameter to pass local or domain administrator credentials	

		.PARAMETER MaxLocalThreads 
		The maximum number of threads on the local server to use.

		.PARAMETER MaxRemoteThreads
		The maximum number of threads to use on the remote computers when pulling information. 

		.PARAMETER CsvPath
		Submit the full path of where to output the CSV inventory file.		

		.EXAMPLE
		New-Inventory -ComputerNames $List -Credentials $Creds -MaxLocalThreads 8 -MaxRemoteThreads 4 -CsvPath $HOME\Desktop\PSInventory.csv	

		.NOTES
		This function allows for the user to specify the number of threads used. Please use with caution. If you do not know, either select a number between 1 and 4
	#>
	Param (
		[Parameter (
			Mandatory = $True,
			HelpMessage = "Please enter a text file containing a list of computer names."
		)]
		[System.String[]]$ComputerNames,

		[Parameter (
			Mandatory = $True,
			HelpMessage = "Please enter your administrator credentials." 
		)]
		[System.Management.Automation.CredentialAttribute()]$Credentials,

		[Parameter (
			Mandatory = $False
		)]
		[int]$MaxLocalThreads = 1,

		[Parameter (
			Mandatory = $False
		)]
		[int]$MaxRemoteThreads = 1,

		[Parameter (
			Mandatory = $True,
			HelpMessage = "Please enter the destination for the CSV File"
		)]
		[System.String]$CsvPath,
		
		[Parameter (
			Mandatory = $False,
			HelpMessage = "Please enter True or False"
		)]
		[bool]$StopWatch = $False
	)

	BEGIN {
		IF ($StopWatch -eq $True) {
			$Clock = [System.Diagnostics.StopWatch]::New()
			$Clock.Start() 
		}
		# Creating pool for threads and then creating a container for threads.	
		$RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxLocalThreads)
		$RunspacePool.Open()
		$Threads = [System.Collections.ArrayList]::New()
	}

	PROCESS {
		TRY {
			Write-Debug -Message "Attempting to add instructions to threads."
			$ComputerNames | Foreach {
				# Creating powershell session for each thread and assigning it to the pool.
				$Powershell = [powershell]::Create()
				$Powershell.RunspacePool = $RunspacePool
				[void]$Powershell.AddScript({
					Param (
						[System.String]$PC,
						[System.Management.Automation.CredentialAttribute()]$Cred,
						[int]$MaxRemoteThreads 
					)
					TRY {
						# Trying to connect to individual PC. If PC fails, will immediatly move on. 
						$Session = New-PSSession -ComputerName $PC -Credential $Cred -ErrorAction Stop
						$DataPull = Invoke-Command -Session $Session -ScriptBlock {
							$Cred = $using:Cred 
							$MaxThreads = $using:MaxRemoteThreads 
							$RSPool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads)
							$RSPool.Open() 
							$ThreadContainer = [System.Collections.ArrayList]::New() 

							# Pulling ComputerSystem Info	
							$PS1 = [powershell]::Create() 
							$PS1.RunspacePool = $RSPool
							[void]$PS1.AddScript({
								$PC = Get-CimInstance -ClassName CIM_ComputerSystem 
								Write-Output $PC 
							})
							$H1 = $PS1.BeginInvoke()
							$T1 = [System.String]::Empty
							$T1 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null 
							$T1 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T1 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T1 = $T1 | Select-Object -Property Powershell, Handle, Tag
							$T1.Powershell = $PS1
							$T1.Handle = $H1
							$T1.Tag = 'PC'
							[void]$ThreadContainer.Add($T1) 

							# Pulling OS Information	
							$PS2 = [powershell]::Create()
							$PS2.RunspacePool = $RSPool
							[void]$PS2.AddScript({
								$OS = Get-CimInstance -ClassName CIM_OperatingSystem
								Write-Output $OS 
							})
							$H2 = $PS2.BeginInvoke()
							$T2 = [System.String]::Empty
							$T2 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T2 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T2 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T2 = $T2 | Select-Object -Property Powershell, Handle, Tag 
							$T2.Powershell = $PS2
							$T2.Handle = $H2 
							$T2.Tag = 'OS'
							[void]$ThreadContainer.Add($T2)

							# Pulling BIOS Information
							$PS3 = [powershell]::Create()
							$PS3.RunspacePool = $RSPool
							[void]$PS3.AddScript({
								$BIOS = Get-CimInstance -ClassName CIM_BIOSElement
								Write-Output $BIOS
							})
							$H3 = $PS3.BeginInvoke()
							$T3 = [System.String]::Empty
							$T3 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T3 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T3 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T3 = $T3 | Select-Object -Property Powershell, Handle, Tag
							$T3.Powershell = $PS3
							$T3.Handle = $H3
							$T3.Tag = 'BIOS'
							[void]$ThreadContainer.Add($T3)

							# Pulling Software List
							$PS4 = [powershell]::Create()
							$PS4.RunspacePool = $RSPool
							[void]$PS4.AddScript({
								$Software = Get-CimInstance -ClassName CIM_Product
								Write-Output $Software
							})
							$H4 = $PS4.BeginInvoke()
							$T4 = [System.String]::Empty
							$T4 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T4 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T4 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T4 = $T4 | Select-Object -Property Powershell, Handle, Tag
							$T4.Powershell = $PS4
							$T4.Handle = $H4
							$T4.Tag = 'Software'
							[void]$ThreadContainer.Add($T4)

							# Pulling Printer Info
							$PS5 = [powershell]::Create()
							$PS5.RunspacePool = $RSPool
							[void]$PS5.AddScript({
								$Printers = Get-CimInstance -ClassName CIM_Printer
								Write-Output $Printers
							})
							$H5 = $PS5.BeginInvoke()
							$T5 = [System.String]::Empty
							$T5 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T5 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T5 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T5 = $T5 | Select-Object -Property Powershell, Handle, Tag
							$T5.Powershell = $PS5
							$T5.Handle = $H5
							$T5.Tag = 'Printers'
							[void]$ThreadContainer.Add($T5) 

							# Pulling info for CPU
							$PS6 = [powershell]::Create()
							$PS6.RunspacePool = $RSPool
							[void]$PS6.AddScript({
								$CPU = Get-CimInstance -ClassName CIM_Processor
								Write-Output $CPU 
							})
							$H6 = $PS6.BeginInvoke()
							$T6 = [System.String]::Empty
							$T6 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T6 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T6 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T6 = $T6 | Select-Object -Property Powershell, Handle, Tag
							$T6.Powershell = $PS6
							$T6.Handle = $H6
							$T6.Tag = 'CPU'
							[void]$ThreadContainer.Add($T6)

							# Pulling info for C Drive
							$PS7 = [powershell]::Create()
							$PS7.RunspacePool = $RSPool
							[void]$PS7.AddScript({
								$HDD = Get-CimInstance -ClassName CIM_StorageVolume | Where-Object {$_.DriveLetter -eq 'C:'}
								Write-Output $HDD
							})
							$H7 = $PS7.BeginInvoke()
							$T7 = [System.String]::Empty
							$T7 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T7 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T7 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T7 = $T7 | Select-Object -Property Powershell, Handle, Tag
							$T7.Powershell = $PS7
							$T7.Handle = $H7
							$T7.Tag = 'Storage'
							[void]$ThreadContainer.Add($T7)

							# Pulling list of User accounts 
							$PS8 = [powershell]::Create()
							$PS8.RunspacePool = $RSPool
							[void]$PS8.AddScript({
								$Users = Get-ChildItem -Path C:\Users -Force | Where-Object {$_.Name -notlike "All*"} | Where-Object {$_.Name -notlike "Default*"} | Where-Object {$_.Name -notlike "*Public*"} | Where-Object {$_.Name -notlike "desktop.ini"}
								Write-Output $Users 
							})
							$H8 = $PS8.BeginInvoke()
							$T8 = [System.String]::Empty
							$T8 | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
							$T8 | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
							$T8 | Add-Member -MemberType NoteProperty -Name Tag -Value $Null
							$T8 = $T8 | Select-Object -Property Powershell, Handle, Tag 
							$T8.Powershell = $PS8
							$T8.Handle = $H8 
							$T8.Tag = 'Users'
							[void]$ThreadContainer.Add($T8)

							DO {
								$ThreadContainer | Foreach {
									IF ($_.Handle.IsCompleted -eq $True) {
										$PSID = $_.Powershell.InstanceID.Guid
										IF ($_.Tag -eq 'PC') {
											$PC = $_.Powershell.EndInvoke($_.Handle) 
										} ELSEIF ($_.Tag -eq 'OS') {
											$OS = $_.Powershell.EndInvoke($_.Handle)
										} ELSEIF ($_.Tag -eq 'BIOS') {
											$BIOS = $_.Powershell.EndInvoke($_.Handle) 
										} ELSEIF ($_.Tag -eq 'Software') {
											$Software = $_.Powershell.EndInvoke($_.Handle) 
										} ELSEIF ($_.Tag -eq 'Printers') {
											$Printers = $_.Powershell.EndInvoke($_.Handle) 
										} ELSEIF ($_.Tag -eq 'CPU') {
											$CPU = $_.Powershell.EndInvoke($_.Handle) 
										} ELSEIF ($_.Tag -eq 'Storage') {
											$Storage = $_.Powershell.EndInvoke($_.Handle) 
										} ELSEIF ($_.Tag -eq 'Users') {
											$Users = $_.Powershell.EndInvoke($_.Handle)
										}
										$ThreadContainer = $ThreadContainer | Where-Object {$_.Powershell.InstanceID.Guid -ne $PSID} 
										$_.Powershell.Dispose() 
									}
								}
							} until ($ThreadContainer -eq $Null)
							$RSPool.Close()
							$RSPool.Dispose() 

							$Hash = @{
								ComputerName = $env:COMPUTERNAME
								Manufacturer = $PC.Manufacturer
								Model = $PC.Model
								SerialNumber = $BIOS.SerialNumber 
								CurrentUser = $PC.Username 
								BuildNumber = $OS.BuildNumber 
								OSArchitecture = $OS.OSArchitecture
								LastRestart = $OS.LastBootUpTime 
								TotalRAM = $PC.TotalPhysicalMemory / 1GB
								CPU = $CPU.Name
								Printers = $Printers.Name 
								Software = $Software.Name 
								TotalStorage = $Storage.Capacity / 1GB
								AvailableStorage = $Storage.FreeSpace / 1GB 
								UserProfiles = $Users
								TotalProfiles = $Users.Count
							}
							$Object = New-Object -TypeName psobject -Property $Hash 
							Write-Output $Object 
						}
						Write-Output $DataPull 
					} CATCH {
						Start-Sleep -Milliseconds 10 
					}
				})
				$Hash = @{
					PC = $_
					Cred = $Credentials
					MaxRemoteThreads = $MaxRemoteThreads
				}
				[void]$Powershell.AddParameters($Hash)
				$Handle = $Powershell.BeginInvoke() 
				$Container = [System.String]::Empty 
				$Container | Add-Member -MemberType NoteProperty -Name Powershell -Value $Null
				$Container | Add-Member -MemberType NoteProperty -Name Handle -Value $Null
				$Container | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Null
				$Container = $Container | Select-Object -Property Powershell, Handle, ComputerName 
				$Container.Powershell = $Powershell
				$Container.Handle = $Handle
				$Container.ComputerName = $_ 
				[void]$Threads.Add($Container) 
			}
		} CATCH {
			Write-Verbose -Message "Could not spin up threads." 
		} 
	}

	END {
		$Data = [System.Collections.ArrayList]::New()
		DO {
			$Threads | Foreach {
				IF ($_.Handle.IsCompleted -eq $True) {
					$PSID = $_.Powershell.InstanceID.Guid
					$Line = $_.Powershell.EndInvoke($_.Handle)
					$Line | Export-Csv -Path $CsvPath -Append -Force
					[void]$Data.Add($Line)
					$_.Powershell.Dispose()
					$Threads = $Threads | Where-Object {$_.Powershell.InstanceID.Guid -ne $PSID}
				}
			}
		} until ($Threads -eq $Null) 

		$RunspacePool.Close()
		$RunspacePool.Dispose() 
		Write-Output $Data 
		IF ($StopWatch -eq $True) {
			$Clock.Stop()
			Write-Output $Clock.Elapsed
		}
	}
}
