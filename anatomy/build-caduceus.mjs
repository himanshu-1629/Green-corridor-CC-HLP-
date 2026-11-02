import { writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// Load installed Anatomy kit modules
import * as k from "/Users/himanshusingh/.agents/skills/anatomy/kit/iso-kit.mjs";
import * as G from "/Users/himanshusingh/.agents/skills/anatomy/kit/lathe.mjs";
import { kitScript } from "/Users/himanshusingh/.agents/skills/anatomy/scripts/inline-kit.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ============================================================================
// GREEN CORRIDOR — ANATOMY MEDICAL CADUCEUS EMBLEM
// Dimensions & Coordinate Space
// Camera: Azimuth 42°, Elevation 32°
// World units: mm / px aligned to real medical apparatus
// ============================================================================

const WIDTH = 680;
const HEIGHT = 720;
const AZIMUTH = 42;
const ELEVATION = 32;

// BRAND PALETTE (Neue Montreal System)
const BRAND = {
  orange: "#FF6D29",
  brown: "#453027",
  nearBlack: "#161316",
  grey: "#BABABA",
  white: "#FFFFFF",
  greyLight: "#E8E8E8",
  greyDark: "#7A7A7A",
  brownDark: "#2B1D17",
  orangeDark: "#D85518",
  orangeGlow: "rgba(255, 109, 41, 0.45)",
};

// World bounding points for isometric projection fitting
const BOUNDS = [
  [-110, -110, 0],
  [110, 110, 0],
  [-140, -40, 240], // Wing left tip
  [140, 40, 240],  // Wing right tip
  [0, 0, 310],     // Top finial
];

export const P = k.fitProjection(BOUNDS, WIDTH, HEIGHT, {
  pad: 28,
  azimuth: AZIMUTH,
  elevation: ELEVATION,
});

const at = (pt) => k.iso(pt, P);
const S = (paths, style) => k.solidSvg(paths, style);
const L = (d, style) => k.lineSvg(d, style);
const D = (pts, style) => k.dotsSvg(pts, style);

console.log("Anatomy projection established:", { width: WIDTH, height: HEIGHT });

// ============================================================================
// PARTS ASSEMBLY
// ============================================================================
const parts = {
  groundShadow: [],
  basePedestal: [],
  backSerpents: [],
  backWings: [],
  centralStaff: [],
  frontSerpents: [],
  frontWings: [],
  crowningOrb: [],
  statusDial: [],
};

// 1. Soft Ground Ambient Shadow (Anchoring on #FFFFFF canvas)
const shadowR = 90;
const shadowPath = k.haloOf({ x: -shadowR, y: -shadowR * 0.7, w: shadowR * 2, d: shadowR * 1.4, r: shadowR * 0.6 }, 0, 0, P);
parts.groundShadow.push(`
  <defs>
    <radialGradient id="gc-contact-shadow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="${BRAND.nearBlack}" stop-opacity="0.18"/>
      <stop offset="45%" stop-color="${BRAND.brown}" stop-opacity="0.08"/>
      <stop offset="100%" stop-color="${BRAND.white}" stop-opacity="0.0"/>
    </radialGradient>
    <filter id="soft-blur" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="8"/>
    </filter>
  </defs>
  <ellipse cx="${at([0, 0, 0])[0]}" cy="${at([0, 0, 0])[1]}" rx="120" ry="46" fill="url(#gc-contact-shadow)" filter="url(#soft-blur)"/>
`);

// 2. Base Mounting Pedestal (Grounded precision collar)
const BASE_COL = { x: -48, y: -48, w: 96, d: 96, r: 24 };
parts.basePedestal.push(S(k.slabOf(BASE_COL, 0, 6, P, 6, 1.2), { tone: "mid", fill: BRAND.greyLight, stroke: BRAND.greyDark }));
parts.basePedestal.push(S(k.cylinder(0, 0, 36, 6, 8, P, 32), { tone: "mid", fill: BRAND.white, stroke: BRAND.grey }));
parts.basePedestal.push(S(k.cylinder(0, 0, 24, 14, 6, P, 32), { tone: "lo", fill: BRAND.brown, stroke: BRAND.nearBlack }));

// Hex mounting screws on pedestal
for (const [x, y] of k.corners({ x: -36, y: -36, w: 72, d: 72, r: 8 }, 8)) {
  parts.basePedestal.push(S(k.cylinder(x, y, 3.2, 6, 1.8, P, 12), { tone: "hi", fill: BRAND.orange, stroke: BRAND.brown }));
  parts.basePedestal.push(D([at([x, y, 7.8])], { size: 0.6, fill: BRAND.white }));
}

// Circular ticks on pedestal rim
const rimTicks = k.radialTicks(0, 0, 35, 36, 6, 14, [1.5, 3.0], P);
if (rimTicks) {
  parts.basePedestal.push(L(rimTicks.minor, { stroke: BRAND.grey, width: 0.6 }));
  parts.basePedestal.push(L(rimTicks.major, { stroke: BRAND.orange, width: 1.0 }));
}

// 3. Central Staff (Asclepius / Caduceus Shaft)
const STAFF_R = 7.5;
const STAFF_Z0 = 20;
const STAFF_Z1 = 265;

// Lower Spindle
parts.centralStaff.push(S(k.cylinder(0, 0, 11, STAFF_Z0, 6, P, 32), { tone: "mid", fill: BRAND.brown, stroke: BRAND.nearBlack }));
// Main Staff Cylinder
parts.centralStaff.push(S(k.cylinder(0, 0, STAFF_R, STAFF_Z0 + 6, STAFF_Z1 - STAFF_Z0 - 6, P, 32), {
  tone: "hi",
  fill: BRAND.white,
  stroke: BRAND.greyDark,
}));

// Longitudinal grooves / fluting on the staff
for (let deg = 0; deg < 360; deg += 45) {
  const rad = (deg * Math.PI) / 180;
  const gx = (STAFF_R - 0.2) * Math.cos(rad);
  const gy = (STAFF_R - 0.2) * Math.sin(rad);
  const p0 = at([gx, gy, STAFF_Z0 + 8]);
  const p1 = at([gx, gy, STAFF_Z1 - 8]);
  parts.centralStaff.push(`<line x1="${p0[0]}" y1="${p0[1]}" x2="${p1[0]}" y2="${p1[1]}" stroke="${BRAND.grey}" stroke-width="0.75" stroke-dasharray="8 4"/>`);
}

// Crossover Junction Collars along the staff
const collarHeights = [80, 140, 200, 250];
for (const cz of collarHeights) {
  parts.centralStaff.push(S(k.cylinder(0, 0, STAFF_R + 3.2, cz, 4.5, P, 28), {
    tone: "mid",
    fill: BRAND.brown,
    stroke: BRAND.orange,
  }));
  parts.centralStaff.push(S(k.cylinder(0, 0, STAFF_R + 1.2, cz + 4.5, 1.5, P, 28), {
    tone: "hi",
    fill: BRAND.orange,
    stroke: BRAND.brown,
  }));
}

// 4. Intertwined Serpents (Serpent Alpha & Serpent Beta)
// We compute smooth 3D helical spirals weaving in front and behind
const numSpirals = 3;
const zStart = 35;
const zEnd = 245;
const serpentRadius = 38;
const tubeRadius = 6.2;

const serpentSteps = 120;
const serpentA_Pts = [];
const serpentB_Pts = [];

for (let i = 0; i <= serpentSteps; i++) {
  const t = i / serpentSteps;
  const z = zStart + t * (zEnd - zStart);
  // Width swells in middle and tapers at tail and neck
  const r = serpentRadius * Math.sin(Math.PI * (0.08 + 0.84 * t));
  const angle = t * numSpirals * 2 * Math.PI - Math.PI / 2;

  // Serpent Alpha
  const ax = r * Math.cos(angle);
  const ay = r * Math.sin(angle);
  serpentA_Pts.push({ x: ax, y: ay, z, t });

  // Serpent Beta (180 deg out of phase)
  const bx = r * Math.cos(angle + Math.PI);
  const by = r * Math.sin(angle + Math.PI);
  serpentB_Pts.push({ x: bx, y: by, z, t });
}

// Function to draw segmented beveled serpent body with depth sorting
function renderSerpentSegments(pts, isSerpentA) {
  for (let i = 0; i < pts.length - 1; i++) {
    const p1 = pts[i];
    const p2 = pts[i + 1];
    const midZ = (p1.z + p2.z) / 2;
    const midY = (p1.y + p2.y) / 2;
    const midX = (p1.x + p2.x) / 2;

    // Depth test relative to central staff (staff is at x=0, y=0)
    // In our camera azimuth 42°, positive depth is in front of staff
    const depth = midX * Math.cos((AZIMUTH * Math.PI) / 180) + midY * Math.sin((AZIMUTH * Math.PI) / 180);
    const isFront = depth > -2;

    // Segment thickness taper
    const currR = tubeRadius * (0.6 + 0.5 * Math.sin(Math.PI * p1.t));

    // Project points to 2D
    const screen1 = at([p1.x, p1.y, p1.z]);
    const screen2 = at([p2.x, p2.y, p2.z]);

    // Direction vector in screen
    const dx = screen2[0] - screen1[0];
    const dy = screen2[1] - screen1[1];
    const len = Math.hypot(dx, dy) || 1;
    const nx = -dy / len;
    const ny = dx / len;

    const corner1 = [screen1[0] + nx * currR, screen1[1] + ny * currR];
    const corner2 = [screen2[0] + nx * currR, screen2[1] + ny * currR];
    const corner3 = [screen2[0] - nx * currR, screen2[1] - ny * currR];
    const corner4 = [screen1[0] - nx * currR, screen1[1] - ny * currR];

    const polyD = `M ${corner1[0].toFixed(2)} ${corner1[1].toFixed(2)} L ${corner2[0].toFixed(2)} ${corner2[1].toFixed(2)} L ${corner3[0].toFixed(2)} ${corner3[1].toFixed(2)} L ${corner4[0].toFixed(2)} ${corner4[1].toFixed(2)} Z`;

    const mainColor = isSerpentA ? (i % 8 < 4 ? BRAND.orange : BRAND.orangeDark) : (i % 8 < 4 ? BRAND.brown : BRAND.brownDark);
    const strokeColor = isSerpentA ? BRAND.brownDark : BRAND.nearBlack;

    // Ribbing line across serpent
    const ribMid1 = [(corner1[0] + corner4[0]) / 2, (corner1[1] + corner4[1]) / 2];
    const ribMid2 = [(corner2[0] + corner3[0]) / 2, (corner2[1] + corner3[1]) / 2];

    const segmentSvg = `
      <path d="${polyD}" fill="${mainColor}" stroke="${strokeColor}" stroke-width="1.0" stroke-linejoin="round"/>
      <line x1="${corner1[0].toFixed(2)}" y1="${corner1[1].toFixed(2)}" x2="${corner4[0].toFixed(2)}" y2="${corner4[1].toFixed(2)}" stroke="${BRAND.white}" stroke-width="0.6" stroke-opacity="0.7"/>
    `;

    if (isFront) {
      parts.frontSerpents.push(segmentSvg);
    } else {
      parts.backSerpents.push(segmentSvg);
    }
  }

  // Sculpted Serpent Head at the top
  const headPt = pts[pts.length - 1];
  const neckPt = pts[pts.length - 8];
  const headPos = at([headPt.x, headPt.y, headPt.z + 4]);
  const neckPos = at([neckPt.x, neckPt.y, neckPt.z]);

  const facingX = isSerpentA ? 1 : -1;
  const headSvg = `
    <!-- Serpent Head (${isSerpentA ? "Alpha" : "Beta"}) -->
    <g transform="translate(${headPos[0].toFixed(2)}, ${headPos[1].toFixed(2)})">
      <!-- Cranial Crown Bevel -->
      <path d="M 0 0 C ${facingX * 14} -12, ${facingX * 22} -4, ${facingX * 24} 6 C ${facingX * 20} 14, ${facingX * 8} 12, 0 6 Z"
            fill="${isSerpentA ? BRAND.orange : BRAND.brown}" stroke="${BRAND.nearBlack}" stroke-width="1.3"/>
      <!-- Snout / Tapered Jaw -->
      <path d="M ${facingX * 14} 2 L ${facingX * 28} 8 L ${facingX * 16} 11 Z"
            fill="${isSerpentA ? BRAND.orangeDark : BRAND.brownDark}" stroke="${BRAND.nearBlack}" stroke-width="0.9"/>
      <!-- Precision Orange Eye Lens -->
      <circle cx="${facingX * 12}" cy="1" r="2.8" fill="${BRAND.orange}" stroke="${BRAND.white}" stroke-width="0.8"/>
      <circle cx="${facingX * 12}" cy="1" r="1.1" fill="${BRAND.nearBlack}"/>
    </g>
  `;
  parts.frontSerpents.push(headSvg);
}

renderSerpentSegments(serpentA_Pts, true);
renderSerpentSegments(serpentB_Pts, false);

// 5. Symmetrical Feathered Wings (Upper Caduceus Arch)
// Left and Right wing roots originate at staff height z = 230
const WING_Z = 225;
const WING_SPAN = 135;

function buildWing(isLeft) {
  const sign = isLeft ? -1 : 1;
  const wingRoot = at([sign * 8, 0, WING_Z]);

  // Primary Feather Blades (Sweeping curve to apex)
  const feathers = [
    // Outer Primary Flight Feathers (Apex sweep)
    { tip: [sign * WING_SPAN, sign * 20, WING_Z + 75], mid: [sign * (WING_SPAN * 0.65), sign * 14, WING_Z + 58], w: 14, tone: "hi", fill: BRAND.white },
    { tip: [sign * (WING_SPAN * 0.92), sign * 16, WING_Z + 55], mid: [sign * (WING_SPAN * 0.60), sign * 12, WING_Z + 44], w: 13, tone: "mid", fill: BRAND.greyLight },
    { tip: [sign * (WING_SPAN * 0.82), sign * 12, WING_Z + 36], mid: [sign * (WING_SPAN * 0.52), sign * 10, WING_Z + 30], w: 12, tone: "mid", fill: BRAND.white },
    { tip: [sign * (WING_SPAN * 0.70), sign * 8, WING_Z + 18], mid: [sign * (WING_SPAN * 0.44), sign * 8, WING_Z + 16], w: 11, tone: "lo", fill: BRAND.greyLight },
    // Secondary Covert Feathers (Mid layer)
    { tip: [sign * (WING_SPAN * 0.58), sign * 6, WING_Z + 42], mid: [sign * (WING_SPAN * 0.38), sign * 6, WING_Z + 30], w: 12, tone: "hi", fill: BRAND.white },
    { tip: [sign * (WING_SPAN * 0.46), sign * 4, WING_Z + 28], mid: [sign * (WING_SPAN * 0.30), sign * 4, WING_Z + 20], w: 11, tone: "mid", fill: BRAND.greyLight },
    // Tertiary Covert Feathers (Base shoulder)
    { tip: [sign * (WING_SPAN * 0.32), sign * 2, WING_Z + 16], mid: [sign * (WING_SPAN * 0.20), sign * 2, WING_Z + 12], w: 10, tone: "lo", fill: BRAND.brown },
  ];

  const wingParts = [];

  // Main Wing Spar Bone (Shoulder arch)
  const sparStart = at([sign * 6, 0, WING_Z]);
  const sparMid = at([sign * (WING_SPAN * 0.5), sign * 12, WING_Z + 48]);
  const sparTip = at([sign * (WING_SPAN * 0.85), sign * 18, WING_Z + 68]);

  wingParts.push(`
    <!-- Wing Bone Spar -->
    <path d="M ${sparStart[0].toFixed(2)} ${sparStart[1].toFixed(2)} Q ${sparMid[0].toFixed(2)} ${sparMid[1].toFixed(2)} ${sparTip[0].toFixed(2)} ${sparTip[1].toFixed(2)}"
          fill="none" stroke="${BRAND.nearBlack}" stroke-width="4.5" stroke-linecap="round"/>
    <path d="M ${sparStart[0].toFixed(2)} ${sparStart[1].toFixed(2)} Q ${sparMid[0].toFixed(2)} ${sparMid[1].toFixed(2)} ${sparTip[0].toFixed(2)} ${sparTip[1].toFixed(2)}"
          fill="none" stroke="${BRAND.orange}" stroke-width="1.8" stroke-linecap="round"/>
  `);

  // Render individual feathers back to front
  for (const f of feathers) {
    const tipPt = at(f.tip);
    const midPt = at(f.mid);
    const basePt = at([sign * 12, 0, WING_Z + 2]);

    const nx = -sign * 6;
    const ny = 6;

    const fD = `M ${basePt[0].toFixed(2)} ${basePt[1].toFixed(2)} Q ${midPt[0].toFixed(2) + nx} ${midPt[1].toFixed(2) + ny} ${tipPt[0].toFixed(2)} ${tipPt[1].toFixed(2)} Q ${midPt[0].toFixed(2) - nx} ${midPt[1].toFixed(2) - ny} ${basePt[0].toFixed(2)} ${basePt[1].toFixed(2)} Z`;

    wingParts.push(`
      <path d="${fD}" fill="${f.fill}" stroke="${BRAND.nearBlack}" stroke-width="1.1" stroke-linejoin="round"/>
      <!-- Feather Central Quill Shaft -->
      <path d="M ${basePt[0].toFixed(2)} ${basePt[1].toFixed(2)} Q ${midPt[0].toFixed(2)} ${midPt[1].toFixed(2)} ${tipPt[0].toFixed(2)} ${tipPt[1].toFixed(2)}"
            fill="none" stroke="${BRAND.greyDark}" stroke-width="0.8"/>
    `);
  }

  return wingParts.join("\n");
}

parts.frontWings.push(buildWing(true));  // Left wing
parts.frontWings.push(buildWing(false)); // Right wing

// 6. Crowning Spherical Orb & Finial Beacon
const ORB_Z = STAFF_Z1 + 14;
const ORB_R = 17;
const orbCenter = at([0, 0, ORB_Z]);

parts.crowningOrb.push(`
  <!-- Crowning Finial Orb of Hermes -->
  <defs>
    <radialGradient id="gc-orb-grad" cx="35%" cy="30%" r="65%">
      <stop offset="0%" stop-color="${BRAND.white}"/>
      <stop offset="30%" stop-color="${BRAND.orange}"/>
      <stop offset="75%" stop-color="${BRAND.brown}"/>
      <stop offset="100%" stop-color="${BRAND.nearBlack}"/>
    </radialGradient>
  </defs>
  <!-- Main Sphere -->
  <circle cx="${orbCenter[0].toFixed(2)}" cy="${orbCenter[1].toFixed(2)}" r="${ORB_R}" fill="url(#gc-orb-grad)" stroke="${BRAND.nearBlack}" stroke-width="1.4"/>
  <!-- Specular Rim Ring -->
  <ellipse cx="${orbCenter[0].toFixed(2)}" cy="${orbCenter[1].toFixed(2)}" rx="${ORB_R + 3.5}" ry="${ORB_R * 0.45}" fill="none" stroke="${BRAND.orange}" stroke-width="1.2" stroke-dasharray="4 2"/>
  <!-- Pinnacle Apex Tip -->
  <polygon points="${orbCenter[0]},${orbCenter[1] - ORB_R - 10} ${orbCenter[0] - 3.5},${orbCenter[1] - ORB_R + 1} ${orbCenter[0] + 3.5},${orbCenter[1] - ORB_R + 1}"
           fill="${BRAND.orange}" stroke="${BRAND.nearBlack}" stroke-width="0.9"/>
`);

// 7. Status Dial & Precision Plate Markings (Anatomy craft plate)
const plateX = WIDTH / 2 - 120;
const plateY = HEIGHT - 45;
parts.statusDial.push(`
  <g transform="translate(${plateX}, ${plateY})">
    <rect x="0" y="0" width="240" height="30" rx="6" fill="${BRAND.white}" stroke="${BRAND.grey}" stroke-width="1.2"/>
    <rect x="3" y="3" width="234" height="24" rx="4" fill="${BRAND.greyLight}" stroke="${BRAND.grey}" stroke-width="0.8"/>
    <!-- Corner Rivets -->
    <circle cx="8" cy="8" r="1.5" fill="${BRAND.brown}"/>
    <circle cx="232" cy="8" r="1.5" fill="${BRAND.brown}"/>
    <circle cx="8" cy="22" r="1.5" fill="${BRAND.brown}"/>
    <circle cx="232" cy="22" r="1.5" fill="${BRAND.brown}"/>
    <!-- Engraved Metadata -->
    <text x="18" y="19" font-family="'Neue Montreal', 'NeueMontreal', sans-serif" font-size="10.5" font-weight="700" fill="${BRAND.nearBlack}" letter-spacing="1.2">
      GC-CADUCEUS // ANATOMY-3D // LIVE
    </text>
    <circle cx="218" cy="15" r="3.5" fill="${BRAND.orange}"/>
  </g>
`);

// Assemble SVG in strict Painter's Depth Order:
// 1. Ground Shadow -> 2. Base Pedestal -> 3. Back Serpents -> 4. Central Staff -> 5. Front Serpents -> 6. Wings -> 7. Crowning Orb -> 8. Status Dial
const assembledSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${WIDTH} ${HEIGHT}" width="${WIDTH}" height="${HEIGHT}" class="anatomy-caduceus">
  <style>
    .anatomy-caduceus {
      background: transparent;
      overflow: visible;
    }
  </style>

  <!-- 1. Ground Contact Shadow -->
  <g id="gc-layer-shadow">
    ${parts.groundShadow.join("\n")}
  </g>

  <!-- 2. Base Pedestal -->
  <g id="gc-layer-base">
    ${parts.basePedestal.join("\n")}
  </g>

  <!-- 3. Rear Serpent Loops (Behind Staff) -->
  <g id="gc-layer-serpents-rear">
    ${parts.backSerpents.join("\n")}
  </g>

  <!-- 4. Central Staff Assembly -->
  <g id="gc-layer-staff">
    ${parts.centralStaff.join("\n")}
  </g>

  <!-- 5. Front Serpent Loops (In Front of Staff) -->
  <g id="gc-layer-serpents-front">
    ${parts.frontSerpents.join("\n")}
  </g>

  <!-- 6. Feathered Wings Assembly -->
  <g id="gc-layer-wings">
    ${parts.frontWings.join("\n")}
  </g>

  <!-- 7. Crowning Finial Orb -->
  <g id="gc-layer-finial">
    ${parts.crowningOrb.join("\n")}
  </g>

  <!-- 8. Calibration Status Plate -->
  <g id="gc-layer-plate">
    ${parts.statusDial.join("\n")}
  </g>
</svg>
`;

// Save generated SVG figure
const svgPath = join(__dirname, "../web/caduceus-anatomy.svg");
writeFileSync(svgPath, assembledSvg, "utf-8");
console.log(`✓ Standalone Anatomy Caduceus SVG generated: ${svgPath}`);

// ============================================================================
// GENERATE INTERACTIVE ANATOMY 3D TURNING WEBPAGE
// Includes scroll-linked rotation, deterministic angle mapping, Three.js PBR
// with brand materials, contact shadow, and smooth reversal.
// ============================================================================

const htmlContent = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Green Corridor — Anatomy 3D Caduceus Emblem</title>
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
      pointer-events: none !important;
      opacity: 0;
      transition: opacity 0.15s ease-out;
      font-family: 'Neue Montreal', -apple-system, sans-serif;
    }

    #canvas-container {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      position: relative;
    }

    canvas {
      width: 100% !important;
      height: 100% !important;
      display: block;
      outline: none;
    }

    /* Precision Anatomy HUD Overlay */
    .hud-badge {
      display: none !important;
      position: absolute;
      bottom: 12px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      align-items: center;
      gap: 8px;
      background: rgba(255, 255, 255, 0.94);
      border: 1.2px solid ${BRAND.grey};
      border-radius: 30px;
      padding: 5px 14px;
      box-shadow: 0 4px 14px rgba(22, 19, 22, 0.08);
      font-size: 11px;
      font-weight: 700;
      color: ${BRAND.nearBlack};
      letter-spacing: 0.8px;
      pointer-events: none;
      backdrop-filter: blur(8px);
    }
    .hud-dot {
      width: 7px;
      height: 7px;
      border-radius: 50%;
      background: ${BRAND.orange};
      box-shadow: 0 0 8px ${BRAND.orange};
      animation: pulse 2s infinite ease-in-out;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(0.85); }
    }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
</head>
<body>
  <div id="canvas-container">
    <div class="hud-badge">
      <span class="hud-dot"></span>
      <span>ANATOMY 3D CADUCEUS // NEUE MONTREAL</span>
    </div>
  </div>

  <script>
    const BRAND = {
      orange: 0xFF6D29,
      brown: 0x453027,
      nearBlack: 0x161316,
      grey: 0xBABABA,
      white: 0xFFFFFF,
      greyLight: 0xE8E8E8,
      greyDark: 0x7A7A7A,
    };

    const container = document.getElementById('canvas-container');
    const scene = new THREE.Scene();

    // Perspective camera framing the full majestic wingspan, staff, and finial orb with generous padding (no clipping)
    const camera = new THREE.PerspectiveCamera(40, container.clientWidth / container.clientHeight, 0.1, 1000);
    camera.position.set(0, 1.8, 56);
    camera.lookAt(0, 1.8, 0);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: 'high-performance' });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2.0));
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setClearColor(0x000000, 0);
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.15;
    container.appendChild(renderer.domElement);

    // Studio Lighting for Pure White Canvas
    const ambLight = new THREE.AmbientLight(0xFFFFFF, 1.45);
    scene.add(ambLight);

    const keyLight = new THREE.DirectionalLight(0xFFFFFF, 2.2);
    keyLight.position.set(18, 26, 22);
    scene.add(keyLight);

    // Warm orange rim light
    const orangeRimLight = new THREE.DirectionalLight(BRAND.orange, 1.8);
    orangeRimLight.position.set(-20, -8, -14);
    scene.add(orangeRimLight);

    // Bottom bounce light
    const fillLight = new THREE.DirectionalLight(BRAND.grey, 0.85);
    fillLight.position.set(0, -22, 12);
    scene.add(fillLight);

    // Contact ambient shadow plane on white
    const shadowCanvas = document.createElement('canvas');
    shadowCanvas.width = 512; shadowCanvas.height = 512;
    const sCtx = shadowCanvas.getContext('2d');
    const sGrad = sCtx.createRadialGradient(256, 256, 0, 256, 256, 256);
    sGrad.addColorStop(0, 'rgba(22, 19, 22, 0.18)');
    sGrad.addColorStop(0.35, 'rgba(69, 48, 39, 0.08)');
    sGrad.addColorStop(0.7, 'rgba(186, 186, 186, 0.03)');
    sGrad.addColorStop(1, 'rgba(255, 255, 255, 0.0)');
    sCtx.fillStyle = sGrad;
    sCtx.fillRect(0, 0, 512, 512);

    const shadowTex = new THREE.CanvasTexture(shadowCanvas);
    const shadowGeo = new THREE.PlaneGeometry(36, 36);
    const shadowMat = new THREE.MeshBasicMaterial({ map: shadowTex, transparent: true, opacity: 0.15, depthWrite: false });
    const shadowPlane = new THREE.Mesh(shadowGeo, shadowMat);
    shadowPlane.rotation.x = -Math.PI / 2;
    shadowPlane.position.y = -13.2;
    scene.add(shadowPlane);

    // Assembly Group
    const caduceusGroup = new THREE.Group();
    caduceusGroup.position.y = 0.6;
    scene.add(caduceusGroup);

    // Engineered Brand Materials
    const staffMat = new THREE.MeshStandardMaterial({
      color: BRAND.white,
      roughness: 0.15,
      metalness: 0.88,
    });

    const collarMat = new THREE.MeshStandardMaterial({
      color: BRAND.brown,
      roughness: 0.22,
      metalness: 0.78,
    });

    const orangeAccentMat = new THREE.MeshStandardMaterial({
      color: BRAND.orange,
      roughness: 0.18,
      metalness: 0.72,
      emissive: BRAND.orange,
      emissiveIntensity: 0.12,
    });

    const serpentAMat = new THREE.MeshStandardMaterial({
      color: BRAND.orange,
      roughness: 0.20,
      metalness: 0.75,
    });

    const serpentBMat = new THREE.MeshStandardMaterial({
      color: BRAND.brown,
      roughness: 0.28,
      metalness: 0.68,
    });

    const wingMat = new THREE.MeshStandardMaterial({
      color: BRAND.white,
      roughness: 0.18,
      metalness: 0.55,
    });

    const wingShadowMat = new THREE.MeshStandardMaterial({
      color: 0xEFEFEF,
      roughness: 0.26,
      metalness: 0.45,
    });

    // 1. Central Staff (Fluted Lathe Geometry)
    const staffGeo = new THREE.CylinderGeometry(0.68, 0.58, 21, 32);
    const staff = new THREE.Mesh(staffGeo, staffMat);
    caduceusGroup.add(staff);

    // Stepped Crossover Rings & Collars
    [-7.5, -3.2, 1.2, 5.6, 9.2].forEach(y => {
      const ringGeo = new THREE.TorusGeometry(0.95, 0.22, 16, 32);
      const ring = new THREE.Mesh(ringGeo, y === 9.2 ? orangeAccentMat : collarMat);
      ring.rotation.x = Math.PI / 2;
      ring.position.y = y;
      caduceusGroup.add(ring);
    });

    // Bottom Tapered Spindle Tip
    const bottomTipGeo = new THREE.ConeGeometry(0.58, 2.4, 24);
    const bottomTip = new THREE.Mesh(bottomTipGeo, collarMat);
    bottomTip.rotation.x = Math.PI;
    bottomTip.position.y = -11.7;
    caduceusGroup.add(bottomTip);

    // Crowning Orb (Finial Sphere)
    const orbGeo = new THREE.SphereGeometry(1.85, 36, 36);
    const orb = new THREE.Mesh(orbGeo, orangeAccentMat);
    orb.position.y = 11.4;
    caduceusGroup.add(orb);

    // Finial Pinnacle Needle
    const pinGeo = new THREE.ConeGeometry(0.48, 2.2, 24);
    const pin = new THREE.Mesh(pinGeo, staffMat);
    pin.position.y = 13.5;
    caduceusGroup.add(pin);

    // 2. Muscular Intertwined Serpents (Double Helix)
    function createSerpent(isAlpha) {
      const curvePts = [];
      const steps = 160;
      const height = 18.0;
      const turns = 2.5;
      const phase = isAlpha ? 0 : Math.PI;

      for (let i = 0; i <= steps; i++) {
        const u = i / steps;
        const y = -8.8 + u * height;
        const radius = 3.6 * Math.sin(Math.PI * (0.08 + 0.84 * u));
        const theta = u * turns * 2 * Math.PI + phase;
        const x = radius * Math.cos(theta);
        const z = radius * Math.sin(theta) * 0.90;
        curvePts.push(new THREE.Vector3(x, y, z));
      }

      const curve = new THREE.CatmullRomCurve3(curvePts);
      const tubeGeo = new THREE.TubeGeometry(curve, 120, 0.52, 20, false);
      const mat = isAlpha ? serpentAMat : serpentBMat;
      const mesh = new THREE.Mesh(tubeGeo, mat);
      caduceusGroup.add(mesh);

      // Serpent Head (Sculpted Cobra-Hooded Head)
      const lastPt = curvePts[curvePts.length - 1];
      const prevPt = curvePts[curvePts.length - 6];
      const dir = new THREE.Vector3().subVectors(lastPt, prevPt).normalize();

      const headGroup = new THREE.Group();
      headGroup.position.copy(lastPt);

      const headGeo = new THREE.ConeGeometry(0.85, 2.0, 16);
      const head = new THREE.Mesh(headGeo, isAlpha ? orangeAccentMat : collarMat);
      head.rotation.z = isAlpha ? -Math.PI / 3.2 : Math.PI / 3.2;
      head.rotation.y = isAlpha ? 0.35 : -0.35;
      headGroup.add(head);

      // Jewel Eyes (Faceted Orange)
      const eyeGeo = new THREE.SphereGeometry(0.18, 12, 12);
      const eyeL = new THREE.Mesh(eyeGeo, orangeAccentMat);
      eyeL.position.set(isAlpha ? -0.35 : 0.35, 0.4, 0.45);
      headGroup.add(eyeL);

      caduceusGroup.add(headGroup);
    }

    createSerpent(true);
    createSerpent(false);

    // 3. Symmetrical Multi-Tier Feathered Wings (Extruded Aerofoil Blades)
    function createFeatherShape(width, length) {
      const s = new THREE.Shape();
      s.moveTo(0, 0);
      s.quadraticCurveTo(width * 0.45, length * 0.35, width * 0.5, length * 0.85);
      s.quadraticCurveTo(width * 0.25, length, 0, length);
      s.quadraticCurveTo(-width * 0.25, length, -width * 0.5, length * 0.85);
      s.quadraticCurveTo(-width * 0.45, length * 0.35, 0, 0);
      return s;
    }

    function createWing(isLeft) {
      const wingGroup = new THREE.Group();
      const sign = isLeft ? -1 : 1;

      // Tier A: 7 Primary Flight Feathers (Broad, Elegant Fan)
      const primarySpecs = [
        { w: 2.8, len: 9.2, rot: 0.32, x: 2.2, y: 7.6, z: 0.1 },
        { w: 2.6, len: 8.6, rot: 0.48, x: 3.5, y: 7.2, z: 0.2 },
        { w: 2.4, len: 7.9, rot: 0.64, x: 4.8, y: 6.8, z: 0.1 },
        { w: 2.2, len: 7.1, rot: 0.82, x: 6.0, y: 6.3, z: 0.2 },
        { w: 2.0, len: 6.3, rot: 1.00, x: 7.1, y: 5.7, z: 0.1 },
        { w: 1.8, len: 5.4, rot: 1.18, x: 8.0, y: 5.0, z: 0.2 },
        { w: 1.6, len: 4.5, rot: 1.36, x: 8.8, y: 4.2, z: 0.1 },
      ];

      primarySpecs.forEach((spec, idx) => {
        const shape = createFeatherShape(spec.w, spec.len);
        const geo = new THREE.ExtrudeGeometry(shape, {
          depth: 0.24,
          bevelEnabled: true,
          bevelThickness: 0.08,
          bevelSize: 0.06,
          bevelSegments: 2,
        });
        const mat = idx % 2 === 0 ? wingMat : wingShadowMat;
        const mesh = new THREE.Mesh(geo, mat);
        mesh.position.set(sign * spec.x, spec.y, spec.z);
        mesh.rotation.z = sign * -spec.rot;
        mesh.rotation.y = sign * 0.14;
        wingGroup.add(mesh);
      });

      // Tier B: 4 Secondary Covert Feathers (Lower Mid-Wing Volume)
      const secondarySpecs = [
        { w: 2.2, len: 5.8, rot: 0.55, x: 3.0, y: 8.0, z: 0.4 },
        { w: 2.0, len: 5.2, rot: 0.72, x: 4.2, y: 7.5, z: 0.45 },
        { w: 1.8, len: 4.6, rot: 0.90, x: 5.3, y: 6.9, z: 0.4 },
        { w: 1.6, len: 4.0, rot: 1.08, x: 6.3, y: 6.3, z: 0.45 },
      ];

      secondarySpecs.forEach(spec => {
        const shape = createFeatherShape(spec.w, spec.len);
        const geo = new THREE.ExtrudeGeometry(shape, {
          depth: 0.22,
          bevelEnabled: true,
          bevelThickness: 0.07,
          bevelSize: 0.05,
          bevelSegments: 2,
        });
        const mesh = new THREE.Mesh(geo, collarMat);
        mesh.position.set(sign * spec.x, spec.y, spec.z);
        mesh.rotation.z = sign * -spec.rot;
        mesh.rotation.y = sign * 0.18;
        wingGroup.add(mesh);
      });

      // Wing Root Spar (Metallic Orange Spine)
      const sparGeo = new THREE.CylinderGeometry(0.48, 0.28, 9.2, 20);
      const spar = new THREE.Mesh(sparGeo, orangeAccentMat);
      spar.position.set(sign * 5.2, 9.2, 0.35);
      spar.rotation.z = sign * -1.02;
      wingGroup.add(spar);

      caduceusGroup.add(wingGroup);
    }

    createWing(true);
    createWing(false);

    // Initial heroic front-facing orientation (subtle 4° angle shows depth without edge-on flattening)
    const BASE_ROTATION_Y = 0.06;
    caduceusGroup.rotation.y = BASE_ROTATION_Y;

    // Scroll-Linked Interaction
    let targetRotationY = BASE_ROTATION_Y;
    let targetTiltX = 0.0;
    let targetScale = 1.0;
    let currentRotationY = BASE_ROTATION_Y;
    let currentTiltX = 0.0;
    let currentScale = 1.0;
    let scrollProgress = 0.0;

    window.addEventListener('message', (e) => {
      if (e.data) {
        if (typeof e.data.scrollProgress === 'number') {
          scrollProgress = Math.max(0, Math.min(2.5, e.data.scrollProgress));
          // Rotate smoothly as user scrolls down, reverse on scroll up
          targetRotationY = BASE_ROTATION_Y + scrollProgress * Math.PI * 0.95;
          targetTiltX = Math.sin(scrollProgress * Math.PI * 0.5) * 0.20;
          targetScale = 1.0 - scrollProgress * 0.06;
        }
        if (typeof e.data.opacity === 'number') {
          document.body.style.opacity = String(Math.max(0, Math.min(1, e.data.opacity)));
        }
      }
    });

    window.addEventListener('scroll', () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight || 1;
      const progress = window.scrollY / maxScroll;
      targetRotationY = BASE_ROTATION_Y + progress * Math.PI * 1.5;
      targetTiltX = Math.sin(progress * Math.PI) * 0.25;
    });

    // Pointer Interactive Hover Tilt
    let mouseX = 0, mouseY = 0;
    window.addEventListener('pointermove', (e) => {
      mouseX = (e.clientX / window.innerWidth) * 2 - 1;
      mouseY = -(e.clientY / window.innerHeight) * 2 + 1;
    });

    // Render Loop
    let clock = new THREE.Clock();

    function animate() {
      requestAnimationFrame(animate);
      const delta = clock.getDelta();

      // Smooth damped follow (Anatomy spring physics)
      currentRotationY += (targetRotationY + mouseX * 0.32 - currentRotationY) * (delta * 6.0);
      currentTiltX += (targetTiltX + mouseY * 0.22 - currentTiltX) * (delta * 6.0);
      currentScale += (targetScale - currentScale) * (delta * 6.0);

      // Subtle idle breathing when at rest
      const idle = Math.sin(clock.getElapsedTime() * 1.6) * 0.03;

      caduceusGroup.rotation.y = currentRotationY + idle;
      caduceusGroup.rotation.x = currentTiltX;
      caduceusGroup.scale.set(currentScale, currentScale, currentScale);
      caduceusGroup.position.y = 0.6 + idle * 3;

      renderer.render(scene, camera);
    }
    animate();

    function updateDimensions() {
      if (container.clientWidth > 0 && container.clientHeight > 0) {
        camera.aspect = container.clientWidth / container.clientHeight;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, container.clientHeight);
      }
    }

    window.addEventListener('resize', updateDimensions);
    if (window.ResizeObserver) {
      new ResizeObserver(updateDimensions).observe(container);
    }
    // Microtask check on initial layout
    setTimeout(updateDimensions, 100);
    setTimeout(updateDimensions, 400);
  </script>
</body>
</html>
`;

const htmlPath = join(__dirname, "../web/caduceus-anatomy-3d.html");
writeFileSync(htmlPath, htmlContent, "utf-8");
console.log(`✓ Interactive Anatomy 3D Caduceus HTML generated: ${htmlPath}`);

const emblemPath = join(__dirname, "../web/caduceus-emblem.html");
writeFileSync(emblemPath, htmlContent, "utf-8");
console.log(`✓ Embedded platform view asset updated: ${emblemPath}`);
