# TodoistX Local - A Feature-Rich Offline-First Todo App

TodoistX Local is a complete, production-ready, and offline-first todo list application built with Flutter. It's designed to be modern, professional, and accessible, providing a private and secure way to manage your tasks without needing an internet connection or any cloud services.

## Features

- **100% Offline & Private:** All data, including tasks, projects, tags, and images, is stored locally on your device using the Hive database. No sign-up, no login, no data ever leaves your device.
- **Modern Material 3 UI:** A clean, professional, and accessible design with smooth animations, rounded cards, and clean typography.
- **Light & Dark Themes:** Choose between a light theme, a dark theme, or have the app follow your system's setting.
- **Comprehensive Task Management:**
    - Create tasks with titles, descriptions, due dates, and priorities (Low, Medium, High).
    - Attach images to tasks from your camera or gallery.
    - Add reminders to get local notifications for your tasks.
    - Use Speech-to-Text to dictate task titles and descriptions.
- **Projects & Tags:**
    - Organize tasks into projects with custom names, colors, and icons.
    - Assign multiple tags to tasks for flexible organization.
- **Powerful Views & Navigation:**
    - **Home:** A filterable and groupable list of all your upcoming tasks.
    - **Today:** A dedicated view for tasks due today.
    - **Calendar:** A full monthly calendar view with markers for tasks on due dates.
    - **Search:** A global search to quickly find any task by its title or description.
- **Filtering & Grouping:**
    - Filter the main task list by project, tag, or priority.
    - Group the task list by project, priority, or due date for a clear overview.
- **Local Analytics:**
    - A productivity screen shows a chart of your completed tasks over the last week.
    - A streak counter motivates you to keep completing tasks every day.
- **Data Management:**
    - (Coming soon) Export and import your entire database as a JSON file.
- **Localization:**
    - The app is set up for internationalization (i18n) with support for English and Hindi.

## Tech Stack & Architecture

- **Framework:** Flutter & Dart (Null Safety)
- **State Management:** Riverpod (`flutter_riverpod`)
- **Routing:** GoRouter (`go_router`)
- **Local Database:** Hive (`hive_flutter`)
- **Architecture:** A clean, feature-first architecture that separates concerns (data, presentation, services). UI is built with a reactive approach using Riverpod providers.

## Setup & Run Instructions

### Prerequisites
- You must have the Flutter SDK installed. For installation instructions, see the [official Flutter documentation](https://flutter.dev/docs/get-started/install).

### 1. Clone the Repository
```bash
git clone <repository-url>
cd todoistx_local
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

The app should now build and run on your connected device or emulator. Because this is an offline-first app, no further configuration is needed.

## Project Structure

The project follows a feature-first directory structure to keep the code organized and scalable.

```
/lib
  /src
    /common/          # Shared widgets, models, services, providers
    /features/        # Contains individual app features
      /analytics/
      /calendar/
      /projects/
      /settings/
      /tasks/
      ...
    /l10n/            # Localization files
    /routes/          # GoRouter configuration
    app.dart          # Root MaterialApp widget
    main.dart         # App entry point
  /test/              # Unit and widget tests
/l10n.yaml            # Localization config
...
```
---
*This project was built by an AI software engineer.*
