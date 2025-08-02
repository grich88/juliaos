#!/usr/bin/env python3
"""
🚀 AdeptDAO Enhanced Leverage Integration
=======================================

Integrates the Enhanced Leverage System with AdeptDAO for intelligent optimization.
"""

import os
import sys
from pathlib import Path

# Add leverage system to path
LEVERAGE_PATH = Path(__file__).parent.parent / "leverage_system"
sys.path.append(str(LEVERAGE_PATH))

try:
    from leverage_system.leverage_integration_helper import (
        run_intelligent_induction,
        health_check,
        scan_my_app,
        leverage_my_app,
        generate_leverage_report,
        print_system_status
    )
    LEVERAGE_AVAILABLE = True
except ImportError:
    print("⚠️ Enhanced Leverage System not found")
    print(f"Expected path: {LEVERAGE_PATH}")
    LEVERAGE_AVAILABLE = False

class AdeptDAOLeverageOptimizer:
    """Enhanced optimization for AdeptDAO using intelligent leverage system."""
    
    def __init__(self, project_path="."):
        self.project_path = project_path
        self.induction_results = None
        self.health_status = None
        self.scan_results = None
        
        if not LEVERAGE_AVAILABLE:
            print("❌ Leverage system not available - optimization disabled")
            return
            
        print("🚀 AdeptDAO Leverage Optimizer initialized")
        print_system_status()
    
    def run_comprehensive_analysis(self):
        """Run complete analysis of AdeptDAO codebase."""
        if not LEVERAGE_AVAILABLE:
            return {"error": "Leverage system not available"}
        
        print("\n🧠 Running Comprehensive Analysis...")
        print("=" * 50)
        
        try:
            # Step 1: Health Check
            print("\n📊 Running Health Check...")
            self.health_status = health_check(self.project_path)
            print(f"Status: {self.health_status.get('status', 'unknown')}")
            
            # Step 2: Intelligent Induction
            print("\n🎯 Running Intelligent Induction...")
            self.induction_results = run_intelligent_induction(self.project_path)
            
            # Step 3: Detailed Scan
            print("\n🔍 Running Detailed Scan...")
            self.scan_results = scan_my_app(self.project_path)
            
            # Generate comprehensive report
            report = generate_leverage_report(self.project_path)
            
            results = {
                "health_status": self.health_status,
                "induction_results": self.induction_results,
                "scan_results": self.scan_results,
                "report": report
            }
            
            # Save report to file
            report_path = Path(self.project_path) / "leverage_analysis_report.txt"
            with open(report_path, "w") as f:
                f.write(report)
            
            print(f"\n✅ Analysis complete! Report saved to {report_path}")
            return results
            
        except Exception as e:
            print(f"❌ Analysis failed: {e}")
            return {"error": str(e)}
    
    def optimize_component(self, component_name):
        """Optimize a specific component using intelligent leverage."""
        if not LEVERAGE_AVAILABLE:
            return {"error": "Leverage system not available"}
        
        print(f"\n🎯 Optimizing component: {component_name}")
        
        try:
            result = leverage_my_app(component_name, self.project_path)
            
            print(f"✅ Optimization complete!")
            print(f"📈 Exponential value: {result.get('exponential_value', 1.0)}×")
            print(f"💼 Business value: {result.get('business_value', 'standard')}")
            print(f"⚙️ Implementation effort: {result.get('implementation_effort', 'unknown')}")
            
            if result.get('optimization_recommendations'):
                print("\n💡 Optimization Recommendations:")
                for rec in result['optimization_recommendations']:
                    print(f"  • {rec}")
            
            return result
            
        except Exception as e:
            print(f"❌ Optimization failed: {e}")
            return {"error": str(e)}
    
    def optimize_dao_analysis(self):
        """Optimize DAO analysis components."""
        components = [
            "proposal_analysis",
            "sentiment_analysis",
            "financial_analysis",
            "technical_analysis",
            "governance_metrics"
        ]
        
        results = {}
        for component in components:
            print(f"\n🔄 Optimizing {component}...")
            result = self.optimize_component(component)
            results[component] = result
        
        return results
    
    def optimize_frontend_components(self):
        """Optimize React frontend components."""
        components = [
            "proposal_dashboard",
            "voting_interface",
            "analytics_dashboard",
            "wallet_integration",
            "governance_interface"
        ]
        
        results = {}
        for component in components:
            print(f"\n🔄 Optimizing {component}...")
            result = self.optimize_component(component)
            results[component] = result
        
        return results
    
    def optimize_backend_services(self):
        """Optimize FastAPI backend services."""
        services = [
            "proposal_service",
            "analysis_service",
            "blockchain_service",
            "cache_service",
            "metrics_service"
        ]
        
        results = {}
        for service in services:
            print(f"\n🔄 Optimizing {service}...")
            result = self.optimize_component(service)
            results[service] = result
        
        return results

def main():
    """Run complete optimization of AdeptDAO."""
    optimizer = AdeptDAOLeverageOptimizer()
    
    # Run comprehensive analysis
    print("\n🚀 Starting AdeptDAO Optimization")
    print("=" * 50)
    
    analysis = optimizer.run_comprehensive_analysis()
    if "error" in analysis:
        print(f"❌ Analysis failed: {analysis['error']}")
        return
    
    # Optimize each component
    print("\n🎯 Starting Component Optimization")
    print("=" * 50)
    
    # DAO Analysis
    print("\n📊 Optimizing DAO Analysis Components...")
    dao_results = optimizer.optimize_dao_analysis()
    
    # Frontend
    print("\n🖥️ Optimizing Frontend Components...")
    frontend_results = optimizer.optimize_frontend_components()
    
    # Backend
    print("\n⚙️ Optimizing Backend Services...")
    backend_results = optimizer.optimize_backend_services()
    
    # Generate final report
    print("\n📋 Generating Final Report...")
    final_report = {
        "analysis": analysis,
        "optimizations": {
            "dao_analysis": dao_results,
            "frontend": frontend_results,
            "backend": backend_results
        }
    }
    
    # Save final report
    report_path = Path("optimization_report.json")
    import json
    with open(report_path, "w") as f:
        json.dump(final_report, f, indent=2)
    
    print(f"\n✅ Optimization complete! Final report saved to {report_path}")

if __name__ == "__main__":
    main()