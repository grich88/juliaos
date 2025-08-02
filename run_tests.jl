using Test
using JuliaOS.Agents.AgentMetrics

@testset "Monitoring Tests" begin
    # Test metric types
    @test isa(COUNTER, MetricType)
    @test isa(GAUGE, MetricType)
    @test isa(HISTOGRAM, MetricType)
    @test isa(SUMMARY, MetricType)

    # Test metric recording
    test_agent_id = "test_agent_1"
    init_agent_metrics(test_agent_id)

    # Test counter metric
    counter_metric = record_metric(test_agent_id, "test_counter", 1, type=COUNTER)
    @test counter_metric !== nothing
    @test counter_metric.type == COUNTER
    @test counter_metric.value == 1

    # Test gauge metric
    gauge_metric = record_metric(test_agent_id, "test_gauge", 42.5, type=GAUGE)
    @test gauge_metric !== nothing
    @test gauge_metric.type == GAUGE
    @test gauge_metric.value == 42.5

    # Test histogram metric
    histogram_values = [1.0, 2.0, 3.0, 4.0, 5.0]
    histogram_metric = record_metric(test_agent_id, "test_histogram", histogram_values, type=HISTOGRAM)
    @test histogram_metric !== nothing
    @test histogram_metric.type == HISTOGRAM
    @test histogram_metric.value == histogram_values

    # Test summary metric
    summary_data = Dict("count" => 5, "sum" => 15.0, "avg" => 3.0)
    summary_metric = record_metric(test_agent_id, "test_summary", summary_data, type=SUMMARY)
    @test summary_metric !== nothing
    @test summary_metric.type == SUMMARY
    @test summary_metric.value == summary_data

    # Test metric retrieval
    metrics = get_agent_metrics(test_agent_id)
    @test haskey(metrics, "test_counter")
    @test haskey(metrics, "test_gauge")
    @test haskey(metrics, "test_histogram")
    @test haskey(metrics, "test_summary")

    # Test metric reset
    reset_metrics(test_agent_id)
    empty_metrics = get_agent_metrics(test_agent_id)
    @test isempty(empty_metrics)
end