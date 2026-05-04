//------------------------------------------------------------
// Heartbeat Driven Dynamic Music System
// Final Project - ChucK
//------------------------------------------------------------


//============================================================
// Instrument Setup
//============================================================

// Reverb 
NRev reverb => dac;
0.15 => reverb.mix;

// Melody
SinOsc melody => LPF mFilt => ADSR env => Gain master => reverb;
3000 => mFilt.freq;
0.7 => mFilt.Q;

// Chord
SinOsc chord1 => LPF cFilt => Gain chordGain => reverb;
SinOsc chord2 => cFilt;
SinOsc chord3 => cFilt;
2000 => cFilt.freq;

// Gain
0.20 => master.gain;
0.07 => chordGain.gain;

// ADSR
env.set(20::ms, 120::ms, 0.5, 150::ms);


//============================================================
// Drum Setup
//============================================================

// Kick
SinOsc kick => ADSR kickEnv => Gain kickGain => dac;
0.45 => kickGain.gain;
kickEnv.set(5::ms, 50::ms, 0.0, 50::ms);
0 => int kickBusy;

// Hi-hat
Noise hat => BPF bp => ADSR hatEnv => Gain hatGain => dac;
8000 => bp.freq;
0.7 => bp.Q;
0.15 => hatGain.gain;
hatEnv.set(1::ms, 10::ms, 0.0, 10::ms);


//============================================================
// Heart Rate Data
//============================================================
[
58, 59, 60, 62,
65, 68, 72, 78,
85, 92, 100, 110,
120, 135, 150, 168,
175, 160, 140, 120,
95, 75, 65
] @=> int heartData[];


//============================================================
// Scale Arrays
//============================================================
[48, 48, 50, 52] @=> int zone1[];
[48, 50, 52, 53, 55] @=> int zone2[];
[45, 48, 50, 52, 55, 57, 59] @=> int zone3[];
[43, 45, 48, 50, 52, 55, 57] @=> int zone4[];
[43, 45, 48, 50, 52, 55, 57, 59, 62, 64, 66, 69] @=> int zone5[];


//============================================================
// Chord Progressions
//============================================================
[
[60, 64, 67],   // C
[57, 60, 64],   // Am
[53, 57, 60],   // F
[55, 59, 62]    // G
] @=> int chords[][];


//============================================================
// Utility Functions
//============================================================
fun int getZone(int bpm)
{
    if(bpm < 70) return 1;
    else if(bpm < 90) return 2;
    else if(bpm < 120) return 3;
    else if(bpm < 145) return 4;
    else return 5;
}

fun dur bpmToDur(float bpm)
{
    return (60.0 / bpm)::second;
}

fun float lerp(float a, float b, float t)
{
    return a + (b - a) * t;
}

fun float bpmToGain(float bpm)
{
    return 0.15 + (bpm / 180.0) * 0.45;
}

fun void kickDrop()
{
    for(120 => float f; f > 60; f - 5 => f)
    {
        f => kick.freq;
        8::ms => now;
    }
    0 => kickBusy;
}


//============================================================
// Accent Pattern
//============================================================
fun float accent(int beat, int zone)
{
    if(zone == 1)
    {
        if(beat == 1 || beat == 8) return 1.0;
        else return 0.4;
    }
    else if(zone == 2)
    {
        if(beat == 1) return 1.0;
        else return 0.5;
    }
    else if(zone == 3)
    {
        if(beat == 1 || beat == 3) return 1.0;
        else return 0.6;
    }
    else if(zone == 4)
    {
        if(beat % 2 == 0) return 1.0;
        else return 0.6;
    }
    else
    {
        if(beat == 2 || beat == 6) return 1.0;
        else return 0.7;
    }
}


//============================================================
// Melody Note Selection
//============================================================
0 => int currentIndex;

fun int pickNote(int zone)
{
    int scale[];

    if(zone == 1) zone1 @=> scale;
    else if(zone == 2) zone2 @=> scale;
    else if(zone == 3) zone3 @=> scale;
    else if(zone == 4) zone4 @=> scale;
    else zone5 @=> scale;

    if(Math.randomf() < 0.8){
        currentIndex + Math.random2(-1, 1) => currentIndex;
    }
    else{
        Math.random2(0, scale.size()-1) => currentIndex;
    }

    if(currentIndex < 0) 0 => currentIndex;
    if(currentIndex >= scale.size()) scale.size()-1 => currentIndex;

    return scale[currentIndex];
}


//============================================================
// Chord Playback
//============================================================
fun void playChord(int zone)
{
    chords[(zone-1) % chords.size()][0] => int root;
    chords[(zone-1) % chords.size()][1] => int third;
    chords[(zone-1) % chords.size()][2] => int fifth;

    Std.mtof(root) => chord1.freq;
    Std.mtof(third) => chord2.freq;
    Std.mtof(fifth) => chord3.freq;
}


//============================================================
// Main Performance
//============================================================
80.0 => float currentBPM;
1 => int beatCount;

for(0 => int i; i < heartData.size(); i++)
{
    heartData[i] => float targetBPM;
    getZone(heartData[i]) => int zone;

    <<< "Heart Rate:", heartData[i], "Zone:", zone >>>;

    for(0 => int step; step < 8; step++)
    {
        if(step == 0){
            0 => currentIndex;
        }

        lerp(currentBPM, targetBPM, 0.15) => currentBPM;

        bpmToDur(currentBPM) => dur beatDur;
        bpmToGain(currentBPM) => float baseGain;

        if(beatCount % 8 == 1)
        {
            playChord(zone);
        }

        pickNote(zone) => int note;
        Std.mtof(note) => melody.freq;

        accent(beatCount, zone) * baseGain * 0.7 => master.gain;

        if((beatCount == 1 || beatCount == 5) && kickBusy == 0){
            1 => kickBusy;
            120 => kick.freq;
            kickEnv.keyOn();
            spork ~ kickDrop();
        }

        if(beatCount % 2 == 0){
            0.15 => hatGain.gain;
        }
        else{
            0.08 => hatGain.gain;
        }

        if(zone <= 2){
            hatEnv.keyOn();
        }
        else if(zone <= 3){
            if(beatCount % 2 == 0 || Math.randomf() < 0.3)
                hatEnv.keyOn();
        }
        else{
            if(Math.randomf() < 0.7)
                hatEnv.keyOn();
        }

        float rhythm;

        if(zone <= 2)
            1.0 => rhythm;
        else if(zone <= 3)
            0.5 => rhythm;
        else
            (Math.randomf() < 0.7 ? 0.5 : 1.0) => rhythm;

        env.keyOn();
        beatDur * rhythm * 0.8 => now;
        env.keyOff();
        beatDur * rhythm * 0.2 => now;

        beatCount++;
        if(beatCount > 8) 1 => beatCount;
    }
}


//============================================================
// Final Release
//============================================================
env.keyOff();
kickEnv.keyOff();
hatEnv.keyOff();
2::second => now;