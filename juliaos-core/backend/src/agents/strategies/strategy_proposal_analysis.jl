# ProposalAnalysis strategy for DAO governance analysis using multi-agent swarm
# This strategy orchestrates specialized AI agents to analyze proposals from different perspectives

using ..CommonTypes: StrategyConfig, AgentContext, StrategySpecification, StrategyMetadata, StrategyInput
using JSON3

Base.@kwdef struct StrategyProposalAnalysisConfig <: StrategyConfig
    financial_agent_prompt::String = """
    You are a Financial Analyst AI specializing in DAO governance and blockchain economics. Analyze the proposal with focus on:
    
    1. Treasury Impact:
       - Direct costs and potential returns
       - Long-term financial implications
       - Resource allocation efficiency
    
    2. Tokenomics:
       - Impact on token value and distribution
       - Staking and rewards implications
       - Market dynamics considerations
    
    3. Risk Assessment:
       - Financial risks and mitigation strategies
       - Market volatility considerations
       - Opportunity costs
    
    4. ROI Analysis:
       - Expected returns (quantitative if possible)
       - Timeline for value realization
       - Success metrics and KPIs
    
    Return your analysis as detailed JSON with fields:
    {
        "treasury_impact": {
            "immediate_cost": string,
            "long_term_impact": string,
            "resource_efficiency": string
        },
        "tokenomics_analysis": {
            "token_value_impact": string,
            "distribution_effects": string,
            "market_implications": string
        },
        "risk_assessment": {
            "risk_level": "low"|"medium"|"high",
            "key_risks": string[],
            "mitigation_strategies": string[]
        },
        "roi_projection": {
            "expected_returns": string,
            "timeline": string,
            "confidence_level": number,
            "key_metrics": string[]
        },
        "recommendations": string[]
    }
    """

    technical_agent_prompt::String = """
    You are a Technical Risk Assessor AI specializing in blockchain and DAO infrastructure. Evaluate the proposal with focus on:
    
    1. Technical Complexity:
       - Implementation difficulty
       - Required expertise and resources
       - Integration challenges
    
    2. Security Considerations:
       - Smart contract risks
       - Attack vectors
       - Security best practices compliance
    
    3. Implementation Feasibility:
       - Technical prerequisites
       - Dependencies and constraints
       - Scalability considerations
    
    4. Maintenance Requirements:
       - Ongoing support needs
       - Upgrade paths
       - Technical debt implications
    
    Return your analysis as detailed JSON with fields:
    {
        "complexity_assessment": {
            "level": "low"|"medium"|"high",
            "key_challenges": string[],
            "required_expertise": string[]
        },
        "security_analysis": {
            "risk_level": "low"|"medium"|"high",
            "vulnerabilities": string[],
            "security_recommendations": string[]
        },
        "feasibility_study": {
            "technical_readiness": number,
            "prerequisites": string[],
            "scalability_assessment": string
        },
        "maintenance_outlook": {
            "support_requirements": string,
            "upgrade_complexity": string,
            "long_term_considerations": string[]
        },
        "timeline_estimate": {
            "development_time": string,
            "testing_time": string,
            "deployment_phases": string[]
        }
    }
    """

    sentiment_agent_prompt::String = """
    You are a Community Sentiment Analyst AI specializing in DAO governance and community dynamics. Assess the proposal with focus on:
    
    1. Language and Communication:
       - Clarity and accessibility
       - Technical vs. non-technical balance
       - Tone and professionalism
    
    2. Community Impact:
       - Stakeholder benefits and drawbacks
       - Alignment with DAO values
       - Potential controversies
    
    3. Governance Implications:
       - Decision-making process impact
       - Precedent considerations
       - Power dynamics
    
    4. Engagement Potential:
       - Expected participation levels
       - Community feedback predictions
       - Discussion quality indicators
    
    Return your analysis as detailed JSON with fields:
    {
        "communication_assessment": {
            "clarity_score": number,
            "accessibility_level": string,
            "tone_analysis": string
        },
        "community_impact": {
            "stakeholder_benefits": string[],
            "potential_drawbacks": string[],
            "value_alignment": string
        },
        "governance_analysis": {
            "process_impact": string,
            "precedent_implications": string[],
            "power_distribution_effects": string
        },
        "engagement_forecast": {
            "expected_participation": "low"|"medium"|"high",
            "discussion_topics": string[],
            "contentious_points": string[]
        },
        "sentiment_indicators": {
            "overall_sentiment": "negative"|"neutral"|"positive",
            "confidence_level": number,
            "key_concerns": string[]
        }
    }
    """
end

Base.@kwdef struct ProposalAnalysisInput <: StrategyInput
    proposal_title::String
    proposal_description::String
    proposal_address::String
    dao_context::Dict{String,Any} = Dict{String,Any}()
end

function strategy_proposal_analysis_initialization(cfg::StrategyProposalAnalysisConfig, ctx::AgentContext)
    push!(ctx.logs, "Initializing enhanced ProposalAnalysis strategy with GPT-4 Turbo capabilities")
    
    # Verify required tools
    required_tools = ["llm_chat", "realms_proposal_fetcher"]
    for tool_name in required_tools
        tool_index = findfirst(tool -> tool.metadata.name == tool_name, ctx.tools)
        if tool_index === nothing
            push!(ctx.logs, "ERROR: Required tool '$tool_name' not found in context tools.")
            return
        end
    end
    
    push!(ctx.logs, "Enhanced ProposalAnalysis strategy initialized successfully")
end

function strategy_proposal_analysis(cfg::StrategyProposalAnalysisConfig, ctx::AgentContext, input::ProposalAnalysisInput)
    push!(ctx.logs, "Starting enhanced multi-agent analysis for proposal: $(input.proposal_address)")
    
    # Get the LLM chat tool
    llm_tool_index = findfirst(tool -> tool.metadata.name == "llm_chat", ctx.tools)
    if llm_tool_index === nothing
        push!(ctx.logs, "ERROR: LLM chat tool not found")
        return Dict("error" => "LLM tool not available")
    end
    llm_tool = ctx.tools[llm_tool_index]
    
    # Prepare the proposal text with context
    dao_context_str = ""
    if !isempty(input.dao_context)
        dao_context_str = """
        DAO Context:
        $(JSON3.write(input.dao_context, pretty=true))
        """
    end
    
    proposal_text = """
    Title: $(input.proposal_title)
    
    Description: $(input.proposal_description)
    
    Address: $(input.proposal_address)
    
    $dao_context_str
    """
    
    # Financial Analysis Agent
    push!(ctx.logs, "Running enhanced Financial Analyst agent...")
    financial_prompt = cfg.financial_agent_prompt * "\n\nProposal to analyze:\n" * proposal_text
    financial_result = llm_tool.execute(llm_tool.config, financial_prompt)
    push!(ctx.logs, "Financial analysis completed")
    
    # Technical Risk Assessment Agent
    push!(ctx.logs, "Running enhanced Technical Risk Assessor agent...")
    technical_prompt = cfg.technical_agent_prompt * "\n\nProposal to analyze:\n" * proposal_text
    technical_result = llm_tool.execute(llm_tool.config, technical_prompt)
    push!(ctx.logs, "Technical analysis completed")
    
    # Sentiment Analysis Agent
    push!(ctx.logs, "Running enhanced Community Sentiment Analyst agent...")
    sentiment_prompt = cfg.sentiment_agent_prompt * "\n\nProposal to analyze:\n" * proposal_text
    sentiment_result = llm_tool.execute(llm_tool.config, sentiment_prompt)
    push!(ctx.logs, "Sentiment analysis completed")
    
    # Parse and aggregate results
    try
        financial_analysis = JSON3.read(financial_result, Dict)
        technical_analysis = JSON3.read(technical_result, Dict)
        sentiment_analysis = JSON3.read(sentiment_result, Dict)
        
        # Generate comprehensive aggregated summary
        overall_score = calculate_overall_score(financial_analysis, technical_analysis, sentiment_analysis)
        recommendation = get_detailed_recommendation(overall_score, financial_analysis, technical_analysis, sentiment_analysis)
        key_considerations = extract_key_considerations(financial_analysis, technical_analysis, sentiment_analysis)
        risk_profile = calculate_risk_profile(financial_analysis, technical_analysis)
        
        aggregated_summary = Dict(
            "overall_score" => overall_score,
            "recommendation" => recommendation,
            "key_considerations" => key_considerations,
            "risk_profile" => risk_profile,
            "confidence_metrics" => Dict(
                "financial" => financial_analysis["roi_projection"]["confidence_level"],
                "technical" => technical_analysis["complexity_assessment"]["level"],
                "sentiment" => sentiment_analysis["sentiment_indicators"]["confidence_level"]
            )
        )
        
        result = Dict(
            "proposal_address" => input.proposal_address,
            "proposal_title" => input.proposal_title,
            "proposal_description" => input.proposal_description,
            "financial_analysis" => financial_analysis,
            "technical_analysis" => technical_analysis,
            "sentiment_analysis" => sentiment_analysis,
            "aggregated_summary" => aggregated_summary
        )
        
        push!(ctx.logs, "Enhanced multi-agent analysis completed successfully with overall score: $overall_score")
        return result
        
    catch e
        error_msg = "Error processing analysis results: $e"
        push!(ctx.logs, "ERROR: $error_msg")
        return Dict("error" => error_msg)
    end
end

# Helper functions for enhanced analysis

function calculate_overall_score(financial::Dict, technical::Dict, sentiment::Dict)::Float64
    # Enhanced scoring algorithm
    financial_score = get_financial_score(financial)
    technical_score = get_technical_score(technical)
    sentiment_score = get_sentiment_score(sentiment)
    
    # Weighted average based on confidence levels
    weights = Dict(
        "financial" => financial["roi_projection"]["confidence_level"],
        "technical" => technical_score_to_confidence(technical["complexity_assessment"]["level"]),
        "sentiment" => sentiment["sentiment_indicators"]["confidence_level"]
    )
    
    total_weight = sum(values(weights))
    
    weighted_score = (
        financial_score * weights["financial"] +
        technical_score * weights["technical"] +
        sentiment_score * weights["sentiment"]
    ) / total_weight
    
    return round(weighted_score, digits=2)
end

function get_financial_score(analysis::Dict)::Float64
    # Convert risk level to score
    risk_scores = Dict("low" => 0.9, "medium" => 0.6, "high" => 0.3)
    risk_score = risk_scores[analysis["risk_assessment"]["risk_level"]]
    
    # Consider ROI confidence
    roi_confidence = analysis["roi_projection"]["confidence_level"]
    
    return (risk_score + roi_confidence) / 2
end

function get_technical_score(analysis::Dict)::Float64
    # Convert complexity levels to scores
    complexity_scores = Dict("low" => 0.9, "medium" => 0.6, "high" => 0.3)
    complexity_score = complexity_scores[analysis["complexity_assessment"]["level"]]
    
    # Consider security risk level
    security_scores = Dict("low" => 0.9, "medium" => 0.6, "high" => 0.3)
    security_score = security_scores[analysis["security_analysis"]["risk_level"]]
    
    return (complexity_score + security_score) / 2
end

function get_sentiment_score(analysis::Dict)::Float64
    # Convert sentiment to score
    sentiment_scores = Dict("positive" => 0.9, "neutral" => 0.6, "negative" => 0.3)
    sentiment_score = sentiment_scores[analysis["sentiment_indicators"]["overall_sentiment"]]
    
    # Consider clarity score
    clarity_score = analysis["communication_assessment"]["clarity_score"]
    
    return (sentiment_score + clarity_score) / 2
end

function technical_score_to_confidence(level::String)::Float64
    confidence_map = Dict("low" => 0.8, "medium" => 0.6, "high" => 0.4)
    return confidence_map[level]
end

function get_detailed_recommendation(score::Float64, financial::Dict, technical::Dict, sentiment::Dict)::String
    if score >= 0.8
        "Strong Approval Recommended - High confidence across all analysis dimensions"
    elseif score >= 0.6
        "Cautious Approval - Consider implementing suggested risk mitigation strategies"
    elseif score >= 0.4
        "Further Discussion Needed - Significant concerns identified"
    else
        "Rejection Recommended - Multiple critical issues identified"
    end
end

function calculate_risk_profile(financial::Dict, technical::Dict)::Dict
    Dict(
        "overall_risk" => max(
            risk_level_to_number(financial["risk_assessment"]["risk_level"]),
            risk_level_to_number(technical["security_analysis"]["risk_level"])
        ),
        "financial_risks" => financial["risk_assessment"]["key_risks"],
        "technical_risks" => technical["security_analysis"]["vulnerabilities"],
        "mitigation_strategies" => vcat(
            financial["risk_assessment"]["mitigation_strategies"],
            technical["security_analysis"]["security_recommendations"]
        )
    )
end

function risk_level_to_number(level::String)::Float64
    risk_scores = Dict("low" => 0.3, "medium" => 0.6, "high" => 0.9)
    return risk_scores[level]
end

function extract_key_considerations(financial::Dict, technical::Dict, sentiment::Dict)::Vector{String}
    considerations = String[]
    
    # Financial considerations
    if financial["risk_assessment"]["risk_level"] == "high"
        push!(considerations, "High Financial Risk: " * join(financial["risk_assessment"]["key_risks"][1:min(2, end)], "; "))
    end
    
    # Technical considerations
    if technical["complexity_assessment"]["level"] == "high"
        push!(considerations, "High Technical Complexity: " * join(technical["complexity_assessment"]["key_challenges"][1:min(2, end)], "; "))
    end
    
    # Security considerations
    if technical["security_analysis"]["risk_level"] == "high"
        push!(considerations, "Security Concerns: " * join(technical["security_analysis"]["vulnerabilities"][1:min(2, end)], "; "))
    end
    
    # Community considerations
    if !isempty(sentiment["sentiment_indicators"]["key_concerns"])
        push!(considerations, "Community Concerns: " * join(sentiment["sentiment_indicators"]["key_concerns"][1:min(2, end)], "; "))
    end
    
    return considerations
end