import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Entry point of the application
/// This function runs first and starts the app
void main() {
  runApp(const MyApp());
}

/// Root widget of the app
/// Defines the app theme (purple color scheme) and sets HomePage as the main screen
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shake to Get a Quote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

/// HomePage widget - The main screen of the app
/// Stateful widget because it needs to change state when quotes are updated
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State class for HomePage
/// Manages the app's state, animations, and shake detection
/// TickerProviderStateMixin is needed for smooth animations
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// EventChannel to receive shake events from Android native code
  static const platform = EventChannel('com.example/shake_events');

  /// List of motivational quotes to display
  /// Each quote has an emoji at the end for visual appeal
  final List<String> quotes = [
    "Don't hesitate — failure is easier than regret. 💪",
    "Every small step brings you closer to your goal. 🚶",
    "Success is not an accident; it's the result of preparation and persistence. 🎯",
    "Learn something new today, even if it's small. 📚",
    "Obstacles are what reveal our true strength. 🏔️",
    "Start where you are, use what you have, do what you can. ✨",
    "Focus creates greatness. 🔥",
  ];

  /// Stores the currently displayed quote
  late String currentQuote;

  /// Tracks the last quote shown to avoid duplicate consecutive quotes
  late String lastQuote;

  /// Controls the fade animation of the quote (fade in/out)
  late AnimationController fadeController;

  /// The actual fade animation that goes from 0 to 1 (invisible to visible)
  late Animation<double> fadeAnimation;

  /// Stream subscription to listen for shake events from Android
  StreamSubscription? shakeSubscription;

  /// initState is called when the widget is first created
  /// Used to initialize variables and setup listeners
  @override
  void initState() {
    super.initState();

    /// Set the first quote to display
    currentQuote = quotes[0];

    /// Track the last quote to avoid showing same quote twice in a row
    lastQuote = currentQuote;

    /// Setup the animation controller that controls the fade effect
    /// 800 milliseconds = 0.8 seconds for fade animation duration
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    /// Create the fade animation: starts at 0 (invisible) and goes to 1 (visible)
    /// Tween defines the value range, CurvedAnimation makes it smooth
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeIn));

    /// Start the fade animation immediately when the app loads
    fadeController.forward();

    /// Setup listener to receive shake events from Android
    _setupShakeListener();
  }

  /// Setup listener to receive shake events from Android native code
  /// When phone is shaken, Android sends an event through the EventChannel
  /// This function listens for those events and triggers _showNewQuote()
  void _setupShakeListener() {
    /// receiveBroadcastStream() listens for continuous events from Android
    shakeSubscription = platform.receiveBroadcastStream().listen(
      /// When an event is received (phone is shaken), call _showNewQuote()
      (dynamic event) {
        _showNewQuote();
      },

      /// If there's an error in communication, show error to user
      onError: (dynamic error) {
        debugPrint('Shake Detection Error: $error');

        /// Show error message only if widget is still mounted (not disposed)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Shake detection error. Check permissions.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  /// Display a new random quote when phone is shaken
  /// Also plays the fade animation to show the new quote smoothly
  /// Avoids showing the same quote twice in a row
  void _showNewQuote() {
    /// setState() tells Flutter to update the UI
    /// Get a random quote and keep trying if it's the same as the last one
    setState(() {
      do {
        currentQuote = (quotes..shuffle()).first;
      } while (currentQuote == lastQuote && quotes.length > 1);

      /// Remember this quote so we don't show it again next time
      lastQuote = currentQuote;
    });

    /// Reset the animation to the beginning (opacity = 0, invisible)
    fadeController.reset();

    /// Play the animation forward (fade in from 0 to 1)
    fadeController.forward();
  }

  /// dispose() is called when the widget is destroyed
  /// Clean up resources to prevent memory leaks
  @override
  void dispose() {
    /// Stop and clean up the animation controller
    fadeController.dispose();

    /// Stop listening to shake events from Android
    shakeSubscription?.cancel();

    /// Call parent dispose
    super.dispose();
  }

  /// build() creates the UI (visual layout) of the app
  /// This is called whenever setState() updates the UI
  @override
  Widget build(BuildContext context) {
    /// Scaffold is the main structure of the app (AppBar + body)
    return Scaffold(
      /// AppBar - Top bar of the app with the title
      appBar: AppBar(
        title: const Text('Shake to Get a Quote'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),

      /// body - Main content area of the app
      body: Container(
        color: Colors.grey[100],

        /// Center - Centers the child widget in the middle of the screen
        child: Center(
          /// FadeTransition - Animates the opacity (fade in/out effect)
          /// Uses fadeAnimation to control the animation
          child: FadeTransition(
            opacity: fadeAnimation,

            /// Padding - Adds space around the quote text
            child: Padding(
              padding: const EdgeInsets.all(32.0),

              /// Text - The actual quote that is displayed
              child: Text(
                currentQuote,
                textAlign: TextAlign.center,

                /// TextStyle - Styling for the quote (size, color, weight)
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
