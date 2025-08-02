"""
Tests for the Enhanced Leverage System
====================================

Comprehensive test suite covering core functionality,
induction engine, and integration features.
"""

import unittest
from pathlib import Path
from juliaos.leverage import (
    LeverageInductionEngine,
    run_intelligent_induction,
    quick_induction_analysis,
    get_induction_recommendations,
    health_check,
    scan_my_app,
    leverage_my_app
)

class TestLeverageSystem(unittest.TestCase):
    """Test suite for the Enhanced Leverage System"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_project_path = str(Path(__file__).parent / "test_project")
        self.engine = LeverageInductionEngine()
    
    def test_induction_engine_initialization(self):
        """Test that the induction engine initializes correctly"""
        self.assertIsNotNone(self.engine)
        self.assertEqual(self.engine.project_path, ".")
    
    def test_quick_analysis(self):
        """Test quick analysis functionality"""
        analysis = quick_induction_analysis(self.test_project_path)
        self.assertIsInstance(analysis, dict)
        self.assertIn('project_analysis', analysis)
        self.assertIn('basic_strategy', analysis)
    
    def test_recommendations(self):
        """Test recommendation generation"""
        recommendations = get_induction_recommendations(self.test_project_path)
        self.assertIsInstance(recommendations, list)
        self.assertTrue(len(recommendations) > 0)
    
    def test_health_check(self):
        """Test system health check"""
        health = health_check(self.test_project_path)
        self.assertIsInstance(health, dict)
        self.assertIn('status', health)
        self.assertIn('recommendations', health)
    
    def test_app_scan(self):
        """Test application scanning"""
        scan = scan_my_app(self.test_project_path)
        self.assertIsInstance(scan, dict)
        self.assertIn('services', scan)
        self.assertIn('ready', scan)
    
    def test_feature_leverage(self):
        """Test feature-specific leverage"""
        result = leverage_my_app("test_feature", self.test_project_path)
        self.assertIsInstance(result, dict)
        self.assertIn('exponential_value', result)
        self.assertIn('business_value', result)
        self.assertIn('implementation_effort', result)
    
    def test_intelligent_induction(self):
        """Test complete induction process"""
        results = run_intelligent_induction(self.test_project_path)
        self.assertIsInstance(results, dict)
        self.assertIn('project_analysis', results)
        self.assertIn('leverage_strategy', results)
        self.assertIn('implementation_plan', results)

if __name__ == '__main__':
    unittest.main()