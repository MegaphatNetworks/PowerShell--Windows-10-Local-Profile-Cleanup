# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# #                                                                                                   # # 
# #                                                                                                   # # 
# #                                  The Windows 10 Local Profile Cleanup                             # # 
# #                                           by Gabriel Polmar                                       # # 
# #                                           Megaphat Networks                                       # # 
# #                                           www.megaphat.info                                       # #
# #                                                                                                   # # 
# #                                                                                                   # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
Clear

Function Say($something) {
	Write-Host $something 
}

Function SayB($something) {
	Write-Host $something -ForegroundColor darkblue -BackgroundColor white
}

Function SayN($something) {
	Write-Host $something -NoNewLine
}


$OSInfo = (Get-ComputerInfo)
$OSW32 = (Get-WMIObject win32_operatingsystem)

Function Wait ($secs) {
	if (!($secs)) {$secs = 1}
	Start-Sleep $secs
}

Function getOSArch() {
	Return ($OSW32.OSArchitecture.Replace("-bit",""))
}

Function isOSTypeHome {
	Return ($OSW32.Caption | select-string "Home")
}

Function isOSTypePro {
	Return ($OSW32.Caption | select-string "Pro")
}

Function isOSTypeEnt {
	Return ($OSW32.Caption | select-string "Ent")
}

Function getWinVer {
	Return $($OSW32.version)
}

Function getWinVerMajor {
	Return ($OSW32.version.substring(0,$OSW32.version.indexof(".")))
}

function getMachineType() {
	Return ($OSInfo.OsProductType)
}

function getWin10Ver {
	Return ($OSInfo.WindowsVersion)
}

function getPSVerMajor() {
	return ((Get-Host).Version.Major)
}

Function isAdminLocal {
	Return (new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole("Administrators")
}

Function isAdminDomain {
	Return (new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole("Domain Admins")
}

Function isElevated {
	Return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
}

Function regSet ($KeyPath, $KeyItem, $KeyValue) {
	$Key = $KeyPath.Split("\")
	ForEach ($level in $Key) {
		If (!($ThisKey)) {
			$ThisKey = "$level"
		} Else {
			$ThisKey = "$ThisKey\$level"
		}
		If (!(Test-Path $ThisKey)) {New-Item $ThisKey -Force -ErrorAction SilentlyContinue | out-null}
	}
	if ($KeyValue -ne $null) {
		Set-ItemProperty $KeyPath $KeyItem -Value $KeyValue -ErrorAction SilentlyContinue 
	} Else {
		Remove-ItemProperty $KeyPath $KeyItem -ErrorAction SilentlyContinue 
	}
}

Function regGet($Key, $Item) {
	If (!(Test-Path $Key)) {
		Return
	} Else {
		If (!($Item)) {$Item = "(Default)"}
		$ret = (Get-ItemProperty -Path $Key -Name $Item -ErrorAction SilentlyContinue).$Item
		Return $ret
	}
}

function File-Exists($tFile) {
	if (!(Test-Path $tFile)) {Return $false} Else {Return $true}
}

function Elevate() {
	Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`" elevate" -f $PSCommandPath) -Verb RunAs
}

function getADInfo() {
	try {
		$ret = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain())
		Say "Retrieved AD Information"
		Return $ret
	}
	catch {
		$ret = $false
		Return $ret
	}
}

function File-Exists($tFile) {
	if (!(Test-Path $tFile)) {Return $false} Else {Return $true}
}

# # # # # # # # # # # # # # # # # # # # 
# # # # BEGIN MAIN ROUTINES # # # # # # 
# # # # # # # # # # # # # # # # # # # #

if (!(isElevated)) {Elevate} Else {SayB "Executing with elevated permissions"}

$winMver = getWinVerMajor
Say "Windows Version is $winMver"

$psMver = getPSVerMajor
Say "PowerShell Version is $psMver"

$PCType   = getMachineType
Say "This computer is a $PCType"

$w10ver = getWin10Ver
Say "Windows 10 Version $w10ver"

$LocalProfiles = (Get-CimInstance -ClassName win32_userprofile) | Where {$_.Special -eq $false}
# LocalPath, LastuseTime, Loaded, Special
$adi = getADInfo
if ($adi -ne $false) {
	# DOMAIN COMPUTER
	$ThisAD = $adi.name
	$ThisDC = $adi.DomainControllers.Name
	$ThisForest = $ThisAD.SubString(0,$ThisAD.IndexOf("."))
	$ThisRoot = $ThisAD.Split('.')[-1]
	Say "Domain Name: $ThisAD"
	Say "Domain Controller: $ThisDC"
	SayN "Comparing : " ; SayN $ThisDC ; Say " against local system profiles."
	$ADUsers = Invoke-Command -ComputerName $ThisDC -ScriptBlock {Get-ADUser -Filter *} | 
		Where {$_.DistinguishedName -like "*OU=*"  -and $_.ObjectClass -eq "User" -and $_.DistinguishedName -like "*DC=$ThisForest*" -and $_.DistinguishedName -like "*DC=$ThisRoot*"}
	SayN "Found ";SayN ($ADUsers | where {$_.Enabled -eq $false}).Count;	SayN " Disabled User Accounts on ";	Say $adi.name
	SayN "Found ";SayN ($ADUsers | where {$_.Enabled -eq $true}).Count;	SayN " Enabled User Accounts on ";	Say $adi.name
	Say "Checking if disabled account profiles exist on computer"
	foreach ($rpro in ($ADUsers | where {$_.Enabled -eq $false})) {
		# SayN "Disabled by AD: "; $rpro.SamAccountName
		foreach ($lpro in $LocalProfiles) {
			# SayN "	Local: "; $lpro.LocalPath.split('\')[-1]
			$lUID = $lpro.LocalPath.split('\')[-1]
			$rUID = $rpro.SamAccountName
			if ($lUID -eq $rUID) {
				$TBRemove += @($lpro)
			}
		}
	}
	SayN $TBRemove.Count; Say " disabled AD account profiles detected on this machine."
}

Say 
Say "Scanning for Outdated Local Profiles"
$UsersOld = $LocalProfiles | Where {(!$_.Special) -and ($_.LastUseTime) -lt (Get-Date).AddDays(-182)} 
$msg = "Found " + $UsersOld.Count + " Old User Accounts"
Say $msg
ForEach ($oua in $UsersOld) {
	$TBRemove += @($oua)
}
ForEach ($TB in $TBRemove) {
	$LPath += @($TB.LocalPath)
	SayN "Path: " 
	$TB | select LocalPath, LastUseTime
}
$TBRemove  | Remove-CimInstance 
ForEach ($LP in $LPath) {
	if (File-Exists $LP) {
		Say "Removing Folder $LP"
		Remove-Item -Path $LP -Force -Recurse
	}
}
SayB "Finished"