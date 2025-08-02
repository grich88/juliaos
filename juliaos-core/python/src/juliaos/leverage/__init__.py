"""
🚀 Enhanced Leverage System - Core Package
========================================

Intelligent project optimization and leverage system with automated analysis
and developer consultation capabilities.

Main components:
- Intelligent Induction Engine
- Integration Helper
- Universal Leverage System Core
"""

from .leverage_induction import (
    LeverageInductionEngine,
    run_intelligent_induction,
    ProjectMetrics,
    InductionQuestion
)

from .leverage_integration_helper import (
    run_intelligent_induction as run_induction,
    quick_induction_analysis,
    get_induction_recommendations,
    health_check,
    scan_my_app,
    leverage_my_app,
    auto_leverage_everything,
    get_system_info,
    print_system_status,
    print_quick_start_guide,
    run_demo
)

__version__ = "3.2.0"
__all__ = [
    # Core classes
    'LeverageInductionEngine',
    'ProjectMetrics',
    'InductionQuestion',
    
    # Main functions
    'run_intelligent_induction',
    'run_induction',
    'quick_induction_analysis',
    'get_induction_recommendations',
    
    # Helper functions
    'health_check',
    'scan_my_app',
    'leverage_my_app',
    'auto_leverage_everything',
    'get_system_info',
    'print_system_status',
    'print_quick_start_guide',
    'run_demo'
]