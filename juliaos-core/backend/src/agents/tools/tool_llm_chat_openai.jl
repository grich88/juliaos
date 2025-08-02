using DotEnv
DotEnv.load!()

using ...Resources: OpenAI
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

OPENAI_API_KEY = ENV["OPENAI_API_KEY"]
OPENAI_MODEL = get(ENV, "AI_MODEL", "gpt-4-turbo")

Base.@kwdef struct ToolLLMChatConfig <: ToolConfig
    api_key::String = OPENAI_API_KEY
    model_name::String = OPENAI_MODEL
    temperature::Float64 = 0.7
    max_tokens::Int = 2048
    stream::Bool = true
end

function tool_llm_chat(cfg::ToolLLMChatConfig, task::Dict)
    openai_cfg = OpenAI.OpenAIConfig(
        api_key = cfg.api_key,
        model = cfg.model_name,
        temperature = cfg.temperature,
        max_tokens = cfg.max_tokens,
        stream = cfg.stream
    )

    if !haskey(task, "prompt") || !(task["prompt"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'prompt' field")
    end

    try
        messages = [
            Dict("role" => "system", "content" => "You are an expert AI analyst specializing in DAO governance and blockchain technology."),
            Dict("role" => "user", "content" => task["prompt"])
        ]
        
        response = OpenAI.chat_completion(
            openai_cfg,
            messages
        )
        
        return Dict(
            "output" => response.choices[1].message.content,
            "success" => true,
            "model" => cfg.model_name,
            "finish_reason" => response.choices[1].finish_reason
        )
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

const TOOL_LLM_CHAT_METADATA = ToolMetadata(
    "llm_chat",
    "Advanced LLM chat tool using OpenAI's GPT-4 Turbo for enhanced DAO analysis."
)

const TOOL_LLM_CHAT_SPECIFICATION = ToolSpecification(
    tool_llm_chat,
    ToolLLMChatConfig,
    TOOL_LLM_CHAT_METADATA
)