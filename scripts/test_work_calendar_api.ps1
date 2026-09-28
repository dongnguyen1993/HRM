$ErrorActionPreference = "Stop"

Write-Host "=== 1. LOGIN ADMIN ==="
$loginBody = @{
    userCode = "ADMIN"
    password = "123456"
} | ConvertTo-Json

$loginRes = Invoke-RestMethod -Uri "http://localhost:7014/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $loginRes.data.accessToken
Write-Host "Login successful!"

$headers = @{
    Authorization = "Bearer $token"
}

Write-Host "`n=== 2. GET MONTH CALENDAR (09/2026) ==="
$res = Invoke-RestMethod -Uri "http://localhost:7014/api/work-calendar/month?year=2026&month=9" -Method Get -Headers $headers
Write-Host "Total days in month: $($res.data.Count)"
$res.data | Select-Object -First 5 | Format-Table CalendarDate, DayNumber, DayOfWeekVi, DayType, ShiftCodes, HasSpecialMeal, SpecialMealPrice

Write-Host "`n=== 3. BATCH SPECIAL MEAL SETUP ==="
$specialMealBody = @{
    dates = @("2026-09-22", "2026-09-23")
    mealTypes = @("DAY_LUNCH", "NIGHT_DINNER")
    price = 35000
    note = "Suat an du an dac biet"
    removeSpecialMeal = $false
} | ConvertTo-Json

try {
    $batchRes = Invoke-RestMethod -Uri "http://localhost:7014/api/work-calendar/special-meal/batch" -Method Post -Body $specialMealBody -ContentType "application/json; charset=utf-8" -Headers $headers
    Write-Host "Batch Special Meal Result: $($batchRes.message)"
} catch {
    $stream = $_.Exception.Response.GetResponseStream()
    $reader = [System.IO.StreamReader]::new($stream)
    Write-Host "ERROR RESPONSE: $($reader.ReadToEnd())" -ForegroundColor Red
    throw
}

Write-Host "`n=== 4. VERIFY UPDATED DATES ==="
$resUpdated = Invoke-RestMethod -Uri "http://localhost:7014/api/work-calendar/month?year=2026&month=9" -Method Get -Headers $headers
$specialDays = $resUpdated.data | Where-Object { $_.calendarDate -in @("2026-09-22", "2026-09-23") }
$specialDays | Format-Table CalendarDate, DayType, HasSpecialMeal, SpecialMealTypes, SpecialMealPrice, SpecialMealNote

Write-Host "`n=== 5. UPDATE DAY SHIFT (2026-09-22 -> HOLIDAY) ==="
$shiftBody = @{
    date = "2026-09-22"
    dayType = "HOLIDAY"
    shiftCodes = @()
} | ConvertTo-Json

$shiftRes = Invoke-RestMethod -Uri "http://localhost:7014/api/work-calendar/day-shift" -Method Put -Body $shiftBody -ContentType "application/json" -Headers $headers
Write-Host "Update Day Shift Result: $($shiftRes.message)"

Write-Host "`n=== 6. VERIFY DAY SHIFT ==="
$resHoliday = Invoke-RestMethod -Uri "http://localhost:7014/api/work-calendar/month?year=2026&month=9" -Method Get -Headers $headers
$holidayDay = $resHoliday.data | Where-Object { $_.calendarDate -eq "2026-09-22" }
$holidayDay | Format-Table CalendarDate, DayType, ShiftCodes, HasSpecialMeal, SpecialMealTypes

Write-Host "`n=== 7. RESTORE (WORKDAY) ==="
$restoreBody = @{
    date = "2026-09-22"
    dayType = "WORKDAY"
    shiftCodes = @("SHIFT_DAY", "SHIFT_NIGHT")
} | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:7014/api/work-calendar/day-shift" -Method Put -Body $restoreBody -ContentType "application/json" -Headers $headers | Out-Null
Write-Host "Restored successfully!"
