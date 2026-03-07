# Resume Roaster AI 🚀

A cross-platform Flutter Web application that brutally roasts your resume. Powered by Google's Gemini AI and backed by Firebase, this analyzer rips apart your missing skills and weak formatting based on your target job description. Then, it automatically generates a perfectly structured, ATS-friendly PDF to completely rewrite and save your career.

## 🌟 Features

*   **Intelligent Scoring:** Evaluates your resume against specific job descriptions to calculate an ATS match percentage.
*   **Brutal Feedback:** The AI acts as a harsh career coach, providing humorous but highly critical feedback on your lack of skills, weak impact, and missing sections.
*   **Auto-Rewrite Engine:** Uses Gemini AI to completely rewrite your weak bullet points into strong, metric-driven statements.
*   **Smart PDF Export:** Generates and formats a complete, perfectly structured ATS-optimized PDF resume directly in your browser, ready to download and submit.
*   **Persistent Storage:** Saves your past resume analyses and generated PDFs securely using Firebase.
*   **Responsive UI:** A stunning, glassmorphism-inspired interface built entirely with Flutter Web.

## 🛠️ Technology Stack

*   **Frontend:** Flutter (Web), Dart
*   **Backend & Database:** Firebase (Authentication, Cloud Firestore)
*   **AI Engine:** Google Gemini (2.5 Flash) via `google_generative_ai`
*   **PDF Generation:** `syncfusion_flutter_pdf`
*   **Deployment:** Docker, Nginx, AWS EC2, GitHub Actions (CI/CD)

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (stable channel)
*   A Firebase project with Authentication and Firestore enabled.
*   A Google Gemini API Key.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Akhi1Babu/Resume-Analyzer.git
    cd Resume-Analyzer
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application locally:**
    You must provide your Gemini API key via a Dart define flag to run the AI engine.
    ```bash
    flutter run -d chrome --dart-define=GEMINI_API_KEY="your_api_key_here"
    ```

## 🐋 Docker Deployment

This project includes a complete Dockerfile and GitHub Actions workflow for automated deployments.

1.  Set your `GEMINI_API_KEY`, `DOCKER_PASSWORD`, `HOST`, `USERNAME`, and `SSH_KEY` in your GitHub Repository Secrets.
2.  Push to the `main` branch to trigger the automated CI/CD pipeline, which builds the Flutter web app, packages it in an Alpine Nginx container, and deploys it to your AWS server.

---
*Built with ❤️ using Flutter and AI.*
