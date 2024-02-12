// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

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
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              ),
              child: const Text('Inscription'),
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
        const SnackBar(
          content: Text('Invalid credentials'),
          backgroundColor: Colors.red,
        ),
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
    const ActivitiesPage(), // Placeholder for Activities Page, to be implemented
    const BasketPage(),
    const ProfilePage()
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
  const ActivitiesPage({super.key});

  @override
  _ActivitiesPageState createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController; // Make it nullable
  List<Activity> _activities = [];
  Set<String> _categories = {'All'};
  List<Activity> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    fetchActivities().then((activities) {
      setState(() {
        _activities = activities;
        _categories
            .addAll(_activities.map((activity) => activity.category).toSet());
        _filteredActivities = _activities;
        // Initialize the TabController here
        _tabController = TabController(vsync: this, length: _categories.length);
      });
    });
  }

  Future<List<Activity>> fetchActivities() async {
    // Simulate fetching activities from a backend
    var url = Uri.parse('http://localhost:3030/activities');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data
          .map((activityJson) => Activity.fromJson(activityJson))
          .toList();
    } else {
      throw Exception('Failed to load activities');
    }
  }

  void filterActivities(String category) {
    setState(() {
      if (category == 'All') {
        _filteredActivities = _activities;
      } else {
        _filteredActivities = _activities
            .where((activity) => activity.category == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if _tabController is initialized
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        bottom: _tabController == null
            ? null
            : TabBar(
                controller: _tabController!,
                isScrollable: true,
                tabs:
                    _categories.map((category) => Tab(text: category)).toList(),
                onTap: (index) =>
                    filterActivities(_categories.elementAt(index)),
              ),
      ),
      body: _tabController == null
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loading indicator until _tabController is initialized
          : ListView.builder(
              itemCount: _filteredActivities.length,
              itemBuilder: (context, index) {
                final activity = _filteredActivities[index];
                return ListTile(
                  leading: Image.network(activity.imageUrl),
                  title: Text(activity.title),
                  subtitle: Text(
                      '${activity.category} - ${activity.location} - \$${activity.price}'),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose(); // Use null-aware call to dispose
    super.dispose();
  }
}

class ActivityDetailPage extends StatelessWidget {
  final Activity activity;

  const ActivityDetailPage({super.key, required this.activity});

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
                  style: Theme.of(context).textTheme.titleLarge),
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
                child: const Text('Return'),
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
        const SnackBar(
          content: Text('You are not logged in.'),
          backgroundColor: Colors.red,
        ),
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

    final responseBody = jsonDecode(response.body);
    final message = responseBody['message'] ?? 'An unexpected error occurred';

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }
}

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});

  @override
  _BasketPageState createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  late Future<List<Activity>> basketItems;
  double totalPrice = 0.0;

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
      // Check if the basket is empty and return an empty list instead of throwing an exception
      if (activitiesJson.isEmpty) {
        return []; // Return an empty list for an empty basket
      }
      return activitiesJson.map((json) => Activity.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      // Specifically handle the case where the basket is not found (which can imply it's empty)
      return []; // Return an empty list for an empty or not found basket
    } else {
      // For any other error, you might still want to throw an exception or handle it differently
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
      setState(() {
        calculateTotalPrice(activities);
      });
    });
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
            return const Center(
              child: Text(
                'Your basket is empty.',
                style: TextStyle(fontSize: 18.0),
              ),
            );
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
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              removeActivityFromBasket(activity.id),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Total: \$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18.0)),
                ),
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
        const SnackBar(
          content: Text('You are not logged in.'),
          backgroundColor: Colors.red,
        ),
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

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        // Refetch the basket items to update the UI after removal
        basketItems = fetchBasketItems();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Activity removed from basket'),
            backgroundColor: Colors.blue),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(responseBody.message ??
                'Failed to remove activity from basket'),
            backgroundColor: Colors.red),
      );
    }
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _loginController;
  late TextEditingController _passwordController;
  late TextEditingController _birthdayController;
  late TextEditingController _addressController;
  late TextEditingController _postalCodeController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
    _birthdayController = TextEditingController();
    _addressController = TextEditingController();
    _postalCodeController = TextEditingController();
    _cityController = TextEditingController();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You are not logged in.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:3030/profile'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final profileData = json.decode(response.body);
      setState(() {
        _loginController.text = profileData['login'] ?? '';
        _birthdayController.text = profileData['birthday'] ?? '';
        _addressController.text = profileData['address'] ?? '';
        _postalCodeController.text = profileData['postalCode'] ?? '';
        _cityController.text = profileData['city'] ?? '';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to fetch profile data'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _updateProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You are not logged in.'),
          backgroundColor: Colors.red));
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3030/profile/update'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "password": _passwordController.text,
        "birthday": _birthdayController.text,
        "address": _addressController.text,
        "postalCode": _postalCodeController.text,
        "city": _cityController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Login'),
              readOnly: true,
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _birthdayController,
              decoration: const InputDecoration(labelText: 'Birthday'),
              keyboardType: TextInputType.datetime,
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _postalCodeController,
              decoration: const InputDecoration(labelText: 'Postal Code'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Update Profile'),
            ),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _register() async {
    var url = Uri.parse('http://localhost:3030/register');
    var response = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "login": _usernameController.text,
          "password": _passwordController.text,
        }));

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Successfully registered
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Registration successful'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Navigate back to login page
    } else {
      // Registration failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(body.message ?? 'Registration failed'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
