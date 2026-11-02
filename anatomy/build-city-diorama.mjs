import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ============================================================================
// GREEN CORRIDOR — ARCHITECTURAL 3D EMERGENCY CITY DIORAMA
// Highly Detailed Isometric World featuring:
// - Multi-Storey Landmark Hospital with facade louvers, ER ambulance bay & helipad
// - Tiered urban buildings with window grids, cornices & rooftop machinery
// - Raised 3D sidewalks, curbs, asphalt avenues, crosswalks & lane markings
// - High-fidelity emergency ambulance vehicles with wheels, strobes & chevrons
// - Glowing orange illuminated corridor ribbon (#FF6D29) with transit pulses
// - Signal preemption gantries with green priority lights
// - 3D Projected Floating HUD markers for Incident, Ambulance, Hospital, Signal
// ============================================================================

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Green Corridor — 3D Emergency City Diorama</title>
  <link rel="stylesheet" href="fonts/NeueMontreal.css">
  <style>
    @font-face {
      font-family: 'Neue Montreal';
      src: url('fonts/NeueMontreal-Regular.woff2') format('woff2'),
           url('fonts/NeueMontreal-Regular.ttf') format('truetype');
      font-weight: 400;
    }
    @font-face {
      font-family: 'Neue Montreal';
      src: url('fonts/NeueMontreal-Medium.woff2') format('woff2'),
           url('fonts/NeueMontreal-Medium.ttf') format('truetype');
      font-weight: 500;
    }
    @font-face {
      font-family: 'Neue Montreal';
      src: url('fonts/NeueMontreal-Bold.woff2') format('woff2'),
           url('fonts/NeueMontreal-Bold.ttf') format('truetype');
      font-weight: 700;
    }

    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      width: 100%;
      height: 100%;
      background: transparent;
      overflow: hidden;
      font-family: 'Neue Montreal', -apple-system, BlinkMacSystemFont, sans-serif;
    }

    #diorama-container {
      width: 100%;
      height: 100%;
      position: relative;
      overflow: hidden;
      cursor: grab;
      user-select: none;
    }
    #diorama-container:active {
      cursor: grabbing;
    }

    canvas {
      width: 100% !important;
      height: 100% !important;
      display: block;
      outline: none;
    }

    /* Floating 3D HUD Precision Markers */
    .hud-marker {
      position: absolute;
      transform: translate(-50%, -100%);
      pointer-events: none;
      transition: opacity 0.25s ease;
      z-index: 10;
      white-space: nowrap;
    }

    .hud-card {
      display: flex;
      align-items: center;
      gap: 7px;
      padding: 5px 11px;
      border-radius: 8px;
      font-family: 'Neue Montreal', sans-serif;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.4px;
      background: rgba(255, 255, 255, 0.95);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border: 1px solid rgba(22, 19, 22, 0.10);
      box-shadow: 0 4px 16px rgba(69, 48, 39, 0.12), 0 1px 3px rgba(22, 19, 22, 0.05);
      color: #161316;
    }

    .hud-card.orange-theme {
      background: #FFFFFF;
      border: 1.2px solid #FF6D29;
      box-shadow: 0 4px 20px rgba(255, 109, 41, 0.25), 0 2px 6px rgba(69, 48, 39, 0.08);
    }

    .hud-card .hud-pulse-dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: #FF6D29;
      box-shadow: 0 0 8px #FF6D29;
      animation: pulse 1.8s infinite ease-in-out;
      flex-shrink: 0;
    }

    .hud-card .hud-green-dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: #10B981;
      box-shadow: 0 0 8px #10B981;
      animation: pulse 2.2s infinite ease-in-out;
      flex-shrink: 0;
    }

    .hud-pointer {
      width: 1px;
      height: 14px;
      background: #FF6D29;
      margin: 0 auto;
      box-shadow: 0 0 4px rgba(255, 109, 41, 0.6);
    }
    .hud-pointer.dark {
      background: #453027;
      box-shadow: none;
    }

    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.4; transform: scale(0.85); }
    }

    .tactile-badge {
      position: absolute;
      bottom: 12px;
      right: 14px;
      display: flex;
      align-items: center;
      gap: 6px;
      padding: 5px 10px;
      border-radius: 6px;
      background: rgba(255, 255, 255, 0.92);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(22, 19, 22, 0.08);
      font-size: 10px;
      font-weight: 600;
      color: #453027;
      letter-spacing: 0.6px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
      pointer-events: none;
    }
  </style>
  <script src="three.min.js"></script>
  <script>
    if (typeof THREE === 'undefined') {
      document.write('<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"><\\/script>');
    }
  </script>
</head>
<body>
  <div id="diorama-container">
    <!-- Floating 3D Projected Labels -->
    <div id="marker-incident" class="hud-marker">
      <div class="hud-card">
        <span class="hud-pulse-dot"></span>
        <span>INCIDENT SITE // SEC 4</span>
      </div>
      <div class="hud-pointer dark"></div>
    </div>

    <div id="marker-ambulance" class="hud-marker">
      <div class="hud-card orange-theme">
        <span class="hud-pulse-dot"></span>
        <span style="color:#FF6D29;">AMBULANCE 04 // EN ROUTE</span>
      </div>
      <div class="hud-pointer"></div>
    </div>

    <div id="marker-hospital" class="hud-marker">
      <div class="hud-card">
        <span style="color:#FF6D29; font-weight:700;">+</span>
        <span>LEVEL-1 TRAUMA // ER DOCK</span>
      </div>
      <div class="hud-pointer"></div>
    </div>

    <div id="marker-signal" class="hud-marker">
      <div class="hud-card">
        <span class="hud-green-dot"></span>
        <span>SIGNAL PREEMPTION // LOCKED</span>
      </div>
      <div class="hud-pointer dark"></div>
    </div>

    <div class="tactile-badge">
      <span style="width:5px; height:5px; border-radius:50%; background:#FF6D29;"></span>
      <span>3D EMERGENCY DIORAMA // INTERACTIVE</span>
    </div>
  </div>

  <script>
    // ============================================================================
    // BRAND COLORS
    // ============================================================================
    const BRAND = {
      orange: 0xFF6D29,
      brown: 0x453027,
      nearBlack: 0x161316,
      grey: 0xBABABA,
      white: 0xFFFFFF,
      greyLight: 0xF5F5F7,
      greyMid: 0xDCDCE2,
      greyDark: 0x585862,
      asphalt: 0x1C1A1E,
      roadMarking: 0xFAFAFA,
      curbStone: 0xE2E0DC,
      hospitalGlass: 0x3E6B89,
      hospitalSpandrel: 0x2A3E4E,
      grass: 0xE8EEE8,
    };

    const container = document.getElementById('diorama-container');
    const scene = new THREE.Scene();

    // 3/4 Perspective Camera framing the miniature isometric world with heroic presence & larger scale
    const aspect = container.clientWidth / container.clientHeight;
    const camera = new THREE.PerspectiveCamera(28, aspect, 0.5, 600);
    camera.position.set(24, 20, 26);
    camera.lookAt(1.0, 2.2, -0.5);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2.0));
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.16;
    container.appendChild(renderer.domElement);

    // ============================================================================
    // LIGHTING (Studio Sun, Rim Highlight & Orange Corridor Bounce)
    // ============================================================================
    const ambLight = new THREE.AmbientLight(0xFFFFFF, 1.40);
    scene.add(ambLight);

    const sunLight = new THREE.DirectionalLight(0xFFFAF2, 2.2);
    sunLight.position.set(30, 44, 26);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 2048;
    sunLight.shadow.mapSize.height = 2048;
    sunLight.shadow.camera.near = 1;
    sunLight.shadow.camera.far = 130;
    const d = 26;
    sunLight.shadow.camera.left = -d;
    sunLight.shadow.camera.right = d;
    sunLight.shadow.camera.top = d;
    sunLight.shadow.camera.bottom = -d;
    sunLight.shadow.bias = -0.0003;
    scene.add(sunLight);

    const fillLight = new THREE.DirectionalLight(0xEFF4F8, 0.95);
    fillLight.position.set(-24, 18, -22);
    scene.add(fillLight);

    // Warm Orange Route Illumination Light
    const orangeRouteLight = new THREE.PointLight(0xFF6D29, 2.6, 32);
    orangeRouteLight.position.set(4, 5, 2);
    scene.add(orangeRouteLight);

    // Root Group for Entire City Diorama
    const cityWorld = new THREE.Group();
    scene.add(cityWorld);

    // ============================================================================
    // 1. ORGANIC BLENDED GROUND DISC (No Harsh Boundaries, Seamless Page Fade)
    // ============================================================================
    // High-resolution procedural ground texture with smooth radial alpha falloff
    const groundCanvas = document.createElement('canvas');
    groundCanvas.width = 1024;
    groundCanvas.height = 1024;
    const gCtx = groundCanvas.getContext('2d');
    const centerG = 512;
    const groundGrad = gCtx.createRadialGradient(centerG, centerG, 80, centerG, centerG, 500);
    groundGrad.addColorStop(0.0, 'rgba(255, 255, 255, 1.0)'); // Pure white foundation matching #FFFFFF hero canvas
    groundGrad.addColorStop(0.50, 'rgba(255, 255, 255, 0.96)');
    groundGrad.addColorStop(0.70, 'rgba(255, 255, 255, 0.68)');
    groundGrad.addColorStop(0.85, 'rgba(255, 255, 255, 0.28)');
    groundGrad.addColorStop(0.96, 'rgba(255, 255, 255, 0.05)');
    groundGrad.addColorStop(1.0, 'rgba(255, 255, 255, 0.0)'); // 100% transparent organic fade
    gCtx.fillStyle = groundGrad;
    gCtx.fillRect(0, 0, 1024, 1024);

    const groundTex = new THREE.CanvasTexture(groundCanvas);
    const groundGeo = new THREE.PlaneGeometry(54, 54, 32, 32);
    const groundMat = new THREE.MeshStandardMaterial({
      map: groundTex,
      transparent: true,
      roughness: 0.75,
      metalness: 0.02,
      depthWrite: false,
    });
    const groundMesh = new THREE.Mesh(groundGeo, groundMat);
    groundMesh.rotation.x = -Math.PI / 2;
    groundMesh.position.y = 0;
    groundMesh.receiveShadow = true;
    cityWorld.add(groundMesh);

    // Soft Ambient Occlusion Contact Shadow underneath the city core
    const shadowCanvas = document.createElement('canvas');
    shadowCanvas.width = 512;
    shadowCanvas.height = 512;
    const sCtx = shadowCanvas.getContext('2d');
    const sGrad = sCtx.createRadialGradient(256, 256, 40, 256, 256, 250);
    sGrad.addColorStop(0.0, 'rgba(22, 19, 22, 0.16)');
    sGrad.addColorStop(0.40, 'rgba(69, 48, 39, 0.08)');
    sGrad.addColorStop(0.75, 'rgba(22, 19, 22, 0.02)');
    sGrad.addColorStop(1.0, 'rgba(255, 255, 255, 0.0)');
    sCtx.fillStyle = sGrad;
    sCtx.fillRect(0, 0, 512, 512);

    const shadowTex = new THREE.CanvasTexture(shadowCanvas);
    const shadowGeo = new THREE.PlaneGeometry(50, 50);
    const shadowMat = new THREE.MeshBasicMaterial({
      map: shadowTex,
      transparent: true,
      depthWrite: false,
    });
    const shadowMesh = new THREE.Mesh(shadowGeo, shadowMat);
    shadowMesh.rotation.x = -Math.PI / 2;
    shadowMesh.position.y = -0.02;
    cityWorld.add(shadowMesh);

    const hw = 17;
    const hd = 15;

    // ============================================================================
    // 2. URBAN ROAD NETWORK (Asphalt, Raised Sidewalk Curbs, Crosswalks)
    // ============================================================================
    const roadMat = new THREE.MeshStandardMaterial({
      color: BRAND.asphalt,
      roughness: 0.70,
      metalness: 0.10,
    });
    const roadMarkingMat = new THREE.MeshBasicMaterial({ color: BRAND.roadMarking });
    const curbMat = new THREE.MeshStandardMaterial({
      color: BRAND.curbStone,
      roughness: 0.45,
    });

    // Main Avenue East-West (X: -17 to 17, Z: 2, width: 5.4)
    const roadEWGeo = new THREE.PlaneGeometry(34, 5.4);
    const roadEW = new THREE.Mesh(roadEWGeo, roadMat);
    roadEW.rotation.x = -Math.PI / 2;
    roadEW.position.set(0, 0.03, 2);
    roadEW.receiveShadow = true;
    cityWorld.add(roadEW);

    // North-South Avenue 1 (X: -4, Z: -15 to 15, width: 5.2)
    const roadNSGeo = new THREE.PlaneGeometry(5.2, 30);
    const roadNS = new THREE.Mesh(roadNSGeo, roadMat);
    roadNS.rotation.x = -Math.PI / 2;
    roadNS.position.set(-4, 0.03, 0);
    roadNS.receiveShadow = true;
    cityWorld.add(roadNS);

    // Hospital Access Avenue (X: 11.5, connecting to ER ambulance bay)
    const roadHospGeo = new THREE.PlaneGeometry(5.0, 18);
    const roadHosp = new THREE.Mesh(roadHospGeo, roadMat);
    roadHosp.rotation.x = -Math.PI / 2;
    roadHosp.position.set(11.5, 0.03, -4.5);
    roadHosp.receiveShadow = true;
    cityWorld.add(roadHosp);

    // Raised Sidewalk Curbs along road edges (Visible 3D Depth)
    function createCurb(x, z, w, d) {
      const curbGeo = new THREE.BoxGeometry(w, 0.18, d);
      const curb = new THREE.Mesh(curbGeo, curbMat);
      curb.position.set(x, 0.09, z);
      curb.receiveShadow = true;
      curb.castShadow = true;
      cityWorld.add(curb);
    }

    createCurb(0, -0.9, 33, 0.24); // North curb of EW avenue
    createCurb(0, 4.9, 33, 0.24);  // South curb of EW avenue

    // Crosswalk Striping at Intersections
    function createCrosswalk(x, z, horizontal = true) {
      const group = new THREE.Group();
      for (let i = -1.8; i <= 1.8; i += 0.75) {
        const stripeGeo = new THREE.PlaneGeometry(horizontal ? 0.35 : 1.3, horizontal ? 1.3 : 0.35);
        const stripe = new THREE.Mesh(stripeGeo, roadMarkingMat);
        stripe.rotation.x = -Math.PI / 2;
        stripe.position.set(horizontal ? i : 0, 0.045, horizontal ? 0 : i);
        group.add(stripe);
      }
      group.position.set(x, 0, z);
      cityWorld.add(group);
    }

    createCrosswalk(-4, 6.4, true);
    createCrosswalk(-4, -2.4, true);
    createCrosswalk(0.4, 2, false);
    createCrosswalk(11.5, 6.2, true);

    // Dashed Center Lane Dividers
    for (let x = -hw + 3; x <= hw - 3; x += 3.2) {
      if (Math.abs(x - (-4)) > 3.6 && Math.abs(x - 11.5) > 3.2) {
        const dashGeo = new THREE.PlaneGeometry(1.6, 0.22);
        const dash = new THREE.Mesh(dashGeo, roadMarkingMat);
        dash.rotation.x = -Math.PI / 2;
        dash.position.set(x, 0.045, 2);
        cityWorld.add(dash);
      }
    }

    // ============================================================================
    // 3. MULTI-STOREY LANDMARK HOSPITAL (High-Detail Medical Center)
    // ============================================================================
    const hospitalGroup = new THREE.Group();
    hospitalGroup.position.set(11.8, 0, -8.5);
    // Proportionally reduce hospital size by 28% (scale: 0.72) to balance with city & ambulance
    hospitalGroup.scale.set(0.72, 0.72, 0.72);
    cityWorld.add(hospitalGroup);

    // Architectural Hospital Materials
    const hospMainMat = new THREE.MeshStandardMaterial({
      color: 0xFFFFFF,
      roughness: 0.25,
      metalness: 0.12,
    });
    const hospPodiumMat = new THREE.MeshStandardMaterial({
      color: 0xEAE7E2,
      roughness: 0.40,
      metalness: 0.08,
    });
    const hospGlassMat = new THREE.MeshStandardMaterial({
      color: BRAND.hospitalGlass,
      roughness: 0.10,
      metalness: 0.85,
    });
    const orangeTrimMat = new THREE.MeshStandardMaterial({
      color: BRAND.orange,
      roughness: 0.22,
      metalness: 0.25,
    });
    const darkAccentMat = new THREE.MeshStandardMaterial({
      color: BRAND.nearBlack,
      roughness: 0.50,
      metalness: 0.40,
    });

    // 1. Hospital Main Tower (Tiered Architecture: 14.5 units high)
    const towerGeo = new THREE.BoxGeometry(8.6, 14.5, 8.0);
    const tower = new THREE.Mesh(towerGeo, hospMainMat);
    tower.position.y = 14.5 / 2;
    tower.castShadow = true;
    tower.receiveShadow = true;
    hospitalGroup.add(tower);

    // Recessed Glass Curtain Wall Facade (Facing Avenue)
    const glassCurtainGeo = new THREE.BoxGeometry(8.7, 11.5, 1.4);
    const glassCurtain = new THREE.Mesh(glassCurtainGeo, hospGlassMat);
    glassCurtain.position.set(0, 7.2, 3.5);
    hospitalGroup.add(glassCurtain);

    // Orange Architectural Facade Louvers / Floor Bands
    for (let fl = 2.4; fl <= 13.0; fl += 1.6) {
      const louverGeo = new THREE.BoxGeometry(8.8, 0.20, 1.5);
      const louver = new THREE.Mesh(louverGeo, orangeTrimMat);
      louver.position.set(0, fl, 3.5);
      hospitalGroup.add(louver);
    }

    // Vertical Aluminum Mullions on Glass Wall
    for (let mx = -3.6; mx <= 3.6; mx += 1.8) {
      const mullionGeo = new THREE.BoxGeometry(0.12, 11.5, 1.55);
      const mullion = new THREE.Mesh(mullionGeo, darkAccentMat);
      mullion.position.set(mx, 7.2, 3.5);
      hospitalGroup.add(mullion);
    }

    // 2. Lower Emergency Wing & Ambulance Bay (Extending to Road)
    const erWingGeo = new THREE.BoxGeometry(7.2, 4.4, 6.0);
    const erWing = new THREE.Mesh(erWingGeo, hospPodiumMat);
    erWing.position.set(-2.8, 2.2, 3.4);
    erWing.castShadow = true;
    erWing.receiveShadow = true;
    hospitalGroup.add(erWing);

    // Cantilevered Red / Orange ER Ambulance Dock Canopy
    const erCanopyGeo = new THREE.BoxGeometry(5.8, 0.5, 4.4);
    const erCanopy = new THREE.Mesh(erCanopyGeo, orangeTrimMat);
    erCanopy.position.set(-2.8, 3.8, 6.4);
    erCanopy.castShadow = true;
    hospitalGroup.add(erCanopy);

    // ER Entrance Bay Glass Automatic Doors
    const erDoorGeo = new THREE.BoxGeometry(3.6, 2.8, 0.2);
    const erDoor = new THREE.Mesh(erDoorGeo, hospGlassMat);
    erDoor.position.set(-2.8, 1.4, 6.3);
    hospitalGroup.add(erDoor);

    // Canopy Support Pillars
    [-5.2, -0.4].forEach(px => {
      const pillarGeo = new THREE.CylinderGeometry(0.16, 0.16, 3.8, 16);
      const pillar = new THREE.Mesh(pillarGeo, darkAccentMat);
      pillar.position.set(px, 1.9, 8.2);
      pillar.castShadow = true;
      hospitalGroup.add(pillar);
    });

    // 3. Rooftop Helipad Deck (Circle Platform with Bevel)
    const helipadDeckGeo = new THREE.CylinderGeometry(4.2, 4.4, 0.6, 32);
    const helipadDeckMat = new THREE.MeshStandardMaterial({
      color: 0x24242A,
      roughness: 0.65,
    });
    const helipadDeck = new THREE.Mesh(helipadDeckGeo, helipadDeckMat);
    helipadDeck.position.set(0, 14.8, 0);
    helipadDeck.castShadow = true;
    helipadDeck.receiveShadow = true;
    hospitalGroup.add(helipadDeck);

    // Helipad Yellow Perimeter Ring
    const heliRingGeo = new THREE.RingGeometry(3.2, 3.6, 32);
    const heliRingMat = new THREE.MeshBasicMaterial({ color: 0xFFD13B, side: THREE.DoubleSide });
    const heliRing = new THREE.Mesh(heliRingGeo, heliRingMat);
    heliRing.rotation.x = -Math.PI / 2;
    heliRing.position.set(0, 15.12, 0);
    hospitalGroup.add(heliRing);

    // Medical Cross Marking '+'
    const crossBarMat = new THREE.MeshBasicMaterial({ color: BRAND.orange });
    const crossBar1 = new THREE.Mesh(new THREE.PlaneGeometry(2.4, 0.75), crossBarMat);
    crossBar1.rotation.x = -Math.PI / 2;
    crossBar1.position.set(0, 15.15, 0);
    hospitalGroup.add(crossBar1);

    const crossBar2 = new THREE.Mesh(new THREE.PlaneGeometry(0.75, 2.4), crossBarMat);
    crossBar2.rotation.x = -Math.PI / 2;
    crossBar2.position.set(0, 15.15, 0);
    hospitalGroup.add(crossBar2);

    // Illuminated Rooftop Communications Tower & Strobe
    const mastGeo = new THREE.CylinderGeometry(0.12, 0.28, 5.2, 16);
    const mast = new THREE.Mesh(mastGeo, darkAccentMat);
    mast.position.set(3.4, 17.2, -2.8);
    hospitalGroup.add(mast);

    const beaconLight = new THREE.PointLight(0xFF6D29, 2.2, 12);
    beaconLight.position.set(3.4, 20.0, -2.8);
    hospitalGroup.add(beaconLight);

    const beaconOrb = new THREE.Mesh(
      new THREE.SphereGeometry(0.35, 16, 16),
      new THREE.MeshBasicMaterial({ color: 0xFF6D29 })
    );
    beaconOrb.position.copy(beaconLight.position);
    hospitalGroup.add(beaconOrb);

    // ============================================================================
    // 4. ARCHITECTURAL SURROUNDING BUILDINGS (Differentiated Silhouettes & Windows)
    // ============================================================================
    const buildingsGroup = new THREE.Group();
    cityWorld.add(buildingsGroup);

    // Helper to generate a detailed multi-tiered building with window grids and parapets
    function createDetailedBuilding({ x, z, w, d, height, baseColor, glassColor, tiers = 2 }) {
      const bldg = new THREE.Group();
      bldg.position.set(x, 0, z);

      const wallMat = new THREE.MeshStandardMaterial({
        color: baseColor,
        roughness: 0.38,
        metalness: 0.08,
      });
      const windowMat = new THREE.MeshStandardMaterial({
        color: glassColor,
        roughness: 0.15,
        metalness: 0.80,
      });
      const trimMat = new THREE.MeshStandardMaterial({
        color: BRAND.brown,
        roughness: 0.50,
      });

      // Tier 1 (Podium)
      const t1H = tiers > 1 ? height * 0.65 : height;
      const t1Geo = new THREE.BoxGeometry(w, t1H, d);
      const t1 = new THREE.Mesh(t1Geo, wallMat);
      t1.position.y = t1H / 2;
      t1.castShadow = true;
      t1.receiveShadow = true;
      bldg.add(t1);

      // Recessed Windows on Tier 1
      const winGeo = new THREE.BoxGeometry(w + 0.06, t1H * 0.70, d - 0.6);
      const win = new THREE.Mesh(winGeo, windowMat);
      win.position.y = t1H * 0.52;
      bldg.add(win);

      // Parapet Roof Cornice
      const parapetGeo = new THREE.BoxGeometry(w + 0.25, 0.25, d + 0.25);
      const parapet = new THREE.Mesh(parapetGeo, trimMat);
      parapet.position.y = t1H + 0.12;
      bldg.add(parapet);

      // Tier 2 (Setback Upper Tower)
      if (tiers > 1) {
        const t2H = height * 0.35;
        const t2W = w * 0.78;
        const t2D = d * 0.78;
        const t2Geo = new THREE.BoxGeometry(t2W, t2H, t2D);
        const t2 = new THREE.Mesh(t2Geo, wallMat);
        t2.position.set(0, t1H + t2H / 2, 0);
        t2.castShadow = true;
        t2.receiveShadow = true;
        bldg.add(t2);

        // Upper Windows
        const uWinGeo = new THREE.BoxGeometry(t2W + 0.05, t2H * 0.65, t2D - 0.4);
        const uWin = new THREE.Mesh(uWinGeo, windowMat);
        uWin.position.set(0, t1H + t2H * 0.50, 0);
        bldg.add(uWin);

        // Rooftop HVAC Unit
        const hvacGeo = new THREE.BoxGeometry(t2W * 0.45, 0.6, t2D * 0.45);
        const hvac = new THREE.Mesh(hvacGeo, new THREE.MeshStandardMaterial({ color: 0xCCCCCC, roughness: 0.6 }));
        hvac.position.set(0, t1H + t2H + 0.3, 0);
        bldg.add(hvac);
      }

      buildingsGroup.add(bldg);
    }

    // Varied urban architectural blocks around the road grid (proportional miniature scale)
    createDetailedBuilding({
      x: -11.8, z: -8.8, w: 5.6, d: 5.0, height: 7.2,
      baseColor: 0xF6F5F2, glassColor: 0x486B84, tiers: 2
    });
    createDetailedBuilding({
      x: -12.2, z: 8.8, w: 4.8, d: 4.4, height: 5.4,
      baseColor: 0xEDECE8, glassColor: 0x3E5A70, tiers: 1
    });
    createDetailedBuilding({
      x: 2.8, z: -10.2, w: 5.2, d: 4.8, height: 8.0,
      baseColor: 0xFDFDFC, glassColor: 0x5C849E, tiers: 2
    });
    createDetailedBuilding({
      x: 3.2, z: 9.6, w: 5.4, d: 4.8, height: 5.6,
      baseColor: 0xF0EFEA, glassColor: 0x486B84, tiers: 1
    });
    createDetailedBuilding({
      x: -12.4, z: -0.8, w: 4.8, d: 4.4, height: 6.2,
      baseColor: 0xF5F4F0, glassColor: 0x406078, tiers: 1
    });
    createDetailedBuilding({
      x: 12.4, z: 10.2, w: 4.8, d: 4.4, height: 5.0,
      baseColor: 0xFBFBFA, glassColor: 0x557A95, tiers: 1
    });

    // Stylized Architectural Trees for Scale
    function createTree(x, z) {
      const treeGroup = new THREE.Group();
      const trunkGeo = new THREE.CylinderGeometry(0.12, 0.16, 1.0, 8);
      const trunkMat = new THREE.MeshStandardMaterial({ color: BRAND.brown, roughness: 0.8 });
      const trunk = new THREE.Mesh(trunkGeo, trunkMat);
      trunk.position.y = 0.5;
      treeGroup.add(trunk);

      const foliageMat = new THREE.MeshStandardMaterial({ color: 0x6E8E72, roughness: 0.65 });
      const foliageGeo = new THREE.ConeGeometry(0.9, 2.0, 8);
      const foliage = new THREE.Mesh(foliageGeo, foliageMat);
      foliage.position.y = 1.8;
      foliage.castShadow = true;
      treeGroup.add(foliage);

      treeGroup.position.set(x, 0, z);
      cityWorld.add(treeGroup);
    }

    [
      [-7.5, 5.6], [-7.5, 8.2], [7.2, 5.6], [7.2, 8.2],
      [-7.5, -2.0], [7.2, -2.0], [7.5, -5.4], [7.5, -8.2]
    ].forEach(([tx, tz]) => createTree(tx, tz));

    // ============================================================================
    // 5. HIGH-FIDELITY EMERGENCY AMBULANCE VEHICLES
    // ============================================================================
    function createAmbulanceVehicle() {
      const ambGroup = new THREE.Group();

      const bodyMat = new THREE.MeshStandardMaterial({
        color: BRAND.white,
        roughness: 0.22,
        metalness: 0.20,
      });
      const orangeStripeMat = new THREE.MeshStandardMaterial({
        color: BRAND.orange,
        roughness: 0.18,
        metalness: 0.15,
        emissive: BRAND.orange,
        emissiveIntensity: 0.2,
      });
      const glassMat = new THREE.MeshStandardMaterial({
        color: 0x16222C,
        roughness: 0.08,
        metalness: 0.90,
      });
      const wheelMat = new THREE.MeshStandardMaterial({
        color: 0x141414,
        roughness: 0.85,
      });
      const hubMat = new THREE.MeshStandardMaterial({
        color: 0xCCCCCC,
        metalness: 0.8,
        roughness: 0.2,
      });

      // Main Medical Box Body
      const bodyBoxGeo = new THREE.BoxGeometry(1.7, 1.35, 3.4);
      const bodyBox = new THREE.Mesh(bodyBoxGeo, bodyMat);
      bodyBox.position.set(0, 1.05, -0.2);
      bodyBox.castShadow = true;
      ambGroup.add(bodyBox);

      // Cabin Front
      const cabGeo = new THREE.BoxGeometry(1.6, 1.0, 1.3);
      const cab = new THREE.Mesh(cabGeo, bodyMat);
      cab.position.set(0, 0.85, 1.5);
      cab.castShadow = true;
      ambGroup.add(cab);

      // Windshield (Slanted Front)
      const wsGeo = new THREE.BoxGeometry(1.5, 0.60, 0.7);
      const ws = new THREE.Mesh(wsGeo, glassMat);
      ws.position.set(0, 1.05, 1.6);
      ambGroup.add(ws);

      // Side Emergency Hi-Vis Orange Stripe
      const stripeGeo = new THREE.BoxGeometry(1.74, 0.32, 3.6);
      const stripe = new THREE.Mesh(stripeGeo, orangeStripeMat);
      stripe.position.set(0, 0.95, 0.2);
      ambGroup.add(stripe);

      // Dual Rooftop Emergency Strobe Lightbar
      const lightBarGeo = new THREE.BoxGeometry(1.2, 0.22, 0.45);
      const lightBar = new THREE.Mesh(lightBarGeo, orangeStripeMat);
      lightBar.position.set(0, 1.82, 0.6);
      ambGroup.add(lightBar);

      // 4 Realistic Wheels with Rims
      const wheelPositions = [
        [-0.92, 0.38, 1.2], [0.92, 0.38, 1.2],
        [-0.92, 0.38, -1.1], [0.92, 0.38, -1.1]
      ];
      wheelPositions.forEach(([wx, wy, wz]) => {
        const wheelGeo = new THREE.CylinderGeometry(0.38, 0.38, 0.28, 18);
        const wheel = new THREE.Mesh(wheelGeo, wheelMat);
        wheel.rotation.z = Math.PI / 2;
        wheel.position.set(wx, wy, wz);
        wheel.castShadow = true;
        ambGroup.add(wheel);

        const hubGeo = new THREE.CylinderGeometry(0.18, 0.18, 0.30, 12);
        const hub = new THREE.Mesh(hubGeo, hubMat);
        hub.rotation.z = Math.PI / 2;
        hub.position.set(wx, wy, wz);
        ambGroup.add(hub);
      });

      return ambGroup;
    }

    // Lead En-Route Ambulance on Active Emergency Corridor
    const leadAmbulance = createAmbulanceVehicle();
    leadAmbulance.position.set(2.4, 0.05, 2.0);
    leadAmbulance.rotation.y = -Math.PI / 2;
    cityWorld.add(leadAmbulance);

    // Strobe PointLight for lead ambulance
    const strobeLight = new THREE.PointLight(0xFF6D29, 2.8, 8);
    strobeLight.position.set(2.4, 2.2, 2.0);
    cityWorld.add(strobeLight);

    // Secondary stationary ambulance parked at hospital ER bay
    const erAmbulance = createAmbulanceVehicle();
    erAmbulance.position.set(9.0, 0.05, -3.2);
    erAmbulance.rotation.y = 0;
    cityWorld.add(erAmbulance);

    // ============================================================================
    // 6. ILLUMINATED ORANGE EMERGENCY CORRIDOR RIBBON (#FF6D29)
    // ============================================================================
    // Route from Incident Site -> Avenue -> Hospital Bay
    const routePoints = [
      new THREE.Vector3(-15, 0.10, 2),
      new THREE.Vector3(-6, 0.10, 2),
      new THREE.Vector3(2.4, 0.10, 2),
      new THREE.Vector3(10.6, 0.10, 2),
      new THREE.Vector3(11.5, 0.10, 1.0),
      new THREE.Vector3(11.5, 0.10, -3.8)
    ];

    const routeCurve = new THREE.CatmullRomCurve3(routePoints, false, 'catmullrom', 0.15);
    const routeTubularGeo = new THREE.TubeGeometry(routeCurve, 72, 0.30, 12, false);
    const routeMat = new THREE.MeshStandardMaterial({
      color: BRAND.orange,
      emissive: BRAND.orange,
      emissiveIntensity: 0.90,
      roughness: 0.20,
      metalness: 0.15,
    });
    const routeMesh = new THREE.Mesh(routeTubularGeo, routeMat);
    cityWorld.add(routeMesh);

    // Outer Glow Aura Ribbon
    const auraCurveGeo = new THREE.TubeGeometry(routeCurve, 72, 0.75, 8, false);
    const auraMat = new THREE.MeshBasicMaterial({
      color: BRAND.orange,
      transparent: true,
      opacity: 0.26,
    });
    const auraMesh = new THREE.Mesh(auraCurveGeo, auraMat);
    cityWorld.add(auraMesh);

    // Animated Transit Pulse Particles traversing the corridor
    const pulseCount = 16;
    const pulseSpheres = [];
    for (let i = 0; i < pulseCount; i++) {
      const pGeo = new THREE.SphereGeometry(0.26, 12, 12);
      const pMat = new THREE.MeshBasicMaterial({ color: 0xFFFFFF });
      const pMesh = new THREE.Mesh(pGeo, pMat);
      cityWorld.add(pMesh);
      pulseSpheres.push({ mesh: pMesh, offset: i / pulseCount });
    }

    // Traffic Signal Priority Gantry Nodes
    function createTrafficPreemptionNode(x, z) {
      const nodeGroup = new THREE.Group();
      const mastGeo = new THREE.CylinderGeometry(0.08, 0.08, 3.0, 12);
      const mastMat = new THREE.MeshStandardMaterial({ color: BRAND.nearBlack, metalness: 0.6 });
      const mast = new THREE.Mesh(mastGeo, mastMat);
      mast.position.y = 1.5;
      nodeGroup.add(mast);

      const headGeo = new THREE.BoxGeometry(0.38, 0.95, 0.38);
      const head = new THREE.Mesh(headGeo, mastMat);
      head.position.y = 2.5;
      nodeGroup.add(head);

      // Green Priority Light
      const greenLight = new THREE.Mesh(
        new THREE.SphereGeometry(0.14, 12, 12),
        new THREE.MeshBasicMaterial({ color: 0x10B981 })
      );
      greenLight.position.set(0, 2.3, 0.22);
      nodeGroup.add(greenLight);

      nodeGroup.position.set(x, 0, z);
      cityWorld.add(nodeGroup);
    }

    createTrafficPreemptionNode(-5.2, 4.0);
    createTrafficPreemptionNode(10.0, 4.0);

    // ============================================================================
    // 7. 3D PROJECTED HUD MARKERS
    // ============================================================================
    const markers = [
      { id: 'marker-incident', pos: new THREE.Vector3(-15, 2.2, 2) },
      { id: 'marker-ambulance', pos: new THREE.Vector3(2.4, 2.9, 2) },
      { id: 'marker-hospital', pos: new THREE.Vector3(11.8, 13.2, -8.5) },
      { id: 'marker-signal', pos: new THREE.Vector3(-5.2, 3.6, 4.0) },
    ];

    function updateHudMarkers() {
      const widthHalf = container.clientWidth / 2;
      const heightHalf = container.clientHeight / 2;
      const tempV = new THREE.Vector3();

      markers.forEach(m => {
        const el = document.getElementById(m.id);
        if (!el) return;

        tempV.copy(m.pos);
        tempV.applyMatrix4(cityWorld.matrixWorld);
        tempV.project(camera);

        if (tempV.z > 1.0) {
          el.style.opacity = '0';
          return;
        }

        const x = (tempV.x * widthHalf) + widthHalf;
        const y = -(tempV.y * heightHalf) + heightHalf;

        el.style.left = \`\${x}px\`;
        el.style.top = \`\${y}px\`;
        el.style.opacity = '1';
      });
    }

    // ============================================================================
    // 8. INTERACTIVE DAMPED ROTATION & SCROLL DYNAMICS
    // ============================================================================
    let isDragging = false;
    let prevMouseX = 0;
    let prevMouseY = 0;

    let targetRotY = 0.0;
    let targetTiltX = 0.0;
    let currentRotY = 0.0;
    let currentTiltX = 0.0;
    let scrollProgress = 0.0;

    let mouseNormX = 0, mouseNormY = 0;
    window.addEventListener('pointermove', (e) => {
      const rect = container.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        mouseNormX = ((e.clientX - rect.left) / rect.width) * 2 - 1;
        mouseNormY = -(((e.clientY - rect.top) / rect.height) * 2 - 1);
      }
    });

    container.addEventListener('pointerdown', (e) => {
      isDragging = true;
      prevMouseX = e.clientX;
      prevMouseY = e.clientY;
    });

    window.addEventListener('pointerup', () => { isDragging = false; });
    window.addEventListener('pointercancel', () => { isDragging = false; });

    window.addEventListener('pointermove', (e) => {
      if (!isDragging) return;
      const dx = e.clientX - prevMouseX;
      const dy = e.clientY - prevMouseY;
      prevMouseX = e.clientX;
      prevMouseY = e.clientY;
      targetRotY += dx * 0.007;
      targetTiltX += dy * 0.005;
      targetTiltX = Math.max(-0.25, Math.min(0.25, targetTiltX));
    });

    // Receive Scroll Updates from Flutter Parent View
    window.addEventListener('message', (e) => {
      if (e.data && typeof e.data.scrollProgress === 'number') {
        scrollProgress = Math.max(0, Math.min(3.0, e.data.scrollProgress));
        targetRotY = scrollProgress * 0.65;
        targetTiltX = Math.sin(scrollProgress * Math.PI * 0.4) * 0.12;
      }
    });

    // Forward wheel scrolling over 3D canvas so parent page scrolls normally
    window.addEventListener('wheel', (e) => {
      try {
        if (window.parent && window.parent !== window) {
          window.parent.postMessage({
            type: 'GC_FORWARD_WHEEL',
            deltaY: e.deltaY,
            deltaX: e.deltaX,
          }, '*');
          window.parent.scrollBy({ top: e.deltaY, behavior: 'auto' });
        }
      } catch (_) {}
    }, { passive: true });

    window.addEventListener('scroll', () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight || 1;
      const progress = window.scrollY / maxScroll;
      targetRotY = progress * 0.85;
      targetTiltX = Math.sin(progress * Math.PI) * 0.15;
    });

    // ============================================================================
    // 9. ANIMATION LOOP
    // ============================================================================
    const clock = new THREE.Clock();

    function animate() {
      requestAnimationFrame(animate);
      const delta = clock.getDelta();
      const elapsed = clock.getElapsedTime();

      const targetCombinedRotY = targetRotY + (mouseNormX * 0.14);
      const targetCombinedTiltX = targetTiltX - (mouseNormY * 0.08);

      currentRotY += (targetCombinedRotY - currentRotY) * (delta * 5.0);
      currentTiltX += (targetCombinedTiltX - currentTiltX) * (delta * 5.0);

      const idleFloat = Math.sin(elapsed * 1.5) * 0.22;
      cityWorld.position.y = idleFloat;
      cityWorld.rotation.y = currentRotY;
      cityWorld.rotation.x = currentTiltX;

      // Animate Corridor Transit Pulse Spheres
      pulseSpheres.forEach(p => {
        let t = (elapsed * 0.35 + p.offset) % 1.0;
        const pt = routeCurve.getPointAt(t);
        p.mesh.position.set(pt.x, pt.y + 0.12, pt.z);
        const s = 0.20 + Math.sin(t * Math.PI) * 0.12;
        p.mesh.scale.set(s, s, s);
      });

      // Animate Ambulance Strobe
      const strobeActive = (Math.sin(elapsed * 16) > 0);
      strobeLight.intensity = strobeActive ? 3.6 : 0.4;

      // Slowly nudge lead ambulance along road
      const ambT = (elapsed * 0.04) % 0.4;
      leadAmbulance.position.x = 0.5 + ambT * 12;
      markers[1].pos.x = leadAmbulance.position.x;
      strobeLight.position.x = leadAmbulance.position.x;

      cityWorld.updateMatrixWorld();
      updateHudMarkers();

      renderer.render(scene, camera);
    }
    animate();

    function updateSize() {
      if (container.clientWidth > 0 && container.clientHeight > 0) {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
        updateHudMarkers();
      }
    }

    window.addEventListener('resize', updateSize);
    if (window.ResizeObserver) {
      new ResizeObserver(updateSize).observe(container);
    }
    setTimeout(updateSize, 120);
    setTimeout(updateSize, 500);
  </script>
</body>
</html>
`;

const cityHtmlPath = join(__dirname, "../web/city-diorama.html");
writeFileSync(cityHtmlPath, htmlContent, "utf-8");
console.log(`✓ Upgraded 3D City Diorama HTML generated: ${cityHtmlPath}`);
