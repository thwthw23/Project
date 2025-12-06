# Script kiểm tra và khắc phục vấn đề GitHub Desktop
# Chạy script này từ thư mục Project

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "KIỂM TRA GITHUB DESKTOP VÀ REPOSITORY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiểm tra vị trí hiện tại
Write-Host "[1/8] Kiểm tra vị trí hiện tại..." -ForegroundColor Yellow
$currentPath = Get-Location
Write-Host "  Thư mục hiện tại: $currentPath" -ForegroundColor Green

# 2. Kiểm tra có phải git repository
Write-Host ""
Write-Host "[2/8] Kiểm tra git repository..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "  ✓ Thư mục .git tồn tại" -ForegroundColor Green
} else {
    Write-Host "  ✗ KHÔNG TÌM THẤY thư mục .git!" -ForegroundColor Red
    Write-Host "  → Đây không phải là git repository" -ForegroundColor Red
    exit 1
}

# 3. Kiểm tra remote
Write-Host ""
Write-Host "[3/8] Kiểm tra remote repository..." -ForegroundColor Yellow
try {
    $remoteUrl = git remote get-url origin 2>$null
    if ($remoteUrl) {
        Write-Host "  ✓ Remote URL: $remoteUrl" -ForegroundColor Green
        
        if ($remoteUrl -like "*github.com*") {
            Write-Host "  ✓ Đang sử dụng GitHub" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Remote không phải GitHub" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ KHÔNG CÓ remote được cấu hình!" -ForegroundColor Red
        Write-Host "  → Chạy: git remote add origin https://github.com/TDMHorizon/Project.git" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Lỗi khi kiểm tra remote: $_" -ForegroundColor Red
}

# 4. Kiểm tra branch
Write-Host ""
Write-Host "[4/8] Kiểm tra branch..." -ForegroundColor Yellow
try {
    $currentBranch = git branch --show-current 2>$null
    if ($currentBranch) {
        Write-Host "  ✓ Branch hiện tại: $currentBranch" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Không xác định được branch" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Lỗi khi kiểm tra branch: $_" -ForegroundColor Red
}

# 5. Kiểm tra trạng thái repository
Write-Host ""
Write-Host "[5/8] Kiểm tra trạng thái repository..." -ForegroundColor Yellow
try {
    $status = git status --porcelain 2>$null
    $statusOutput = git status 2>$null
    
    if ($status) {
        Write-Host "  ⚠ CÓ THAY ĐỔI chưa được commit:" -ForegroundColor Yellow
        Write-Host $statusOutput -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  → Cần commit trước khi push:" -ForegroundColor Yellow
        Write-Host "    git add ." -ForegroundColor Cyan
        Write-Host "    git commit -m 'Your message'" -ForegroundColor Cyan
    } else {
        Write-Host "  ✓ Không có thay đổi chưa commit" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ Lỗi khi kiểm tra status: $_" -ForegroundColor Red
}

# 6. Kiểm tra commit history
Write-Host ""
Write-Host "[6/8] Kiểm tra commit history..." -ForegroundColor Yellow
try {
    $lastCommit = git log -1 --oneline 2>$null
    if ($lastCommit) {
        Write-Host "  ✓ Commit cuối cùng: $lastCommit" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Chưa có commit nào" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Lỗi khi kiểm tra log: $_" -ForegroundColor Red
}

# 7. Kiểm tra đồng bộ với remote
Write-Host ""
Write-Host "[7/8] Kiểm tra đồng bộ với remote..." -ForegroundColor Yellow
try {
    git fetch origin 2>&1 | Out-Null
    $ahead = (git rev-list --count HEAD..origin/main 2>$null)
    $behind = (git rev-list --count origin/main..HEAD 2>$null)
    
    if ($ahead -gt 0) {
        Write-Host "  ⚠ Local đang AHEAD remote $ahead commit(s)" -ForegroundColor Yellow
        Write-Host "  → Có thể push: git push origin main" -ForegroundColor Cyan
    } elseif ($behind -gt 0) {
        Write-Host "  ⚠ Local đang BEHIND remote $behind commit(s)" -ForegroundColor Yellow
        Write-Host "  → Cần pull trước: git pull origin main" -ForegroundColor Cyan
    } else {
        Write-Host "  ✓ Đồng bộ với remote" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠ Không thể kiểm tra đồng bộ (có thể chưa có remote hoặc chưa push lần đầu)" -ForegroundColor Yellow
}

# 8. Kiểm tra cấu hình user
Write-Host ""
Write-Host "[8/8] Kiểm tra cấu hình user..." -ForegroundColor Yellow
try {
    $userName = git config --get user.name 2>$null
    $userEmail = git config --get user.email 2>$null
    
    if ($userName) {
        Write-Host "  ✓ User name: $userName" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Chưa cấu hình user.name" -ForegroundColor Yellow
    }
    
    if ($userEmail) {
        Write-Host "  ✓ User email: $userEmail" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ Chưa cấu hình user.email" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Lỗi khi kiểm tra config: $_" -ForegroundColor Red
}

# Tóm tắt
Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "TÓM TẮT" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Đường dẫn repository nên mở trong GitHub Desktop:" -ForegroundColor Yellow
Write-Host "  $currentPath" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "Remote URL:" -ForegroundColor Yellow
if ($remoteUrl) {
    Write-Host "  $remoteUrl" -ForegroundColor White -BackgroundColor DarkBlue
} else {
    Write-Host "  CHƯA ĐƯỢC CẤU HÌNH" -ForegroundColor Red
}
Write-Host ""

# Gợi ý
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "GỢI Ý ĐỂ PUSH TRONG GITHUB DESKTOP" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Mở GitHub Desktop" -ForegroundColor Yellow
Write-Host "2. File → Add Local Repository" -ForegroundColor Yellow
Write-Host "3. Chọn thư mục: $currentPath" -ForegroundColor Yellow
Write-Host "4. Đảm bảo đã đăng nhập đúng tài khoản GitHub" -ForegroundColor Yellow
Write-Host "5. Nếu có thay đổi, commit và push" -ForegroundColor Yellow
Write-Host ""
Write-Host "Nếu vẫn không được, xem file GITHUB_DESKTOP_TROUBLESHOOTING.md" -ForegroundColor Cyan
Write-Host ""

