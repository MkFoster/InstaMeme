# 📸 InstaMeme — On-Device AI Meme Generator for iOS

InstaMeme is a fully on-device, privacy-first meme creation app powered by Apple Silicon and the MLX framework.  
With just a photo and a tap, InstaMeme generates short, punchy meme captions using **local inference**—no internet connection required.

Users can:
- Take a live photo or pick from their library  
- Auto-generate meme captions using Vision + Llama running in MLX  
- Remix memes endlessly  
- Share or export them as burned-in images  
- Build and extend a persistent personal meme gallery  

InstaMeme transforms casual camera moments into share-ready memes instantly—all processed locally on ARM hardware.

---

## 🚀 InstaMeme Highlights

InstaMeme demonstrates **on-device AI** with a fun user experience.

This project showcases:

| Category | Achievement |
|---------|------------|
| **Technological Implementation** | Uses Apple’s MLX, on-device LLM inference, Vision classification, SwiftData persistence, and zero-server architecture. |
| **User Experience** | Designed as a frictionless meme workflow: snap → suggest → remix → share. |
| **Impact** | Demonstrates a pattern for developers to incorporate on-device LLMs and generative UX flows in consumer apps. |
| **WOW Factor** | Watching a live camera image turn instantly into a meme—with no network. |

InstaMeme showcases how the next wave of mobile apps can use **fast, private, localized intelligence** powered by Arm.

---

## ✨ Core Features

- 🧠 **On-Device Caption Generation**  
  Uses MLX + a quantized Llama-based language model for offline meme text.

- 📷 **Live Camera Capture OR Photo Library Import**  
  Built with modern SwiftUI + PhotosPicker integration.

- 👀 **Apple Vision Recognition**  
  Vision framework detects objects in the image, feeding semantic context into the LLM.

- 🖼️ **Burn-In Graphics Rendering**  
  Exported memes are rendered into a final flattened image, guaranteeing compatibility with SMS, Messenger, WhatsApp, etc.

- ♻️ **Remix Mode**  
  Users can regenerate new captions or edit them manually, creating variations without losing prior versions.

- 💾 **SwiftData Storage**  
  Fully persistent offline gallery that never requires a connection.

- 🔄 **Resizable Image Pipeline**  
  Automatically scales images to mobile-friendly dimensions to prevent memory overuse when sharing.

---

## 🛠️ Tech Stack

| Component | Technology |
|----------|------------|
| UI | SwiftUI |
| Storage | SwiftData |
| ML Framework | **MLX** + MLXLLM |
| Computer Vision | Apple **Vision Framework** |
| Model Execution | Quantized on-device Llama variant |
| Rendering | UIKit + SwiftUI `ImageRenderer`, Core Graphics burn-in |
| Platform | iOS (Apple Silicon / A-Series ARM chips) |

---

## 📦 Setup & Build Instructions

### Requirements

- macOS Tahoe or later  
- Xcode 26 or later  
- **Apple Silicon Mac**
- iPhone running iOS 17+ (**required for live camera + on-device ML performance**)  

### 1️⃣ Clone the Repository

```sh
git clone https://github.com/MkFoster/InstaMeme
cd InstaMeme
```

### 2️⃣ Open in Xcode
open InstaMeme.xcodeproj

### 3️⃣ Add Required MLX Packages

In Xcode:

File → Add Packages…

Add these URLs:

* https://github.com/ml-explore/mlx-swift.git
* https://github.com/ml-explore/mlx-swift-lm.git
* https://github.com/ml-explore/mlx-swift-llm.git

Confirm they are attached to the app target in:

Project Settings → Target → Frameworks, Libraries, and Embedded Content

### 4️⃣ Build and Run on a Physical Device
Because the app uses:
* Camera input
* Vision framework
* MLX running on-device
* Neural Engine acceleration

…it must run on real hardware.

Select your device in Xcode and press ⌘ + R

### 5️⃣ First-Run Model Download

When you tap Suggest Captions for the first time:
* The app will automatically download the quantized MLX model.
* It is stored locally and reused — no internet needed afterward.
