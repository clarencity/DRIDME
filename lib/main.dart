import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(SecureUploaderApp());
}

class SecureUploaderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Tools',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: SecureHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SecureHomePage extends StatefulWidget {
  @override
  _SecureHomePageState createState() => _SecureHomePageState();
}

class _SecureHomePageState extends State<SecureHomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  String _selectedState = 'NC';
  final List<String> _usStates = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY'
  ];

  List<PlatformFile> _selectedFiles = [];
  bool _uploading = false;
  bool _sendingMessage = false;
  String _activeTab = 'upload';
  bool _isEditingProfile = false;

  final String fileUploadUrl = "https://webhook.site/YOUR_FILE_UPLOAD_ID";
  final String messageSendUrl = "https://webhook.site/YOUR_MESSAGE_ID";

  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? '';
      _userEmail = prefs.getString('userEmail') ?? '';
      _userPhone = prefs.getString('userPhone') ?? '';
      _phoneController.text = _userPhone;
      _addressController.text = prefs.getString('address') ?? '';
      _cityController.text = prefs.getString('city') ?? '';
      _selectedState = prefs.getString('state') ?? 'NC';
      _zipController.text = prefs.getString('zip') ?? '';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    await prefs.setString('userEmail', _userEmail);
    await prefs.setString('userPhone', _userPhone);
    await prefs.setString('address', _addressController.text);
    await prefs.setString('city', _cityController.text);
    await prefs.setString('state', _selectedState);
    await prefs.setString('zip', _zipController.text);
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _selectedFiles = result.files;
      });
    }
  }

  Future<void> _uploadFiles() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _uploading = true);
    for (var file in _selectedFiles) {
      try {
        var uri = Uri.parse(fileUploadUrl);
        var request = http.MultipartRequest('POST', uri);
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
        var response = await request.send();
        if (response.statusCode == 200) {
          print("✅ Uploaded ${file.name}");
        } else {
          print("❌ Upload failed: ${response.statusCode}");
        }
      } catch (e) {
        print("⚠️ Upload error: $e");
      }
    }
    setState(() => _uploading = false);
  }

  Future<void> _sendSecureMessage() async {
    final email = _emailController.text.trim();
    final message = _messageController.text.trim();
    if (email.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Both email and message are required.")),
      );
      return;
    }
    setState(() => _sendingMessage = true);
    try {
      final response = await http.post(
        Uri.parse(messageSendUrl),
        body: {'to': email, 'message': message},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Secure message sent.")),
        );
        _emailController.clear();
        _messageController.clear();
      } else {
        print("❌ Failed to send message.");
      }
    } catch (e) {
      print("⚠️ Message error: $e");
    }
    setState(() => _sendingMessage = false);
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = picked);
    }
  }

  Widget _buildProfileUI() {
    return Column(
      children: [
        SizedBox(height: 20),
        GestureDetector(
          onTap: _isEditingProfile ? _pickProfileImage : null,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _profileImage != null
                ? FileImage(File(_profileImage!.path))
                : AssetImage('assets/avatar_placeholder.png') as ImageProvider,
            child: _isEditingProfile
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, size: 16, color: Colors.indigo),
                    ),
                  )
                : null,
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(labelText: 'Name'),
          controller: TextEditingController(text: _userName),
          onChanged: _isEditingProfile ? (val) => _userName = val : null,
          readOnly: !_isEditingProfile,
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(labelText: 'Email'),
          controller: TextEditingController(text: _userEmail),
          onChanged: _isEditingProfile ? (val) => _userEmail = val : null,
          keyboardType: TextInputType.emailAddress,
          readOnly: !_isEditingProfile,
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(labelText: 'Phone Number'),
          controller: _phoneController,
          onChanged: _isEditingProfile
              ? (val) {
                  String digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length >= 10) {
                    final formatted =
                        '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
                    _phoneController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                  _userPhone = _phoneController.text;
                }
              : null,
          keyboardType: TextInputType.phone,
          readOnly: !_isEditingProfile,
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(labelText: 'Mailing Address'),
          controller: _addressController,
          readOnly: !_isEditingProfile,
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(labelText: 'City'),
          controller: _cityController,
          readOnly: !_isEditingProfile,
        ),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: InputDecoration(labelText: 'State'),
          items: _usStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: _isEditingProfile
              ? (value) {
                  setState(() => _selectedState = value!);
                }
              : null,
        ),
        SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(labelText: 'Zip Code'),
          controller: _zipController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          readOnly: !_isEditingProfile,
        ),
        SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            if (_isEditingProfile) {
              final phone = _phoneController.text.trim();
              final zip = _zipController.text.trim();
              final phoneRegExp = RegExp(r'^(\(\d{3}\)\s\d{3}-\d{4})\$');
              final zipRegExp = RegExp(r'^\d{5}(?:[-\s]\d{4})?\$');
              if (!phoneRegExp.hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("⚠️ Enter a valid phone number.")),
                );
                return;
              }
              if (!zipRegExp.hasMatch(zip)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("⚠️ Enter a valid ZIP code.")),
                );
                return;
              }
              _saveProfile();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("✅ Profile saved")),
              );
            }
            setState(() => _isEditingProfile = !_isEditingProfile);
          },
          icon: Icon(_isEditingProfile ? Icons.save : Icons.edit),
          label: Text(_isEditingProfile ? "Save Profile" : "Edit Profile"),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => print("🚪 Log out tapped"),
          icon: Icon(Icons.logout),
          label: Text("Log Out"),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeaderBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Icon(Icons.shield, color: Colors.indigo),
          SizedBox(width: 8),
          Text("Secure Tools",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo)),
        ]),
        if (_uploading || _sendingMessage)
          CircularProgressIndicator(color: Colors.indigo, strokeWidth: 2),
      ],
    );
  }

  Widget _buildIconTabs() {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconTab('upload', Icons.folder, 'Upload Files'),
          _buildIconTab('email', Icons.email, 'Secure Message'),
          _buildIconTab('wearable', Icons.watch, 'Wearables'),
          _buildIconTab('profile', Icons.person, 'Profile'),
        ],
      ),
      SizedBox(height: 12),
      Divider(thickness: 1, color: Colors.grey.shade300),
    ]);
  }

  Widget _buildIconTab(String key, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          IconButton(
            icon: Icon(icon,
                size: 48,
                color: _activeTab == key ? Colors.indigo : Colors.grey),
            onPressed: () => setState(() => _activeTab = key),
          ),
          Text(key[0].toUpperCase() + key.substring(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _activeTab == key ? Colors.indigo : Colors.grey,
              ))
        ],
      ),
    );
  }

  Widget _buildFileUploadUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickFiles,
          icon: Icon(Icons.upload_file),
          label: Text('Pick Files'),
        ),
        SizedBox(height: 10),
        if (_selectedFiles.isNotEmpty)
          ElevatedButton.icon(
            onPressed: _uploading ? null : _uploadFiles,
            icon: Icon(Icons.cloud_upload),
            label: Text(_uploading ? 'Uploading...' : 'Upload Files'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        SizedBox(height: 10),
        if (_selectedFiles.isNotEmpty)
          ..._selectedFiles.map((file) {
            final isImage = file.name.toLowerCase().endsWith('.png') ||
                file.name.toLowerCase().endsWith('.jpg') ||
                file.name.toLowerCase().endsWith('.jpeg') ||
                file.name.toLowerCase().endsWith('.gif');
            return ListTile(
              leading: isImage && file.bytes != null
                  ? Image.memory(file.bytes!,
                      width: 40, height: 40, fit: BoxFit.cover)
                  : Icon(Icons.insert_drive_file),
              title: Text(file.name),
              subtitle: Text('${(file.size / 1024).toStringAsFixed(2)} KB'),
            );
          }),
      ],
    );
  }

  Widget _buildSecureMessageUI() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: InputDecoration(labelText: 'Recipient Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 10),
        TextField(
          controller: _messageController,
          decoration: InputDecoration(labelText: 'Secure Message'),
          maxLines: 4,
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _sendingMessage ? null : _sendSecureMessage,
          icon: Icon(Icons.send, color: Colors.white),
          label: Text(_sendingMessage ? 'Sending...' : 'Send Secure Message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWearablesUI() {
    final metrics = [
      {'label': 'Heart Rate', 'value': '76 bpm', 'icon': Icons.favorite},
      {'label': 'Steps Today', 'value': '8,542', 'icon': Icons.directions_walk},
      {'label': 'Sleep Duration', 'value': '7h 12m', 'icon': Icons.bed},
      {'label': 'Oxygen Level', 'value': '98%', 'icon': Icons.bubble_chart},
      {
        'label': 'Calories Burned',
        'value': '412 kcal',
        'icon': Icons.local_fire_department
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wearable Health Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        ...metrics.map((metric) => Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(metric['icon'] as IconData,
                    color: Colors.indigo, size: 32),
                title: Text(metric['label'] as String),
                subtitle: Text(metric['value'] as String,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBar(),
            SizedBox(height: 20),
            _buildIconTabs(),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Builder(
                  builder: (_) {
                    switch (_activeTab) {
                      case 'upload':
                        return _buildFileUploadUI();
                      case 'email':
                        return _buildSecureMessageUI();
                      case 'wearable':
                        return _buildWearablesUI();
                      case 'profile':
                        return _buildProfileUI();
                      default:
                        return Center(child: Text("Select an option above"));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
