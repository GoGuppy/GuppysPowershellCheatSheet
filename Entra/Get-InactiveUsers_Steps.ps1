# ============================================================
# STEP 1 - Install the Graph module (only need to do this once)
# ============================================================
Install-Module Microsoft.Graph -Scope CurrentUser


# ============================================================
# STEP 2 - Connect to Graph
# ============================================================
Connect-MgGraph -Scopes "User.Read.All", "AuditLog.Read.All"


# ============================================================
# STEP 3 - Pull all enabled users + filter licensed & inactive
# ============================================================
$Users = Get-MgUser -All `
    -Filter "accountEnabled eq true" `
    -Property "displayName, userPrincipalName, signInActivity, assignedLicenses"

$Users.Count


# ============================================================
# STEP 4 - Filter to licensed + inactive (60+ days)
# ============================================================
$InactiveUsers = $Users | Where-Object {
    $_.AssignedLicenses.Count -gt 0 -and (
        -not $_.SignInActivity -or
        [datetime]$_.SignInActivity.LastSignInDateTime -lt (Get-Date).AddDays(-60)
    )
}

$InactiveUsers.Count


# ============================================================
# STEP 5 - View results + export to CSV
# ============================================================
$InactiveUsers | Select-Object DisplayName, UserPrincipalName,
    @{ Name = "LastSignIn"; Expression = {
        if ($_.SignInActivity) { $_.SignInActivity.LastSignInDateTime } else { "Never" }
    }} |
    Sort-Object LastSignIn |
    Format-Table -AutoSize

$InactiveUsers | Select-Object DisplayName, UserPrincipalName,
    @{ Name = "LastSignIn"; Expression = {
        if ($_.SignInActivity) { $_.SignInActivity.LastSignInDateTime } else { "Never" }
    }} |
    Export-Csv -Path ".\InactiveUsers_$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation

Write-Host "Done. $($InactiveUsers.Count) inactive users exported." -ForegroundColor Green
