. .\Register.ps1

# Test variables
$testScriptPath = $scriptPath
$testLogonTaskName = "Test_Logon_Task"
$testScheduleTaskName = "Test_Schedule_Task"

# Clean up existing test tasks
Get-ScheduledTask -TaskName $testLogonTaskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false
Get-ScheduledTask -TaskName $testScheduleTaskName -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false

# Test logon trigger
Write-Host "Testing logon trigger registration..."
$logonResult = Register-ScheduledTaskTriggerAfterLogon -TaskName $testLogonTaskName -ScriptPath $testScriptPath
Write-Host "Logon task registration result: $logonResult"

# Test schedule trigger
Write-Host "Testing schedule trigger registration..."
$scheduleResult = Register-ScheduledTaskTriggeredOnSchedule -TaskName $testScheduleTaskName -ScriptPath $testScriptPath -IntervalMinutes 10
Write-Host "Schedule task registration result: $scheduleResult"

# Verify tasks exist
$logonTaskExists = Get-ScheduledTask -TaskName $testLogonTaskName -ErrorAction SilentlyContinue
$scheduleTaskExists = Get-ScheduledTask -TaskName $testScheduleTaskName -ErrorAction SilentlyContinue

Write-Host "Logon task exists: $($logonTaskExists -ne $null)"
Write-Host "Schedule task exists: $($scheduleTaskExists -ne $null)"

# Clean up when done
Write-Host "Cleaning up test tasks..."
if ($logonTaskExists) { Unregister-ScheduledTask -TaskName $testLogonTaskName -Confirm:$false }
if ($scheduleTaskExists) { Unregister-ScheduledTask -TaskName $testScheduleTaskName -Confirm:$false }