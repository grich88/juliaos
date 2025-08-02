# JuliaOS

JuliaOS is an AI-powered DAO governance system built with Julia and Next.js.

## Architecture

The project consists of two main components:

- **Backend**: Julia-based server using Oxygen.jl for API endpoints and WebSocket communication
- **Frontend**: Next.js application with Solana wallet integration

### Backend Features

- AI-powered agent system for DAO proposal analysis
- Real-time monitoring and metrics
- WebSocket support for live updates
- Integration with Universal Leverage System
- CORS-enabled API endpoints

### Frontend Features

- Modern React with Next.js 14
- Solana wallet integration
- Real-time DAO proposal tracking
- Responsive UI with Tailwind CSS

## Development Setup

### Prerequisites

- Julia 1.11.6 or higher
- Node.js 18 or higher
- npm or yarn

### Backend Setup

```bash
cd juliaos-core/julia
julia --project=.
]activate .
]instantiate
exit()
julia --project=. --threads 3,1 src/server.jl
```

### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

## Environment Variables

### Frontend (.env.local)
```
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_SOLANA_NETWORK=devnet
```

## License

MIT License