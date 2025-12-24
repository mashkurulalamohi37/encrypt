# Zero-Cost E2EE Anonymous Communication System - Implementation Plan

## Overview
This project aims to build a secure, anonymous, and zero-cost communication system using a Flutter mobile app and a self-hosted backend on Oracle Cloud Free Tier.

## Architecture

### Backend (Self-Hosted on Oracle Cloud Free Tier)
- **OS**: Ubuntu (Ampere A1 Instance)
- **Network**: Tor Hidden Service (Onion Address) - No Public IP/DNS required.
- **Components**:
    - **Tor**: Exposes the services via `.onion` address.
    - **Mosquitto (MQTT)**: For real-time signaling and message queuing.
    - **Coturn (TURN)**: For WebRTC media relay (Voice/Video).
    - **PostgreSQL**: For storing offline encrypted blobs (binary data).
    - **Custom Server logic (Optional)**: If needed to interface between MQTT/DB, or direct connection to DB/MQTT from client.

### Frontend (Flutter App)
- **Networking**: All traffic routed through a local Tor SOCKS5 proxy (127.0.0.1:9050).
- **Encryption**:
    - **Transport**: Tor Hidden Service (End-to-End Encryption at network layer).
    - **Message**: Signal Protocol (Double Ratchet, X3DH) - `libsignal_protocol_dart`.
    - **Metadata**: Sealed Sender (sender identity encrypted).
- **Storage**:
    - **Keys**: `flutter_secure_storage`.
    - **Database**: `drift` with `sqlcipher_flutter_libs` (Encrypted local DB).
- **Calls**: `flutter_webrtc` (P2P with TURN relay).
- **Panic Button**: Wipe keys and database on duress.

## Roadmap & Status

### Phase 1: Project Setup & Dependencies [CURRENT]
- [x] Create Flutter Project.
- [ ] Add Dependencies (`libsignal_protocol_dart`, `drift`, `sqlcipher`, `webrtc`, etc.).
- [ ] Set up project structure.

### Phase 2: Backend Configuration (Infrastructure as Code)
- [x] Create `docker-compose.yml` for Mosquitto, Coturn, PostgreSQL [Done].
- [x] Create `torrc` configuration for Hidden Service [Done].
- [x] Documentation for deploying to Oracle Cloud [Done].

### Phase 3: Frontend - Core Security & Networking
- [ ] Integrate Tor (SOCKS5 Proxy client) [Done basic service].
- [x] Implement Signal Protocol (Session setup, Encryption/Decryption) [Done].
- [x] Secure Storage & Database Implementation [Done].

### Phase 4: Frontend - Features
- [x] Registration (Anonymous UUID generation) [Done].
- [x] Chat Interface (UI) [Done].
- [x] Voice/Video Call Logic (WebRTC) [Basic Setup Done].
- [x] Panic Button Implementation [Done].

## Dependencies (Specification)
- `libsignal_protocol_dart`
- `flutter_secure_storage`
- `drift` + `sqlcipher_flutter_libs`
- `flutter_webrtc`
- `uuid`
- `tor_android` (or equivalent SOCKS proxy handler)
