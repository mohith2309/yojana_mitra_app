import { NextRequest, NextResponse } from 'next/server';
import * as fs from 'fs';
import * as path from 'path';

export async function GET(request: NextRequest) {
  try {
    const projectPath = process.cwd();
    const logPath = path.join(projectPath, '.workflow_log.json');
    let logs = [];
    if (fs.existsSync(logPath)) {
      logs = JSON.parse(fs.readFileSync(logPath, 'utf-8'));
    }
    const agents = [
      { role: 'feature_developer', status: 'idle', progress: 0 },
      { role: 'qa_tester', status: 'idle', progress: 0 },
      { role: 'security_auditor', status: 'idle', progress: 0 },
      { role: 'deployment_manager', status: 'idle', progress: 0 },
    ];
    return NextResponse.json({
      agents,
      logs: logs.slice(-20),
      stats: { tasksCompleted: logs.length, successRate: 0 },
      isRunning: false,
    });
  } catch (error) {
    return NextResponse.json({ agents: [], logs: [], stats: {}, isRunning: false });
  }
}
