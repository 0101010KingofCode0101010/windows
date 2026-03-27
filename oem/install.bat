@echo off
:: Chờ mạng ổn định trong 10 giây
timeout /t 10 /nobreak > NUL

:: Bắt đầu script PowerShell để lấy và cài đặt Proxy free
powershell -NoProfile -ExecutionPolicy Bypass -Command "^
    $proxyListUrl = 'https://api.proxyscrape.com/v2/?request=displayproxies&protocol=http&timeout=10000&country=all&ssl=all&anonymity=all';^
    Write-Host 'Downloading free proxy list...';^
    try {^
        $proxies = (Invoke-WebRequest -Uri $proxyListUrl -UseBasicParsing).Content -split '`n' | Where-Object { $_ -match ':' };^
    } catch {^
        Write-Host 'Failed to download proxy list. Exiting.';^
        exit 1;^
    }^
    ^
    if ($proxies.Count -eq 0) { Write-Host 'No proxies found.'; exit 1; }^
    ^
    Write-Host 'Found' $proxies.Count 'proxies. Testing for best one...';^
    $bestProxy = $null;^
    $bestTime = 99999;^
    ^
    :: Test 10 cái đầu tiên để tìm cái nhanh nhất^
    $proxiesToTest = $proxies | Select-Object -First 10;^
    foreach ($proxy in $proxiesToTest) {^
        $proxy = $proxy.Trim();^
        if (-not $proxy) { continue; }^
        Write-Host 'Testing:' $proxy -NoNewline;^
        $sw = [System.Diagnostics.Stopwatch]::StartNew();^
        try {^
            :: Test kết nối thử đến Google qua proxy này^
            $result = Invoke-WebRequest -Uri 'http://www.google.com' -Proxy $proxy -TimeoutSec 5 -UseBasicParsing;^
            $sw.Stop();^
            $time = $sw.ElapsedMilliseconds;^
            Write-Host ' - OK (' $time 'ms)';^
            if ($time -lt $bestTime) {^
                $bestTime = $time;^
                $bestProxy = $proxy;^
            }^
        } catch {^
            $sw.Stop();^
            Write-Host ' - Failed';^
        }^
    }^
    ^
    if ($bestProxy) {^
        Write-Host 'Best proxy found:' $bestProxy 'with' $bestTime 'ms. Setting up...';^
        :: 1. Cài đặt Proxy cho IE/Chrome/Hệ thống (Internet Settings)^
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 1;^
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyServer -Value $bestProxy;^
        ^
        :: 2. Cài đặt Proxy cho WinHTTP (Dịch vụ hệ thống, Edge cũ)^
        :: netsh winhttp set proxy $bestProxy;^
        :: Do netsh cần quyền admin cao hơn khi chạy script OEM, cách tốt nhất là force registry^
        $proxySplit = $bestProxy -split ':';^
        $proxyHost = $proxySplit[0];^
        $proxyPort = $proxySplit[1];^
        :: Lệnh netsh winhttp import proxy source=ie thường hiệu quả nhất trong script OEM^
        netsh winhttp import proxy source=ie;^
        ^
        Write-Host 'Proxy configuration applied to system and browsers.';^
    } else {^
        Write-Host 'No working proxy found in the test sample.';^
    }^
"

:: (Tùy chọn) Thêm file exe ngoài vào đây để cài đặt
:: Ví dụ: nếu bạn có file coker.exe trong data\, bạn có thể cài nó ở đây
:: C:\OEM\coker.exe /silent

:: === PHẦN MỚI: TỰ ĐỘNG BẬT BỘ CÀI ĐẶT ===
echo Dang mo file cai dat...

:: Biến %~dp0 sẽ lấy đường dẫn chính xác của thư mục oem
:: Nhớ thay "app_cay_trial.exe" bằng tên file thực tế của bạn
set "APP_PATH=%~dp0app_cay_trial.exe"

:: Mở file exe lên một cách bình thường
start "" "%APP_PATH%"

echo Da mo bo cai dat, ban thao tac truc tiep tren man hinh nhe!
pause