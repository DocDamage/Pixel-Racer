// Web Audio API Procedural Synthesizer & Sound Effects Engine

export class SoundEngine {
    constructor() {
        this.ctx = null;
        this.masterGain = null;
        this.sfxGain = null;
        this.musicGain = null;
        this.isMuted = false;
        this.initialized = false;

        // Vehicle Engine Audio Nodes
        this.engineOsc1 = null;
        this.engineOsc2 = null;
        this.engineFilter = null;
        this.engineGain = null;
        this.engineRunning = false;

        // Tire Skid Audio Nodes
        this.skidNode = null;
        this.skidGain = null;
        this.skidFilter = null;

        // Nitro Audio Nodes
        this.nitroNode = null;
        this.nitroGain = null;

        // Music Arpeggio Loop
        this.musicInterval = null;
    }

    init() {
        if (this.initialized) return;
        try {
            const AudioContext = window.AudioContext || window.webkitAudioContext;
            this.ctx = new AudioContext();

            this.masterGain = this.ctx.createGain();
            this.masterGain.gain.setValueAtTime(0.7, this.ctx.currentTime);
            this.masterGain.connect(this.ctx.destination);

            this.sfxGain = this.ctx.createGain();
            this.sfxGain.gain.setValueAtTime(0.8, this.ctx.currentTime);
            this.sfxGain.connect(this.masterGain);

            this.musicGain = this.ctx.createGain();
            this.musicGain.gain.setValueAtTime(0.35, this.ctx.currentTime);
            this.musicGain.connect(this.masterGain);

            this.setupEngineSound();
            this.setupSkidSound();
            this.setupNitroSound();

            this.initialized = true;
        } catch (err) {
            console.warn('[SoundEngine] Web Audio not supported or blocked:', err);
        }
    }

    resume() {
        if (this.ctx && this.ctx.state === 'suspended') {
            this.ctx.resume();
        }
        if (!this.initialized) {
            this.init();
        }
    }

    setupEngineSound() {
        if (!this.ctx) return;

        this.engineGain = this.ctx.createGain();
        this.engineGain.gain.setValueAtTime(0, this.ctx.currentTime);

        this.engineFilter = this.ctx.createBiquadFilter();
        this.engineFilter.type = 'lowpass';
        this.engineFilter.frequency.setValueAtTime(350, this.ctx.currentTime);

        this.engineOsc1 = this.ctx.createOscillator();
        this.engineOsc1.type = 'sawtooth';
        this.engineOsc1.frequency.setValueAtTime(45, this.ctx.currentTime);

        this.engineOsc2 = this.ctx.createOscillator();
        this.engineOsc2.type = 'triangle';
        this.engineOsc2.frequency.setValueAtTime(90, this.ctx.currentTime);

        this.engineOsc1.connect(this.engineFilter);
        this.engineOsc2.connect(this.engineFilter);
        this.engineFilter.connect(this.engineGain);
        this.engineGain.connect(this.sfxGain);

        this.engineOsc1.start();
        this.engineOsc2.start();
    }

    setupSkidSound() {
        if (!this.ctx) return;

        const bufferSize = this.ctx.sampleRate * 2;
        const noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const output = noiseBuffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
            output[i] = Math.random() * 2 - 1;
        }

        const whiteNoise = this.ctx.createBufferSource();
        whiteNoise.buffer = noiseBuffer;
        whiteNoise.loop = true;

        this.skidFilter = this.ctx.createBiquadFilter();
        this.skidFilter.type = 'bandpass';
        this.skidFilter.frequency.setValueAtTime(1100, this.ctx.currentTime);
        this.skidFilter.Q.setValueAtTime(3.0, this.ctx.currentTime);

        this.skidGain = this.ctx.createGain();
        this.skidGain.gain.setValueAtTime(0, this.ctx.currentTime);

        whiteNoise.connect(this.skidFilter);
        this.skidFilter.connect(this.skidGain);
        this.skidGain.connect(this.sfxGain);

        whiteNoise.start();
    }

    setupNitroSound() {
        if (!this.ctx) return;

        const bufferSize = this.ctx.sampleRate * 2;
        const noiseBuffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
        const output = noiseBuffer.getChannelData(0);
        for (let i = 0; i < bufferSize; i++) {
            output[i] = Math.random() * 2 - 1;
        }

        const nitroNoise = this.ctx.createBufferSource();
        nitroNoise.buffer = noiseBuffer;
        nitroNoise.loop = true;

        const nitroFilter = this.ctx.createBiquadFilter();
        nitroFilter.type = 'lowpass';
        nitroFilter.frequency.setValueAtTime(1400, this.ctx.currentTime);

        this.nitroGain = this.ctx.createGain();
        this.nitroGain.gain.setValueAtTime(0, this.ctx.currentTime);

        nitroNoise.connect(nitroFilter);
        nitroFilter.connect(this.nitroGain);
        this.nitroGain.connect(this.sfxGain);

        nitroNoise.start();
    }

    updateEngine(speedRatio, isAccelerating) {
        if (!this.initialized || !this.engineGain || this.isMuted) return;

        const clampedRatio = Math.max(0, Math.min(1.2, speedRatio));
        const baseFreq = 45 + clampedRatio * 180 + (isAccelerating ? 30 : 0);
        const filterFreq = 300 + clampedRatio * 1600;
        const targetGain = 0.08 + clampedRatio * 0.14 + (isAccelerating ? 0.05 : 0);

        const now = this.ctx.currentTime;
        this.engineOsc1.frequency.setTargetAtTime(baseFreq, now, 0.05);
        this.engineOsc2.frequency.setTargetAtTime(baseFreq * 2, now, 0.05);
        this.engineFilter.frequency.setTargetAtTime(filterFreq, now, 0.05);
        this.engineGain.gain.setTargetAtTime(targetGain, now, 0.05);
    }

    stopEngine() {
        if (this.engineGain && this.ctx) {
            this.engineGain.gain.setTargetAtTime(0, this.ctx.currentTime, 0.1);
        }
    }

    updateSkid(driftSlipRatio) {
        if (!this.initialized || !this.skidGain || this.isMuted) return;
        const gain = Math.max(0, Math.min(0.25, driftSlipRatio * 0.3));
        this.skidGain.gain.setTargetAtTime(gain, this.ctx.currentTime, 0.03);
    }

    updateNitro(isNitroActive) {
        if (!this.initialized || !this.nitroGain || this.isMuted) return;
        const gain = isNitroActive ? 0.35 : 0;
        this.nitroGain.gain.setTargetAtTime(gain, this.ctx.currentTime, 0.05);
    }

    playCrash(intensity = 1.0) {
        if (!this.initialized || this.isMuted) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'triangle';
        osc.frequency.setValueAtTime(140 * intensity, now);
        osc.frequency.exponentialRampToValueAtTime(30, now + 0.25);

        gain.gain.setValueAtTime(0.4 * intensity, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);

        osc.connect(gain);
        gain.connect(this.sfxGain);

        osc.start(now);
        osc.stop(now + 0.35);
    }

    playCountdown(isFinal = false) {
        if (!this.initialized || this.isMuted) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'square';
        osc.frequency.setValueAtTime(isFinal ? 880 : 440, now);

        gain.gain.setValueAtTime(0.25, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + (isFinal ? 0.6 : 0.25));

        osc.connect(gain);
        gain.connect(this.sfxGain);

        osc.start(now);
        osc.stop(now + (isFinal ? 0.65 : 0.3));
    }

    playLapFanfare() {
        if (!this.initialized || this.isMuted) return;
        const notes = [523.25, 659.25, 783.99, 1046.50]; // C5, E5, G5, C6
        notes.forEach((freq, idx) => {
            const now = this.ctx.currentTime + idx * 0.09;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();

            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, now);

            gain.gain.setValueAtTime(0.2, now);
            gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);

            osc.connect(gain);
            gain.connect(this.sfxGain);

            osc.start(now);
            osc.stop(now + 0.3);
        });
    }

    playVictory() {
        if (!this.initialized || this.isMuted) return;
        const melody = [
            { f: 523.25, d: 0.15 }, { f: 659.25, d: 0.15 }, { f: 783.99, d: 0.15 },
            { f: 1046.50, d: 0.35 }, { f: 880.00, d: 0.15 }, { f: 1046.50, d: 0.6 }
        ];
        let t = this.ctx.currentTime;
        melody.forEach(n => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.type = 'square';
            osc.frequency.setValueAtTime(n.f, t);

            gain.gain.setValueAtTime(0.25, t);
            gain.gain.exponentialRampToValueAtTime(0.001, t + n.d);

            osc.connect(gain);
            gain.connect(this.sfxGain);

            osc.start(t);
            osc.stop(t + n.d + 0.05);
            t += n.d;
        });
    }

    playMenuBeep(isSelect = false) {
        if (!this.initialized || this.isMuted) return;
        const now = this.ctx.currentTime;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();

        osc.type = 'sine';
        osc.frequency.setValueAtTime(isSelect ? 900 : 600, now);
        if (isSelect) {
            osc.frequency.exponentialRampToValueAtTime(1200, now + 0.08);
        }

        gain.gain.setValueAtTime(0.12, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.1);

        osc.connect(gain);
        gain.connect(this.sfxGain);

        osc.start(now);
        osc.stop(now + 0.12);
    }

    startRetroBGM() {
        if (!this.ctx || this.musicInterval) return;
        const chords = [
            [220, 261.63, 329.63, 392], // Am7
            [174.61, 220, 261.63, 329.63], // Fmaj7
            [261.63, 329.63, 392, 493.88], // Cmaj7
            [196, 246.94, 293.66, 349.23]  // G7
        ];
        let chordIdx = 0;
        let noteStep = 0;

        this.musicInterval = setInterval(() => {
            if (!this.ctx || this.isMuted || this.ctx.state !== 'running') return;
            const currentChord = chords[chordIdx];
            const freq = currentChord[noteStep % currentChord.length];

            const now = this.ctx.currentTime;
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            const filter = this.ctx.createBiquadFilter();

            osc.type = 'sawtooth';
            osc.frequency.setValueAtTime(freq * 1.5, now);

            filter.type = 'lowpass';
            filter.frequency.setValueAtTime(600, now);
            filter.frequency.exponentialRampToValueAtTime(150, now + 0.18);

            gain.gain.setValueAtTime(0.08, now);
            gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.2);

            osc.connect(filter);
            filter.connect(gain);
            gain.connect(this.musicGain);

            osc.start(now);
            osc.stop(now + 0.22);

            noteStep++;
            if (noteStep % 8 === 0) {
                chordIdx = (chordIdx + 1) % chords.length;
            }
        }, 150);
    }

    stopRetroBGM() {
        if (this.musicInterval) {
            clearInterval(this.musicInterval);
            this.musicInterval = null;
        }
    }

    toggleMute() {
        this.isMuted = !this.isMuted;
        if (this.masterGain && this.ctx) {
            this.masterGain.gain.setValueAtTime(this.isMuted ? 0 : 0.7, this.ctx.currentTime);
        }
        return this.isMuted;
    }
}

export const soundEngine = new SoundEngine();
