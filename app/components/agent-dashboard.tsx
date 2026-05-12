'use client';
import React, { useState, useEffect } from 'react';

export default function AgentDashboard() {
  const [agents, setAgents] = useState([
    { role: 'feature_developer', status: 'idle', progress: 0 },
    { role: 'qa_tester', status: 'idle', progress: 0 },
    { role: 'security_auditor', status: 'idle', progress: 0 },
    { role: 'deployment_manager', status: 'idle', progress: 0 },
  ]);
  const [logs, setLogs] = useState([]);
  const [stats, setStats] = useState({ tasksCompleted: 0, successRate: 0 });

  useEffect(() => {
    const fetchStatus = async () => {
      try {
        const response = await fetch('/api/agent-status');
        if (response.ok) {
          const data = await response.json();
          setAgents(data.agents);
          setLogs(data.logs || []);
          setStats(data.stats);
        }
      } catch (error) {
        console.error('Error:', error);
      }
    };
    fetchStatus();
    const interval = setInterval(fetchStatus, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-slate-900 text-white p-6">
      <div className="max-w-6xl mx-auto space-y-6">
        <div>
          <h1 className="text-3xl font-bold">🤖 BharatSeva Agent</h1>
          <p className="text-slate-400">Autonomous Multi-Agent System</p>
        </div>
        <div className="grid grid-cols-4 gap-3">
          <div className="bg-slate-800 rounded p-3">
            <p className="text-slate-400 text-xs">Tasks</p>
            <p className="text-2xl font-bold">{stats.tasksCompleted}</p>
          </div>
          <div className="bg-slate-800 rounded p-3">
            <p className="text-slate-400 text-xs">Success</p>
            <p className="text-2xl font-bold text-green-400">{stats.successRate}%</p>
          </div>
        </div>
        <div>
          <h2 className="text-lg font-bold mb-3">Agents</h2>
          <div className="grid grid-cols-4 gap-3">
            {agents.map((agent) => (
              <div key={agent.role} className="bg-slate-700 rounded p-4">
                <h3 className="font-medium capitalize text-sm">{agent.role.replace(/_/g, ' ')}</h3>
                <div className="mt-2 bg-black/30 rounded h-2">
                  <div className="h-full bg-blue-500" style={{ width: `${agent.progress}%` }}></div>
                </div>
              </div>
            ))}
          </div>
        </div>
        <div className="bg-slate-800 rounded p-4">
          <h2 className="text-lg font-bold mb-3">Logs</h2>
          {logs.length === 0 ? <p className="text-slate-400">No logs</p> : <div className="space-y-1">{logs.slice(-5).map((log, idx) => (<div key={idx} className="text-xs text-slate-300">{log.agent} • {log.task}</div>))}</div>}
        </div>
      </div>
    </div>
  );
}
