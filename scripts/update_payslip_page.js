const fs = require('fs');

const filePath = 'd:/HRM/HRM.Frontend/src/pages/ESS/MyPayslip/index.tsx';
let content = fs.readFileSync(filePath, 'utf8');

// Normalize to LF for matching
const isCrlf = content.includes('\r\n');
content = content.replace(/\r\n/g, '\n');

// 1. Replace fetchPayslip, fetchPeriods, handlePeriodChange
const fetchRegex = /  const fetchPayslip = async \(periodId\?: string\) => \{[\s\S]*?  const handlePeriodChange = \(val: string\) => \{\n    setSelectedPeriodId\(val\);\n    fetchPayslip\(val\);\n  \};/;

const newFetchBlock = `  const fetchPayslip = async (periodId?: string, empCode?: string) => {
    setLoading(true);
    try {
      const codeToUse = empCode !== undefined ? empCode : targetEmployeeCode;
      const res = await myPayslipService.getMyPayslip(periodId, codeToUse);
      if (res && res.isSuccess && res.data) {
        setPayslip(res.data);
      } else {
        setPayslip(null);
        setEmptyMessage(
          res?.message ||
            'Bảng lương tháng này đang được phòng Nhân sự xử lý, chưa được công bố.',
        );
      }
    } catch (err: any) {
      setPayslip(null);
      setEmptyMessage(
        err?.response?.data?.message ||
          'Bảng lương tháng này đang được phòng Nhân sự xử lý, chưa được công bố.',
      );
    } finally {
      setLoading(false);
    }
  };

  const fetchPeriods = async (empCode?: string) => {
    setLoading(true);
    try {
      const codeToUse = empCode !== undefined ? empCode : targetEmployeeCode;
      const res = await myPayslipService.getPublishedPeriods(codeToUse);
      if (res && res.isSuccess && res.data && res.data.length > 0) {
        setPeriods(res.data);
        const latestPeriodId = res.data[0].periodId;
        setSelectedPeriodId(latestPeriodId);
        await fetchPayslip(latestPeriodId, codeToUse);
      } else {
        setPeriods([]);
        setPayslip(null);
        setEmptyMessage(
          res?.message ||
            'Chưa có kỳ lương nào được công bố cho tài khoản nhân viên này.',
        );
        setLoading(false);
      }
    } catch {
      setPeriods([]);
      setPayslip(null);
      setEmptyMessage(
        'Không thể kết nối đến máy chủ hoặc chưa có kỳ lương nào được công bố.',
      );
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPeriods();
  }, []);

  const handlePeriodChange = (val: string) => {
    setSelectedPeriodId(val);
    fetchPayslip(val, targetEmployeeCode);
  };

  const handleEmployeeChange = (val: string) => {
    setTargetEmployeeCode(val);
    fetchPeriods(val);
  };`;

if (fetchRegex.test(content)) {
  content = content.replace(fetchRegex, newFetchBlock);
  console.log('Successfully replaced fetch blocks via Regex!');
} else {
  console.error('Regex did not match fetch block!');
}

// 2. Add Admin Employee Switcher right after Period Select in Toolbar
const toolbarTarget = `            </Select>
          </div>`;

const adminEmployeeSelect = `            </Select>
          </div>

          {isAdmin && (
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                flex: isMobileScreen ? '1 1 100%' : '0 1 auto',
              }}
            >
              <UserOutlined style={{ color: '#1677ff' }} />
              <span
                style={{
                  fontWeight: 500,
                  color: token.colorTextSecondary,
                  whiteSpace: 'nowrap',
                }}
              >
                Nhân viên:
              </span>
              <Select
                style={{ width: isMobileScreen ? '100%' : 260 }}
                value={targetEmployeeCode || 'ADMIN'}
                onChange={handleEmployeeChange}
                placeholder="Chọn nhân viên..."
                options={[
                  { label: 'ADMIN - Quản Trị Viên (Tôi)', value: 'ADMIN' },
                  { label: '1200837 - Nguyễn Lâm Đồng', value: '1200837' },
                  { label: '1200840 - Pham Hoang Giang', value: '1200840' },
                  { label: '1200841 - Vu Thi Hoa', value: '1200841' },
                  { label: '1200842 - Hoang Van Son', value: '1200842' },
                  { label: '1200843 - Nguyen Thi Mai', value: '1200843' },
                  { label: '1200844 - Do Tuan Anh', value: '1200844' },
                  { label: '1200845 - Bui Minh Nguyet', value: '1200845' },
                  { label: '1200846 - Phan Hoang Long', value: '1200846' },
                  { label: '1200847 - Ngo Chi Thanh', value: '1200847' },
                ]}
              />
            </div>
          )}`;

const tbIndex = content.indexOf(toolbarTarget);
if (tbIndex !== -1) {
  content = content.substring(0, tbIndex) + adminEmployeeSelect + content.substring(tbIndex + toolbarTarget.length);
  console.log('Successfully injected Admin Employee Switcher!');
} else {
  console.error('Could not find toolbar target!');
}

if (isCrlf) {
  content = content.replace(/\n/g, '\r\n');
}

fs.writeFileSync(filePath, content, 'utf8');
console.log('Saved index.tsx successfully!');
