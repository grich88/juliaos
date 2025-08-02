# -*- coding: utf-8 -*-
"""
Enhanced Leverage System - Integration Helper v3.2.0-Enhanced
================================================================

FIXED VERSION with Intelligent Induction Phase

One-liner functions for seamless integration with any application.
Now includes intelligent project analysis and developer consultation.

NEW FEATURES:
- Intelligent Induction Phase
- Project priority discovery
- Developer consultation integration
- Customized leverage targeting

PERFORMANCE IMPROVEMENTS:
- No hanging on complex codebases
- Cross-platform timeout support
- Intelligent file filtering
- Cached analysis results

Quick Start:
    from leverage_integration_helper_fixed import *
    
    # NEW: Run intelligent induction phase
    induction_results = run_intelligent_induction()
    
    # Quick health check
    health = health_check()
    
    # Scan and analyze
    scan_results = scan_my_app()
    
    # Apply targeted leverage
    result = leverage_my_app("payment_processor")

Example Output:
    {
        'exponential_value': 4.2,
        'integration_code': '# Enhanced code...',
        'business_value': 'high',
        'implementation_effort': 'medium'
    }
"""

import sys
import os
from typing import Dict, List, Any, Optional

# Import the enhanced core system
try:
    from .universal_leverage_system_core import UniversalLeverageSystem, ServiceInfo, LeverageAnalysis
    CORE_AVAILABLE = True
except ImportError:
    print("[WARNING] Enhanced Universal Leverage System core not found")
    print("[INFO] Make sure universal_leverage_system_core.py is in the same directory")
    CORE_AVAILABLE = False

class LeverageIntegration:
    """Main integration class for the leverage system"""
    def __init__(self):
        self.system = UniversalLeverageSystem() if CORE_AVAILABLE else None
        self.induction_available = INDUCTION_AVAILABLE
        
    def health_check(self, project_path="."):
        """Run health check"""
        return health_check(project_path)
        
    def scan_app(self, project_path="."):
        """Scan application"""
        return scan_my_app(project_path)
        
    def leverage_app(self, feature_name, project_path="."):
        """Apply leverage to app"""
        return leverage_my_app(feature_name, project_path)
        
    def run_induction(self, project_path="."):
        """Run intelligent induction"""
        return run_intelligent_induction(project_path)

# Import the induction engine
try:
    from .leverage_induction import LeverageInductionEngine, run_intelligent_induction as _run_intelligent_induction
    INDUCTION_AVAILABLE = True
except ImportError:
    print("[WARNING] Induction engine not available - basic analysis only")
    INDUCTION_AVAILABLE = False

def get_system_info() -> Dict[str, Any]:
    """
    📊 Get system availability and capabilities
    """
    return {
        'core_available': CORE_AVAILABLE,
        'induction_available': INDUCTION_AVAILABLE,
        'version': '3.2.0-Enhanced',
        'features': {
            'intelligent_induction': INDUCTION_AVAILABLE,
            'project_analysis': CORE_AVAILABLE,
            'developer_consultation': INDUCTION_AVAILABLE,
            'targeted_optimization': CORE_AVAILABLE and INDUCTION_AVAILABLE
        }
    }

def print_system_status():
    """Print current system status"""
    info = get_system_info()
    print("🚀 Enhanced Leverage System Status:")
    print(f"   Core System: {'✅ Available' if info['core_available'] else '❌ Not Available'}")
    print(f"   Induction Engine: {'✅ Available' if info['induction_available'] else '❌ Not Available'}")
    print(f"   Version: {info['version']}")

# Initialize the system
if CORE_AVAILABLE:
    _leverage_system = UniversalLeverageSystem()
    print("[LEVERAGE] 🚀 Universal Leverage System ready for seamless integration")
else:
    _leverage_system = None

# =============================================================================
# 🎯 NEW: INTELLIGENT INDUCTION FUNCTIONS
# =============================================================================

def run_intelligent_induction(project_path: str = ".") -> Dict[str, Any]:
    """
    🧠 NEW: Run complete intelligent induction phase
    
    Analyzes your project, consults with you about priorities,
    and generates a customized leverage strategy.
    
    Args:
        project_path: Path to your project (default: current directory)
    
    Returns:
        Complete induction results with analysis, strategy, and implementation plan
    
    Example:
        results = run_intelligent_induction()
        print(f"Primary targets: {results['leverage_strategy']['primary_targets']}")
    """
    if not INDUCTION_AVAILABLE:
        print("❌ Intelligent induction not available")
        print("📋 Falling back to basic analysis...")
        return scan_my_app(project_path)
    
    try:
        print("🧠 Starting Intelligent Induction Phase...")
        return _run_intelligent_induction(project_path)
    except Exception as e:
        print(f"⚠️ Induction failed: {e}")
        print("📋 Falling back to basic analysis...")
        return scan_my_app(project_path) if CORE_AVAILABLE else {'error': str(e)}

def quick_induction_analysis(project_path: str = ".") -> Dict[str, Any]:
    """
    ⚡ NEW: Quick induction analysis without developer consultation
    
    Runs automated project analysis only, skipping the interactive consultation.
    Good for CI/CD pipelines or automated analysis.
    
    Args:
        project_path: Path to your project
    
    Returns:
        Automated analysis results
    """
    if not INDUCTION_AVAILABLE:
        return {'error': 'Induction engine not available'}
    
    try:
        engine = LeverageInductionEngine()
        
        # Run only the automated analysis phase
        analysis = engine.analyze_project_structure()
        
        # Generate basic strategy without developer input
        basic_strategy = {
            'primary_targets': [],
            'recommendations': [
                "Run full induction for personalized strategy",
                "Consider performance optimization",
                "Review code architecture"
            ]
        }
        
        return {
            'project_analysis': analysis,
            'basic_strategy': basic_strategy,
            'analysis_type': 'automated_only'
        }
    except Exception as e:
        return {'error': str(e)}

def get_induction_recommendations(project_path: str = ".") -> List[str]:
    """
    💡 NEW: Get quick recommendations based on induction analysis
    
    Args:
        project_path: Path to your project
    
    Returns:
        List of actionable recommendations
    """
    if not INDUCTION_AVAILABLE:
        return ["Induction engine not available - run basic health check"]
    
    try:
        results = quick_induction_analysis(project_path)
        
        if 'error' in results:
            return [f"Analysis error: {results['error']}"]
        
        analysis = results.get('project_analysis', {})
        recommendations = []
        
        # Technology-specific recommendations
        tech_stack = analysis.get('technology_stack', {})
        
        if 'react' in tech_stack.get('frontend', []):
            recommendations.append("🔧 Consider React component optimization and memoization")
        
        if 'nodejs' in tech_stack.get('backend', []):
            recommendations.append("⚡ Review Node.js async patterns and performance")
        
        if any(db in tech_stack.get('database', []) for db in ['mongodb', 'postgresql', 'mysql']):
            recommendations.append("🗄️ Database query optimization opportunities identified")
        
        # Size-based recommendations
        size_metrics = analysis.get('project_size', {})
        if size_metrics.get('lines_of_code', 0) > 10000:
            recommendations.append("📊 Large codebase detected - consider modular optimization")
        
        # Complexity recommendations
        complexity = analysis.get('complexity_metrics', {}).get('overall_complexity', 0)
        if complexity > 7:
            recommendations.append("🧮 High complexity detected - prioritize refactoring")
        
        # Default recommendations
        if not recommendations:
            recommendations = [
                "🚀 Run full intelligent induction for personalized optimization",
                "📊 Project structure looks good - consider performance monitoring",
                "🎯 Focus on high-impact, low-effort improvements"
            ]
        
        return recommendations
        
    except Exception as e:
        return [f"Error generating recommendations: {e}"]

# =============================================================================
# 🔧 ENHANCED CORE FUNCTIONS (Now with induction support)
# =============================================================================

def health_check(project_path: str = ".") -> Dict[str, Any]:
    """
    🏥 Enhanced health check with induction insights
    
    Quick system health check with intelligent recommendations.
    
    Args:
        project_path: Path to check (default: current directory)
    
    Returns:
        Health status with recommendations
    
    Example:
        health = health_check()
        print(f"Status: {health['status']}")
        print(f"Recommendations: {health['recommendations']}")
    """
    if not CORE_AVAILABLE:
        return {
            'status': 'system_unavailable',
            'error': 'Core leverage system not available',
            'recommendations': ['Install universal_leverage_system_core_fixed.py']
        }
    
    try:
        result = _leverage_system.health_check(project_path)
        
        # Add induction recommendations if available
        if INDUCTION_AVAILABLE:
            induction_recs = get_induction_recommendations(project_path)
            result['induction_recommendations'] = induction_recs[:3]  # Top 3
        
        return result
    except Exception as e:
        return {
            'status': 'error',
            'error': str(e),
            'recommendations': ['Check project path and permissions']
        }

def scan_my_app(project_path: str = ".") -> Dict[str, Any]:
    """
    📊 Enhanced application scan with intelligent analysis
    
    Comprehensive scan of your application with priority scoring.
    
    Args:
        project_path: Path to scan (default: current directory)
    
    Returns:
        Detailed scan results with priority services
    
    Example:
        scan = scan_my_app()
        print(f"Found {scan['services_count']} services")
        print(f"Priority services: {scan['priority_services']}")
    """
    if not CORE_AVAILABLE:
        return {
            'error': 'Core system not available',
            'services': [],
            'ready': False
        }
    
    try:
        result = _leverage_system.scan_my_app(project_path)
        
        # Enhance with induction insights if available
        if INDUCTION_AVAILABLE and not result.get('error'):
            try:
                quick_analysis = quick_induction_analysis(project_path)
                if 'project_analysis' in quick_analysis:
                    result['induction_insights'] = {
                        'technology_stack': quick_analysis['project_analysis'].get('technology_stack', {}),
                        'complexity_score': quick_analysis['project_analysis'].get('complexity_metrics', {}).get('overall_complexity', 0),
                        'optimization_areas': quick_analysis['project_analysis'].get('potential_bottlenecks', [])
                    }
            except:
                pass  # Don't fail the scan if induction fails
        
        return result
    except Exception as e:
        return {
            'error': str(e),
            'services': [],
            'ready': False
        }

def leverage_my_app(feature_name: str, project_path: str = ".") -> Dict[str, Any]:
    """
    🎯 Enhanced feature leverage with intelligent targeting
    
    Apply exponential leverage to a specific feature with business context.
    
    Args:
        feature_name: Name of the feature to enhance
        project_path: Project path (default: current directory)
    
    Returns:
        Enhanced leverage results with business insights
    
    Example:
        result = leverage_my_app("user_authentication")
        print(f"Exponential value: {result['exponential_value']}×")
        print(f"Business value: {result['business_value']}")
        print(f"Implementation effort: {result['implementation_effort']}")
    """
    if not CORE_AVAILABLE:
        return {
            'error': 'Core system not available',
            'exponential_value': 1.0
        }
    
    try:
        # Get enhanced leverage results
        result = _leverage_system.leverage_my_app(feature_name, project_path)
        
        # Add induction context if available
        if INDUCTION_AVAILABLE:
            try:
                recommendations = get_induction_recommendations(project_path)
                result['induction_recommendations'] = recommendations[:2]  # Top 2 relevant
            except:
                pass  # Don't fail leverage if induction fails
        
        return result
    except Exception as e:
        return {
            'error': str(e),
            'feature_name': feature_name,
            'exponential_value': 1.0
        }

def auto_leverage_everything(project_path: str = ".") -> Dict[str, Any]:
    """
    💡 Enhanced auto-leverage with intelligent prioritization
    
    Automatically discover and leverage all opportunities with smart targeting.
    
    Args:
        project_path: Project path (default: current directory)
    
    Returns:
        Auto-leverage results with intelligent prioritization
    
    Example:
        results = auto_leverage_everything()
        print(f"Found {results['opportunities_found']} opportunities")
        for opp in results['leverage_opportunities']:
            print(f"- {opp['feature']}: {opp['leverage_result']['exponential_value']}×")
    """
    if not CORE_AVAILABLE:
        return {
            'error': 'Core system not available',
            'opportunities_found': 0
        }
    
    try:
        return _leverage_system.auto_leverage_everything(project_path)
    except Exception as e:
        return {
            'error': str(e),
            'opportunities_found': 0
        }

def run_intelligent_analysis(project_path: str = ".") -> Dict[str, Any]:
    """
    🧠 NEW: Run complete intelligent analysis pipeline
    
    Combines technical analysis with induction for comprehensive insights.
    
    Args:
        project_path: Project path (default: current directory)
    
    Returns:
        Complete analysis with technical and business insights
    
    Example:
        analysis = run_intelligent_analysis()
        strategy = analysis['targeted_strategy']
        plan = analysis['enhancement_plan']
    """
    if not CORE_AVAILABLE:
        return {'error': 'Core system not available'}
    
    try:
        return _leverage_system.run_intelligent_analysis(project_path)
    except Exception as e:
        return {'error': str(e)}

# =============================================================================
# 🎯 CONVENIENCE FUNCTIONS
# =============================================================================

def quick_leverage_check(feature_name: str, project_path: str = ".") -> float:
    """
    ⚡ Quick leverage potential check
    
    Args:
        feature_name: Feature to check
        project_path: Project path
    
    Returns:
        Exponential value as float
    """
    result = leverage_my_app(feature_name, project_path)
    return result.get('exponential_value', 1.0)

def get_top_opportunities(project_path: str = ".", limit: int = 5) -> List[Dict[str, Any]]:
    """
    🏆 Get top leverage opportunities
    
    Args:
        project_path: Project path
        limit: Number of opportunities to return
    
    Returns:
        List of top opportunities sorted by potential
    """
    try:
        auto_results = auto_leverage_everything(project_path)
        opportunities = auto_results.get('leverage_opportunities', [])
        
        # Sort by exponential value
        sorted_opportunities = sorted(
            opportunities,
            key=lambda x: x.get('leverage_result', {}).get('exponential_value', 0),
            reverse=True
        )
        
        return sorted_opportunities[:limit]
    except Exception as e:
        return [{'error': str(e)}]

def generate_leverage_report(project_path: str = ".") -> str:
    """
    📋 Generate comprehensive leverage report
    
    Args:
        project_path: Project path
    
    Returns:
        Formatted report string
    """
    try:
        # Get comprehensive analysis
        if INDUCTION_AVAILABLE and CORE_AVAILABLE:
            analysis = run_intelligent_analysis(project_path)
            
            report = f"""
🚀 ENHANCED LEVERAGE SYSTEM - COMPREHENSIVE REPORT
{'=' * 55}

📊 PROJECT ANALYSIS:
{'-' * 20}
Technology Stack: {', '.join(analysis.get('induction_results', {}).get('project_analysis', {}).get('technology_stack', {}).get('frontend', []))}
Services Found: {analysis.get('basic_analysis', {}).get('services_count', 0)}
Total Leverage: {analysis.get('basic_analysis', {}).get('total_leverage', 0):.1f}×

🎯 STRATEGIC TARGETS:
{'-' * 20}"""
            
            targets = analysis.get('targeted_strategy', {}).get('primary_targets', [])
            for i, target in enumerate(targets[:3], 1):
                area = target.get('area', 'Unknown')
                multiplier = target.get('potential_multiplier', 1.0)
                report += f"\n{i}. {area} - {multiplier:.1f}× potential"
            
            report += f"""

📋 IMPLEMENTATION PLAN:
{'-' * 20}"""
            
            phases = analysis.get('enhancement_plan', {}).get('phase_breakdown', {})
            for phase_name, phase_info in phases.items():
                report += f"\n• {phase_name}: {phase_info.get('name', 'TBD')}"
            
            report += f"""

💡 KEY RECOMMENDATIONS:
{'-' * 20}"""
            
            recommendations = get_induction_recommendations(project_path)
            for rec in recommendations[:3]:
                report += f"\n• {rec}"
            
            report += f"""

🎉 NEXT STEPS:
{'-' * 20}
1. 🚀 Implement priority targets
2. 📊 Monitor performance improvements  
3. 🔄 Iterate based on results
4. 📈 Track business impact

Generated by Enhanced Leverage System v3.2.0-Enhanced
"""
            return report
            
        else:
            # Basic report
            health = health_check(project_path)
            scan = scan_my_app(project_path)
            
            return f"""
🚀 BASIC LEVERAGE SYSTEM REPORT
{'=' * 35}

📊 BASIC ANALYSIS:
{'-' * 18}
Health Status: {health.get('status', 'unknown')}
Services Found: {scan.get('services_count', 0)}
Total Leverage: {scan.get('total_leverage', 0):.1f}×

💡 RECOMMENDATIONS:
{'-' * 18}"""+ '\n'.join(f"• {rec}" for rec in health.get('recommendations', [])[:3]) + """

🔧 SYSTEM STATUS:
{'-' * 16}
Core System: """ + ('✅ Available' if CORE_AVAILABLE else '❌ Not Available') + """
Induction Engine: """ + ('✅ Available' if INDUCTION_AVAILABLE else '❌ Not Available') + """

For enhanced analysis, install the induction engine.
"""
    
    except Exception as e:
        return f"❌ Report generation failed: {e}"

def print_quick_start_guide():
    """Print quick start guide for new users"""
    print("""
🚀 ENHANCED LEVERAGE SYSTEM - QUICK START GUIDE
==============================================

🎯 NEW: Intelligent Induction (Recommended)
  run_intelligent_induction()      # Complete analysis with consultation
  quick_induction_analysis()       # Automated analysis only
  get_induction_recommendations()  # Quick recommendations

🏥 Health & Analysis
  health_check()                   # System health check
  scan_my_app()                    # Discover services
  
🎯 Apply Leverage
  leverage_my_app("feature_name")  # Enhance specific feature
  auto_leverage_everything()       # Auto-discover and enhance
  
📊 Reporting & Insights
  generate_leverage_report()       # Comprehensive report
  get_top_opportunities()          # Best opportunities
  
💡 Pro Tips:
  • Start with run_intelligent_induction() for best results
  • Use health_check() to verify system status
  • Check get_system_info() for available features
  
🔗 Integration Example:
  from leverage_integration_helper_fixed import *
  
  # Run intelligent analysis
  results = run_intelligent_induction()
  
  # Apply to priority targets
  for target in results['targeted_strategy']['priority_features'][:3]:
      leverage_result = leverage_my_app(target)
      print(f"{target}: {leverage_result['exponential_value']}× leverage")
""")

# =============================================================================
# 🚀 MAIN DEMO FUNCTION
# =============================================================================

def run_demo():
    """
    🎬 Run a comprehensive demo of the enhanced leverage system
    """
    print("🚀 ENHANCED LEVERAGE SYSTEM - COMPREHENSIVE DEMO")
    print("=" * 55)
    
    # System status
    print("\n📊 System Status:")
    print_system_status()
    
    # Quick health check
    print("\n🏥 Health Check:")
    health = health_check()
    print(f"   Status: {health.get('status', 'unknown')}")
    print(f"   Services: {health.get('services_count', 0)}")
    
    # Quick scan
    print("\n📊 App Scan:")
    scan = scan_my_app()
    print(f"   Services Found: {len(scan.get('services', []))}")
    print(f"   Ready for Leverage: {scan.get('ready', False)}")
    
    # Induction demo if available
    if INDUCTION_AVAILABLE:
        print("\n🧠 Induction Recommendations:")
        recommendations = get_induction_recommendations()
        for i, rec in enumerate(recommendations[:3], 1):
            print(f"   {i}. {rec}")
    else:
        print("\n⚠️ Induction engine not available - install for enhanced analysis")
    
    # Quick leverage test
    print("\n🎯 Quick Leverage Test:")
    test_result = leverage_my_app("demo_feature")
    print(f"   Feature: demo_feature")
    print(f"   Exponential Value: {test_result.get('exponential_value', 1.0)}×")
    print(f"   Business Value: {test_result.get('business_value', 'standard')}")
    
    print("\n🎉 Demo Complete!")
    print("💡 Run print_quick_start_guide() for usage instructions")

# Auto-run demo if executed directly
if __name__ == "__main__":
    run_demo()

# Export all functions for easy importing
__all__ = [
    # NEW: Induction functions
    'run_intelligent_induction',
    'quick_induction_analysis', 
    'get_induction_recommendations',
    'run_intelligent_analysis',
    
    # Enhanced core functions
    'health_check',
    'scan_my_app', 
    'leverage_my_app',
    'auto_leverage_everything',
    
    # Convenience functions
    'quick_leverage_check',
    'get_top_opportunities',
    'generate_leverage_report',
    
    # Utility functions
    'get_system_info',
    'print_system_status',
    'print_quick_start_guide',
    'run_demo'
] 