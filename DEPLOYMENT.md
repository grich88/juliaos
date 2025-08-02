# AdeptDAO Deployment Guide

## 🚀 Quick Start

AdeptDAO is now ready for deployment with real Solana integration and AI analysis capabilities. This guide will help you get the complete system running.

## 📋 Prerequisites

### Required Software

1. **Node.js** (v18 or higher)
   - Download from [nodejs.org](https://nodejs.org/)
   - Verify: `node --version`

2. **Python** (v3.9 or higher)
   - Download from [python.org](https://www.python.org/)
   - Verify: `python --version`

3. **Julia** (v1.11.4 or higher)
   - Download from [julialang.org](https://julialang.org/downloads/)
   - Recommended: Install [juliaup](https://github.com/JuliaLang/juliaup) for version management
   - Verify: `julia --version`

4. **Docker** (for PostgreSQL database)
   - Download from [docker.com](https://www.docker.com/get-started/)
   - Verify: `docker --version`

### Optional APIs

- **OpenAI API Key** (for AI analysis)
- **Solana RPC Endpoint** (free tier available from Alchemy, QuickNode, etc.)

## 🏗️ Installation

### 1. Backend Setup (JuliaOS)

```bash
cd juliaos-core/backend

# Install Julia dependencies
julia --project=. -e "using Pkg; Pkg.instantiate()"

# Start PostgreSQL database
docker compose up julia-db -d

# Start Julia backend (runs on port 8052)
julia --project=. run_server.jl
```

### 2. Application Server Setup (FastAPI)

```bash
cd app-server

# Create Python virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy and configure environment
cp .env.example .env
# Edit .env with your API keys and configuration

# Start FastAPI server (runs on port 8000)
uvicorn main:app --reload
```

### 3. Frontend Setup (Next.js)

```bash
cd frontend

# Install dependencies
npm install

# Copy and configure environment
cp .env.local.example .env.local
# Edit .env.local with your configuration

# Start development server (runs on port 3000)
npm run dev
```

## ⚙️ Configuration

### Backend Environment (.env files)

**juliaos-core/backend/.env**
```env
# Database
DB_HOST=localhost
DB_PORT=5433
DB_USER=juliaos
DB_PASSWORD=juliaos_pass
DB_NAME=juliaos_db

# Server
HOST=0.0.0.0
PORT=8052

# AI Services
OPENAI_API_KEY=your-openai-api-key-here
SOLANA_RPC_URL=https://api.devnet.solana.com
```

**app-server/.env**
```env
# JuliaOS Backend
JULIAOS_SERVER_URL=http://localhost:8052

# Solana
SOLANA_RPC_URL=https://api.devnet.solana.com

# AI Services
OPENAI_API_KEY=your-openai-api-key-here

# CORS
CORS_ORIGINS=http://localhost:3000
LOG_LEVEL=info
```

**frontend/.env.local**
```env
# API
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_SOLANA_NETWORK=devnet
NEXT_PUBLIC_SOLANA_RPC_URL=https://api.devnet.solana.com
```

## 🧪 Testing the System

### 1. Health Checks

- **Frontend**: http://localhost:3000
- **FastAPI**: http://localhost:8000/health
- **JuliaOS**: http://localhost:8052/health

### 2. Sample DAO Addresses (Devnet)

Try these Realms DAO addresses in the frontend:
- `DPiH3H3c7t47BMxqTxLsuPQpEC6Kne8GA9VXbxpnZxFE` (Mango DAO)
- `FMEWULPSGR1BQNT9FMIZJSKJFWM9Q46JMESLY8S3OQ2QZJBQ1XQE` (Sample DAO)

### 3. Features to Test

1. **DAO Proposal Listing**: Enter a DAO address to see proposals
2. **AI Analysis**: Click on a proposal to see multi-agent analysis
3. **Vote Preparation**: Test vote transaction preparation
4. **Wallet Integration**: Connect Phantom, Solflare, or Backpack wallet

## 🐛 Troubleshooting

### Common Issues

**Julia not found**
```bash
# Install Julia via juliaup (recommended)
curl -fsSL https://install.julialang.org | sh
julia --version
```

**Docker not available**
```bash
# Alternative: Run PostgreSQL locally
# Update DB_HOST in .env to your local PostgreSQL instance
```

**API Connection Errors**
- Check all services are running on correct ports
- Verify CORS settings in app-server/.env
- Check firewall/antivirus blocking connections

**Wallet Connection Issues**
- Ensure you're on Solana Devnet
- Try different wallet providers
- Check browser console for errors

### Development Mode

For development, you can run the system with mock data:

1. Start only the FastAPI server (app-server)
2. Start the frontend
3. The system will use enhanced mock data for AI analysis and blockchain interactions

## 🏆 Production Deployment

### Environment-Specific Configurations

**Mainnet Configuration**
```env
NEXT_PUBLIC_SOLANA_NETWORK=mainnet-beta
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
```

**Performance Optimizations**
- Use production Solana RPC providers (Alchemy, QuickNode)
- Configure Redis for JuliaOS caching
- Set up proper database connection pooling
- Use HTTPS for all endpoints

### Security Considerations

- Never commit API keys to version control
- Use environment-specific .env files
- Implement rate limiting for API endpoints
- Validate all user inputs
- Use HTTPS in production

## 📊 Monitoring

The system includes health check endpoints for monitoring:

- `/health` - FastAPI health and dependency status
- `/` - Basic service availability
- Database connection status
- JuliaOS backend connectivity
- Solana RPC connectivity

## 🔄 Updates and Maintenance

### Updating Dependencies

```bash
# Julia packages
cd juliaos-core/backend
julia --project=. -e "using Pkg; Pkg.update()"

# Python packages
cd app-server
pip install -r requirements.txt --upgrade

# Node.js packages
cd frontend
npm update
```

### Database Migrations

```bash
cd juliaos-core/backend
# Migrations are handled automatically by Docker setup
# Manual migration: Run SQL files in migrations/ directory
```

## 🎯 Key Features Implemented

✅ **Real Solana Integration**: Direct SPL Governance account parsing
✅ **AI Multi-Agent Analysis**: Contextual proposal analysis
✅ **Transaction Preparation**: Unsigned vote transaction construction
✅ **Wallet Integration**: Support for major Solana wallets
✅ **Responsive UI**: Modern, accessible interface
✅ **Error Handling**: Graceful fallbacks and error recovery
✅ **Health Monitoring**: Comprehensive system health checks

## 🏁 Success Criteria

The AdeptDAO system is ready for the JuliaOS bounty when:

1. All three services start without errors
2. Health endpoints return 200 status
3. Frontend loads and displays DAO proposals
4. AI analysis generates contextual results
5. Vote transactions can be prepared
6. Wallet connection works properly

---

For support or questions, refer to the main README.md or check the individual component documentation. 