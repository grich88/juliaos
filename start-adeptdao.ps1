# AdeptDAO Quick Start Script
# This script helps start all components of AdeptDAO

Write-Host "🚀 AdeptDAO Quick Start" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "�� Checking Prerequisites..." -ForegroundColor Yellow

$nodeVersion = node --version 2>$null
$pythonVersion = python --version 2>$null  
$dockerVersion = docker --version 2>$null

if ($nodeVersion) { Write-Host "✅ Node.js: $nodeVersion" -ForegroundColor Green }
else { Write-Host "❌ Node.js not found - Please install from nodejs.org" -ForegroundColor Red }

if ($pythonVersion) { Write-Host "✅ Python: $pythonVersion" -ForegroundColor Green }
else { Write-Host "❌ Python not found - Please install from python.org" -ForegroundColor Red }

if ($dockerVersion) { Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green }
else { Write-Host "⚠️  Docker not found - Database may not start" -ForegroundColor Yellow }

Write-Host ""
Write-Host "🔧 Starting AdeptDAO Components..." -ForegroundColor Yellow
Write-Host ""

Write-Host "1️⃣  Database (PostgreSQL):" -ForegroundColor Cyan
Write-Host "   cd juliaos-core/backend && docker compose up julia-db -d"
Write-Host ""

Write-Host "2️⃣  FastAPI Server (Port 8000):" -ForegroundColor Cyan  
Write-Host "   cd app-server && python -m venv venv && venv\\Scripts\\activate && pip install -r requirements.txt && uvicorn main:app --reload"
Write-Host ""

Write-Host "3️⃣  Next.js Frontend (Port 3000):" -ForegroundColor Cyan
Write-Host "   cd frontend && npm install && npm run dev"
Write-Host ""

Write-Host "4️⃣  JuliaOS Backend (Port 8052) - Optional for full AI:" -ForegroundColor Cyan
Write-Host "   cd juliaos-core/backend && julia --project=. -e \"using Pkg; Pkg.instantiate()\" && julia --project=. run_server.jl"
Write-Host ""

Write-Host "🌐 Access Points:" -ForegroundColor Green
Write-Host "   • Frontend: http://localhost:3000"
Write-Host "   • API Docs: http://localhost:8000/docs"
Write-Host "   • Health Check: http://localhost:8000/health"
Write-Host ""

Write-Host "📝 Sample DAO Addresses to try:" -ForegroundColor Magenta
Write-Host "   • DPiH3H3c7t47BMxqTxLsuPQpEC6Kne8GA9VXbxpnZxFE"
Write-Host "   • 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
Write-Host ""

Write-Host "💡 Tips:" -ForegroundColor Blue
Write-Host "   • Start with just FastAPI + Frontend for quick demo"
Write-Host "   • Add OpenAI API key for enhanced AI analysis"
Write-Host "   • Check DEPLOYMENT.md for detailed instructions"

