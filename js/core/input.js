// Unified Input Manager: Keyboard, Gamepad, and Touch

export class InputManager {
    constructor() {
        this.keys = {};
        this.touchState = {
            steerLeft: false,
            steerRight: false,
            throttle: false,
            brake: false,
            drift: false,
            nitro: false
        };

        // Smoothed analog steering (-1.0 to 1.0)
        this.steerSmooth = 0;
        this.steerSpeed = 8.0; // Responsive interpolation rate

        this.initKeyboard();
        this.initTouch();
    }

    initKeyboard() {
        window.addEventListener('keydown', (e) => {
            this.keys[e.code] = true;
            // Prevent scrolling on arrow keys & space
            if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) {
                e.preventDefault();
            }
        });

        window.addEventListener('keyup', (e) => {
            this.keys[e.code] = false;
        });

        window.addEventListener('blur', () => {
            this.keys = {};
            this.steerSmooth = 0;
        });
    }

    initTouch() {
        // Touch events will be bound to UI elements via bindTouchElement()
    }

    bindTouchButton(elementId, stateKey) {
        const el = document.getElementById(elementId);
        if (!el) return;

        const start = (e) => {
            e.preventDefault();
            this.touchState[stateKey] = true;
            el.classList.add('active');
        };
        const end = (e) => {
            e.preventDefault();
            this.touchState[stateKey] = false;
            el.classList.remove('active');
        };

        el.addEventListener('touchstart', start, { passive: false });
        el.addEventListener('touchend', end, { passive: false });
        el.addEventListener('touchcancel', end, { passive: false });
        el.addEventListener('mousedown', start);
        el.addEventListener('mouseup', end);
        el.addEventListener('mouseleave', end);
    }

    pollGamepad() {
        if (!navigator.getGamepads) return null;
        const gamepads = navigator.getGamepads();
        for (const gp of gamepads) {
            if (gp && gp.connected) {
                const steer = Math.abs(gp.axes[0]) > 0.15 ? gp.axes[0] : 0;
                const throttle = gp.buttons[7]?.value || (gp.buttons[0]?.pressed ? 1 : 0); // RT or A
                const brake = gp.buttons[6]?.value || (gp.buttons[1]?.pressed ? 1 : 0);    // LT or B
                const drift = gp.buttons[4]?.pressed || gp.buttons[2]?.pressed;           // LB or X
                const nitro = gp.buttons[5]?.pressed || gp.buttons[3]?.pressed;           // RB or Y
                const reset = gp.buttons[8]?.pressed;                                     // Back / Select
                const pause = gp.buttons[9]?.pressed;                                     // Start

                return { steer, throttle, brake, drift, nitro, reset, pause };
            }
        }
        return null;
    }

    getState(dt = 0.016) {
        let rawSteer = 0;
        let throttle = 0;
        let brake = 0;
        let drift = false;
        let nitro = false;
        let reset = false;
        let pause = false;

        // 1. Keyboard & Touch
        if (this.keys['KeyA'] || this.keys['ArrowLeft'] || this.touchState.steerLeft) rawSteer -= 1;
        if (this.keys['KeyD'] || this.keys['ArrowRight'] || this.touchState.steerRight) rawSteer += 1;
        if (this.keys['KeyW'] || this.keys['ArrowUp'] || this.touchState.throttle) throttle = 1;
        if (this.keys['KeyS'] || this.keys['ArrowDown'] || this.touchState.brake) brake = 1;
        if (this.keys['Space'] || this.touchState.drift) drift = true;
        if (this.keys['ShiftLeft'] || this.keys['ShiftRight'] || this.keys['KeyN'] || this.touchState.nitro) nitro = true;
        if (this.keys['KeyR']) reset = true;
        if (this.keys['Escape'] || this.keys['KeyP']) pause = true;

        // Smooth digital keyboard steering for fluid arcade handling
        if (rawSteer !== 0) {
            this.steerSmooth += (rawSteer - this.steerSmooth) * Math.min(1, dt * this.steerSpeed);
        } else {
            this.steerSmooth += (0 - this.steerSmooth) * Math.min(1, dt * this.steerSpeed * 1.5);
            if (Math.abs(this.steerSmooth) < 0.01) this.steerSmooth = 0;
        }

        let finalSteer = this.steerSmooth;

        // 2. Gamepad Override
        const gp = this.pollGamepad();
        if (gp) {
            if (Math.abs(gp.steer) > 0.05) finalSteer = gp.steer;
            if (gp.throttle > 0) throttle = Math.max(throttle, gp.throttle);
            if (gp.brake > 0) brake = Math.max(brake, gp.brake);
            if (gp.drift) drift = true;
            if (gp.nitro) nitro = true;
            if (gp.reset) reset = true;
            if (gp.pause) pause = true;
        }

        return {
            steer: Math.max(-1, Math.min(1, finalSteer)),
            throttle: Math.max(0, Math.min(1, throttle)),
            brake: Math.max(0, Math.min(1, brake)),
            drift,
            nitro,
            reset,
            pause
        };
    }
}
