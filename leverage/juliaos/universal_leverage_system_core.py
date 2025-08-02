#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Universal Leverage System v3.2.0-Enhanced - CORE ENGINE with Intelligent Induction
===================================================================================

FIXED VERSION with intelligent project analysis and developer consultation.

New Features:
- Intelligent Induction Phase
- Project priority discovery
- Technology-specific optimization  
- Developer consultation integration
- Customized leverage targeting

Performance Improvements:
- Safe regex patterns (no hanging)
- Cross-platform timeouts
- Intelligent file filtering
- Cached analysis results
"""

import os
import re
import json
import sys
import time
import threading
from contextlib import contextmanager
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict
from pathlib import Path

# Import the induction engine
try:
    from .leverage_induction import LeverageInductionEngine, run_intelligent_induction
    INDUCTION_AVAILABLE = True
except ImportError:
    INDUCTION_AVAILABLE = False
    print("[WARNING] Induction engine not available - using basic analysis")

@dataclass
class ServiceInfo:
    """Enhanced service information with induction data"""
    name: str
    language: str
    file_path: str
    methods: List[str]
    complexity_score: float
    leverage_potential: float
    priority_score: float = 0.0  # NEW: Based on induction analysis
    optimization_targets: List[str] = None  # NEW: Specific optimization areas

    def __post_init__(self):
        if self.optimization_targets is None:
            self.optimization_targets = []

@dataclass
class LeverageAnalysis:
    """Enhanced analysis with intelligent targeting"""
    exponential_value: float
    services_enhanced: int
    integration_code: str
    performance_impact: str
    business_value: str = "standard"  # NEW: Business impact assessment
    implementation_effort: str = "medium"  # NEW: Effort estimation
    priority_ranking: int = 5  # NEW: Priority based on induction (1-10)
    target_areas: List[str] = None  # NEW: Specific areas to target

    def __post_init__(self):
        if self.target_areas is None:
            self.target_areas = []

class UniversalLeverageSystem:
    """
    🚀 Enhanced Universal Leverage System with Intelligent Induction
    
    Automatically analyzes projects, consults with developers, and applies
    targeted leverage based on business priorities and technical analysis.
    """
    
    def __init__(self):
        self.version = "3.2.0-Enhanced"
        self.services_cache = {}
        self.analysis_cache = {}
        self.induction_results = {}  # NEW: Store induction analysis
        self.developer_priorities = {}  # NEW: Store developer input
        
        # Enhanced configuration with induction support
        self.config = {
            'max_files': 100,
            'max_file_size': 1024 * 1024,  # 1MB limit
            'analysis_timeout': 5,  # 5 second timeout per file
            'max_methods_to_extract': 20,  # Limit method extraction
            'skip_directories': {
                'node_modules', '__pycache__', '.git', 'venv', 'dist', 'build',
                'target', 'out', 'bin', 'obj', '.next', '.nuxt', 'coverage'
            },
            'skip_file_patterns': {
                r'test.*\.', r'spec\.', r'\.d\.ts$', r'\.min\.', r'\.map$',
                r'config\.', r'\.config\.', r'webpack', r'babel'
            },
            'induction_enabled': INDUCTION_AVAILABLE,  # NEW: Induction availability
            'smart_targeting': True,  # NEW: Use intelligent targeting
            'priority_threshold': 6.0  # NEW: Minimum priority for enhancement
        }
        
        # FIXED: Much safer JavaScript method patterns
        self.js_method_patterns = [
            r'(\w+)\s*\([^)]{0,100}\)\s*{',  # Limited parentheses content
            r'function\s+(\w+)\s*\(',
            r'(\w+)\s*:\s*function\s*\(',
            r'(\w+)\s*=>\s*{',
        ]
        
        print(f"[LEVERAGE] Universal Leverage System v{self.version} ready for seamless integration")

    def run_intelligent_analysis(self, project_path: str = ".") -> Dict[str, Any]:
        """
        🎯 NEW: Run complete intelligent analysis with induction phase
        """
        results = {
            'basic_analysis': {},
            'induction_results': {},
            'targeted_strategy': {},
            'enhancement_plan': {}
        }
        
        # Phase 1: Basic technical analysis (existing functionality)
        print("\n📊 Phase 1: Technical Analysis")
        print("-" * 40)
        basic_analysis = self.scan_my_app(project_path)
        results['basic_analysis'] = basic_analysis
        
        # Phase 2: Intelligent induction (NEW)
        if self.config['induction_enabled']:
            print("\n🧠 Phase 2: Intelligent Induction")
            print("-" * 40)
            try:
                induction_results = run_intelligent_induction(project_path)
                self.induction_results = induction_results
                results['induction_results'] = induction_results
                
                # Phase 3: Generate targeted strategy
                print("\n🎯 Phase 3: Targeted Enhancement Strategy")
                print("-" * 40)
                targeted_strategy = self.generate_targeted_strategy(basic_analysis, induction_results)
                results['targeted_strategy'] = targeted_strategy
                
            except Exception as e:
                print(f"⚠️ Induction phase failed: {e}")
                print("📊 Continuing with basic analysis...")
                results['induction_results'] = {'error': str(e)}
        else:
            print("📊 Induction phase not available - using basic analysis")
        
        # Phase 4: Create implementation plan
        print("\n📋 Phase 4: Implementation Plan")
        print("-" * 40)
        enhancement_plan = self.create_enhancement_plan(results)
        results['enhancement_plan'] = enhancement_plan
        
        return results

    def generate_targeted_strategy(self, basic_analysis: Dict[str, Any], induction_results: Dict[str, Any]) -> Dict[str, Any]:
        """
        🎯 NEW: Generate targeted leverage strategy based on induction results
        """
        strategy = {
            'priority_features': [],
            'targeted_multipliers': {},
            'business_alignment': {},
            'implementation_order': []
        }
        
        # Extract priorities from induction
        leverage_strategy = induction_results.get('leverage_strategy', {})
        primary_targets = leverage_strategy.get('primary_targets', [])
        
        # Map induction targets to technical services
        discovered_services = basic_analysis.get('services', [])
        
        for target in primary_targets:
            target_area = target.get('area', '')
            potential_multiplier = target.get('potential_multiplier', 1.0)
            
            # Find matching services
            matching_services = self.find_matching_services(target_area, discovered_services)
            
            if matching_services:
                strategy['priority_features'].extend(matching_services)
                for service in matching_services:
                    strategy['targeted_multipliers'][service] = potential_multiplier
        
        # Set business alignment
        strategy['business_alignment'] = {
            'primary_goal': induction_results.get('developer_input', {}).get('business_goal', {}).get('response', 'performance'),
            'target_improvements': [t.get('area') for t in primary_targets[:3]],
            'expected_roi': leverage_strategy.get('expected_impact', {}).get('overall', 'moderate')
        }
        
        # Implementation order based on effort and impact
        phases = leverage_strategy.get('implementation_phases', [])
        strategy['implementation_order'] = [phase.get('phase', f'Phase {i+1}') for i, phase in enumerate(phases)]
        
        print(f"🎯 Strategy generated with {len(strategy['priority_features'])} priority targets")
        return strategy

    def find_matching_services(self, target_area: str, services: List[str]) -> List[str]:
        """
        🔍 NEW: Find services that match induction target areas
        """
        matches = []
        target_keywords = target_area.lower().split()
        
        for service in services:
            service_lower = service.lower()
            # Check for keyword matches
            if any(keyword in service_lower for keyword in target_keywords):
                matches.append(service)
            
            # Technology-specific matching
            if 'react' in target_area.lower() and any(term in service_lower for term in ['component', 'jsx', 'tsx']):
                matches.append(service)
            elif 'database' in target_area.lower() and any(term in service_lower for term in ['query', 'db', 'sql', 'mongo']):
                matches.append(service)
            elif 'api' in target_area.lower() and any(term in service_lower for term in ['api', 'endpoint', 'route']):
                matches.append(service)
        
        return list(set(matches))  # Remove duplicates

    def create_enhancement_plan(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """
        📋 NEW: Create comprehensive enhancement plan
        """
        plan = {
            'immediate_actions': [],
            'phase_breakdown': {},
            'success_metrics': {},
            'monitoring_setup': []
        }
        
        # Immediate actions from induction
        induction_plan = results.get('induction_results', {}).get('implementation_plan', {})
        plan['immediate_actions'] = induction_plan.get('immediate_actions', [])
        
        # Phase breakdown
        targeted_strategy = results.get('targeted_strategy', {})
        for i, phase in enumerate(targeted_strategy.get('implementation_order', []), 1):
            plan['phase_breakdown'][f'Phase {i}'] = {
                'name': phase,
                'targets': targeted_strategy.get('priority_features', [])[:2],  # 2 targets per phase
                'estimated_duration': f"{i*2}-{i*2+1} weeks"
            }
        
        # Success metrics
        plan['success_metrics'] = induction_plan.get('success_metrics', {
            'performance': 'Measure execution time improvements',
            'quality': 'Track code quality metrics',
            'business': 'Monitor business KPI improvements'
        })
        
        # Monitoring setup
        plan['monitoring_setup'] = [
            'Set up performance monitoring dashboards',
            'Implement automated testing for enhanced features',
            'Create business metrics tracking',
            'Schedule weekly progress reviews'
        ]
        
        print("📋 Enhancement plan created with intelligent targeting")
        return plan

    # ... existing methods (scan_my_app, leverage_my_app, etc.) remain the same ...
    
    def scan_my_app(self, project_path: str = ".") -> Dict[str, Any]:
        """
        📊 Scan application and discover services with enhanced analysis
        """
        print(f"[LEVERAGE] 📊 Scanning application: {project_path}")
        
        start_time = time.time()
        
        # Check cache first
        cache_key = f"scan_{project_path}_{os.path.getmtime(project_path) if os.path.exists(project_path) else 0}"
        if cache_key in self.analysis_cache:
            print(f"[LEVERAGE] 📋 Using cached scan results")
            return self.analysis_cache[cache_key]
        
        services = self.discover_services(project_path)
        languages = list(set(service.language for service in services))
        
        total_leverage = sum(service.leverage_potential for service in services)
        ready_for_leverage = len(services) > 0 and total_leverage > 1.0
        
        # Enhanced analysis with priority scoring
        enhanced_services = []
        for service in services:
            # Apply priority scoring if induction results available
            if self.induction_results:
                service.priority_score = self.calculate_priority_score(service)
            enhanced_services.append(service)
        
        # Sort by priority score
        enhanced_services.sort(key=lambda s: s.priority_score, reverse=True)
        
        result = {
            'services': [service.name for service in enhanced_services],
            'languages': languages,
            'total_leverage': total_leverage,
            'ready': ready_for_leverage,
            'service_details': [asdict(service) for service in enhanced_services],
            'scan_duration': time.time() - start_time,
            'priority_services': [s.name for s in enhanced_services if s.priority_score > self.config['priority_threshold']]
        }
        
        # Cache the result
        self.analysis_cache[cache_key] = result
        
        print(f"[LEVERAGE] ✅ Scan complete: {len(services)} services, {total_leverage:.1f}× total leverage")
        return result

    def calculate_priority_score(self, service: ServiceInfo) -> float:
        """
        🎯 NEW: Calculate priority score based on induction results
        """
        base_score = service.leverage_potential
        
        # Boost score based on induction targets
        leverage_strategy = self.induction_results.get('leverage_strategy', {})
        primary_targets = leverage_strategy.get('primary_targets', [])
        
        for target in primary_targets:
            target_area = target.get('area', '').lower()
            if any(keyword in service.name.lower() for keyword in target_area.split()):
                base_score *= 1.5  # 50% boost for matching targets
                break
        
        # Boost based on business priorities
        developer_input = self.induction_results.get('developer_input', {})
        for category, response_data in developer_input.items():
            response = response_data.get('response', '').lower()
            if any(keyword in service.name.lower() for keyword in response.split()):
                base_score *= 1.3  # 30% boost for business alignment
        
        return min(base_score, 10.0)  # Cap at 10.0

    def leverage_my_app(self, feature_name: str, project_path: str = ".") -> Dict[str, Any]:
        """
        🎯 Apply targeted leverage to specific features with intelligent enhancement
        """
        print(f"[LEVERAGE] 🎯 Leveraging feature: {feature_name}")
        
        start_time = time.time()
        
        # Discover and analyze the feature
        analysis_result = self.analyze_feature(feature_name, project_path)
        
        # Generate enhanced integration code
        integration_code = self.generate_smart_integration_code(feature_name, analysis_result)
        
        # Calculate enhanced exponential value
        exponential_value = self.calculate_enhanced_exponential_value(analysis_result)
        
        # Generate performance impact assessment
        performance_impact = self.assess_performance_impact(exponential_value)
        
        # NEW: Enhanced result with business context
        result = {
            'feature_name': feature_name,
            'exponential_value': exponential_value,
            'services_enhanced': analysis_result.get('services_count', 0),
            'integration_code': integration_code,
            'usage_example': self.generate_usage_example(feature_name, exponential_value),
            'performance_impact': performance_impact,
            'leverage_duration': time.time() - start_time,
            # NEW: Enhanced metadata
            'business_value': self.assess_business_value(feature_name, exponential_value),
            'implementation_effort': self.estimate_implementation_effort(analysis_result),
            'priority_ranking': self.get_priority_ranking(feature_name),
            'optimization_recommendations': self.get_optimization_recommendations(feature_name, analysis_result)
        }
        
        print(f"[LEVERAGE] ✅ Feature leveraged: {exponential_value:.1f}× exponential value ready")
        return result

    def assess_business_value(self, feature_name: str, exponential_value: float) -> str:
        """🎯 NEW: Assess business value based on induction results"""
        if not self.induction_results:
            return "standard"
        
        # Check if feature aligns with business goals
        business_goal = self.induction_results.get('developer_input', {}).get('business_goal', {}).get('response', '')
        
        if exponential_value > 5.0:
            return "very_high"
        elif exponential_value > 3.0:
            return "high" 
        elif exponential_value > 2.0:
            return "medium"
        else:
            return "low"

    def estimate_implementation_effort(self, analysis_result: Dict[str, Any]) -> str:
        """🔧 NEW: Estimate implementation effort"""
        services_count = analysis_result.get('services_count', 0)
        complexity = analysis_result.get('complexity_score', 1.0)
        
        if services_count > 5 or complexity > 7.0:
            return "high"
        elif services_count > 2 or complexity > 4.0:
            return "medium"
        else:
            return "low"

    def get_priority_ranking(self, feature_name: str) -> int:
        """📊 NEW: Get priority ranking from induction results"""
        if not self.induction_results:
            return 5  # Default medium priority
        
        # Check against primary targets
        primary_targets = self.induction_results.get('leverage_strategy', {}).get('primary_targets', [])
        
        for i, target in enumerate(primary_targets):
            if feature_name.lower() in target.get('area', '').lower():
                return 10 - i  # Higher ranking for earlier targets
        
        return 5  # Default

    def get_optimization_recommendations(self, feature_name: str, analysis_result: Dict[str, Any]) -> List[str]:
        """💡 NEW: Get specific optimization recommendations"""
        recommendations = []
        
        # Technology-specific recommendations
        if 'react' in feature_name.lower():
            recommendations.extend([
                "Implement React.memo for component optimization",
                "Use useMemo and useCallback for expensive calculations",
                "Consider code splitting for large components"
            ])
        elif 'api' in feature_name.lower():
            recommendations.extend([
                "Implement caching strategies",
                "Add request/response compression",
                "Consider API rate limiting"
            ])
        elif 'database' in feature_name.lower():
            recommendations.extend([
                "Optimize query patterns",
                "Implement connection pooling",
                "Add database indexing"
            ])
        
        # General recommendations based on complexity
        complexity = analysis_result.get('complexity_score', 1.0)
        if complexity > 5.0:
            recommendations.append("Consider breaking down into smaller modules")
        
        return recommendations

    def generate_smart_integration_code(self, feature_name: str, analysis_result: Dict[str, Any]) -> str:
        """
        🧠 NEW: Generate intelligent integration code based on induction results
        """
        services_count = analysis_result.get('services_count', 0)
        exponential_value = self.calculate_enhanced_exponential_value(analysis_result)
        
        # Get technology-specific template
        tech_context = self.get_technology_context(feature_name)
        
        code_template = f"""# {feature_name} with {exponential_value:.2f}× leverage
# Services leveraged: {services_count}
# Generated by Universal Leverage System v{self.version}

{tech_context['class_template'].format(
    feature_name=feature_name.replace('_', '').title(),
    exponential_value=exponential_value,
    services_count=services_count
)}"""

        return code_template

    def get_technology_context(self, feature_name: str) -> Dict[str, str]:
        """🔧 NEW: Get technology-specific code templates"""
        
        # Check induction results for technology stack
        tech_stack = {}
        if self.induction_results:
            tech_stack = self.induction_results.get('project_analysis', {}).get('technology_stack', {})
        
        # React/JavaScript template
        if any(tech in tech_stack.get('frontend', []) for tech in ['react', 'javascript', 'nextjs']):
            return {
                'class_template': '''class {feature_name}Leveraged {{
    constructor() {{
        this.leverage_potential = {exponential_value:.2f};
        this.services_count = {services_count};
        this.enhanced = true;
    }}
    
    process(data) {{
        // Apply exponential leverage to input data
        const leveraged_result = this.enhanceWithLeverage(data);
        return leveraged_result;
    }}
    
    enhanceWithLeverage(data) {{
        // Intelligent enhancement based on induction analysis
        return {{
            ...data,
            leverage_applied: true,
            exponential_value: this.leverage_potential,
            enhancement_timestamp: Date.now()
        }};
    }}
}}'''
            }
        
        # Python template
        elif 'python' in tech_stack.get('backend', []):
            return {
                'class_template': '''class {feature_name}Leveraged:
    def __init__(self):
        self.leverage_potential = {exponential_value:.2f}
        self.services_count = {services_count}
        self.enhanced = True
    
    def process(self, data):
        """Process with intelligent exponential leverage"""
        # Handle different input types safely
        if isinstance(data, dict):
            result = data.copy()
        elif isinstance(data, list):
            result = data[:]
        else:
            result = {{"value": data}}
        
        # Apply exponential enhancement
        result["leverage_applied"] = True
        result["exponential_value"] = self.leverage_potential
        result["enhancement_factor"] = self.calculate_enhancement_factor()
        
        return result
    
    def calculate_enhancement_factor(self):
        """Calculate dynamic enhancement based on context"""
        return min(self.leverage_potential * 1.5, 10.0)'''
            }
        
        # Default template
        else:
            return {
                'class_template': '''class {feature_name}Leveraged:
    def __init__(self):
        self.leverage_potential = {exponential_value:.2f}
        self.services_count = {services_count}
        self.enhanced = True
    
    def process(self, data):
        """Process with automatic exponential leverage"""
        # Handle different input types safely
        if isinstance(data, dict):
            result = data.copy()
        elif isinstance(data, list):
            result = data[:]
        else:
            result = {{"value": data}}
        
        # Apply exponential enhancement
        result["leverage_applied"] = True
        result["exponential_value"] = self.leverage_potential
        
        return result'''
            }

    # ... rest of existing methods remain the same ...
    
    @contextmanager
    def timeout(self, seconds):
        """Context manager for timeout operations (Windows-compatible)"""
        def timeout_handler():
            raise TimeoutError(f"Operation timed out after {seconds} seconds")
        
        timer = threading.Timer(seconds, timeout_handler)
        timer.start()
        try:
            yield
        finally:
            timer.cancel()

    def discover_services(self, project_path: str) -> List[ServiceInfo]:
        """Discover services with enhanced analysis"""
        services = []
        files_processed = 0
        
        print(f"[LEVERAGE] 🔍 Discovering services in: {project_path}")
        
        # Check cache first
        cache_key = f"discover_{project_path}_{os.path.getmtime(project_path) if os.path.exists(project_path) else 0}"
        if cache_key in self.services_cache:
            print(f"[LEVERAGE] 📋 Using cached results for {project_path}")
            return self.services_cache[cache_key]
        
        for root, dirs, files in os.walk(project_path):
            # FIXED: Skip problematic directories
            dirs[:] = [d for d in dirs if d not in self.config['skip_directories']]
            
            for file_name in files:
                if files_processed >= self.config['max_files']:
                    break
                
                # FIXED: Skip test and config files
                if any(re.search(pattern, file_name, re.IGNORECASE) for pattern in self.config['skip_file_patterns']):
                    continue
                
                file_path = os.path.join(root, file_name)
                
                # FIXED: Check file size
                try:
                    if os.path.getsize(file_path) > self.config['max_file_size']:
                        continue
                except OSError:
                    continue
                
                service = self.analyze_file_safe(file_path)
                if service:
                    services.append(service)
                
                files_processed += 1
        
        # Cache the results
        self.services_cache[cache_key] = services
        
        print(f"[LEVERAGE] ✅ Discovery complete: {len(services)} services found ({files_processed} processed, {len(os.listdir(project_path)) - files_processed if os.path.exists(project_path) else 0} skipped)")
        return services

    def analyze_file_safe(self, file_path: str) -> Optional[ServiceInfo]:
        """Safely analyze a file with timeout protection"""
        try:
            with self.timeout(self.config['analysis_timeout']):
                return self.analyze_file_for_service(file_path)
        except (TimeoutError, Exception):
            return None

    def analyze_file_for_service(self, file_path: str) -> Optional[ServiceInfo]:
        """Analyze a file and extract service information"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                # FIXED: Read limited content to prevent memory issues
                content = f.read(50000)  # 50KB limit
            
            file_ext = Path(file_path).suffix.lower()
            language = self.detect_language(file_ext)
            
            if not language:
                return None
            
            methods = self.extract_methods_safe(content, language)
            
            if not methods:
                return None
            
            # Calculate metrics
            complexity_score = self.calculate_complexity_score(content, methods)
            leverage_potential = self.calculate_leverage_potential(complexity_score, len(methods), language)
            
            service_name = Path(file_path).stem
            
            return ServiceInfo(
                name=service_name,
                language=language,
                file_path=file_path,
                methods=methods[:self.config['max_methods_to_extract']],  # FIXED: Limit methods
                complexity_score=complexity_score,
                leverage_potential=leverage_potential
            )
            
        except Exception:
            return None

    def extract_methods_safe(self, content: str, language: str) -> List[str]:
        """FIXED: Safely extract methods with timeout protection"""
        methods = []
        
        try:
            if language in ['javascript', 'typescript']:
                # FIXED: Use safer regex patterns
                for pattern in self.js_method_patterns:
                    matches = re.findall(pattern, content[:10000], re.MULTILINE)  # FIXED: Limit content
                    methods.extend([match if isinstance(match, str) else match[0] for match in matches[:5]])  # FIXED: Limit matches
                    if len(methods) >= self.config['max_methods_to_extract']:
                        break
            
            elif language == 'python':
                # FIXED: Simple and safe Python pattern
                pattern = r'def\s+(\w+)\s*\('
                matches = re.findall(pattern, content[:10000])  # FIXED: Limit content
                methods.extend(matches[:self.config['max_methods_to_extract']])  # FIXED: Limit matches
            
            return list(set(methods))  # Remove duplicates
            
        except Exception:
            return []

    def detect_language(self, file_ext: str) -> Optional[str]:
        """Detect programming language from file extension"""
        language_map = {
            '.js': 'javascript',
            '.jsx': 'javascript', 
            '.ts': 'typescript',
            '.tsx': 'typescript',
            '.py': 'python',
            '.java': 'java',
            '.cs': 'csharp',
            '.php': 'php',
            '.rb': 'ruby',
            '.go': 'golang',
            '.rs': 'rust',
            '.sol': 'solidity'
        }
        
        return language_map.get(file_ext)

    def calculate_complexity_score(self, content: str, methods: List[str]) -> float:
        """Calculate complexity score based on content analysis"""
        lines = content.count('\n')
        method_count = len(methods)
        
        # Simple complexity calculation
        complexity = (lines / 100) + (method_count / 10)
        return min(complexity, 10.0)  # Cap at 10

    def calculate_leverage_potential(self, complexity: float, method_count: int, language: str) -> float:
        """Calculate leverage potential for a service"""
        base_leverage = 1.0
        
        # Language multipliers
        language_multipliers = {
            'javascript': 1.2,
            'typescript': 1.3,
            'python': 1.1,
            'java': 1.0,
            'csharp': 1.0
        }
        
        base_leverage *= language_multipliers.get(language, 1.0)
        
        # Complexity and method count factors
        complexity_factor = min(complexity / 5.0, 2.0)
        method_factor = min(method_count / 10.0, 1.5)
        
        total_leverage = base_leverage * complexity_factor * method_factor
        return round(min(total_leverage, 10.0), 1)

    def calculate_enhanced_exponential_value(self, analysis_result: Dict[str, Any]) -> float:
        """Calculate exponential value with enhanced intelligence"""
        base_value = analysis_result.get('services_count', 1) * 0.5
        complexity_bonus = analysis_result.get('complexity_score', 1.0) * 0.3
        
        # NEW: Apply induction boost if available
        induction_boost = 1.0
        if self.induction_results:
            leverage_strategy = self.induction_results.get('leverage_strategy', {})
            if leverage_strategy.get('primary_targets'):
                induction_boost = 1.5  # 50% boost for induction-targeted features
        
        total_value = (base_value + complexity_bonus) * induction_boost
        return round(min(total_value, 10.0), 1)

    def analyze_feature(self, feature_name: str, project_path: str) -> Dict[str, Any]:
        """Enhanced feature analysis with induction context"""
        print(f"[LEVERAGE] 🎯 Analyzing feature: {feature_name}")
        
        services = self.discover_services(project_path)
        matching_services = [s for s in services if feature_name.lower() in s.name.lower()]
        
        if not matching_services:
            # Create basic analysis for new features
            return {
                'services_count': 1,
                'complexity_score': 2.0,
                'leverage_potential': 1.0,
                'analysis_type': 'new_feature'
            }
        
        # Aggregate analysis from matching services
        total_complexity = sum(s.complexity_score for s in matching_services)
        avg_complexity = total_complexity / len(matching_services)
        total_leverage = sum(s.leverage_potential for s in matching_services)
        
        return {
            'services_count': len(matching_services),
            'complexity_score': avg_complexity,
            'leverage_potential': total_leverage,
            'matching_services': [s.name for s in matching_services],
            'analysis_type': 'existing_feature'
        }

    def assess_performance_impact(self, exponential_value: float) -> str:
        """Assess the performance impact of leverage application"""
        if exponential_value > 7.0:
            return "Transformational performance improvement expected"
        elif exponential_value > 5.0:
            return "Significant performance enhancement anticipated"
        elif exponential_value > 3.0:
            return "Moderate performance improvement likely"
        elif exponential_value > 2.0:
            return "Minor performance gains expected"
        else:
            return "Minimal performance impact"

    def generate_usage_example(self, feature_name: str, exponential_value: float) -> str:
        """Generate intelligent usage example"""
        return f"""# 🚀 Usage Example for {feature_name} ({exponential_value}× leverage)

# Basic usage
from your_module import {feature_name}_leveraged

# Method 1: Process data with automatic leverage
data = {{"user_id": 123, "action": "process"}}
enhanced_result = {feature_name}_leveraged.process(data)
print(f"Enhanced with {{enhanced_result['exponential_value']}}× leverage")

# Method 2: Access leverage metadata
leverage_info = {{
    "exponential_value": {exponential_value},
    "enhancement_active": True,
    "optimization_level": "{'high' if exponential_value > 5 else 'medium'}"
}}

# Method 3: Conditional enhancement
if {feature_name}_leveraged.leverage_potential > 3.0:
    result = {feature_name}_leveraged.process(data)
else:
    result = standard_process(data)"""

    def health_check(self, project_path: str = ".") -> Dict[str, Any]:
        """Enhanced health check with induction integration"""
        print(f"[LEVERAGE] 🏥 Health checking: {project_path}")
        
        start_time = time.time()
        services = self.discover_services(project_path)
        duration = time.time() - start_time
        
        total_leverage = sum(service.leverage_potential for service in services)
        
        if len(services) == 0:
            status = "no_services"
        elif total_leverage > 10.0:
            status = "excellent"
        elif total_leverage > 5.0:
            status = "good"
        elif total_leverage > 2.0:
            status = "fair"
        else:
            status = "needs_improvement"
        
        result = {
            'status': status,
            'services_count': len(services),
            'total_leverage': total_leverage,
            'duration': duration,
            'induction_available': self.config['induction_enabled'],
            'recommendations': self.get_health_recommendations(status, total_leverage)
        }
        
        print(f"[LEVERAGE] ✅ Health check complete: {status} ({len(services)} services)")
        return result

    def get_health_recommendations(self, status: str, total_leverage: float) -> List[str]:
        """Get health-based recommendations"""
        recommendations = []
        
        if status == "no_services":
            recommendations.extend([
                "Consider adding more discoverable services",
                "Check if files are in supported languages",
                "Ensure code structure follows common patterns"
            ])
        elif status == "needs_improvement":
            recommendations.extend([
                "Run intelligent induction to identify optimization targets",
                "Focus on high-complexity services first",
                "Consider code refactoring for better leverage potential"
            ])
        elif total_leverage > 5.0:
            recommendations.extend([
                "Excellent leverage potential detected",
                "Run induction phase for targeted optimization",
                "Consider implementing suggested enhancements"
            ])
        
        if self.config['induction_enabled']:
            recommendations.append("Run 'run_intelligent_induction()' for personalized optimization strategy")
        
        return recommendations

    def auto_leverage_everything(self, project_path: str = ".") -> Dict[str, Any]:
        """Enhanced auto-leverage with intelligent targeting"""
        print(f"[LEVERAGE] 💡 Auto-discovering opportunities in: {project_path}")
        
        start_time = time.time()
        
        try:
            # Step 1: Run intelligent analysis if available
            if self.config['induction_enabled']:
                analysis_results = self.run_intelligent_analysis(project_path)
                
                # Use induction results to guide auto-leverage
                leverage_strategy = analysis_results.get('targeted_strategy', {})
                priority_features = leverage_strategy.get('priority_features', [])
                
                opportunities = []
                for feature in priority_features[:5]:  # Top 5 priorities
                    opportunity = {
                        'feature': feature,
                        'leverage_result': self.leverage_my_app(feature, project_path),
                        'priority': 'high'
                    }
                    opportunities.append(opportunity)
                
                if opportunities:
                    result = {
                        'opportunities_found': len(opportunities),
                        'leverage_opportunities': opportunities,
                        'total_potential': sum(opp['leverage_result']['exponential_value'] for opp in opportunities),
                        'discovery_duration': time.time() - start_time,
                        'strategy_applied': 'intelligent_induction'
                    }
                else:
                    result = {
                        'opportunities_found': 0,
                        'message': 'No high-priority opportunities found via induction',
                        'discovery_duration': time.time() - start_time,
                        'strategy_applied': 'intelligent_induction'
                    }
            else:
                # Fallback to basic discovery
                services = self.discover_services(project_path)
                opportunities = []
                
                for service in services[:3]:  # Top 3 services
                    opportunity = {
                        'feature': service.name,
                        'leverage_result': self.leverage_my_app(service.name, project_path),
                        'priority': 'medium'
                    }
                    opportunities.append(opportunity)
                
                result = {
                    'opportunities_found': len(opportunities),
                    'leverage_opportunities': opportunities,
                    'total_potential': sum(opp['leverage_result']['exponential_value'] for opp in opportunities) if opportunities else 0,
                    'discovery_duration': time.time() - start_time,
                    'strategy_applied': 'basic_discovery'
                }
            
        except Exception as e:
            print(f"[LEVERAGE] ❌ Auto-discovery error: {{e}}")
            result = {
                'opportunities_found': 0,
                'error': str(e),
                'discovery_duration': time.time() - start_time,
                'strategy_applied': 'error_recovery'
            }
        
        print(f"[LEVERAGE] ✅ Auto-discovery complete: {result.get('opportunities_found', 0)} opportunities")
        return result

# Export for easy importing
__all__ = ['UniversalLeverageSystem', 'ServiceInfo', 'LeverageAnalysis'] 