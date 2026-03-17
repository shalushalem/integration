import re

with open("lib/home.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Find any sequence of - or - or characters followed by known Dart keywords
# Also handle specific comments we observed, and add newline
replacements = [
    (r"// --- Colors ----------------------------------------------const", r"// --- Colors\nconst"),
    (r"// --- AI Suggestion Messages \(F14\) ------------------------const", r"// --- AI Suggestion Messages\nconst"),
    (r"// ignore: unused_field// ignore: unused_fieldString", r"// ignore: unused_field\n// ignore: unused_field\nString"),
    (r"// ignore: unused_fieldString", r"// ignore: unused_field\nString"),
    (r"// Nav rise controllers — spring-physics feel_navRiseCtrls", r"// Nav rise controllers\n_navRiseCtrls"),
    (r"// -- Home content: collapses when overlay shows --AnimatedBuilder", r"// -- Home content\nAnimatedBuilder"),
    (r"// -- AI Overlay -----------------------------------if", r"// -- AI Overlay\nif"),
    (r"// -- Chat bar — always sits above the nav ---------Positioned", r"// -- Chat bar\nPositioned"),
    (r"// -- Nav always visible at bottom -----------------Positioned", r"// -- Nav always visible\nPositioned"),
    (r"// --- Aurora Layer -------------------------------------Widget", r"// --- Aurora Layer\nWidget"),
    (r"// --- Top Bar ------------------------------------------Widget", r"// --- Top Bar\nWidget"),
    (r"// --- Greeting Block -----------------------------------Widget", r"// --- Greeting Block\nWidget"),
    (r"// --- Prompt Chips -------------------------------------Widget", r"// --- Prompt Chips\nWidget"),
    (r"// --- Hero Card ----------------------------------------Widget", r"// --- Hero Card\nWidget"),
    (r"// --- Secondary Cards Row ------------------------------Widget", r"// --- Secondary Cards Row\nWidget"),
    (r"// --- Section Header -----------------------------------Widget", r"// --- Section Header\nWidget"),
    (r"// --- Picks Strip --------------------------------------Widget", r"// --- Picks Strip\nWidget"),
    (r"// -- Pick card bottom sheet ------------------------------Widget", r"// -- Pick card bottom sheet\nWidget"),
    (r"// -- See All panel --------------------------------------Widget", r"// -- See All panel\nWidget"),
    (r"// -- Lens bottom sheet ----------------------------------Widget", r"// -- Lens bottom sheet\nWidget"),
    (r"// -- Coming Soon toast ----------------------------------Widget", r"// -- Coming Soon toast\nWidget"),
    (r"// ----------------------------------------------------------// _NavPillPainter//// Strategy: draw two shapes and union them via Path.combine.//   1. pillPath  — perfect RRect \(no arc direction issues\)//   2. bulgePath — a closed teardrop bezier above the active slot// Path.combine\(PathOperation.union\) merges them seamlessly.// The border stroke is drawn on the combined path.// ----------------------------------------------------------class", 
     r"// _NavPillPainter\nclass"),
    (r"// -- 1. Pill RRect \(always perfect, no arc issues\) --final", r"// -- Pill RRect\nfinal"),
    (r"// -- 2. Bulge path — always built, even at bulgeT=0 --// When bulgeH=0 the arch collapses to a flat line on the// pill top edge, so the union is identical to pillPath.// This avoids the sudden path-appear spike at bulgeT>0.5.final", 
     r"// -- Bulge path\nfinal"),
    (r"// cp1: leaves foot horizontallycx", r"// cp1\ncx"),
    (r"// cp2: arrives at peak horizontallycx", r"// cp2\ncx"),
    (r"// peak\);bp", r"// peak\n);bp"),
    (r"// cp1: leaves peak horizontallyrx", r"// cp1\nrx"),
    (r"// cp2: arrives at foot horizontallyrx", r"// cp2\nrx"),
    (r"// right foot\);bp", r"// right foot\n);bp"),
    (r"// straight line back along pill top \(inside pill ? hidden by union\)final", r"// straight line back\nfinal"),
    (r"// -- Paint -------------------------------------------// Drop shadowcanvas", r"// -- Paint Drop shadow\ncanvas"),
    (r"// Accent glow under bulgeif", r"// Accent glow\nif"),
    (r"// Fillcanvas", r"// Fill\ncanvas"),
    (r"// Border stroke on the final outlinecanvas", r"// Border stroke\ncanvas"),
    (r"// --- AI Overlay State Enum --------------------------------enum", r"// --- AI Overlay State Enum\nenum"),
    (r"// --- AI Data Models ---------------------------------------class", r"// --- AI Data Models\nclass"),
    (r"// --- Intent Config ----------------------------------------const", r"// --- Intent Config\nconst"),
    (r"// --- Gradient Text Widget ---------------------------------class", r"// --- Gradient Text Widget\nclass"),
    (r"// Only the text fades, the card stays solidExpanded", r"// Only the text fades\nExpanded"),
    (r"// Previous icon springs down_navRiseCtrls", r"// Previous icon springs down\n_navRiseCtrls"),
    (r"// New icon springs up with overshoot_navRiseCtrls", r"// New icon \n_navRiseCtrls"),
    (r"// ------------------------------------------------------// INTENT / AI OVERLAY SYSTEM// ------------------------------------------------------void", r"// INTENT SYSTEM\nvoid"),
    (r"// ------------------------------------------------------// AI OVERLAY — full backdrop, content above chat\+nav// ------------------------------------------------------Widget", r"// AI OVERLAY\nWidget"),
    (r"// Full backdrop — tap to dismissPositioned", r"// Full backdrop\nPositioned"),
    (r"// Transparent pass-through zone over chat bar \+ nav// so touches reach those widgets instead of the backdropPositioned", r"// Transparent pass-through\nPositioned"),
    (r"// Content area: stays above chat bar \+ navPositioned", r"// Content area\nPositioned"),
    (r"// AHVI brand headerColumn", r"// AHVI brand header\nColumn"),
    (r"// Scrollable contentExpanded", r"// Scrollable content\nExpanded"),
    (r"// -- Pill shape with animated bulge via CustomPaint --Positioned", r"// -- Pill shape \nPositioned"),
    (r"// -- Nav items -------------------------------------Positioned", r"// -- Nav items\nPositioned"),
    (r"// Total height = pill \(64\) \+ max bulge above \(20\) \+ icon radius that overflows \(6\)const", r"// Total height\nconst"),
    (r"// narrower = cleanerfinal", r"// narrower \nfinal"),
]

for pat, repl in replacements:
    text = re.sub(pat, repl, text)

with open("lib/home.dart", "w", encoding="utf-8") as f:
    f.write(text)

print("Done fixing comments!")
