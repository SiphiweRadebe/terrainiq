<div align="center">

<svg width="120" height="120" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect width="120" height="120" rx="28" fill="#0F1923"/>
  <!-- Terrain lines -->
  <polyline points="10,90 35,55 55,70 75,35 100,45" fill="none" stroke="#1D9E75" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
  <!-- Steep section highlight -->
  <polyline points="55,70 75,35" fill="none" stroke="#EF9F27" stroke-width="3.5" stroke-linecap="round"/>
  <!-- Road surface dots (gravel indicator) -->
  <circle cx="42" cy="64" r="2" fill="#5DCAA5" opacity="0.7"/>
  <circle cx="63" cy="54" r="2" fill="#5DCAA5" opacity="0.7"/>
  <circle cx="84" cy="39" r="2" fill="#EF9F27" opacity="0.9"/>
  <!-- IQ dot -->
  <circle cx="95" cy="28" r="7" fill="#1D9E75"/>
  <text x="95" y="32" text-anchor="middle" font-family="Georgia, serif" font-size="9" font-weight="bold" fill="#ffffff">IQ</text>
</svg>

# TerrainIQ

**Smart road navigation with terrain & surface intelligence**

[![Flutter](https://img.shields.io/badge/Flutter-Web-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-1D9E75?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-In%20Development-EF9F27?style=flat-square)]()

</div>

---

## What is TerrainIQ?

Most navigation apps show you roads as flat, featureless lines. TerrainIQ changes that.

TerrainIQ is a web-based navigation tool that tells you what most maps won't — **how steep a road is**, **whether it's tar or gravel**, and **what to expect before you get there**. Built for drivers who care about the road beneath their wheels, not just the destination.

> "Google Maps tells you where to go. TerrainIQ tells you what you're getting into."

---

## Features

### 🗺️ Interactive Map
Live, zoomable map powered by OpenStreetMap. No Google, no fees.

### 🔺 Steepness Detection
Routes are colour-coded by gradient:
- 🟢 **Flat** — gentle incline, easy driving
- 🟡 **Moderate** — noticeable slope, take care
- 🔴 **Steep** — significant gradient, plan ahead

### 🪨 Road Surface Intelligence
Automatically detects and labels road surfaces along your route:
- Tar / asphalt
- Gravel
- Dirt / unpaved

### 📈 Elevation Profile
A chart showing the full elevation profile of your route at a glance — see every hill and valley before you drive it.

### ⚠️ Smart Warnings
Get heads-up alerts like *"steep descent in 2km"* or *"gravel road ahead"* so there are no surprises.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web |
| Map engine | OpenStreetMap via `flutter_map` |
| Routing | OSRM (open source, free) |
| Elevation data | Open-Elevation API |
| Road surface data | OpenStreetMap tags |
| Hosting | TBD (Firebase / Netlify) |

---

## Getting Started

### Prerequisites
- Flutter SDK (with web support enabled)
- Chrome browser
- Git

### Run locally

```bash
git clone https://github.com/YOUR_USERNAME/terrainiq.git
cd terrainiq
flutter pub get
flutter run -d chrome
```

---

## Roadmap

- [x] Project setup
- [ ] Map screen with OpenStreetMap
- [ ] Route selection (A → B)
- [ ] Steepness colour coding
- [ ] Road surface labels (tar / gravel)
- [ ] Elevation profile chart
- [ ] Smart warnings system

---

## Why TerrainIQ?

Off-road drivers, delivery drivers, motorcyclists, and rural commuters all face the same problem — standard navigation apps treat every road the same. TerrainIQ was built to fill that gap with a focused, personal tool that actually understands the road.

---

<div align="center">
  <sub>Built with Flutter · Powered by OpenStreetMap · Made for real roads</sub>
</div>
