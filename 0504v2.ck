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
SinOsc shimmer => mFilt;
0.05 => shimmer.gain;
3000 => mFilt.freq;
0.7 => mFilt.Q;

// Chord
SinOsc chord1 => LPF cFilt => Gain chordGain => reverb;
SinOsc chord2 => cFilt;
SinOsc chord3 => cFilt;
2000 => cFilt.freq;

// Gain
0.15 => master.gain;
0.20 => chordGain.gain;

// ADSR
env.set(20::ms, 120::ms, 0.5, 150::ms);



//============================================================
// Drum Setup
//============================================================

// Kick
SinOsc kick => ADSR kickEnv => Gain kickGain => dac;
0.35 => kickGain.gain;
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
    // warm-up
    80, 82, 85, 88, 90,

    // gradual rise
    95, 100, 105, 110,

    // zone 2 transition
    115, 120, 125, 128, 130,

    // steady cardio
    132, 135, 138, 140, 142, 145,

    // threshold push
    148, 150, 152, 155, 158,

    // zone 4 climb
    160, 163, 166, 168, 170,

    // sprint peak
    172, 175, 178, 182, 185, 188,

    // recovery drop
    180, 175, 170, 165, 160,

    // second wave (fatigue)
    158, 155, 150, 145, 140,

    // cooldown
    135, 130, 125, 120, 115, 110,

    // final rest
    105, 100, 95, 90, 85
] @=> int heartData[];

//============================================================
// Note Arrays (Zones)
//============================================================
[48, 50, 52] @=> int zone1[];
[48, 50, 52, 55] @=> int zone2[];
[45, 48, 50, 52, 55, 57] @=> int zone3[];
[43, 45, 48, 50, 52, 55, 57, 59] @=> int zone4[];
[43, 45, 48, 50, 52, 55, 57, 59, 62, 64, 66] @=> int zone5[];



//============================================================
// Chord Progressions
//============================================================
// Zone 1：很穩
[
    [60, 64, 67]
] @=> int zone1Chords[][];

// Zone 2：開始動
[
    [60, 64, 67],
    [55, 59, 62]
] @=> int zone2Chords[][];

// Zone 3：正常跑
[
    [60, 64, 67],
    [57, 60, 64],
    [53, 57, 60],
    [55, 59, 62]
] @=> int zone3Chords[][];

// Zone 4：緊張
[
    [57, 60, 64],   // Am
    [59, 62, 65],   // Bdim-ish
    [53, 57, 60],   // F
    [55, 59, 62]    // G
] @=> int zone4Chords[][];

// Zone 5：衝刺
[
    [48, 55, 62],   // C add6（穩但亮）
    [50, 57, 64],   // D sus / tension
    [53, 60, 67],   // F 上移（開始亮）
    [55, 62, 69]    // G open / brightness
] @=> int zone5Chords[][];

//============================================================
// Utility Functions
//============================================================

// BPM → Zone
fun int getZone(int bpm)
{
    if(bpm < 110) return 1;
    else if(bpm < 130) return 2;
    else if(bpm < 150) return 3;
    else if(bpm < 170) return 4;
    else return 5;
}

// BPM → beat duration
fun dur bpmToDur(float bpm)
{
    return (60.0 / bpm)::second;
}

// linear interpolation
fun float lerp(float a, float b, float t)
{
    return a + (b - a) * t;
}

// BPM → gain
fun float bpmToGain(float bpm)
{
    if(bpm < 110) return 0.12;
    else if(bpm < 130) return 0.12 + (bpm-110)*0.003;
    else if(bpm < 150) return 0.18 + (bpm-130)*0.004;
    else if(bpm < 170) return 0.26 + (bpm-150)*0.005;
    else return 0.36 + (bpm-170)*0.006;
}

// kick sweep effect
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

    if(Math.randomf() < 0.8)
    {
        currentIndex + Math.random2(-1, 1) => currentIndex;
    }
    else
    {
        Math.random2(0, scale.size()-1) => currentIndex;
    }

    if(currentIndex < 0) 0 => currentIndex;
    if(currentIndex >= scale.size()) scale.size()-1 => currentIndex;

    return scale[currentIndex];
}



//============================================================
// Chord Playback
//============================================================
0 => int chordIndex;

fun void playChord(int zone)
{
    int currentChord[];

    if(zone == 1) zone1Chords[chordIndex % zone1Chords.size()] @=> currentChord;
    else if(zone == 2) zone2Chords[chordIndex % zone2Chords.size()] @=> currentChord;
    else if(zone == 3) zone3Chords[chordIndex % zone3Chords.size()] @=> currentChord;
    else if(zone == 4) zone4Chords[chordIndex % zone4Chords.size()] @=> currentChord;
    else zone5Chords[chordIndex % zone5Chords.size()] @=> currentChord;

    Std.mtof(currentChord[0]) => chord1.freq;
    Std.mtof(currentChord[1]) => chord2.freq;
    Std.mtof(currentChord[2]) => chord3.freq;

    chordIndex++;
}

//============================================================
// Main Performance
//============================================================
heartData[0] => float currentBPM;
1 => int beatCount;

for(0 => int i; i < heartData.size(); i++)
{
    heartData[i] => float targetBPM;
    getZone(heartData[i]) => int zone;

    <<< "Heart Rate:", heartData[i], "Zone:", zone >>>;

    for(0 => int step; step < 8; step++) // 8 beats
    {
        if(step == 0)
        {
            0 => currentIndex;
        }

        // BPM smoothing
        lerp(currentBPM, targetBPM, 0.25) => currentBPM;

        bpmToDur(currentBPM) => dur beatDur;
        bpmToGain(currentBPM) => float baseGain;

        // chord trigger
        if(beatCount % 8 == 1)
        {
            playChord(zone);
        }

        // Zone 1 extra sparse behavior
        if(zone == 1)
        {
            if(beatCount % 4 == 1)
            {
                pickNote(zone) => int note;
                Std.mtof(note) => melody.freq;
                env.keyOn();
            }

            if(Math.randomf() < 0.12)
            {
                hatEnv.keyOn();
            }
        }

        // Zone 2 behavior (slightly structured groove)
        if(zone == 2)
        {
            if(beatCount % 2 == 0)
            {
                hatEnv.keyOn();
            }

            if(beatCount % 4 == 1)
            {
                pickNote(zone) => int note;
                Std.mtof(note) => melody.freq;
                env.keyOn();
            }

            if(beatCount % 8 == 1 && Math.randomf() < 0.5)
            {
                playChord(zone);
            }
        }


        // ⭐ zone5
        if(zone == 5)
        {
            pickNote(zone) => int note;

            // 亮
            Std.mtof(note + 12) => melody.freq;

            // shimmer 當補光
            Std.mtof(note + 12) => shimmer.freq;

            env.attackTime(10::ms);
            env.releaseTime(120::ms);
            env.keyOn();
        }
        else
        {
            // melody
            pickNote(zone) => int note;
            Std.mtof(note) => melody.freq;

            env.set(20::ms, 120::ms, 0.5, 150::ms);
        }
        // dynamics
        accent(beatCount, zone) * baseGain * 0.7 => master.gain;

        // kick
        if((beatCount == 1 || beatCount == 5) && kickBusy == 0)
        {
            1 => kickBusy;
            120 => kick.freq;
            kickEnv.keyOn();
            spork ~ kickDrop();
        }

        // hi-hat basic rhythm
        if(beatCount % 2 == 0)
        {
            0.15 => hatGain.gain;
        }
        else
        {
            0.08 => hatGain.gain;
        }

        // hi-hat density by zone
        if(zone <= 2)
        {
            hatEnv.keyOn();
        }
        else if(zone <= 3)
        {
            if(beatCount % 2 == 0 || Math.randomf() < 0.3)
                hatEnv.keyOn();
        }
        else if(zone == 4)
        {
            if(Math.randomf() < 0.4)
                hatEnv.keyOn();
        }
        else
        {
            if(beatCount % 4 == 0 && Math.randomf() < 0.2)
            hatEnv.keyOn();
        }

        // rhythm decision
        float rhythm;

        if(zone <= 2)
            1.0 => rhythm;
        else if(zone == 3)
            0.6 => rhythm;
        else if(zone == 4)
            0.5 => rhythm;
        else
            0.35 + Math.random2f(0, 0.15) => rhythm;

        // play envelope
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