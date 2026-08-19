// Complete Vehicle Catalog: 22 Cars + 4 Bikes with custom stats, grid dimensions, and color palettes
export const VEHICLES = {
    // === DRIFT & TUNER ===
    Hachiroku_Drifter: {
        id: 'Hachiroku_Drifter',
        name: 'Hachiroku AE86',
        category: 'Drift Legend',
        type: 'car',
        description: 'Lightweight rear-wheel drift icon. Incredible corner slip and balance.',
        folder: 'Cars/Hachiroku_Drifter',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 82, accel: 80, handling: 88, drift: 96, boost: 80, weight: 60 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Midnight_Godzilla: {
        id: 'Midnight_Godzilla',
        name: 'Midnight Godzilla R34',
        category: 'Tuner Legend',
        type: 'car',
        description: 'All-wheel drive turbocharged beast with razor sharp grip and brutal launch.',
        folder: 'Cars/Midnight_Godzilla',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 92, accel: 90, handling: 86, drift: 80, boost: 88, weight: 78 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Retro_Wedge_70s: {
        id: 'Retro_Wedge_70s',
        name: 'Retro Wedge Stratos',
        category: 'Rally Icon',
        type: 'car',
        description: 'Short wheelbase, high agility wedge built for nimble corner attacks.',
        folder: 'Cars/Retro_Wedge_70s',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 85, accel: 84, handling: 92, drift: 88, boost: 82, weight: 64 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },

    // === SUPERCARS & EXOTICS ===
    Italian_Supercar_87: {
        id: 'Italian_Supercar_87',
        name: 'Testarossa 87',
        category: 'Supercar',
        type: 'car',
        description: 'V12 Italian thoroughbred with wide stance and blisteringly high top speed.',
        folder: 'Cars/Italian_Supercar_87',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 95, accel: 88, handling: 82, drift: 78, boost: 90, weight: 72 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Stuttgart_91: {
        id: 'Stuttgart_91',
        name: 'Stuttgart 911 Turbo',
        category: 'Supercar',
        type: 'car',
        description: 'Rear-engine German engineering. Supreme traction and precision trail braking.',
        folder: 'Cars/Stuttgart_91',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 93, accel: 91, handling: 90, drift: 82, boost: 86, weight: 70 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Hyper_Electric_Future: {
        id: 'Hyper_Electric_Future',
        name: 'Hyper Electric EV',
        category: 'Hypercar',
        type: 'car',
        description: 'Instant torque quad-motor hypercar with unmatched launch acceleration.',
        folder: 'Cars/Hyper_Electric_Future',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 98, accel: 99, handling: 84, drift: 70, boost: 94, weight: 85 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },

    // === FORMULA & OPEN WHEEL ===
    Formula_Grand_Prix: {
        id: 'Formula_Grand_Prix',
        name: 'Formula GP Racer',
        category: 'Grand Prix',
        type: 'car',
        description: 'Ultra-lightweight open-wheel single seater with insane downforce and cornering.',
        folder: 'Cars/Formula_Grand_Prix',
        gridWidth: 32,
        gridHeight: 32,
        stats: { speed: 97, accel: 95, handling: 98, drift: 60, boost: 95, weight: 45 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'white', 'yellow']
    },
    Open_Wheel_Roadster: {
        id: 'Open_Wheel_Roadster',
        name: 'Vintage Roadster',
        category: 'Grand Prix',
        type: 'car',
        description: 'Classic open cockpit cigar racer. Pure mechanical feel and high top speed.',
        folder: 'Cars/Open_Wheel_Roadster',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 88, accel: 85, handling: 84, drift: 75, boost: 84, weight: 52 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },

    // === MUSCLE & CLASSICS ===
    Pony_Fastback_70s: {
        id: 'Pony_Fastback_70s',
        name: '70s Pony Fastback',
        category: 'Muscle',
        type: 'car',
        description: 'V8 American iron with roaring power and thunderous straight line speed.',
        folder: 'Cars/Pony_Fastback_70s',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 90, accel: 86, handling: 72, drift: 85, boost: 88, weight: 80 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    High_Wing_Muscle: {
        id: 'High_Wing_Muscle',
        name: 'Superbird Wing Muscle',
        category: 'Muscle',
        type: 'car',
        description: 'Aerodynamic NASCAR legend with tall wing for maximum high speed stability.',
        folder: 'Cars/High_Wing_Muscle',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 94, accel: 84, handling: 74, drift: 80, boost: 90, weight: 84 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Classic_Mako_Vette: {
        id: 'Classic_Mako_Vette',
        name: 'Mako Shark Vette',
        category: 'Muscle',
        type: 'car',
        description: 'Curvaceous fiberglass icon with tremendous low-end torque.',
        folder: 'Cars/Classic_Mako_Vette',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 89, accel: 85, handling: 76, drift: 82, boost: 85, weight: 75 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },

    // === RALLY & HOT HATCHES ===
    Group_B_Legend: {
        id: 'Group_B_Legend',
        name: 'Group B Turbo 4WD',
        category: 'Rally',
        type: 'car',
        description: 'Unfiltered 80s rally monster. Exceptional acceleration across mud, dirt, and gravel.',
        folder: 'Cars/Group_B_Legend',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 90, accel: 94, handling: 90, drift: 92, boost: 90, weight: 65 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Compact_Rally_Hatch: {
        id: 'Compact_Rally_Hatch',
        name: 'Delta Integrale Rally',
        category: 'Rally',
        type: 'car',
        description: 'Boxy rally king with superb four-wheel power distribution.',
        folder: 'Cars/Compact_Rally_Hatch',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 86, accel: 89, handling: 91, drift: 90, boost: 86, weight: 68 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Tiny_British_Hot_Hatch: {
        id: 'Tiny_British_Hot_Hatch',
        name: 'Classic British Mini',
        category: 'Hot Hatch',
        type: 'car',
        description: 'Go-kart handling and featherweight agility for tight chicanes.',
        folder: 'Cars/Tiny_British_Hot_Hatch',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 76, accel: 86, handling: 98, drift: 80, boost: 78, weight: 48 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Classic_Bug: {
        id: 'Classic_Bug',
        name: 'Classic Beetle Bug',
        category: 'Classic',
        type: 'car',
        description: 'Charming air-cooled cruiser with smooth, forgiving handling.',
        folder: 'Cars/Classic_Bug',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 74, accel: 72, handling: 80, drift: 75, boost: 75, weight: 58 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },

    // === HEAVY & UTILITY ===
    Modern_Monster_Pickup: {
        id: 'Modern_Monster_Pickup',
        name: 'Monster Trophy Truck',
        category: 'Off-Road',
        type: 'car',
        description: 'High-riding trophy truck that ignores rough terrain and shoves opponents aside.',
        folder: 'Cars/Modern_Monster_Pickup',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 84, accel: 82, handling: 70, drift: 82, boost: 85, weight: 95 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Heavy_Tactical_SUV: {
        id: 'Heavy_Tactical_SUV',
        name: 'Tactical Marauder SUV',
        category: 'Heavy',
        type: 'car',
        description: 'Armored all-terrain SUV with massive momentum in vehicle collisions.',
        folder: 'Cars/Heavy_Tactical_SUV',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 80, accel: 78, handling: 68, drift: 74, boost: 82, weight: 98 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Military_Luxury_4x4: {
        id: 'Military_Luxury_4x4',
        name: 'G-Wagon Military 4x4',
        category: 'Heavy',
        type: 'car',
        description: 'Twin-turbo luxury off-roader with solid grip on all surface types.',
        folder: 'Cars/Military_Luxury_4x4',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 83, accel: 81, handling: 72, drift: 76, boost: 84, weight: 92 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Polygon_Truck: {
        id: 'Polygon_Truck',
        name: 'Cyber Polygon Truck',
        category: 'Electric',
        type: 'car',
        description: 'Stainless steel angular futuristic truck with heavy instant boost torque.',
        folder: 'Cars/Polygon_Truck',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 88, accel: 92, handling: 73, drift: 78, boost: 90, weight: 96 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Grand_Royalty_Limo: {
        id: 'Grand_Royalty_Limo',
        name: 'Grand Royalty Limousine',
        category: 'Luxury',
        type: 'car',
        description: 'Extra-long wheelbase luxury limo. Smooth glide with massive presence.',
        folder: 'Cars/Grand_Royalty_Limo',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 81, accel: 74, handling: 65, drift: 80, boost: 80, weight: 94 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    Vintage_Fins_Limousine: {
        id: 'Vintage_Fins_Limousine',
        name: 'Vintage 50s Fin Cruiser',
        category: 'Classic',
        type: 'car',
        description: 'Classic chrome fins cruiser with wide turning radius and stylish drift sweeps.',
        folder: 'Cars/Vintage_Fins_Limousine',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 79, accel: 72, handling: 66, drift: 84, boost: 78, weight: 90 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },
    TukTuk_Utility_3W: {
        id: 'TukTuk_Utility_3W',
        name: 'Tuk-Tuk 3-Wheeler',
        category: 'Special',
        type: 'car',
        description: 'Ultra-agile 3-wheel city racer with extreme drift snap angles.',
        folder: 'Cars/TukTuk_Utility_3W',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 72, accel: 86, handling: 94, drift: 95, boost: 88, weight: 42 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'red', 'yellow']
    },

    // === BIKES ===
    Bologna_Superbike: {
        id: 'Bologna_Superbike',
        name: 'Bologna Superbike V4',
        category: 'Superbike',
        type: 'bike',
        description: '200hp superbike missile with explosive acceleration and lean angle agility.',
        folder: 'Bikes/Bologna_Superbike',
        gridWidth: 46,
        gridHeight: 54,
        stats: { speed: 96, accel: 98, handling: 95, drift: 65, boost: 96, weight: 35 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'white']
    },
    Classic_Italian_Scooter: {
        id: 'Classic_Italian_Scooter',
        name: 'Italian Retro Scooter',
        category: 'Scooter',
        type: 'bike',
        description: 'Vintage 2-stroke scooter. Maximum charm and nimble chicane slicing.',
        folder: 'Bikes/Classic_Italian_Scooter',
        gridWidth: 46,
        gridHeight: 55,
        stats: { speed: 70, accel: 78, handling: 96, drift: 75, boost: 80, weight: 32 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'white']
    },
    Dirt_Mud_Bike: {
        id: 'Dirt_Mud_Bike',
        name: 'Dirt Mud Motocross',
        category: 'Dirt Bike',
        type: 'bike',
        description: 'Knobby tire off-road dirt bike that dominates mud, sand, and grass cuts.',
        folder: 'Bikes/Dirt_Mud_Bike',
        gridWidth: 46,
        gridHeight: 55,
        stats: { speed: 82, accel: 92, handling: 92, drift: 94, boost: 88, weight: 36 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'white']
    },
    Iron_Chopper: {
        id: 'Iron_Chopper',
        name: 'Iron V-Twin Chopper',
        category: 'Cruiser',
        type: 'bike',
        description: 'Heavy V-twin cruiser with low rumble torque and wide highway presence.',
        folder: 'Bikes/Iron_Chopper',
        gridWidth: 46,
        gridHeight: 55,
        stats: { speed: 85, accel: 84, handling: 78, drift: 80, boost: 86, weight: 55 },
        colors: ['default', 'black', 'blue', 'green', 'pink', 'purple', 'white']
    }
};

export function getVehicleSpritePath(vehicleId, colorName = 'default') {
    const v = VEHICLES[vehicleId];
    if (!v) return null;
    const colorSuffix = (colorName && colorName !== 'default') ? `_${colorName}` : '';
    return `${v.folder}/${vehicleId}${colorSuffix}.png`;
}
