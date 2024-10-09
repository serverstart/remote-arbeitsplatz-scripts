# Script to define regional settings on Azure Virtual Machines deployed from the market place
# Locale: German (Germany)
# Author: Original script by Alexandre Verkinderen

# Define the German regional settings XML inline
$RegionalSettingsContent = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
    <!--User List-->
    <gs:UserList>
        <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/> 
    </gs:UserList>
    <!-- user locale -->
    <gs:UserLocale> 
        <gs:Locale Name="de-DE" SetAsCurrent="true"/> 
    </gs:UserLocale>
    <!-- system locale -->
    <gs:SystemLocale Name="de-DE"/>
    <!-- GeoID -->
    <gs:LocationPreferences> 
        <gs:GeoID Value="94"/> 
    </gs:LocationPreferences>
    <gs:MUILanguagePreferences>
        <gs:MUILanguage Value="de-DE"/>
        <gs:MUIFallback Value="en-US"/>
    </gs:MUILanguagePreferences>
    <!-- input preferences -->
    <gs:InputPreferences>
        <!--de-DE-->
        <gs:InputLanguageID Action="add" ID="0407:00000407" Default="true"/> 
    </gs:InputPreferences>
</gs:GlobalizationServices>
"@

# Save the regional settings to C:\RERegion.xml
$RegionalSettings = "C:\RERegion.xml"
[System.IO.File]::WriteAllText($RegionalSettings, $RegionalSettingsContent)

# Set Locale, language, etc.
& $env:SystemRoot\System32\control.exe "intl.cpl,,/f:`"$RegionalSettings`""

# Set languages/culture
Set-WinSystemLocale de-DE
Set-WinUserLanguageList -LanguageList de-DE -Force
Set-Culture -CultureInfo de-DE
Set-WinHomeLocation -GeoId 94
Set-TimeZone -Name "W. Europe Standard Time"

# Cleanup: Remove the regional settings file after the configuration
Remove-Item $RegionalSettings -Force
