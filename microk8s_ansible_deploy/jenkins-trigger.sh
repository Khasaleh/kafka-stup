#!/bin/bash

# Jenkins Job Trigger Script
# This script triggers Jenkins jobs to build and deploy applications

set -e

# Configuration - will be set in main function
JENKINS_URL=""
JENKINS_USER=""
JENKINS_PASSWORD=""
JENKINS_TOKEN=""
ENV=""
IMAGE_TAG=""



# Function to check if curl is available
check_curl() {
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed or not in PATH"
        exit 1
    fi
}

# Function to get Jenkins CSRF crumb
get_jenkins_crumb() {
    # Use token if available, otherwise use password
    local auth_header
    if [ -n "$JENKINS_TOKEN" ]; then
        auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_TOKEN" | base64)"
    else
        auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_PASSWORD" | base64)"
    fi
    
    local crumb_response=$(curl -s -H "$auth_header" "$JENKINS_URL/crumbIssuer/api/json" 2>/dev/null || echo "{}")
    local crumb=$(echo "$crumb_response" | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)
    local crumb_request_field=$(echo "$crumb_response" | grep -o '"crumbRequestField":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$crumb" ] && [ -n "$crumb_request_field" ]; then
        echo "$crumb_request_field:$crumb"
    else
        echo ""
    fi
}

# Function to trigger a Jenkins job
trigger_jenkins_job() {
    local job_name="$1"
    local parameters="$2"
    
    echo "Triggering Jenkins job: $job_name"
    
    # Get fresh CSRF crumb for each request
    local crumb_response=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/json" 2>/dev/null || echo "{}")
    local crumb=$(echo "$crumb_response" | grep -o '"crumb":"[^"]*"' | cut -d'"' -f4)
    local crumb_request_field=$(echo "$crumb_response" | grep -o '"crumbRequestField":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$crumb" ] && [ -n "$crumb_request_field" ]; then
        echo "  - Using CSRF protection"
        local trigger_url="$JENKINS_URL/job/$job_name/build"
        
        if [ -n "$parameters" ]; then
            echo "  - Parameters: $parameters"
            curl -X POST \
                -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                -H "$crumb_request_field:$crumb" \
                -H "Content-Type: application/x-www-form-urlencoded" \
                --data-urlencode "$parameters" \
                "$trigger_url" || {
                echo "  ⚠ Failed to trigger $job_name"
                return 1
            }
        else
            echo "  - No parameters"
            curl -X POST \
                -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                -H "$crumb_request_field:$crumb" \
                "$trigger_url" || {
                echo "  ⚠ Failed to trigger $job_name"
                return 1
            }
        fi
    else
        echo "  - No CSRF protection available, trying without crumb"
        local trigger_url="$JENKINS_URL/job/$job_name/build"
        
        if [ -n "$parameters" ]; then
            echo "  - Parameters: $parameters"
            curl -X POST \
                -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                -H "Content-Type: application/x-www-form-urlencoded" \
                --data-urlencode "$parameters" \
                "$trigger_url" || {
                echo "  ⚠ Failed to trigger $job_name"
                return 1
            }
        else
            echo "  - No parameters"
            curl -X POST \
                -u "$JENKINS_USER:$JENKINS_PASSWORD" \
                "$trigger_url" || {
                echo "  ⚠ Failed to trigger $job_name"
                return 1
            }
        fi
    fi
    
    echo "  ✓ Successfully triggered $job_name"
}

# Function to wait for Jenkins job completion
wait_for_job_completion() {
    local job_name="$1"
    local max_wait=${2:-1800}  # 30 minutes default
    local wait_interval=30
    
    echo "Waiting for job completion: $job_name"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + max_wait))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Use token if available, otherwise use password
        local auth_header
        if [ -n "$JENKINS_TOKEN" ]; then
            auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_TOKEN" | base64)"
        else
            auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_PASSWORD" | base64)"
        fi
        local status_url="$JENKINS_URL/job/$job_name/lastBuild/api/json"
        
        local response=$(curl -s -H "$auth_header" "$status_url" 2>/dev/null || echo "{}")
        local building=$(echo "$response" | grep -o '"building":[^,]*' | cut -d':' -f2 | tr -d ' ')
        local result=$(echo "$response" | grep -o '"result":[^,]*' | cut -d':' -f2 | tr -d '"' | tr -d ',')
        
        if [ "$building" = "false" ]; then
            if [ "$result" = "SUCCESS" ]; then
                echo "  ✓ Job $job_name completed successfully"
                return 0
            elif [ "$result" = "FAILURE" ]; then
                echo "  ✗ Job $job_name failed"
                return 1
            else
                echo "  ⚠ Job $job_name completed with result: $result"
                return 1
            fi
        fi
        
        echo "  - Job $job_name is still building... (waiting $wait_interval seconds)"
        sleep $wait_interval
    done
    
    echo "  ⚠ Timeout waiting for job $job_name to complete"
    return 1
}

# Function to trigger infrastructure build
trigger_infrastructure_build() {
    echo "Triggering infrastructure build..."
    
    # Trigger infrastructure-related jobs
    local infrastructure_jobs=(
        "kafka-restart-$ENV"
        "postgres-restart"
        "registry.service-dev restart"
    )
    
    for job in "${infrastructure_jobs[@]}"; do
        echo "  - Triggering $job..."
        trigger_jenkins_job "$job" "" || {
            echo "  ⚠ Failed to trigger $job (job may not exist)"
        }
    done
    
    echo "✓ Infrastructure jobs triggered"
}

# Function to trigger application builds
trigger_application_builds() {
    echo "Triggering application builds..."
    
    # Map applications to their Jenkins job names for dev environment
    local application_jobs=(
        "multi-branch-k8s-ads-service"
        "multi-branch-k8s-api-server"
        "multi-branch-k8s-order-service"
        "multi-branch-k8s-payment-service"
        "multi-branch-k8s-customer-service"
        "multi-branch-k8s-posts-service"
        "multi-branch-k8s-notification-service"
        "multi-branch-k8s-loyalty-service"
        "multi-branch-k8s-inventory-service"
        "multi-branch-k8s-fazeal-business-management"
        "multi-branch-k8s-fazeal-business"
        "multi-branch-k8s-events-service"
        "multi-branch-k8s-cron-jobs"
        "multi-branch-k8s-chat-app-nodejs"
        "multi-branch-k8s-business-chat"
        "multi-branch-k8s-album-service"
        "multi-branch-k8s-promotion-service"
        "multi-branch-k8s-catalog-service"
        "multi-branch-k8s-dev-employee-service"
        "multi-branch-k8s-translation-service"
        "multi-branch-k8s-watermark-detection"
        "multi-branch-k8s-site-management-service"
        "multi-branch-k8s-shopping-service"
        "multi-branch-k8s-payment-gateway"
        "multi-branch-k8s-api-gateway"
        "multi-branch-k8s-Dev-config_server"
        "multi-branch-k8s-dev-dataload-service"
        "multi-branch-k8s-dev-search-service"
        "multi-branch-k8s-fazeal-logistics"
    )
    
    for job in "${application_jobs[@]}"; do
        echo "  - Triggering $job..."
        trigger_jenkins_job "$job" "" || {
            echo "  ⚠ Failed to trigger $job (job may not exist)"
        }
    done
    
    echo "✓ All application builds triggered"
}

# Function to trigger frontend builds
trigger_frontend_builds() {
    echo "Triggering frontend builds..."
    
    # Map frontend applications to their Jenkins job names for dev environment
    local frontend_jobs=(
        "multi-branch-k8s-angular-ads"
        "multi-branch-k8s-angular-business"
        "multi-branch-k8s-angular-customer"
        "multi-branch-k8s-Angular-Social"
        "multi-branch-k8s-dev-angular-employee"
    )
    
    for job in "${frontend_jobs[@]}"; do
        echo "  - Triggering $job..."
        trigger_jenkins_job "$job" "" || {
            echo "  ⚠ Failed to trigger $job (job may not exist)"
        }
    done
    
    echo "✓ All frontend builds triggered"
}

# Function to trigger deployment job
trigger_deployment() {
    echo "Triggering deployment job..."
    
    # Trigger deployment-related jobs
    local deployment_jobs=(
        "k8s-Prod-deploy"
        "all"
    )
    
    for job in "${deployment_jobs[@]}"; do
        echo "  - Triggering $job..."
        trigger_jenkins_job "$job" "" || {
            echo "  ⚠ Failed to trigger $job (job may not exist)"
        }
    done
    
    echo "✓ Deployment jobs triggered"
}

# Function to trigger full pipeline
trigger_full_pipeline() {
    echo "Triggering full CI/CD pipeline..."
    
    # Trigger all phases in sequence
    echo "Phase 1: Infrastructure..."
    trigger_infrastructure_build
    
    echo "Phase 2: Applications..."
    trigger_application_builds
    
    echo "Phase 3: Frontend..."
    trigger_frontend_builds
    
    echo "Phase 4: Deployment..."
    trigger_deployment
    
    echo "✓ Full pipeline triggered"
}

# Function to check Jenkins connectivity
check_jenkins_connectivity() {
    echo "Checking Jenkins connectivity..."
    
    # Use token if available, otherwise use password
    local auth_header
    if [ -n "$JENKINS_TOKEN" ]; then
        auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_TOKEN" | base64)"
    else
        auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_PASSWORD" | base64)"
    fi
    
    local response=$(curl -s -H "$auth_header" "$JENKINS_URL/api/json" 2>/dev/null || echo "{}")
    
    if echo "$response" | grep -q "nodeName"; then
        echo "✓ Jenkins connectivity successful"
        return 0
    else
        echo "✗ Jenkins connectivity failed"
        return 1
    fi
}

# Function to list available jobs
list_jenkins_jobs() {
    echo "Listing available Jenkins jobs..."
    
    # Use token if available, otherwise use password
    local auth_header
    if [ -n "$JENKINS_TOKEN" ]; then
        auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_TOKEN" | base64)"
    else
        auth_header="Authorization: Basic $(echo -n "$JENKINS_USER:$JENKINS_PASSWORD" | base64)"
    fi
    
    local response=$(curl -s -H "$auth_header" "$JENKINS_URL/api/json?tree=jobs[name,url]" 2>/dev/null || echo "{}")
    
    echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sort
}

# Main execution
main() {
    local action=${1:-"full"}
    
    # Set configuration based on action
    case $action in
        "list")
            # For list action, use minimal parameters
            JENKINS_URL=${2:-"http://192.168.1.224:8080"}
            JENKINS_USER=${3:-"khaled"}
            JENKINS_PASSWORD=${4:-"Welcome123"}
            JENKINS_TOKEN=${5:-""}
            ;;
        *)
            # For other actions, use full parameter set
            JENKINS_URL=${2:-"http://192.168.1.224:8080"}
            JENKINS_USER=${3:-"khaled"}
            JENKINS_PASSWORD=${4:-"Welcome123"}
            JENKINS_TOKEN=${5:-""}
            ENV=${6:-"dev"}
            IMAGE_TAG=${7:-"latest"}
            ;;
    esac
    
    echo "=========================================="
    echo "Jenkins Job Trigger Script"
    echo "=========================================="
    echo "Jenkins URL: $JENKINS_URL"
    echo "Jenkins User: $JENKINS_USER"
    echo "Environment: $ENV"
    echo "Image Tag: $IMAGE_TAG"
    echo "=========================================="
    
    # Check prerequisites
    check_curl
    
    # Check Jenkins connectivity
    check_jenkins_connectivity || {
        echo "Error: Cannot connect to Jenkins. Please check your configuration."
        exit 1
    }
    
    case $action in
        "infrastructure")
            trigger_infrastructure_build
            ;;
        "applications")
            trigger_application_builds
            ;;
        "frontend")
            trigger_frontend_builds
            ;;
        "deploy")
            trigger_deployment
            ;;
        "full")
            trigger_full_pipeline
            ;;
        "list")
            list_jenkins_jobs
            ;;
        *)
            echo "Usage: $0 [action] [jenkins_url] [username] [password] [token] [environment] [image_tag]"
            echo ""
            echo "Actions:"
            echo "  infrastructure - Trigger infrastructure build"
            echo "  applications  - Trigger application builds"
            echo "  frontend      - Trigger frontend builds"
            echo "  deploy        - Trigger deployment"
            echo "  full          - Trigger full pipeline (default)"
            echo "  list          - List available jobs"
            echo ""
            echo "Examples:"
            echo "  $0 full http://192.168.1.224:8080 khaled Welcome123 '' dev v1.2.3"
            echo "  $0 applications http://192.168.1.224:8080 khaled Welcome123 '' dev latest"
            echo "  $0 deploy http://192.168.1.224:8080 khaled Welcome123 '' dev v1.2.3"
            echo "  $0 list http://192.168.1.224:8080 khaled Welcome123"
            exit 1
            ;;
    esac
    
    echo "=========================================="
    echo "Jenkins job triggering completed!"
    echo "=========================================="
    echo "Check Jenkins dashboard: $JENKINS_URL"
    echo "Monitor job progress in Jenkins UI"
}

# Run main function
main "$@" 