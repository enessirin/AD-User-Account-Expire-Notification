Param(
     [Parameter(Mandatory=$true)]
     [string]$days,
     [Parameter(Mandatory=$true)]
     [string]$SMTPServer,
     [Parameter(Mandatory=$true)]
     [string]$SMTPFrom,
     [Parameter(Mandatory=$true)]
     [string]$SMTPTo,
     [Parameter(Mandatory=$true)]
     [string]$MessageSubject
 )

try{Import-Module ActiveDirectory -ErrorAction Stop
Write-Host "ActiveDirectory Module is imported" -ForegroundColor Green}
catch{Write-Host "ActiveDirectory Module could not be imported" -ForegroundColor Red
break}

$accounts = Get-ADUser -Filter {userAccountControl -ne "514"} -Properties accountExpires,userAccountControl,Description

$today = Get-Date
$expired = New-Object System.Collections.Generic.List[System.Object]
$expired.Add("Account,ExpiredDate,Description") 

ForEach ($account in $accounts){
$name = $account.Name
$desc = $account.Description
if($account.accountExpires -eq "9223372036854775807"){$expired.Add("$name, ,$desc")}
else{
$dateexpires = [datetime]::FromFileTime($account.accountexpires)
if($today -gt $dateexpires.AddDays($days)) {$expired.Add("$name,$dateexpires,$desc") }
}
}

$exphtml = $expired | ConvertTo-Html


$messageexp = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
$messageexp.Subject = $messageSubject

$messageexp.IsBodyHTML = $true

$body = $expired | ForEach{[PSCustomObject]@{'Expired User Accounts'=$_}} | ConvertTo-Html -Fragment -Property "Expired User Accounts"


$messageexp.Body = $body -replace ",","</td><td>"
$smtp = New-Object Net.Mail.SmtpClient($smtpServer)

$smtp.Send($messageexp)
