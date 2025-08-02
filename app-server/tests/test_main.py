"""
Tests for AdeptDAO FastAPI Application
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch, MagicMock
import json

from main import app

client = TestClient(app)

def test_root_endpoint():
    """Test the root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["message"] == "AdeptDAO API is running"

def test_health_endpoint():
    """Test the health check endpoint"""
    with patch('main.httpx.AsyncClient') as mock_client, \
         patch('main.solana_client') as mock_solana:
        
        # Mock JuliaOS health check
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_client.return_value.__aenter__.return_value.get = AsyncMock(return_value=mock_response)
        
        # Mock Solana health check
        mock_health_response = MagicMock()
        mock_health_response.value = "ok"
        mock_solana.is_connected = AsyncMock(return_value=True)
        
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert "api" in data
        assert "juliaos_backend" in data
        assert "solana_rpc" in data

@pytest.mark.asyncio
async def test_analyze_proposal():
    """Test proposal analysis endpoint"""
    proposal_address = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
    
    with patch('main.fetch_proposal_data') as mock_fetch, \
         patch('main.call_juliaos_swarm') as mock_swarm:
        
        # Mock proposal data
        mock_fetch.return_value = {
            "title": "Test Proposal",
            "description": "Test Description",
            "state": "Voting",
            "created_at": "2024-01-01T00:00:00Z"
        }
        
        # Mock swarm analysis with enhanced AI response
        mock_swarm.return_value = {
            "financial_analysis": {
                "treasury_impact": {
                    "immediate_cost": "Low - under 1000 SOL",
                    "long_term_impact": "Positive ROI expected",
                    "resource_efficiency": "High"
                },
                "risk_assessment": {
                    "risk_level": "low",
                    "key_risks": ["Market volatility", "Implementation delays"],
                    "mitigation_strategies": ["Phased rollout", "Regular monitoring"]
                }
            },
            "technical_analysis": {
                "complexity_assessment": {
                    "level": "medium",
                    "key_challenges": ["Integration with existing systems"],
                    "required_expertise": ["Smart contract development", "Security auditing"]
                },
                "security_analysis": {
                    "risk_level": "low",
                    "vulnerabilities": [],
                    "security_recommendations": ["Regular audits", "Access control review"]
                }
            },
            "sentiment_analysis": {
                "communication_assessment": {
                    "clarity_score": 0.85,
                    "accessibility_level": "High",
                    "tone_analysis": "Professional and clear"
                },
                "sentiment_indicators": {
                    "overall_sentiment": "positive",
                    "confidence_level": 0.9,
                    "key_concerns": []
                }
            },
            "aggregated_summary": {
                "overall_score": 8.5,
                "recommendation": "Strong Approval Recommended",
                "key_considerations": ["Positive ROI potential", "Low security risk"]
            }
        }
        
        response = client.post(f"/api/v1/proposals/{proposal_address}/analyze")
        assert response.status_code == 200
        data = response.json()
        assert data["proposal_address"] == proposal_address
        assert "financial_analysis" in data
        assert "technical_analysis" in data
        assert "sentiment_analysis" in data
        assert "aggregated_summary" in data
        
        # Verify enhanced AI analysis fields
        financial = data["financial_analysis"]
        assert "treasury_impact" in financial
        assert "risk_assessment" in financial
        
        technical = data["technical_analysis"]
        assert "complexity_assessment" in technical
        assert "security_analysis" in technical
        
        sentiment = data["sentiment_analysis"]
        assert "communication_assessment" in sentiment
        assert "sentiment_indicators" in sentiment
        
        summary = data["aggregated_summary"]
        assert "overall_score" in summary
        assert "recommendation" in summary
        assert "key_considerations" in summary

def test_get_dao_proposals():
    """Test DAO proposals endpoint"""
    dao_address = "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    
    response = client.get(f"/api/v1/dao/{dao_address}/proposals")
    assert response.status_code == 200
    data = response.json()
    assert data["dao_address"] == dao_address
    assert "proposals" in data
    assert len(data["proposals"]) >= 0

def test_prepare_vote_transaction():
    """Test vote preparation endpoint"""
    proposal_address = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
    vote_data = {
        "proposal_address": proposal_address,
        "vote_choice": "approve",
        "user_wallet": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    }
    
    response = client.post(
        f"/api/v1/proposals/{proposal_address}/prepare-vote",
        json=vote_data
    )
    assert response.status_code == 200
    data = response.json()
    assert "unsigned_transaction" in data
    assert "transaction_message" in data

def test_invalid_vote_choice():
    """Test invalid vote choice validation"""
    proposal_address = "7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU"
    vote_data = {
        "proposal_address": proposal_address,
        "vote_choice": "invalid_choice",
        "user_wallet": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM"
    }
    
    response = client.post(
        f"/api/v1/proposals/{proposal_address}/prepare-vote",
        json=vote_data
    )
    assert response.status_code == 422  # Validation error