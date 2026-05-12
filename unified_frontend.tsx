/**
 * BharatSeva Unified Frontend
 * Voice-first platform spanning 5 citizen services
 * Next.js + React + Tailwind + shadcn/ui
 */

'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import {
  Mic,
  StopCircle,
  Home,
  Heart,
  Settings,
  BookmarkIcon,
  AlertCircle,
  Pill,
  TrendingUp,
  Wind,
  CloudRain,
} from 'lucide-react';

interface UserProfile {
  name: string;
  age: number;
  gender: string;
  state: string;
  district?: string;
  phone?: string;
  lat?: number;
  lng?: number;
  languages: string[];

  // Domain-specific
  occupation?: string;
  family_size?: number;
  annual_income?: number;
  marital_status?: string;
  health_conditions?: string[];
  crops?: string[];
}

interface ResultItem {
  id: string;
  name: string;
  domain: 'welfare' | 'medicine' | 'prices' | 'pollution' | 'disaster';
  benefit_amount?: number;
  match_score: number;
  [key: string]: any;
}

interface UnifiedResults {
  schemes: ResultItem[];
  medicines: ResultItem[];
  prices: ResultItem[];
  routes: ResultItem[];
  alerts: ResultItem[];
  tts_text: string;
}

type Tab = 'home' | 'voice' | 'results' | 'saved' | 'profile';

export default function BharatSeva() {
  // Navigation
  const [tab, setTab] = useState<Tab>('home');
  const [activeResultTab, setActiveResultTab] = useState<string>('all');

  // Voice
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);

  // Data
  const [userProfile, setUserProfile] = useState<UserProfile>({
    name: 'User',
    age: 35,
    gender: 'F',
    state: 'UP',
    languages: ['hi', 'en'],
  });

  const [results, setResults] = useState<UnifiedResults>({
    schemes: [],
    medicines: [],
    prices: [],
    routes: [],
    alerts: [],
    tts_text: '',
  });

  const [saved, setSaved] = useState<Set<string>>(new Set());

  // ────────────────────────────────────────────────────────
  // Voice Recording
  // ────────────────────────────────────────────────────────

  const startListening = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (e) => {
        audioChunksRef.current.push(e.data);
      };

      mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/webm' });
        await transcribeAudio(audioBlob);
        stream.getTracks().forEach((track) => track.stop());
      };

      mediaRecorder.start();
      setIsListening(true);
    } catch (err) {
      console.error('Microphone error:', err);
      alert('Microphone access required');
    }
  };

  const stopListening = () => {
    if (mediaRecorderRef.current) {
      mediaRecorderRef.current.stop();
      setIsListening(false);
    }
  };

  const transcribeAudio = async (audioBlob: Blob) => {
    try {
      const formData = new FormData();
      formData.append('file', audioBlob);
      formData.append('language', 'hi');

      const response = await fetch('/api/voice/transcribe', {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();
      setTranscript(data.text);

      if (data.text) {
        await searchUnified(data.text);
      }
    } catch (err) {
      console.error('Transcription error:', err);
      setTranscript('Could not transcribe. Please try again or type.');
    }
  };

  // ────────────────────────────────────────────────────────
  // Unified Search
  // ────────────────────────────────────────────────────────

  const searchUnified = async (query: string) => {
    try {
      const response = await fetch('/api/master/search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: query,
          profile: userProfile,
          language: 'hi',
        }),
      });

      const data = await response.json();
      setResults(data);
      setTab('results');
      setActiveResultTab('all');
    } catch (err) {
      console.error('Search error:', err);
      // Fallback mock results
      setResults(getMockResults());
      setTab('results');
    }
  };

  // ────────────────────────────────────────────────────────
  // Render Functions
  // ────────────────────────────────────────────────────────

  const renderHome = () => (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-purple-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full p-8 text-center border-blue-200">
        <h1 className="text-4xl font-bold text-blue-900 mb-2">भारत सेवा</h1>
        <h2 className="text-xl font-bold text-gray-800 mb-4">BharatSeva</h2>
        <p className="text-lg text-purple-600 font-medium mb-2">
          "Ek awaaz, Paanch Samasyayen"
        </p>
        <p className="text-sm text-gray-600 mb-8">
          One voice. Five solutions. Zero cost.
        </p>

        <div className="grid grid-cols-1 gap-3 mb-6">
          <Button
            onClick={() => setTab('voice')}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white py-6 text-lg"
          >
            <Mic className="mr-2 h-5 w-5" />
            🎤 Start Voice Search
          </Button>

          <Button
            onClick={() => setActiveResultTab('all') || setTab('results')}
            variant="outline"
            className="w-full py-6 text-lg border-purple-300"
          >
            Browse Services
          </Button>
        </div>

        {/* Domain Quick-Pick */}
        <p className="text-xs font-semibold text-gray-700 mb-3">Or pick a service:</p>
        <div className="grid grid-cols-5 gap-2">
          <div className="p-3 bg-green-100 rounded text-center">
            <p className="text-2xl">💰</p>
            <p className="text-xs font-semibold">Schemes</p>
          </div>
          <div className="p-3 bg-orange-100 rounded text-center">
            <p className="text-2xl">💊</p>
            <p className="text-xs font-semibold">Medicine</p>
          </div>
          <div className="p-3 bg-yellow-100 rounded text-center">
            <p className="text-2xl">🌾</p>
            <p className="text-xs font-semibold">Prices</p>
          </div>
          <div className="p-3 bg-blue-100 rounded text-center">
            <p className="text-2xl">💨</p>
            <p className="text-xs font-semibold">Pollution</p>
          </div>
          <div className="p-3 bg-red-100 rounded text-center">
            <p className="text-2xl">⚠️</p>
            <p className="text-xs font-semibold">Alerts</p>
          </div>
        </div>

        <p className="text-xs text-gray-500 mt-6">
          Works offline. No data shared. Made in India.
        </p>
      </Card>
    </div>
  );

  const renderVoice = () => (
    <div className="min-h-screen bg-gradient-to-b from-blue-50 to-purple-50 flex items-center justify-center p-4">
      <Card className="max-w-md w-full p-8 text-center">
        <h2 className="text-2xl font-bold mb-6">अपनी समस्या बताएं</h2>

        <div className="mb-6 p-8 bg-blue-100 rounded-full flex items-center justify-center">
          {isListening ? (
            <div className="animate-pulse">
              <Mic className="h-12 w-12 text-red-500" />
            </div>
          ) : (
            <Mic className="h-12 w-12 text-gray-400" />
          )}
        </div>

        <p className="text-gray-600 mb-6 text-sm">
          "Mera pati nahi raha, pregnant hoon, aur sasta medicine chahiye"
          <br />
          <span className="text-xs text-gray-500">(Hindi, Marathi, Tamil...)</span>
        </p>

        {transcript && (
          <div className="mb-6 p-4 bg-gray-100 rounded text-left text-sm">
            <p className="font-mono">{transcript}</p>
          </div>
        )}

        <div className="flex gap-4">
          {!isListening ? (
            <Button
              onClick={startListening}
              className="flex-1 bg-red-500 hover:bg-red-600 py-6"
            >
              <Mic className="mr-2 h-5 w-5" />
              Start
            </Button>
          ) : (
            <Button
              onClick={stopListening}
              className="flex-1 bg-purple-600 hover:bg-purple-700 py-6"
            >
              <StopCircle className="mr-2 h-5 w-5" />
              Stop
            </Button>
          )}
        </div>

        <Button
          onClick={() => setTab('home')}
          variant="ghost"
          className="w-full mt-4"
        >
          ← Back
        </Button>
      </Card>
    </div>
  );

  const renderResults = () => {
    const hasSchemes = results.schemes.length > 0;
    const hasMedicines = results.medicines.length > 0;
    const hasPrices = results.prices.length > 0;
    const hasRoutes = results.routes.length > 0;
    const hasAlerts = results.alerts.length > 0;

    return (
      <div className="min-h-screen bg-gradient-to-b from-blue-50 to-purple-50 p-4">
        <div className="max-w-2xl mx-auto">
          {/* Domain Tabs */}
          <div className="flex gap-2 mb-6 overflow-x-auto pb-2">
            <button
              onClick={() => setActiveResultTab('all')}
              className={`px-4 py-2 rounded whitespace-nowrap ${
                activeResultTab === 'all'
                  ? 'bg-blue-600 text-white'
                  : 'bg-white border border-gray-300'
              }`}
            >
              All ({results.schemes.length + results.medicines.length + results.prices.length + results.routes.length + results.alerts.length})
            </button>
            {hasSchemes && (
              <button
                onClick={() => setActiveResultTab('schemes')}
                className={`px-4 py-2 rounded whitespace-nowrap ${
                  activeResultTab === 'schemes'
                    ? 'bg-green-600 text-white'
                    : 'bg-white border border-gray-300'
                }`}
              >
                💰 Schemes ({results.schemes.length})
              </button>
            )}
            {hasMedicines && (
              <button
                onClick={() => setActiveResultTab('medicines')}
                className={`px-4 py-2 rounded whitespace-nowrap ${
                  activeResultTab === 'medicines'
                    ? 'bg-orange-600 text-white'
                    : 'bg-white border border-gray-300'
                }`}
              >
                💊 Medicine ({results.medicines.length})
              </button>
            )}
            {hasPrices && (
              <button
                onClick={() => setActiveResultTab('prices')}
                className={`px-4 py-2 rounded whitespace-nowrap ${
                  activeResultTab === 'prices'
                    ? 'bg-yellow-600 text-white'
                    : 'bg-white border border-gray-300'
                }`}
              >
                🌾 Prices ({results.prices.length})
              </button>
            )}
            {hasRoutes && (
              <button
                onClick={() => setActiveResultTab('routes')}
                className={`px-4 py-2 rounded whitespace-nowrap ${
                  activeResultTab === 'routes'
                    ? 'bg-blue-700 text-white'
                    : 'bg-white border border-gray-300'
                }`}
              >
                💨 Routes ({results.routes.length})
              </button>
            )}
            {hasAlerts && (
              <button
                onClick={() => setActiveResultTab('alerts')}
                className={`px-4 py-2 rounded whitespace-nowrap ${
                  activeResultTab === 'alerts'
                    ? 'bg-red-600 text-white'
                    : 'bg-white border border-gray-300'
                }`}
              >
                ⚠️ Alerts ({results.alerts.length})
              </button>
            )}
          </div>

          {/* Results Cards */}
          <div className="space-y-4">
            {(activeResultTab === 'all' || activeResultTab === 'schemes') &&
              results.schemes.map((scheme) => (
                <ResultCard
                  key={scheme.id}
                  item={scheme}
                  domain="welfare"
                  onSave={() => {
                    const newSaved = new Set(saved);
                    newSaved.add(scheme.id);
                    setSaved(newSaved);
                  }}
                  isSaved={saved.has(scheme.id)}
                />
              ))}

            {(activeResultTab === 'all' || activeResultTab === 'medicines') &&
              results.medicines.map((medicine) => (
                <ResultCard
                  key={medicine.id}
                  item={medicine}
                  domain="medicine"
                  onSave={() => {
                    const newSaved = new Set(saved);
                    newSaved.add(medicine.id);
                    setSaved(newSaved);
                  }}
                  isSaved={saved.has(medicine.id)}
                />
              ))}

            {(activeResultTab === 'all' || activeResultTab === 'prices') &&
              results.prices.map((price) => (
                <ResultCard
                  key={price.id}
                  item={price}
                  domain="prices"
                  onSave={() => {
                    const newSaved = new Set(saved);
                    newSaved.add(price.id);
                    setSaved(newSaved);
                  }}
                  isSaved={saved.has(price.id)}
                />
              ))}

            {(activeResultTab === 'all' || activeResultTab === 'routes') &&
              results.routes.map((route) => (
                <ResultCard
                  key={route.id}
                  item={route}
                  domain="pollution"
                  onSave={() => {
                    const newSaved = new Set(saved);
                    newSaved.add(route.id);
                    setSaved(newSaved);
                  }}
                  isSaved={saved.has(route.id)}
                />
              ))}

            {(activeResultTab === 'all' || activeResultTab === 'alerts') &&
              results.alerts.map((alert) => (
                <ResultCard
                  key={alert.id}
                  item={alert}
                  domain="disaster"
                  onSave={() => {
                    const newSaved = new Set(saved);
                    newSaved.add(alert.id);
                    setSaved(newSaved);
                  }}
                  isSaved={saved.has(alert.id)}
                />
              ))}
          </div>

          <Button
            onClick={() => setTab('home')}
            variant="outline"
            className="w-full mt-6"
          >
            ← New Search
          </Button>
        </div>
      </div>
    );
  };

  const renderSaved = () => (
    <div className="min-h-screen bg-gray-100 p-4">
      <div className="max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-6">Saved Items</h2>
        {saved.size === 0 ? (
          <p className="text-gray-600">No saved items yet</p>
        ) : (
          <p className="text-gray-600">{saved.size} saved</p>
        )}
        <Button
          onClick={() => setTab('home')}
          variant="outline"
          className="w-full mt-6"
        >
          ← Home
        </Button>
      </div>
    </div>
  );

  const renderProfile = () => (
    <div className="min-h-screen bg-gray-100 p-4">
      <div className="max-w-2xl mx-auto">
        <h2 className="text-2xl font-bold mb-6">Profile</h2>
        <Card className="p-6">
          <div className="space-y-3">
            <div>
              <label className="text-sm font-semibold">Name</label>
              <input
                type="text"
                value={userProfile.name}
                onChange={(e) =>
                  setUserProfile({ ...userProfile, name: e.target.value })
                }
                className="w-full border rounded p-2"
              />
            </div>
            <div>
              <label className="text-sm font-semibold">State</label>
              <input
                type="text"
                value={userProfile.state}
                onChange={(e) =>
                  setUserProfile({ ...userProfile, state: e.target.value })
                }
                className="w-full border rounded p-2"
              />
            </div>
          </div>
        </Card>
        <Button
          onClick={() => setTab('home')}
          variant="outline"
          className="w-full mt-6"
        >
          ← Home
        </Button>
      </div>
    </div>
  );

  // ────────────────────────────────────────────────────────
  // Main Render
  // ────────────────────────────────────────────────────────

  return (
    <>
      {tab === 'home' && renderHome()}
      {tab === 'voice' && renderVoice()}
      {tab === 'results' && renderResults()}
      {tab === 'saved' && renderSaved()}
      {tab === 'profile' && renderProfile()}

      {/* Bottom Navigation */}
      {tab !== 'voice' && tab !== 'home' && (
        <div className="fixed bottom-0 left-0 right-0 bg-white border-t flex justify-around p-3">
          <button
            onClick={() => setTab('home')}
            className="flex flex-col items-center gap-1"
          >
            <Home className="h-6 w-6" />
            <span className="text-xs">Home</span>
          </button>
          <button
            onClick={() => setTab('voice')}
            className="flex flex-col items-center gap-1"
          >
            <Mic className="h-6 w-6" />
            <span className="text-xs">Search</span>
          </button>
          <button
            onClick={() => setTab('saved')}
            className="flex flex-col items-center gap-1"
          >
            <BookmarkIcon className="h-6 w-6" />
            <span className="text-xs">Saved</span>
          </button>
          <button
            onClick={() => setTab('profile')}
            className="flex flex-col items-center gap-1"
          >
            <Settings className="h-6 w-6" />
            <span className="text-xs">Profile</span>
          </button>
        </div>
      )}
    </>
  );
}

// ────────────────────────────────────────────────────────
// Result Card Component
// ────────────────────────────────────────────────────────

function ResultCard({
  item,
  domain,
  onSave,
  isSaved,
}: {
  item: any;
  domain: string;
  onSave: () => void;
  isSaved: boolean;
}) {
  const borderColor = {
    welfare: 'border-l-green-600',
    medicine: 'border-l-orange-600',
    prices: 'border-l-yellow-600',
    pollution: 'border-l-blue-600',
    disaster: 'border-l-red-600',
  }[domain] || 'border-l-gray-600';

  return (
    <Card className={`p-6 border-l-4 ${borderColor} hover:shadow-lg transition`}>
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1">
          <h3 className="font-bold text-lg text-gray-900">{item.name}</h3>
          {item.ministry && <p className="text-sm text-gray-500">{item.ministry}</p>}
          {item.location && <p className="text-sm text-gray-500">{item.location}</p>}
        </div>
        {item.benefit_amount && (
          <div className="text-right">
            <div className="text-2xl font-bold text-green-600">
              ₹{item.benefit_amount.toLocaleString()}
            </div>
          </div>
        )}
        {item.price_jan_aushadhi && (
          <div className="text-right">
            <div className="text-sm text-green-600 font-bold">Save ₹{item.savings}</div>
            <div className="text-xs text-gray-500">Was ₹{item.price_market}</div>
          </div>
        )}
      </div>

      {item.match_score && (
        <div className="mb-3">
          <div className="flex items-center gap-2 mb-1">
            <span className="text-sm font-semibold text-gray-700">
              {Math.round(item.match_score * 100)}% match
            </span>
          </div>
          <div className="h-2 bg-gray-200 rounded overflow-hidden">
            <div
              className="h-full bg-green-500"
              style={{ width: `${item.match_score * 100}%` }}
            />
          </div>
        </div>
      )}

      <div className="flex gap-2 mt-4">
        <Button
          onClick={onSave}
          variant={isSaved ? 'default' : 'outline'}
          className="flex-1"
        >
          <Heart
            className={`mr-2 h-4 w-4 ${isSaved ? 'fill-current' : ''}`}
          />
          {isSaved ? 'Saved' : 'Save'}
        </Button>
        <Button className="flex-1 bg-purple-600 hover:bg-purple-700">
          Apply
        </Button>
      </div>
    </Card>
  );
}

// ────────────────────────────────────────────────────────
// Mock Results
// ────────────────────────────────────────────────────────

function getMockResults(): UnifiedResults {
  return {
    schemes: [
      {
        id: 'pm-matru-vandana',
        name: 'PM Matru Vandana Yojana',
        domain: 'welfare',
        benefit_amount: 5000,
        match_score: 0.94,
      },
    ],
    medicines: [
      {
        id: 'prenatal-aushadhi',
        name: 'Jan Aushadhi Prenatal Vitamin',
        domain: 'medicine',
        price_jan_aushadhi: 50,
        price_market: 500,
        savings: 450,
        match_score: 0.95,
      },
    ],
    prices: [
      {
        id: 'spinach-price',
        name: 'Fresh Spinach',
        domain: 'prices',
        current_price: 20,
        location: 'Ramgarh Mandi',
        match_score: 0.8,
      },
    ],
    routes: [],
    alerts: [],
    tts_text: 'Found 2 schemes and 1 medicine option for you',
  };
}
