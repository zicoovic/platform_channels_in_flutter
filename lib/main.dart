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

  /// Setup everything when app starts
  @override
  void initState() {
    super.initState();

    /// Show first quote
    currentQuote = quotes[0];

    /// Remember this quote (to avoid showing it twice in a row)
    lastQuote = currentQuote;

    /// Create animation controller (fade in for 800ms)
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    /// Create the fade animation (from invisible to visible)
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeIn));

    /// Start fade animation when app opens
    fadeController.forward();

    /// Listen for shake events from Android
    _setupShakeListener();
  }

  /// Listen for shake events from Android phone
  void _setupShakeListener() {
    /// Get shake events from the EventChannel
    shakeSubscription = platform.receiveBroadcastStream().listen(
      /// When phone shakes, show new quote
      (dynamic event) {
        _showNewQuote();
      },

      /// If something goes wrong, show error message
      onError: (dynamic error) {
        debugPrint('Shake Detection Error: $error');

        /// Show error to user (only if app is still open)
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

  /// Show a new random quote
  void _showNewQuote() {
    /// Update the quote (make sure it's different from the last one)
    setState(() {
      do {
        currentQuote = (quotes..shuffle()).first;
      } while (currentQuote == lastQuote && quotes.length > 1);

      /// Remember this quote so we don't show it again next time
      lastQuote = currentQuote;
    });

    /// Reset animation and play it again (fade in effect)
    fadeController.reset();
    fadeController.forward();
  }

  /// Clean up when app closes
  @override
  void dispose() {
    /// Stop animation
    fadeController.dispose();

    /// Stop listening for shakes
    shakeSubscription?.cancel();

    /// Call parent cleanup
    super.dispose();
  }

  /// Build the UI
  @override
  Widget build(BuildContext context) {
    /// Main app structure
    return Scaffold(
      /// Top bar
      appBar: AppBar(
        title: const Text('Shake to Get a Quote'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),

      /// Main content
      body: Container(
        color: Colors.grey[100],

        /// Center everything on screen
        child: Center(
          /// Fade animation effect
          child: FadeTransition(
            opacity: fadeAnimation,

            /// Add space around the quote
            child: Padding(
              padding: const EdgeInsets.all(32.0),

              /// The quote text
              child: Text(
                currentQuote,
                textAlign: TextAlign.center,

                /// Style the text
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
