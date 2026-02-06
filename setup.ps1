# AI-Powered Medical Report System - Setup Script
# Run this script to set up the complete system

Write-Host "🏥 AI-Powered Medical Report System - Setup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Backend Setup
Write-Host "📦 Step 1: Setting up Backend..." -ForegroundColor Yellow
Write-Host ""

Set-Location med_backend

# Install dependencies
Write-Host "Installing Node.js dependencies..." -ForegroundColor Green
npm install

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
Write-Host ""

# Update database schema
Write-Host "Updating database schema..." -ForegroundColor Green
npm run prisma:push

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Database schema update failed. Make sure PostgreSQL is running." -ForegroundColor Yellow
    Write-Host "You can run 'npm run prisma:push' manually later." -ForegroundColor Yellow
} else {
    Write-Host "✅ Database schema updated successfully" -ForegroundColor Green
}

Write-Host ""

# Go back to root
Set-Location ..

# Step 2: Flutter Setup
Write-Host "📱 Step 2: Setting up Flutter..." -ForegroundColor Yellow
Write-Host ""

# Install Flutter dependencies
Write-Host "Installing Flutter dependencies..." -ForegroundColor Green
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install Flutter dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter dependencies installed successfully" -ForegroundColor Green
Write-Host ""

# Complete
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Start backend server:" -ForegroundColor White
Write-Host "   cd med_backend" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Run Flutter app:" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "   - Quick Start: QUICKSTART_AI_REPORT_SYSTEM.md" -ForegroundColor Gray
Write-Host "   - Full Guide: AI_REPORT_SYSTEM_IMPLEMENTATION_GUIDE.md" -ForegroundColor Gray
Write-Host "   - Summary: IMPLEMENTATION_SUMMARY.md" -ForegroundColor Gray
Write-Host "   - Diagrams: SYSTEM_ARCHITECTURE_DIAGRAMS.md" -ForegroundColor Gray
Write-Host ""
Write-Host "🚀 Ready to test your AI-powered report system!" -ForegroundColor Green
Write-Host ""
