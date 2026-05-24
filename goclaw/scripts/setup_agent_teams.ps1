#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Setup agent teams for GoClaw.

.DESCRIPTION
    Tạo team "deo-coo-team" với deo làm lead, 5 agents L2 làm member.
#>

$ErrorActionPreference = "Stop"

$TENANT = "0193a5b0-7000-7000-8000-000000000001"
$TEAM_ID = "019e593a-fece-792a-a2c5-f34407a1aef3"
$LEAD_AGENT_KEY = "deo"

$sql = @"
BEGIN;

-- 1. Tạo team 'deo-coo-team' trong agent_teams
INSERT INTO agent_teams (id, name, lead_agent_id, description, status, tenant_id, created_by)
VALUES (
  '$TEAM_ID', 
  'deo-coo-team', 
  (SELECT id FROM agents WHERE agent_key = '$LEAD_AGENT_KEY' LIMIT 1),
  'Vietnamese L2 COO Operations Team', 
  'active', 
  '$TENANT',
  'admin'
)
ON CONFLICT (id) 
DO UPDATE SET 
  lead_agent_id = EXCLUDED.lead_agent_id, 
  description = EXCLUDED.description,
  updated_at = NOW();

-- 2. Thêm các L2 Agents làm member
DELETE FROM agent_team_members WHERE team_id = '$TEAM_ID';

-- finance-agent
INSERT INTO agent_team_members (team_id, agent_id, role, tenant_id)
VALUES (
  '$TEAM_ID', 
  (SELECT id FROM agents WHERE agent_key = 'finance-agent' LIMIT 1), 
  'member', 
  '$TENANT'
);

-- legal-agent
INSERT INTO agent_team_members (team_id, agent_id, role, tenant_id)
VALUES (
  '$TEAM_ID', 
  (SELECT id FROM agents WHERE agent_key = 'legal-agent' LIMIT 1), 
  'member', 
  '$TENANT'
);

-- hr-agent
INSERT INTO agent_team_members (team_id, agent_id, role, tenant_id)
VALUES (
  '$TEAM_ID', 
  (SELECT id FROM agents WHERE agent_key = 'hr-agent' LIMIT 1), 
  'member', 
  '$TENANT'
);

-- crm-agent
INSERT INTO agent_team_members (team_id, agent_id, role, tenant_id)
VALUES (
  '$TEAM_ID', 
  (SELECT id FROM agents WHERE agent_key = 'crm-agent' LIMIT 1), 
  'member', 
  '$TENANT'
);

-- office-agent
INSERT INTO agent_team_members (team_id, agent_id, role, tenant_id)
VALUES (
  '$TEAM_ID', 
  (SELECT id FROM agents WHERE agent_key = 'office-agent' LIMIT 1), 
  'member', 
  '$TENANT'
);

COMMIT;
"@

Write-Host "Applying database updates (Agent Teams)..." -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c $sql

Write-Host "`n=== Verify agent_teams ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT id, name, lead_agent_id FROM agent_teams WHERE id='$TEAM_ID';"

Write-Host "`n=== Verify agent_team_members ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT atm.team_id, a.agent_key, atm.role FROM agent_team_members atm JOIN agents a ON a.id=atm.agent_id WHERE atm.team_id='$TEAM_ID';"

Write-Host "`nDone. Team setup complete!" -ForegroundColor Green

