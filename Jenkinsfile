pipeline {
    agent any
    
    environment {
        PROJECT_NAME = 'llvm-fuzzing-project'
        BUILD_TYPE = 'Release'
        FUZZING_DURATION = '120' // 2 minutes for CI
        PARALLEL_JOBS = '4'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BUILD_NUMBER = "${BUILD_NUMBER}"
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Environment Setup') {
            steps {
                sh '''
                    echo "🔧 Setting up environment..."
                    echo "Build: ${BUILD_NUMBER}"
                    echo "Commit: ${GIT_COMMIT_SHORT}"
                    echo "Node: ${NODE_NAME}"
                    
                    # Check dependencies
                    clang --version
                    llvm-config --version
                    cmake --version
                    
                    # Create necessary directories
                    mkdir -p reports artifacts
                '''
            }
        }
        
        stage('Build Project') {
            steps {
                sh '''
                    echo "🔨 Building LLVM Fuzzing Project..."
                    chmod +x scripts/build.sh
                    ./scripts/build.sh
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/*', fingerprint: true
                }
            }
        }
        
        stage('Unit Tests') {
            steps {
                sh '''
                    echo "🧪 Running unit tests..."
                    
                    # Test LLVM example
                    echo "Testing LLVM IR generation..."
                    ./build/llvm_example > reports/llvm_test.txt
                    
                    # Test LLVM Pass
                    echo "Testing LLVM Pass..."
                    if [ -f build/CountInstructions.so ]; then
                        opt -load ./build/CountInstructions.so -countinsts < tests/test_functions.ll > reports/pass_test.txt 2>&1
                        echo "✅ LLVM Pass test completed"
                    else
                        echo "❌ LLVM Pass not found"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Fuzzing Tests') {
            parallel {
                stage('Basic Fuzzing') {
                    steps {
                        sh '''
                            echo "🔥 Running basic fuzzing..."
                            chmod +x scripts/run_fuzzing.sh
                            ./scripts/run_fuzzing.sh basic -t ${FUZZING_DURATION} -j ${PARALLEL_JOBS}
                        '''
                    }
                }
                
                stage('Advanced Fuzzing') {
                    steps {
                        sh '''
                            echo "🚀 Running advanced fuzzing..."
                            ./scripts/run_fuzzing.sh advanced -t ${FUZZING_DURATION} -j ${PARALLEL_JOBS}
                        '''
                    }
                }
            }
        }
        
        stage('Code Analysis') {
            steps {
                sh '''
                    echo "🔍 Running static code analysis..."
                    
                    # Run clang-tidy if available
                    if command -v clang-tidy &> /dev/null; then
                        echo "Running clang-tidy..."
                        find src examples -name "*.cpp" -exec clang-tidy {} -- -I$(llvm-config --includedir) \\; > reports/clang_tidy.txt || true
                    fi
                    
                    # Run cppcheck if available
                    if command -v cppcheck &> /dev/null; then
                        echo "Running cppcheck..."
                        cppcheck --enable=all --xml --xml-version=2 src/ examples/ 2> reports/cppcheck.xml || true
                    fi
                '''
            }
        }
        
        stage('Coverage Analysis') {
            steps {
                sh '''
                    echo "📊 Analyzing code coverage..."
                    
                    # Generate coverage report if gcov is available
                    if command -v gcov &> /dev/null; then
                        echo "Generating coverage report..."
                        mkdir -p reports/coverage
                        
                        # This would require building with coverage flags
                        # For now, create a placeholder
                        echo "Coverage analysis requires rebuilding with --coverage flags" > reports/coverage/coverage.txt
                    fi
                '''
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    echo "🔒 Running security analysis..."
                    
                    # Check for common security issues
                    echo "Checking for potential security issues..."
                    
                    # Look for dangerous functions
                    echo "=== Dangerous Function Usage ===" > reports/security_scan.txt
                    grep -rn "strcpy\\|strcat\\|sprintf\\|gets" src/ examples/ >> reports/security_scan.txt || true
                    
                    # Check for TODO/FIXME comments that might indicate security issues
                    echo "=== TODO/FIXME Comments ===" >> reports/security_scan.txt
                    grep -rn "TODO\\|FIXME\\|XXX" src/ examples/ >> reports/security_scan.txt || true
                    
                    echo "Security scan completed"
                '''
            }
        }
        
        stage('Performance Benchmarks') {
            steps {
                sh '''
                    echo "⚡ Running performance benchmarks..."
                    
                    # Simple performance test
                    echo "Testing LLVM example performance..."
                    time ./build/llvm_example > /dev/null
                    
                    # Test compilation time
                    echo "Testing compilation performance..."
                    time make -C build clean && time make -C build -j${PARALLEL_JOBS}
                    
                    echo "Performance benchmarks completed"
                '''
            }
        }
        
        stage('Artifact Collection') {
            steps {
                sh '''
                    echo "📦 Collecting artifacts..."
                    
                    # Create artifact directory structure
                    mkdir -p artifacts/{binaries,reports,crashes,corpus}
                    
                    # Copy binaries
                    cp build/llvm_example build/fuzz_target build/advanced_fuzzing artifacts/binaries/ || true
                    cp build/CountInstructions.so artifacts/binaries/ || true
                    
                    # Copy reports
                    cp -r reports/* artifacts/reports/ || true
                    
                    # Copy fuzzing results
                    cp -r crashes/* artifacts/crashes/ || true
                    cp -r corpus/* artifacts/corpus/ || true
                    
                    # Create build info
                    cat > artifacts/build_info.txt << EOF
Build Information:
- Build Number: ${BUILD_NUMBER}
- Git Commit: ${GIT_COMMIT_SHORT}
- Build Date: $(date)
- Node: ${NODE_NAME}
- LLVM Version: $(llvm-config --version)
- Clang Version: $(clang --version | head -n1)
EOF
                '''
            }
        }
    }
    
    post {
        always {
            // Archive artifacts
            archiveArtifacts artifacts: 'artifacts/**/*', fingerprint: true
            
            // Publish reports
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'reports',
                reportFiles: '*.html',
                reportName: 'Fuzzing Report'
            ])
            
            // Clean workspace
            sh '''
                echo "🧹 Cleaning up..."
                rm -rf build/ || true
                rm -rf corpus/ || true
                rm -rf crashes/ || true
            '''
        }
        
        success {
            echo "✅ Pipeline completed successfully!"
            
            // Send notification (if configured)
            // slackSend channel: '#fuzzing-ci', 
            //          color: 'good', 
            //          message: "✅ LLVM Fuzzing Project build #${BUILD_NUMBER} succeeded"
        }
        
        failure {
            echo "❌ Pipeline failed!"
            
            // Send notification (if configured)
            // slackSend channel: '#fuzzing-ci', 
            //          color: 'danger', 
            //          message: "❌ LLVM Fuzzing Project build #${BUILD_NUMBER} failed"
        }
        
        unstable {
            echo "⚠️ Pipeline completed with warnings!"
        }
    }
}
