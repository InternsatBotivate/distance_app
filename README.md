# Vendor Distance Explorer

A smart, interactive Flutter application for discovering nearby vendors. This app provides a dynamic map interface, real-time distance and duration calculations, and intelligent search functionality to connect users with vendor locations effortlessly.

![Vendor Distance Explorer Screenshot](https://i.imgur.com/your-screenshot-url.png)
*(Replace this with a screenshot of your app)*

## ✨ Features

-   **🌐 Interactive OpenStreetMap:** A smooth, responsive map interface powered by `flutter_map`.
-   **📍 Dynamic User Anchor:**
    -   **GPS Location:** Starts by automatically fetching your current location.
    -   **Long-Press to Move:** Tap and hold anywhere on the map to set a new starting point.
    -   **Geocoding Search:** Type any address into the search bar to pin a precise location.
-   **🧠 Smart Vendor Search:**
    -   Finds all vendors within a set radius of your anchor point.
    -   **Intelligent Fallback:** If no vendors are found in the radius, the app automatically finds and displays the 5 closest vendors.
-   **🚗 Real-Time Distance & ETA:**
    -   Fetches actual road distance and estimated travel duration from a Google Apps Script API.
    -   Displays this information directly on the lines connecting you to each nearby vendor.
-   **📊 Dynamic UI:**
    -   Visualizes connections with styled polylines on the map.
    -   Nearby vendor markers are highlighted and enlarged for easy identification.
-   **🧾 Sorted Vendor List:**
    -   Displays a horizontal, scrollable list of all nearby vendors.
    -   Automatically sorted from closest to farthest based on real-time travel distance.
-   **ℹ️ Detailed Vendor Info:**
    -   Tap any vendor to bring up a detailed bottom sheet with their name, address, distance, and ETA.
    -   **On-Demand Fetching:** If you tap a vendor that isn't "nearby," the app fetches its details instantly.
-   **🚘 Google Maps Integration:** Launch turn-by-turn navigation directly from the vendor details sheet with a single tap.
-   **🔐 Secure Configuration:** API URLs are managed securely using a `.env` file.

## 🚀 Getting Started

### Prerequisites

-   Ensure you have Flutter (version 3.13 or later) installed.
-   An internet connection to fetch map tiles and API data.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://your-repository-url.git](https://your-repository-url.git)
    cd your_project_directory
    ```

2.  **Create a `.env` file:**
    In the root of the project, create a file named `.env` and add your Google Apps Script URL:
    ```
    APPS_SCRIPT_URL=[https://script.google.com/macros/s/YOUR_APPS_SCRIPT_ID/exec](https://script.google.com/macros/s/YOUR_APPS_SCRIPT_ID/exec)
    ```

3.  **Fetch packages:**
    ```bash
    flutter pub get
    ```

4.  **Run the app:**
    ```bash
    flutter run
    ```

### Platform Setup

-   **Android:** Location permissions are handled by `geolocator`. No other setup is required for debugging.
-   **iOS:** Make sure to provide a description for location usage in `ios/Runner/Info.plist`.
-   **Web:** Location access requires a secure context (`localhost` or `https://`). The permission prompt is triggered by a user action (clicking the "My Location" button).

## 🏗️ Architecture

-   **`lib/main.dart`**: The main entry point of the app, containing the home page, state management, and primary UI widgets. It handles all map interactions and state changes.
-   **`lib/models/vendor.dart`**: Defines the `Vendor` data model, including a `copyWith` method for immutable state updates.
-   **`lib/widgets/vendor_bottom_sheet.dart`**: A separate, reusable widget for displaying detailed vendor information.
-   **Services (Google Apps Script):** All external data (vendor lists, distance calculations, geocoding) is fetched from a single, robust Google Apps Script endpoint.
-   **State Management:** The app uses `StatefulWidget` and `setState` for managing the UI state, including user location, vendor lists, and loading statuses.