# Blind Mate

Blind Mate is a Flutter-based mobile application designed as a social and dating platform with engaging, interactive features. The app emphasizes meaningful connections through features like "Bottle Notes" (anonymous messaging), mini-games, and mission-based interactions.

## 🌟 Key Features

*   **Authentication & Profiles**: Secure user login via Firebase Auth, personalized avatars, and user surveys for better matching.
*   **Matching System**: Connect with other users based on preferences and survey results.
*   **Real-time Chat**: Seamless, real-time messaging with matched users.
*   **Bottle Notes**: Send anonymous messages out into the "sea" and pick up notes left by others, adding a serendipitous way to meet people.
*   **Social Sharing & Posts**: Create posts, share updates, and interact with the community.
*   **Mini Games & Missions**: Engage in fun mini-games and complete daily missions to earn rewards.
*   **Rewards System**: Redeem earned points from missions for in-app perks or items.

## 🏗️ Design Architecture

The application is built using the **MVVM (Model-View-ViewModel)** architectural pattern to ensure a clean separation of concerns, scalability, and maintainability. 

### Folder Structure
*   `lib/models/`: Contains the data structures and business logic entities.
*   `lib/views/`: Contains the UI components, screens, and navigation controllers.
*   `lib/viewmodels/`: Handles the presentation logic, acting as a bridge between Models and Views. It manages states using the `Provider` package.
*   `lib/services/`: Handles external interactions, such as API calls and Firebase services.
*   `lib/utils/`: Helper functions, constants, and theme configurations.

### Tech Stack
*   **Frontend**: [Flutter](https://flutter.dev/) (Dart)
*   **State Management**: [Provider](https://pub.dev/packages/provider) package (`ChangeNotifierProvider` is heavily used across different features like Chat, Matching, BottleNotes, Auth, etc.)
*   **Backend & Database**: [Firebase](https://firebase.google.com/) (Firebase Auth for authentication and Cloud Firestore for real-time database).

## 🚀 Getting Started

To run this project locally, follow these steps:

1.  **Prerequisites**: Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) installed on your machine.
2.  **Clone the repository**:
    ```bash
    git clone https://github.com/Yung729/blindmate.git
    ```
3.  **Navigate to the project directory**:
    ```bash
    cd blindmate
    ```
4.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
5.  **Run the App**:
    Ensure you have an emulator running or a device connected, then execute:
    ```bash
    flutter run
    ```

*Note: As the app relies on Firebase, ensure that your Firebase configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) are properly set up in your local environment if they are not already included in the repository.*
