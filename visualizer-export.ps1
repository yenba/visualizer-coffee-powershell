#---------------------------------------------------------------------------------------------
### Pull all shots from Visualizer for a specific user and export to CSV
#---------------------------------------------------------------------------------------------

# variable setup
$Credential = Get-Credential
$uri = "https://visualizer.coffee/api/shots/?page=1&items=100"
$counter = 0
$fullShotList = @()
$fullShotData = @()
$shotprogress = 0

#check how many pages you have and save to variable
$pageCheck = Invoke-RestMethod -Uri $uri -Method Get -Authentication Basic -Credential $Credential
$pageCount = $pageCheck.paging.pages

#get the shot ID's for each of your shots for all of your pages
do {
    $counter++
    Write-Host "Page counter is now at $counter"
    $uri = "https://visualizer.coffee/api/shots/?page=$counter&items=100"
    $shotList = Invoke-RestMethod -Uri $uri -Method Get -Authentication Basic -Credential $Credential  
    $fullShotList += $shotList.Data

} until ($counter -eq $pageCount)

#cycle through each shot and get the shot data
foreach ($shot in $fullShotList) {
    $shotprogress++
    $uri = "https://visualizer.coffee/api/shots/$($shot.id)/download?essentials=true"
    $shotData = Invoke-RestMethod -Uri $uri -Method Get
    #convert time from epoch time to local time and add to PS object
    $EpochTime = $shot.clock
    $DateTime = (([System.DateTimeOffset]::FromUnixTimeSeconds($EpochTime)).DateTime)
    $shotData | Add-Member -Name 'clock' -Value $datetime.ToLocalTime() -MemberType NoteProperty
    $fullShotData += $shotData
    Write-Host "$shotprogress/$($fullShotList.Count) - Finished with $($datetime.ToLocalTime()) - $($shotdata.profile_title) "
}

#output to a csv file depending on your OS

if ($IsMacOS) {
    $path = "$home/Downloads/visualizer_export.csv"
}
if ($IsWindows) {
    $path = "$home\Downloads\visualizer_export.csv"
}
$fullShotData | Select-Object "clock", "profile_title", "id", "user_id", "drink_tds", "drink_ey", "espresso_enjoyment", "bean_weight", "drink_weight", "grinder_model", "grinder_setting", "bean_brand", "bean_type", "roast_date", "espresso_notes", "roast_level", "bean_notes", "duration", "user_name", "image_preview", "profile_url" | Export-Csv -Path $path
