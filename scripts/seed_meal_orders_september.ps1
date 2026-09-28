$connStr = "Server=localhost,1433;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

# 20 phòng ban đặt cơm theo template và database
$departments = @(
    @{ Code = "GA";       Lunch = 18; OtDay = 3;  Dinner = 0; OtNight = 0; User = "NV002" },
    @{ Code = "HR";       Lunch = 15; OtDay = 2;  Dinner = 0; OtNight = 0; User = "NV001" },
    @{ Code = "ACC";      Lunch = 12; OtDay = 3;  Dinner = 0; OtNight = 0; User = "NV003" },
    @{ Code = "EX";       Lunch = 14; OtDay = 4;  Dinner = 0; OtNight = 0; User = "NV004" },
    @{ Code = "IT";       Lunch = 10; OtDay = 2;  Dinner = 0; OtNight = 0; User = "ADMIN" },
    @{ Code = "HSE";      Lunch = 12; OtDay = 2;  Dinner = 1; OtNight = 1; User = "NV005" },
    @{ Code = "PUR";      Lunch = 10; OtDay = 1;  Dinner = 0; OtNight = 0; User = "NV006" },
    @{ Code = "QC";       Lunch = 32; OtDay = 8;  Dinner = 6; OtNight = 4; User = "NV007" },
    @{ Code = "MA";       Lunch = 20; OtDay = 5;  Dinner = 3; OtNight = 2; User = "NV008" },
    @{ Code = "WH";       Lunch = 28; OtDay = 7;  Dinner = 5; OtNight = 3; User = "NV009" },
    @{ Code = "3IN1";     Lunch = 35; OtDay = 10; Dinner = 8; OtNight = 5; User = "NV010" },
    @{ Code = "VPSX";     Lunch = 22; OtDay = 6;  Dinner = 4; OtNight = 3; User = "NV011" },
    @{ Code = "VB";       Lunch = 25; OtDay = 6;  Dinner = 5; OtNight = 3; User = "NV012" },
    @{ Code = "KTSP";     Lunch = 16; OtDay = 4;  Dinner = 2; OtNight = 1; User = "NV013" },
    @{ Code = "KTSX";     Lunch = 24; OtDay = 6;  Dinner = 5; OtNight = 3; User = "NV014" },
    @{ Code = "SALE";     Lunch = 12; OtDay = 1;  Dinner = 0; OtNight = 0; User = "NV015" },
    @{ Code = "KHSX";     Lunch = 14; OtDay = 3;  Dinner = 1; OtNight = 1; User = "NV016" },
    @{ Code = "DRIVER";   Lunch = 8;  OtDay = 3;  Dinner = 2; OtNight = 1; User = "NV017" },
    @{ Code = "SECURITY"; Lunch = 6;  OtDay = 2;  Dinner = 4; OtNight = 3; User = "NV018" },
    @{ Code = "KOREAN";   Lunch = 8;  OtDay = 3;  Dinner = 0; OtNight = 1; User = "NV019" }
)

# Xóa các đơn đặt cơm cũ trong khoảng từ 01/09/2026 đến 18/09/2026 để nạp lại chuẩn xác
$cmdClean = $conn.CreateCommand()
$cmdClean.CommandText = "DELETE FROM DepartmentMealOrders WHERE OrderDate >= '2026-09-01' AND OrderDate <= '2026-09-18';"
$rowsCleaned = $cmdClean.ExecuteNonQuery()
Write-Host "Cleaned $rowsCleaned existing records in date range."

$tran = $conn.BeginTransaction()

try {
    for ($day = 1; $day -le 18; $day++) {
        $dateStr = "2026-09-{0:D2}" -f $day
        $dt = [DateTime]::ParseExact($dateStr, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
        $isSunday = ($dt.DayOfWeek -eq [DayOfWeek]::Sunday)
        $isSaturday = ($dt.DayOfWeek -eq [DayOfWeek]::Saturday)

        foreach ($dept in $departments) {
            # Tính toán biến động nhẹ theo từng ngày để số liệu sinh động thực tế
            $ratio = 1.0
            if ($isSunday) {
                $ratio = 0.55 # Chủ nhật ít người làm hơn
            } elseif ($isSaturday) {
                $ratio = 0.85 # Thứ bảy ca làm việc ngắn hơn
            } else {
                # Ngày thường: biến động +/- 5%
                $variation = (($day * 7 + $dept.Code.Length) % 5) - 2 # -2 to +2
                $ratio = 1.0 + ($variation * 0.02)
            }

            $lunch = [Math]::Max(1, [int][Math]::Round($dept.Lunch * $ratio))
            $otDay = [Math]::Max(0, [int][Math]::Round($dept.OtDay * $ratio))
            $dinner = [Math]::Max(0, [int][Math]::Round($dept.Dinner * $ratio))
            $otNight = [Math]::Max(0, [int][Math]::Round($dept.OtNight * $ratio))
            $veg = [Math]::Min($lunch, [int][Math]::Round($lunch * 0.08)) # ~8% ăn chay

            # Đối với ngày hôm nay (18/09/2026):
            # Cơm trưa: tất cả 20 PB đều chốt (20/20 PB)
            # Cơm chiều: 16/20 PB chốt
            # Cơm đêm: 11/20 PB chốt
            # Cơm sáng: 8/20 PB chốt
            $lockLunch = 1
            $lockDayOt = if ($day -lt 18) { 1 } elseif ($dept.OtDay -gt 2) { 1 } else { 0 }
            $lockDinner = if ($day -lt 18) { 1 } elseif ($dept.Dinner -gt 2) { 1 } else { 0 }
            $lockNightOt = if ($day -lt 18) { 1 } elseif ($dept.OtNight -gt 2) { 1 } else { 0 }

            $cmd = $conn.CreateCommand()
            $cmd.Transaction = $tran
            $cmd.CommandText = @"
INSERT INTO DepartmentMealOrders (
    OrderDate,
    DepartmentCode,
    DayLunchCount,
    DayOtCount,
    NightDinnerCount,
    NightOtCount,
    VegetarianCount,
    Note,
    OrderedBy,
    IsLockedDayLunch,
    IsLockedDayOt,
    IsLockedNightDinner,
    IsLockedNightOt,
    CreatedAt
) VALUES (
    @OrderDate,
    @DepartmentCode,
    @DayLunchCount,
    @DayOtCount,
    @NightDinnerCount,
    @NightOtCount,
    @VegetarianCount,
    @Note,
    @OrderedBy,
    @IsLockedDayLunch,
    @IsLockedDayOt,
    @IsLockedNightDinner,
    @IsLockedNightOt,
    @CreatedAt
);
"@
            $cmd.Parameters.AddWithValue("@OrderDate", $dt) | Out-Null
            $cmd.Parameters.AddWithValue("@DepartmentCode", $dept.Code) | Out-Null
            $cmd.Parameters.AddWithValue("@DayLunchCount", $lunch) | Out-Null
            $cmd.Parameters.AddWithValue("@DayOtCount", $otDay) | Out-Null
            $cmd.Parameters.AddWithValue("@NightDinnerCount", $dinner) | Out-Null
            $cmd.Parameters.AddWithValue("@NightOtCount", $otNight) | Out-Null
            $cmd.Parameters.AddWithValue("@VegetarianCount", $veg) | Out-Null
            $cmd.Parameters.AddWithValue("@Note", "Đăng ký suất ăn định kỳ tháng 09/2026") | Out-Null
            $cmd.Parameters.AddWithValue("@OrderedBy", $dept.User) | Out-Null
            $cmd.Parameters.AddWithValue("@IsLockedDayLunch", $lockLunch) | Out-Null
            $cmd.Parameters.AddWithValue("@IsLockedDayOt", $lockDayOt) | Out-Null
            $cmd.Parameters.AddWithValue("@IsLockedNightDinner", $lockDinner) | Out-Null
            $cmd.Parameters.AddWithValue("@IsLockedNightOt", $lockNightOt) | Out-Null
            $cmd.Parameters.AddWithValue("@CreatedAt", $dt.AddHours(8)) | Out-Null

            $cmd.ExecuteNonQuery() | Out-Null
        }
    }

    $tran.Commit()
    Write-Host "Successfully seeded meal order test data from 2026-09-01 to 2026-09-18 for 20 departments!"
} catch {
    $tran.Rollback()
    Write-Error "Error seeding data: $_"
} finally {
    $conn.Close()
}
