// Asynchronous Asset Loader with Progress Tracking & Image Cache

export class AssetLoader {
    constructor() {
        this.cache = new Map();
        this.totalCount = 0;
        this.loadedCount = 0;
        this.onProgress = null;
    }

    loadImage(path) {
        if (this.cache.has(path)) {
            return Promise.resolve(this.cache.get(path));
        }

        return new Promise((resolve, reject) => {
            const img = new Image();
            img.onload = () => {
                this.cache.set(path, img);
                this.loadedCount++;
                if (this.onProgress) {
                    this.onProgress(this.loadedCount / Math.max(1, this.totalCount));
                }
                resolve(img);
            };
            img.onerror = () => {
                console.warn(`[AssetLoader] Failed to load: ${path}`);
                this.loadedCount++;
                if (this.onProgress) {
                    this.onProgress(this.loadedCount / Math.max(1, this.totalCount));
                }
                // Return empty placeholder image to prevent hard crash
                const placeholder = new Image();
                this.cache.set(path, placeholder);
                resolve(placeholder);
            };
            img.src = path;
        });
    }

    getImage(path) {
        return this.cache.get(path) || null;
    }

    async preloadCatalog(vehicleList, trackList, onProgress) {
        this.onProgress = onProgress;
        const pathsToLoad = new Set();

        // 1. Vehicles
        for (const v of vehicleList) {
            for (const c of v.colors) {
                const colorSuffix = (c && c !== 'default') ? `_${c}` : '';
                pathsToLoad.add(`${v.folder}/${v.id}${colorSuffix}.png`);
            }
        }

        // 2. Tilesets
        for (const t of trackList) {
            if (t.bgTile) pathsToLoad.add(t.bgTile);
            if (t.roadTile) pathsToLoad.add(t.roadTile);
        }
        pathsToLoad.add('Tilesets/custom_race_track_tileset.png');
        pathsToLoad.add('Tilesets/race_track_1.png');
        pathsToLoad.add('Tilesets/race_track_2.png');
        pathsToLoad.add('Tilesets/race_track_3.png');
        pathsToLoad.add('Tilesets/dirt_1.png');
        pathsToLoad.add('Tilesets/sand.png');
        pathsToLoad.add('Tilesets/grass.png');

        // 3. Environment
        pathsToLoad.add('Enviroment/Grid Slots.png');
        pathsToLoad.add('Enviroment/barrier_red.png');
        pathsToLoad.add('Enviroment/barrier_yellow.png');
        pathsToLoad.add('Enviroment/barrier_white.png');
        pathsToLoad.add('Enviroment/barrier_black.png');
        pathsToLoad.add('Enviroment/tire.png');

        // 4. VFX
        pathsToLoad.add('VFX/Nitro/nitroVFX-Sheet.png');
        pathsToLoad.add('VFX/Smoke/Smoke-Sheet.png');

        this.totalCount = pathsToLoad.size;
        this.loadedCount = 0;

        const promises = Array.from(pathsToLoad).map(p => this.loadImage(p));
        await Promise.all(promises);
        return true;
    }
}
