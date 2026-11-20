[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$loginBody = @{
    UserCode = 'admin'
    Password = 'Hansol@12345'
} | ConvertTo-Json

try {
    $loginRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/sys/auth/login' -Method Post -Body $loginBody -ContentType 'application/json'
    $token = $loginRes.data.accessToken
    Write-Host "[LOGIN SUCCESS] Token received (length: $($token.Length))"

    $headers = @{
        Authorization = "Bearer $token"
    }

    # 1. Test GET /api/hr/employees (paged)
    $paged = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees?pageNumber=1&pageSize=5' -Method Get -Headers $headers
    Write-Host "[API 1 SUCCESS] GET /api/hr/employees: TotalRecords = $($paged.totalRecords), PageSize = $($paged.pageSize), ItemCount = $($paged.data.Count)"

    # 2. Test GET /api/hr/employees/dropdown
    $dropdown = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees/dropdown' -Method Get -Headers $headers
    Write-Host "[API 2 SUCCESS] GET /api/hr/employees/dropdown: Count = $($dropdown.data.Count)"

    # 3. Test GET /api/hr/employees/code/1200849
    $byCode = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees/code/1200849' -Method Get -Headers $headers
    Write-Host "[API 3 SUCCESS] GET /api/hr/employees/code/1200849: Found = $($byCode.data.fullName)"

    # 4. Test GET /api/hr/employees/1
    $byId = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees/1' -Method Get -Headers $headers
    Write-Host "[API 4 SUCCESS] GET /api/hr/employees/1: Found = $($byId.data.fullName), UserCode = $($byId.data.userCode)"

    # 5. Test POST /api/hr/employees (Create test employee)
    $newEmp = @{
        UserCode = '9999001'
        FullName = 'Nguyễn Văn Test'
        Email = 'test9999@hansol.com'
        DepartmentId = 4
        DepartmentCode = 'DEPT_IT'
        PositionRole = 'ENGINEER'
        Plant = 'MAIN'
        VendorName = 'HANSOL'
        ContractType = 'Official'
        Status = 1
    } | ConvertTo-Json

    $createRes = Invoke-RestMethod -Uri 'http://localhost:7014/api/hr/employees' -Method Post -Headers $headers -Body $newEmp -ContentType 'application/json'
    $newEmpId = $createRes.data
    Write-Host "[API 5 SUCCESS] POST /api/hr/employees: Created EmployeeId = $newEmpId"

    # 6. Test PUT /api/hr/employees/{id} (Update test employee)
    $updateEmp = @{
        UserCode = '9999001'
        FullName = 'Nguyễn Văn Test Updated'
        Email = 'test9999_updated@hansol.com'
        DepartmentId = 4
        DepartmentCode = 'DEPT_IT'
        PositionRole = 'SENIOR_ENGINEER'
        Plant = 'MAIN'
        VendorName = 'HANSOL'
        ContractType = 'Official'
        Status = 1
    } | ConvertTo-Json

    $updateRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/employees/$newEmpId" -Method Put -Headers $headers -Body $updateEmp -ContentType 'application/json'
    Write-Host "[API 6 SUCCESS] PUT /api/hr/employees/$($newEmpId): Result = $($updateRes.isSuccess), Message = $($updateRes.message)"

    # 7. Test PATCH /api/hr/employees/{id}/status
    $patchStatus = @{
        Status = 0
    } | ConvertTo-Json
    $statusRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/employees/$newEmpId/status" -Method Patch -Headers $headers -Body $patchStatus -ContentType 'application/json'
    Write-Host "[API 7 SUCCESS] PATCH /api/hr/employees/$($newEmpId)/status: Result = $($statusRes.isSuccess)"

    # 8. Test DELETE /api/hr/employees/{id} (Soft delete)
    $delRes = Invoke-RestMethod -Uri "http://localhost:7014/api/hr/employees/$newEmpId" -Method Delete -Headers $headers
    Write-Host "[API 8 SUCCESS] DELETE /api/hr/employees/$($newEmpId): Result = $($delRes.isSuccess)"

    # Clean up test row from DB
    & 'd:\HRM\scripts\execute_sql.ps1' -sqlCommand "DELETE FROM dbo.HR_Employees WHERE UserCode = '9999001';" | Out-Null
    Write-Host "[CLEANUP] Deleted test employee 9999001 from DB."
} catch {
    Write-Host "[ERROR]: $($_.Exception.Message)"
}
