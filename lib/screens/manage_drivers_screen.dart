import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});

  @override
  State<ManageDriversScreen> createState() =>
      _ManageDriversScreenState();
}

class _ManageDriversScreenState

    extends State<ManageDriversScreen> {
      final nameController = TextEditingController();
final emailController = TextEditingController();
final phoneController = TextEditingController();
final licenseController =
    TextEditingController();
bool isDeleting = false;
 List<Map<String, dynamic>> drivers = [];

  Future<void> loadDrivers() async {
  final data = await Supabase.instance.client
      .from('users')
      .select()
      .eq('role', 'Driver');

  setState(() {
    drivers = List<Map<String, dynamic>>.from(data);
  });
}
@override
void initState() {
  super.initState();
  loadDrivers();
}
  Widget build(BuildContext context) {
  return Stack(
  children: [

    Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text("Manage Drivers"),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE53935),

        onPressed: _showAddDriverDialog,

        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),

        label: const Text(
          "Add Driver",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Registered Drivers",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Manage all ambulance drivers",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                hintText: "Search Driver...",
                prefixIcon:
                    const Icon(Icons.search),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: drivers.length,

                itemBuilder:
                    (context, index) {

                  final driver =
                      drivers[index];

                  return Container(
                    margin:
                        const EdgeInsets.only(
                            bottom: 15),

                    padding:
                        const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                              20),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),

                          blurRadius: 10,
                          offset:
                              const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [

                        const CircleAvatar(
                          radius: 25,
                          backgroundColor:
                              Color(0xFFFFEBEE),

                          child: Icon(
                            Icons.person,
                            color:
                                Color(0xFFE53935),
                          ),
                        ),

                        const SizedBox(
                          width: 15,
                        ),

                      Expanded(
  child: Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [

      Text(
        driver["name"] ?? "No Name",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 5),

      Text(
        "📞 ${driver["phone"] ?? ""}",
      ),

      const SizedBox(height: 5),

      Text(
        "License: ${driver["license_number"] ?? ""}",
      ),
    ],
  ),
),
                        Row(
  mainAxisSize: MainAxisSize.min,
  children: [

    IconButton(
      icon: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
     onPressed: () async {

  final confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Delete Driver?"),
      content: const Text(
        "This action cannot be undone.",
      ),
      actions: [

        TextButton(
          onPressed: () =>
              Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, true),
          child: const Text("Delete"),
        ),
      ],
    ),
  );

  if (confirm == true) {
setState(() {
  isDeleting = true;
});
   await Supabase.instance.client
    .functions
    .invoke(
  'delete-driver',
  body: {
    'driverId': driver['id'],
  },
);

await loadDrivers();
setState(() {
  isDeleting = false;
});
  }
},
    ),

    const Icon(
      Icons.arrow_forward_ios,
    ),
  ],
),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
    ),
    if (isDeleting)
  Container(
    color: Colors.black.withOpacity(0.3),
    child: const Center(
      child: CircularProgressIndicator(),
    ),
  ),],);
  }

  void _showAddDriverDialog() {

    showDialog(
      context: context,

      builder: (_) {

        return AlertDialog(
          title:
              const Text("Register Driver"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [

                TextField(
  controller: nameController,
  decoration: const InputDecoration(
    labelText: "Driver Name",
  ),
),

TextField(
  controller: emailController,
  decoration: const InputDecoration(
    labelText: "Driver Email",
  ),
),

TextField(
  controller: phoneController,
  decoration: const InputDecoration(
    labelText: "Phone Number",
  ),
),
TextField(
  controller: licenseController,
  decoration: const InputDecoration(
    labelText: "Driving License Number",
  ),
),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child:
                  const Text("Cancel"),
            ),

            ElevatedButton(
             onPressed: () async {

  try {
final userId =
    Supabase.instance.client.auth.currentUser!.id;

final response =
    await Supabase.instance.client.functions.invoke(
  'create-driver',
  body: {
    'name': nameController.text,
    'email': emailController.text,
    'phone': phoneController.text,
    'licenseNumber':
        licenseController.text,
    'hospitalId': userId,
  },
);

print(response.data);
await loadDrivers();
nameController.clear();
emailController.clear();
phoneController.clear();
licenseController.clear();
Navigator.pop(context);

showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text("Driver Created"),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email:\n${response.data['email']}",
        ),
        const SizedBox(height: 15),
        Text(
          "Temporary Password:\n${response.data['password']}",
        ),
        const SizedBox(height: 15),
        const Text(
          "Tell the driver to login and use Forgot Password if they want to change it.",
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {

  nameController.clear();
  emailController.clear();
  phoneController.clear();
  licenseController.clear();

  Navigator.pop(context);
},
        child: const Text("OK"),
      ),
    ],
  ),
);

} catch (e) {
  print(e);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.toString()),
    ),
  );
}},
              child: const Text("Register"),
            ),
          ],
        );
      },
    );
  }
}