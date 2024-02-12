// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: getLoggedInUsername(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            // User is logged in, and we have the username
            return MainPage(
                username: snapshot.data!); // Use the fetched username
          } else {
            // User is not logged in
            return LoginPage();
          }
        },
      ),
    );
  }

  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.get(
      Uri.parse('http://localhost:3030/isLoggedIn'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Save the username for later use
      await prefs.setString('username', responseData['username']);
      return true;
    } else {
      return false;
    }
  }

  Future<String?> getLoggedInUsername() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('http://localhost:3030/isLoggedIn'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Optionally save the username again for later use
      await prefs.setString('username', responseData['username']);
      return responseData['username'];
    } else {
      return null;
    }
  }

  // This is part of your widget that decides whether to show the login page or main page
  Future<void> navigateBasedOnLoginStatus(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool loggedIn =
        await isLoggedIn(); // This already updates 'username' in prefs if logged in

    if (loggedIn) {
      // Fetch the username stored in SharedPreferences
      final String username = prefs.getString('username') ?? 'User';
      // Directly navigate to MainPage with the username
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainPage(username: username)),
      );
    } else {
      // Not logged in, navigate to the login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              onPressed: () => _attemptLogin(context),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }

  void _attemptLogin(BuildContext context) async {
    final login = _loginController.text;
    final password = _passwordController.text;
    // Implement the API call for login
    var url = Uri.parse('http://localhost:3030/login');
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"login": login, "password": password}));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(username: login)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }
}

class MainPage extends StatefulWidget {
  final String username;

  const MainPage({super.key, required this.username});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    ActivitiesPage(), // Placeholder for Activities Page, to be implemented
    BasketPage(),
    const Text('Profile Page'), // Placeholder for Profile Page
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Activities'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Basket'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class Activity {
  final String id;
  final String imageUrl;
  final String title;
  final String category;
  final String location;
  final int minimumPeople;
  final double price;

  Activity({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.category,
    required this.location,
    required this.minimumPeople,
    required this.price,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['_id'] ?? '',
      imageUrl: json['imageUrl'] ?? 'https://example.com/default.jpg',
      title: json['title'] ?? 'Untitled',
      category: json['category'] ?? 'Unknown',
      location: json['location'] ?? 'No location provided',
      minimumPeople: json['minimumPeople'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }
}

class ActivitiesPage extends StatefulWidget {
  @override
  _ActivitiesPageState createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  late Future<List<Activity>> futureActivities;

  Future<List<Activity>> fetchActivities() async {
    final response =
        await http.get(Uri.parse('http://localhost:3030/activities'));

    if (response.statusCode == 200) {
      List<dynamic> activitiesJson = json.decode(response.body);
      return activitiesJson.map((json) => Activity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load activities');
    }
  }

  @override
  void initState() {
    super.initState();
    futureActivities = fetchActivities();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Activity>>(
      future: futureActivities,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              Activity activity = snapshot.data![index];
              return ListTile(
                leading: Image.network(activity.imageUrl),
                title: Text(activity.title),
                subtitle: Text('${activity.location} - \$${activity.price}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailPage(activity: activity)),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;

  const ActivityDetailPage({Key? key, required this.activity})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(activity.imageUrl),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(activity.title,
                  style: Theme.of(context).textTheme.headline6),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Category: ${activity.category}"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Location: ${activity.location}"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Minimum People: ${activity.minimumPeople}"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Price: \$${activity.price}"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  // Implement navigation back to activities list
                  Navigator.pop(context);
                },
                child: Text('Return'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () => addToBasket(context, activity.id),
                child: const Text('Add to Basket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Inside ActivityDetailPage

  Future<void> addToBasket(BuildContext context, String activityId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3030/addToBasket'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"activityId": activityId}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity added to basket')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add activity to basket')),
      );
    }
  }
}

class BasketPage extends StatefulWidget {
  @override
  _BasketPageState createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  late Future<List<Activity>> futureActivities;
  late Future<List<Activity>> basketItems;
  double totalPrice = 0.0;

  // Inside _BasketPageState
  Future<List<Activity>> fetchBasketItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      throw Exception('User not logged in');
    }

    final response = await http.get(
      Uri.parse('http://localhost:3030/basket'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      List<dynamic> activitiesJson = json.decode(response.body);
      return activitiesJson.map((json) => Activity.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load basket');
    }
  }

  void calculateTotalPrice(List<Activity> activities) {
    totalPrice = activities.fold(0.0, (sum, item) => sum + item.price);
  }

  @override
  void initState() {
    super.initState();
    basketItems = fetchBasketItems();
    basketItems.then((activities) {
      calculateTotalPrice(activities);
    });
    futureActivities =
        fetchBasketItems(); // Initialize futureActivities in initState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Basket'),
      ),
      body: FutureBuilder<List<Activity>>(
        future: basketItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.data!.isEmpty) {
            return const Text('Your basket is empty.');
          } else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      Activity activity = snapshot.data![index];
                      return ListTile(
                        leading: Image.network(activity.imageUrl),
                        title: Text(activity.title),
                        subtitle:
                            Text('${activity.location} - \$${activity.price}'),
                        // Inside ListView.builder itemBuilder of BasketPage
                        trailing: IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              removeActivityFromBasket(activity.id),
                        ),
                      );
                    },
                  ),
                ),
                Text('Total: \$${totalPrice.toStringAsFixed(2)}'),
              ],
            );
          }
        },
      ),
    );
  }

  // Inside _BasketPageState
  void removeActivityFromBasket(String activityId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3030/removeFromBasket'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"activityId": activityId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        // Refetch the basket items to update the UI after removal
        basketItems = fetchBasketItems();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity removed from basket')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove activity from basket')),
      );
    }
  }
}
