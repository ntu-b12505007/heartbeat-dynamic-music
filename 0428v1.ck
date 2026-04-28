//------------------------------------------------------------
// Heartbeat Driven Dynamic Music System
// Final Project - ChucK
//------------------------------------------------------------

//============================================================
// Instrument Setup
//============================================================
SawOsc melody => ADSR env => Gain master => dac;
TriOsc chord1 => Gain chordGain => master;
TriOsc chord2 => chordGain;
TriOsc chord3 => chordGain;

0.35 => master.gain;
0.18 => chordGain.gain;

// ADSR
env.set(10::ms, 80::ms, 0.6, 100::ms);

//============================================================
// Heart Rate Data
//============================================================
[
    58, 60, 63, 67,
    72, 78, 85, 92,
    102, 115, 128, 142,
    155, 168, 174, 165,
    150, 132, 110, 88,
    74, 65
] @=> int heartData[];

//============================================================
// Scale Arrays
//============================================================
[60, 62, 64] @=> int zone1[];
[60, 62, 64, 65, 67] @=> int zone2[];
[60, 62, 64, 65, 67, 69, 71] @=> int zone3[];
[48, 52, 55, 60, 64, 67, 72] @=> int zone4[];
[48, 52, 55, 60, 64, 67, 72, 76, 79, 84] @=> int zone5[];

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
    else if(bpm < 150) return 4;
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
fun int pickNote(int zone)
{
    if(zone == 1)
        return zone1[Math.random2(0, zone1.size()-1)];
    else if(zone == 2)
        return zone2[Math.random2(0, zone2.size()-1)];
    else if(zone == 3)
        return zone3[Math.random2(0, zone3.size()-1)];
    else if(zone == 4)
        return zone4[Math.random2(0, zone4.size()-1)];
    else
        return zone5[Math.random2(0, zone5.size()-1)];
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

    // Each data point lasts for 8 beats
    for(0 => int step; step < 8; step++)
    {
        // Smooth transition
        lerp(currentBPM, targetBPM, 0.25) => currentBPM;

        bpmToDur(currentBPM) => dur beatDur;
        bpmToGain(currentBPM) => float baseGain;

        // Update chord
        playChord(zone);

        // Melody
        pickNote(zone) => int note;
        Std.mtof(note) => melody.freq;

        accent(beatCount, zone) * baseGain => master.gain;

        env.keyOn();
        beatDur * 0.8 => now;
        env.keyOff();
        beatDur * 0.2 => now;

        beatCount++;
        if(beatCount > 8) 1 => beatCount;
    }
}

// Final release
env.keyOff();
2::second => now;