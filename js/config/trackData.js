// Track Layouts, Surfaces, Waypoints, and Checkpoint Definitions

export const SURFACES = {
    ASPHALT: { id: 'asphalt', friction: 1.0, driftMultiplier: 1.0, maxSpeedMultiplier: 1.0, color: '#3b3f46' },
    DIRT: { id: 'dirt', friction: 0.82, driftMultiplier: 1.45, maxSpeedMultiplier: 0.88, color: '#8b5a2b' },
    SAND: { id: 'sand', friction: 0.68, driftMultiplier: 1.65, maxSpeedMultiplier: 0.75, color: '#d4a359' },
    GRASS: { id: 'grass', friction: 0.45, driftMultiplier: 1.8, maxSpeedMultiplier: 0.55, color: '#2d682a' },
    KERB: { id: 'kerb', friction: 0.95, driftMultiplier: 1.1, maxSpeedMultiplier: 0.98, color: '#e74c3c' }
};

export const TRACKS = {
    grand_prix: {
        id: 'grand_prix',
        name: 'Sunset Grand Prix Circuit',
        subtitle: 'Pro GP Asphalt Course',
        theme: 'asphalt',
        difficulty: 'Medium',
        surfaceType: 'ASPHALT',
        bgTile: 'Tilesets/grass.png',
        roadTile: 'Tilesets/race_track_1.png',
        trackWidth: 160,
        worldWidth: 3600,
        worldHeight: 2800,
        laps: 3,
        description: 'A classic professional circuit with sweeping high-speed corners, a technical chicane, and a long start-finish straight.',
        startAngle: -Math.PI / 2, // Facing North
        gridPositions: [
            { x: 1800, y: 2200, angle: -Math.PI / 2 },
            { x: 1860, y: 2280, angle: -Math.PI / 2 },
            { x: 1740, y: 2360, angle: -Math.PI / 2 },
            { x: 1860, y: 2440, angle: -Math.PI / 2 },
            { x: 1740, y: 2520, angle: -Math.PI / 2 },
            { x: 1860, y: 2600, angle: -Math.PI / 2 }
        ],
        // Waypoints defining the centerline of the track
        waypoints: [
            { x: 1800, y: 2200, speed: 1.0 },
            { x: 1800, y: 1400, speed: 1.0 },
            { x: 1800, y: 800, speed: 0.85 },
            { x: 2100, y: 500, speed: 0.7 },
            { x: 2600, y: 500, speed: 0.9 },
            { x: 3000, y: 800, speed: 0.7 },
            { x: 3100, y: 1300, speed: 0.8 },
            { x: 2800, y: 1600, speed: 0.65 },
            { x: 2400, y: 1500, speed: 0.8 },
            { x: 2200, y: 1700, speed: 0.6 },
            { x: 2400, y: 2000, speed: 0.85 },
            { x: 2900, y: 2200, speed: 0.75 },
            { x: 3000, y: 2500, speed: 0.65 },
            { x: 2600, y: 2650, speed: 0.85 },
            { x: 1200, y: 2650, speed: 1.0 },
            { x: 600, y: 2500, speed: 0.7 },
            { x: 500, y: 2000, speed: 0.85 },
            { x: 700, y: 1500, speed: 0.65 },
            { x: 1100, y: 1500, speed: 0.85 },
            { x: 1400, y: 1200, speed: 0.65 },
            { x: 1300, y: 700, speed: 0.75 },
            { x: 900, y: 500, speed: 0.7 },
            { x: 500, y: 800, speed: 0.65 },
            { x: 450, y: 1300, speed: 0.8 },
            { x: 500, y: 1800, speed: 0.85 },
            { x: 1000, y: 2200, speed: 0.95 },
            { x: 1800, y: 2200, speed: 1.0 }
        ]
    },

    dust_rally: {
        id: 'dust_rally',
        name: 'Dust Devil Rally',
        subtitle: 'Mud & Gravel Circuit',
        theme: 'dirt',
        difficulty: 'Hard',
        surfaceType: 'DIRT',
        bgTile: 'Tilesets/grass_dirt_mix.png',
        roadTile: 'Tilesets/dirt_1.png',
        trackWidth: 170,
        worldWidth: 3400,
        worldHeight: 2800,
        laps: 3,
        description: 'Loose gravel and mud trails demanding extreme drift control, counter-steering, and throttle feathering.',
        startAngle: 0, // Facing East
        gridPositions: [
            { x: 800, y: 600, angle: 0 },
            { x: 720, y: 640, angle: 0 },
            { x: 640, y: 560, angle: 0 },
            { x: 560, y: 640, angle: 0 },
            { x: 480, y: 560, angle: 0 },
            { x: 400, y: 640, angle: 0 }
        ],
        waypoints: [
            { x: 800, y: 600, speed: 1.0 },
            { x: 1600, y: 600, speed: 1.0 },
            { x: 2200, y: 700, speed: 0.75 },
            { x: 2700, y: 1100, speed: 0.6 },
            { x: 2600, y: 1600, speed: 0.7 },
            { x: 2100, y: 1700, speed: 0.8 },
            { x: 1600, y: 1400, speed: 0.6 },
            { x: 1300, y: 1600, speed: 0.6 },
            { x: 1500, y: 2000, speed: 0.8 },
            { x: 2200, y: 2200, speed: 0.85 },
            { x: 2800, y: 2400, speed: 0.65 },
            { x: 2500, y: 2650, speed: 0.6 },
            { x: 1800, y: 2600, speed: 0.85 },
            { x: 1000, y: 2500, speed: 0.75 },
            { x: 600, y: 2100, speed: 0.65 },
            { x: 700, y: 1600, speed: 0.8 },
            { x: 1000, y: 1200, speed: 0.65 },
            { x: 800, y: 900, speed: 0.7 },
            { x: 800, y: 600, speed: 1.0 }
        ]
    },

    desert_oasis: {
        id: 'desert_oasis',
        name: 'Oasis Dunes Speedway',
        subtitle: 'Desert Sands & Oasis Road',
        theme: 'sand',
        difficulty: 'Easy',
        surfaceType: 'SAND',
        bgTile: 'Tilesets/sand.png',
        roadTile: 'Tilesets/race_track_2.png',
        trackWidth: 180,
        worldWidth: 3600,
        worldHeight: 3000,
        laps: 3,
        description: 'Flowing high-speed desert track combining smooth asphalt road with sandy runoffs and wide sweeping bends.',
        startAngle: Math.PI / 2, // Facing South
        gridPositions: [
            { x: 600, y: 1000, angle: Math.PI / 2 },
            { x: 660, y: 920, angle: Math.PI / 2 },
            { x: 540, y: 840, angle: Math.PI / 2 },
            { x: 660, y: 760, angle: Math.PI / 2 },
            { x: 540, y: 680, angle: Math.PI / 2 },
            { x: 660, y: 600, angle: Math.PI / 2 }
        ],
        waypoints: [
            { x: 600, y: 1000, speed: 1.0 },
            { x: 600, y: 1900, speed: 1.0 },
            { x: 800, y: 2400, speed: 0.75 },
            { x: 1300, y: 2700, speed: 0.8 },
            { x: 2000, y: 2600, speed: 0.9 },
            { x: 2600, y: 2300, speed: 0.75 },
            { x: 3000, y: 1800, speed: 0.8 },
            { x: 3100, y: 1100, speed: 0.85 },
            { x: 2800, y: 600, speed: 0.7 },
            { x: 2200, y: 500, speed: 0.85 },
            { x: 1600, y: 700, speed: 0.75 },
            { x: 1300, y: 1200, speed: 0.65 },
            { x: 1600, y: 1600, speed: 0.8 },
            { x: 2100, y: 1600, speed: 0.85 },
            { x: 2300, y: 1200, speed: 0.65 },
            { x: 2000, y: 950, speed: 0.75 },
            { x: 1200, y: 850, speed: 0.75 },
            { x: 600, y: 1000, speed: 1.0 }
        ]
    },

    neon_city: {
        id: 'neon_city',
        name: 'Neon City Midnight GP',
        subtitle: 'Urban Night Street Course',
        theme: 'neon',
        difficulty: 'Expert',
        surfaceType: 'ASPHALT',
        bgTile: 'Tilesets/race_track_3.png',
        roadTile: 'Tilesets/race_track_3.png',
        trackWidth: 150,
        worldWidth: 3200,
        worldHeight: 2800,
        laps: 3,
        description: 'Tight urban night track surrounded by illuminated barriers, 90-degree street corners, and high-speed tunnel straights.',
        startAngle: -Math.PI / 2, // Facing North
        gridPositions: [
            { x: 1600, y: 2100, angle: -Math.PI / 2 },
            { x: 1650, y: 2180, angle: -Math.PI / 2 },
            { x: 1550, y: 2260, angle: -Math.PI / 2 },
            { x: 1650, y: 2340, angle: -Math.PI / 2 },
            { x: 1550, y: 2420, angle: -Math.PI / 2 },
            { x: 1650, y: 2500, angle: -Math.PI / 2 }
        ],
        waypoints: [
            { x: 1600, y: 2100, speed: 1.0 },
            { x: 1600, y: 1200, speed: 1.0 },
            { x: 1600, y: 600, speed: 0.65 },
            { x: 2200, y: 600, speed: 0.8 },
            { x: 2700, y: 600, speed: 0.65 },
            { x: 2700, y: 1200, speed: 0.85 },
            { x: 2200, y: 1200, speed: 0.65 },
            { x: 2200, y: 1700, speed: 0.8 },
            { x: 2700, y: 1700, speed: 0.65 },
            { x: 2700, y: 2400, speed: 0.7 },
            { x: 1900, y: 2400, speed: 0.85 },
            { x: 1200, y: 2400, speed: 0.7 },
            { x: 600, y: 2400, speed: 0.65 },
            { x: 600, y: 1700, speed: 0.85 },
            { x: 1100, y: 1700, speed: 0.65 },
            { x: 1100, y: 1000, speed: 0.85 },
            { x: 600, y: 1000, speed: 0.65 },
            { x: 600, y: 500, speed: 0.7 },
            { x: 1100, y: 500, speed: 0.85 },
            { x: 1600, y: 1200, speed: 0.9 },
            { x: 1600, y: 2100, speed: 1.0 }
        ]
    }
};
