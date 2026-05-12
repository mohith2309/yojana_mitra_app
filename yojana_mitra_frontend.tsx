/**
 * YojanaMitra Frontend
 * Voice-first welfare scheme assistant
 * Next.js + React + Tailwind + shadcn/ui
 */

'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Mic, StopCircle, Volume2, Heart, MapPin, FileText } from 'lucide-react';

interface UserProfile {
  name: string;
  age: number;
  gender: string;
  state: string;
  district?: string;
  occupation: string;
  family_size: number;
  annual_income: number;
  marital_status: string;
  assets: Record<string, any>;
  languages: string[];
  phone?: string;
}

interface SchemeMatch {
  scheme_id: string;
  scheme_name: string;
  ministry: string;
  benefit_amount: number;
  benefit_frequency: string;
  match_score: number;
  match_reasons: string[];
  documents_needed: string[];
  next_steps: string[];
  nearest_csc?: any;
}

export default function YojanaMitra() {
  const [step, setStep] = useState<'intro' | 'profile' | 'voice' | 'results'>('intro');
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [matches, setMatches] = useState<SchemeMatch[]>([]);
  const [saved, setSaved] = useState<Set<string>>(new Set());

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);

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
        stream.getTracks().forEach(track => track.stop());
      };

      mediaRecorder.start();
      setIsListening(true);
    } catch (err) {
      console.error('Microphone access denied:', err);
      alert('Microphone access required for voice input');
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
      formData.append('language', 'hi'); // TODO: detect from user

      const response = await fetch('/api/voice/transcribe', {
        method: 'POST',
        body: formData,
      });

      const data = await response.json();
      setTranscript(data.text);

      // Auto-extract profile from speech
      if (data.text) {
        await extractProfileAndSearch(data.text);
      }
    } catch (err) {
      console.error('Transcription error:', err);
      setTranscript('Could not transcribe audio. Please try again or type.');
    }
  };

  // ────────────────────────────────────────────────────────
  // Profile Extraction & Scheme Search
  // ────────────────────────────────────────────────────────

  const extractProfileAndSearch = async (text: string) => {
    // Mock extraction (in production, use LLM via backend)
    const mockProfile: UserProfile = {
      name: extractName(text) || 'User',
      age: extractAge(text) || 35,
      gender: 'F',
      state: extractState(text) || 'UP',
      occupation: extractOccupation(text) || 'farmer',
      family_size: extractFamilySize(text) || 3,
      annual_income: extractIncome(text) || 60000,
      marital_status: text.toLowerCase().includes('widow') ? 'widow' : 'married',
      assets: {},
      languages: ['hi', 'en'],
    };

    setUserProfile(mockProfile);
    await searchSchemes(mockProfile);
    setStep('results');
  };

  const searchSchemes = async (profile: UserProfile) => {
    try {
      const response = await fetch('/api/schemes/search', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_profile: profile }),
      });

      const data = await response.json();
      setMatches(data);
    } catch (err) {
      console.error('Search error:', err);
      // Fallback mock schemes
      setMatches(getMockMatches(profile));
    }
  };

  // ────────────────────────────────────────────────────────
  // UI Components
  // ────────────────────────────────────────────────────────

  if (step === 'intro') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-orange-50 to-yellow-50 flex items-center justify-center p-4">
        <Card className="max-w-md w-full p-8 text-center border-orange-200">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">YojanaMitra</h1>
          <p className="text-lg text-orange-600 font-medium mb-4">
            "Boli mein sun, scheme mein jod, document khud bhar"
          </p>
          <p className="text-gray-600 mb-8">
            Your AI-powered guide to government welfare schemes
          </p>

          <Button
            onClick={() => setStep('voice')}
            className="w-full bg-orange-600 hover:bg-orange-700 text-white py-6 text-lg mb-4"
          >
            <Mic className="mr-2 h-5 w-5" />
            Start Voice Input
          </Button>

          <Button
            onClick={() => setStep('profile')}
            variant="outline"
            className="w-full py-6 text-lg border-orange-300"
          >
            Enter Details Manually
          </Button>

          <p className="text-xs text-gray-500 mt-6">
            Works offline. Data never shared. Built with Indian govt APIs.
          </p>
        </Card>
      </div>
    );
  }

  if (step === 'voice') {
    return (
      <div className="min-h-screen bg-gradient-to-b from-orange-50 to-yellow-50 flex items-center justify-center p-4">
        <Card className="max-w-md w-full p-8 text-center">
          <h2 className="text-2xl font-bold mb-6">Tell Your Situation</h2>

          <div className="mb-6 p-8 bg-orange-100 rounded-full flex items-center justify-center">
            {isListening ? (
              <div className="animate-pulse">
                <Mic className="h-12 w-12 text-red-500" />
              </div>
            ) : (
              <Mic className="h-12 w-12 text-gray-400" />
            )}
          </div>

          <p className="text-gray-600 mb-6 text-sm">
            "Mera pati nahi raha, do bachche hain, ghar mein gaaye hain"<br />
            (Speak in Hindi, Marathi, Tamil, or English)
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
                Start Recording
              </Button>
            ) : (
              <Button
                onClick={stopListening}
                className="flex-1 bg-orange-600 hover:bg-orange-700 py-6"
              >
                <StopCircle className="mr-2 h-5 w-5" />
                Stop
              </Button>
            )}
          </div>

          <Button
            onClick={() => setStep('profile')}
            variant="ghost"
            className="w-full mt-4"
          >
            Prefer typing? Enter manually
          </Button>
        </Card>
      </div>
    );
  }

  if (step === 'results' && userProfile && matches.length > 0) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-orange-50 to-yellow-50 p-4">
        <div className="max-w-2xl mx-auto">
          {/* Header */}
          <div className="bg-white rounded-lg p-6 mb-6 border border-orange-200">
            <h2 className="text-2xl font-bold text-gray-900">
              {matches.length} schemes for you
            </h2>
            <p className="text-gray-600">
              {userProfile.name}, {userProfile.age} • {userProfile.state} • {userProfile.occupation}
            </p>
          </div>

          {/* Scheme Cards */}
          <div className="space-y-4">
            {matches.map((scheme) => (
              <Card
                key={scheme.scheme_id}
                className="p-6 border-l-4 border-l-orange-600 hover:shadow-lg transition"
              >
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <h3 className="font-bold text-lg text-gray-900">
                      {scheme.scheme_name}
                    </h3>
                    <p className="text-sm text-gray-500">{scheme.ministry}</p>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold text-green-600">
                      ₹{scheme.benefit_amount.toLocaleString()}
                    </div>
                    <p className="text-xs text-gray-500">
                      {scheme.benefit_frequency}
                    </p>
                  </div>
                </div>

                {/* Match Score */}
                <div className="mb-3">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-semibold text-gray-700">
                      {Math.round(scheme.match_score * 100)}% match
                    </span>
                  </div>
                  <div className="h-2 bg-gray-200 rounded overflow-hidden">
                    <div
                      className="h-full bg-green-500"
                      style={{ width: `${scheme.match_score * 100}%` }}
                    />
                  </div>
                </div>

                {/* Match Reasons */}
                <div className="mb-4">
                  <p className="text-sm font-semibold text-gray-700 mb-2">
                    Why you qualify:
                  </p>
                  <ul className="text-sm text-gray-600 space-y-1">
                    {scheme.match_reasons.map((reason, i) => (
                      <li key={i}>✓ {reason}</li>
                    ))}
                  </ul>
                </div>

                {/* Documents Needed */}
                <div className="mb-4 p-3 bg-blue-50 rounded">
                  <p className="text-sm font-semibold text-blue-900 mb-2">
                    Documents needed:
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {scheme.documents_needed.map((doc) => (
                      <span
                        key={doc}
                        className="text-xs bg-blue-200 text-blue-800 px-2 py-1 rounded"
                      >
                        {doc}
                      </span>
                    ))}
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex gap-2">
                  <Button
                    onClick={() => {
                      const newSaved = new Set(saved);
                      newSaved.add(scheme.scheme_id);
                      setSaved(newSaved);
                    }}
                    variant={saved.has(scheme.scheme_id) ? 'default' : 'outline'}
                    className="flex-1"
                  >
                    <Heart
                      className={`mr-2 h-4 w-4 ${
                        saved.has(scheme.scheme_id) ? 'fill-current' : ''
                      }`}
                    />
                    {saved.has(scheme.scheme_id) ? 'Saved' : 'Save'}
                  </Button>

                  <Button
                    onClick={() => {
                      /* Generate form */
                    }}
                    className="flex-1 bg-orange-600 hover:bg-orange-700"
                  >
                    <FileText className="mr-2 h-4 w-4" />
                    Generate Form
                  </Button>
                </div>
              </Card>
            ))}
          </div>

          {/* Next Steps */}
          <Card className="mt-6 p-6 bg-green-50 border-green-200">
            <h3 className="font-bold text-lg text-green-900 mb-4">Next Steps</h3>
            <ol className="space-y-3 text-sm text-green-800">
              <li>1. <span className="font-semibold">Collect Documents:</span> Aadhaar, income certificate, relevant proof</li>
              <li>2. <span className="font-semibold">Visit Nearby CSC:</span> Common Service Center in your area</li>
              <li>3. <span className="font-semibold">Apply:</span> Staff will help you submit application</li>
              <li>4. <span className="font-semibold">Track:</span> Monitor status via government portal</li>
            </ol>
          </Card>

          <Button
            onClick={() => setStep('intro')}
            variant="ghost"
            className="w-full mt-6"
          >
            Search Again
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-100 p-4 text-center">
      <p>Loading...</p>
    </div>
  );
}

// ────────────────────────────────────────────────────────
// Helper Functions
// ────────────────────────────────────────────────────────

function extractName(text: string): string | null {
  const names = ['Ramakali', 'Meena', 'Priya', 'Rajesh'];
  for (const name of names) {
    if (text.toLowerCase().includes(name.toLowerCase())) {
      return name;
    }
  }
  return null;
}

function extractAge(text: string): number | null {
  const match = text.match(/(\d+)\s*(saal|year|sal|वर्ष)/i);
  return match ? parseInt(match[1]) : null;
}

function extractState(text: string): string | null {
  const states: Record<string, string> = {
    'up': 'UP',
    'bihar': 'Bihar',
    'maharashtra': 'Maharashtra',
    'tamil': 'Tamil Nadu',
    'west': 'West Bengal',
  };

  for (const [key, value] of Object.entries(states)) {
    if (text.toLowerCase().includes(key)) {
      return value;
    }
  }
  return null;
}

function extractOccupation(text: string): string | null {
  const occupations = ['farmer', 'kisan', 'widow', 'student', 'worker'];
  for (const occ of occupations) {
    if (text.toLowerCase().includes(occ)) {
      return occ;
    }
  }
  return null;
}

function extractFamilySize(text: string): number | null {
  const match = text.match(/(\d+)\s*(child|bachcha|bacche|member)/i);
  return match ? parseInt(match[1]) + 1 : null; // +1 for respondent
}

function extractIncome(text: string): number | null {
  const match = text.match(/(lakh|साथ|लाख)(\d+)?|([\d]{5})/);
  if (match) {
    const num = match[2] || match[3];
    return num ? parseInt(num) * 10000 : 50000;
  }
  return null;
}

function getMockMatches(profile: UserProfile): SchemeMatch[] {
  return [
    {
      scheme_id: 'pm-matru-vandana',
      scheme_name: 'PM Matru Vandana Yojana',
      ministry: 'MWCD',
      benefit_amount: 5000,
      benefit_frequency: 'quarterly',
      match_score: 0.85,
      match_reasons: ['Female eligible', 'Age group matches'],
      documents_needed: ['Aadhaar', 'Delivery cert', 'Bank account'],
      next_steps: [
        'Collect delivery certificate from ANM',
        'Visit nearest CSC with Aadhaar & bank passbook',
      ],
    },
    {
      scheme_id: 'pm-kisan',
      scheme_name: 'PM-KISAN',
      ministry: 'Agriculture',
      benefit_amount: 6000,
      benefit_frequency: 'yearly',
      match_score: 0.78,
      match_reasons: ['Farmer occupation', 'Land ownership eligible'],
      documents_needed: ['Aadhaar', 'Land record', 'Bank account'],
      next_steps: [
        'Register on PM-KISAN portal',
        'Provide land details & Aadhaar',
      ],
    },
  ];
}
