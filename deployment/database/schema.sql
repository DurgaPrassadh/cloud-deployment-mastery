-- DevOps Dashboard Database Schema
-- PostgreSQL 15+
-- Run this on your Database EC2 instance

-- Create database (run as postgres superuser)
-- CREATE DATABASE devops_dashboard;

-- Connect to the database
-- \c devops_dashboard

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TASKS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    description TEXT DEFAULT '',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    priority VARCHAR(20) NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    environment VARCHAR(20) NOT NULL DEFAULT 'development'
        CHECK (environment IN ('development', 'staging', 'production')),
    assignee VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_environment ON tasks(environment);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at DESC);

-- ============================================
-- DEPLOYMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    environment VARCHAR(20) NOT NULL DEFAULT 'staging'
        CHECK (environment IN ('development', 'staging', 'production')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'building', 'deploying', 'success', 'failed', 'rollback')),
    version VARCHAR(50) NOT NULL,
    commit_sha VARCHAR(40) NOT NULL,
    branch VARCHAR(100) NOT NULL DEFAULT 'main',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    logs JSONB DEFAULT '[]'::jsonb
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_deployments_status ON deployments(status);
CREATE INDEX IF NOT EXISTS idx_deployments_environment ON deployments(environment);
CREATE INDEX IF NOT EXISTS idx_deployments_started_at ON deployments(started_at DESC);

-- ============================================
-- SYSTEM METRICS TABLE (Optional - for historical data)
-- ============================================
CREATE TABLE IF NOT EXISTS system_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cpu_usage DECIMAL(5,2),
    memory_usage DECIMAL(5,2),
    disk_usage DECIMAL(5,2),
    network_in BIGINT,
    network_out BIGINT,
    active_connections INTEGER,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for time-series queries
CREATE INDEX IF NOT EXISTS idx_metrics_recorded_at ON system_metrics(recorded_at DESC);

-- Automatically clean old metrics (keep last 7 days)
CREATE OR REPLACE FUNCTION cleanup_old_metrics() RETURNS trigger AS $$
BEGIN
    DELETE FROM system_metrics WHERE recorded_at < NOW() - INTERVAL '7 days';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_cleanup_metrics
    AFTER INSERT ON system_metrics
    EXECUTE FUNCTION cleanup_old_metrics();

-- ============================================
-- SAMPLE DATA (Optional)
-- ============================================
INSERT INTO tasks (title, description, status, priority, environment, assignee) VALUES
    ('Configure Nginx reverse proxy', 'Set up Nginx to route traffic from frontend to backend API', 'completed', 'high', 'production', 'DevOps Team'),
    ('Set up PM2 process manager', 'Configure PM2 for Node.js backend with auto-restart', 'in_progress', 'high', 'production', 'Backend Team'),
    ('Configure PostgreSQL security groups', 'Restrict database access to backend EC2 only', 'pending', 'critical', 'production', 'Security Team'),
    ('Set up CloudWatch monitoring', 'Configure AWS CloudWatch for all EC2 instances', 'pending', 'medium', 'production', NULL),
    ('Create automated backups', 'Set up daily PostgreSQL backups to S3', 'pending', 'high', 'production', 'DBA Team');

INSERT INTO deployments (name, environment, status, version, commit_sha, branch, duration_seconds) VALUES
    ('Initial Production Deploy', 'production', 'success', 'v1.0.0', 'abc1234567890def1234567890abc1234567890a', 'main', 245),
    ('Feature: API endpoints', 'staging', 'success', 'v1.1.0-beta', 'def5678901234abc5678901234def5678901234b', 'develop', 180);