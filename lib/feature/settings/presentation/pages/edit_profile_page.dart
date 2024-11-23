import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:scribettefix/feature/context/domain/extensions/context_extension.dart';
import 'package:scribettefix/feature/ming_cute_icons/presentation/widgets/ming_cute_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EditProfilePageState();
  }
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;
  File? _profileImage;

  String? email;
  String? name;

  @override
  void initState() {
    super.initState();

    getEmail().then((value) {
      setState(() {
        email = value;
      });
      if (email != null) {
        getUserName(email!).then((value2) {
          setState(() {
            name = value2;
            _nameController.text = name ?? '';
            _emailController.text = email ?? '';
          });
        });
      }
    }).catchError((error) {});
  }

  Future<String?> getEmail() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('email');
    } catch (e) {
      return null;
    }
  }

  Future<String?> getUserName(String email) async {
    try {
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      DocumentSnapshot documentSnapshot = await users.doc(email).get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> userData =
            documentSnapshot.data() as Map<String, dynamic>;
        return userData['name'];
      } else {
        return null;
      }
    } catch (error) {
      return null;
    }
  }

  Future<String?> getProfileImageUrl(String email) async {
    try {
      final profileImageRef =
          FirebaseStorage.instance.ref().child("profile_images/$email.jpg");
      String downloadURL = await profileImageRef.getDownloadURL();
      return downloadURL;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // Subir la imagen a Firebase Storage
      await _uploadProfileImage(_profileImage!);
    }
  }

  Future<void> _uploadProfileImage(File image) async {
    final storageRef =
        FirebaseStorage.instance.ref().child("profile_images/$email.jpg");
    await storageRef.putFile(image);
    String downloadURL = await storageRef.getDownloadURL();

    // Actualizar la URL de la imagen en Firestore
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    await users.doc(email).update({'profileImageUrl': downloadURL});
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          CollectionReference users =
              FirebaseFirestore.instance.collection('users');
          await users.doc(email).update({
            'name': _nameController.text,
            'email': _emailController.text,
          });
          if (context.mounted) {
            final ctxt = context;
            ScaffoldMessenger.of(ctxt).showSnackBar(
              SnackBar(
                content: Text(ctxt.lang!.successUpdate),
              ),
            );
          }
        }
      } catch (error) {
        if (context.mounted) {
          final ctxt = context;
          ScaffoldMessenger.of(ctxt).showSnackBar(
            SnackBar(
              content: Text(ctxt.lang!.errorUpdate),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            MingCuteIcons.mgcLeftFill,
            color: Color(0xFFC9CAD1),
          ),
          onPressed: () {
            _saveChanges();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: const Color(0xFF262D47),
            ),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _saveChanges();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: FutureBuilder<String?>(
                  future: email != null
                      ? getProfileImageUrl(email!)
                      : Future.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFFF7BD03)),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(snapshot.data!),
                            radius: 50,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                        ],
                      );
                    } else {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage(
                                    'assets/default_profile.png',
                                  ) as ImageProvider,
                            radius: 50,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.lang!.editProfileText,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF252D47),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                hint: context.lang!.nameTextLabel, // Name // nameTextLabel
                icon: MingCuteIcons.mgcUser3Fill,
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                hint: context.lang!.emailTextLabel, // Email // emailTextLabel
                icon: MingCuteIcons.mgcMailFill,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
              ),
              const SizedBox(height: 24),
              // Log Out Button
              TextButton.icon(
                onPressed: () async {
                  _showDeleteConfirmationDialog(context);
                },
                icon:
                    const Icon(MingCuteIcons.mgcDeleteFill, color: Colors.red),
                label: Text(
                  context.lang!
                      .deleteAccountLabel, // Delete Account // deleteAccountLabel
                  style: GoogleFonts.montserrat(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE8EFFF),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFE8EFFF),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF545A78),
          size: 20,
        ),
      ),
      validator: validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return context.lang!.missingFields(
                  hint); // "Please enter your $hint" // missingFields
            }
            return null;
          },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            context.lang!
                .deleteAccountLabel, // Delete Account // deleteAccountLabel
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1e2337),
            ),
          ),
          content: Text(
            context.lang!
                .sureAboutDeleteAccount, // Are you sure you want to delete your account? // sureAboutDeleteAccount
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: const Color(0xFF545A78),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.cancel,
                    label: context.lang!.cancelLabel, // Cancel // cancelLabel
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.delete,
                    label: context.lang!.deleteLabel, // delete // deleteLabel
                    onPressed: () async {
                      Navigator.of(context).pop();
                      _handleDeleteAccount(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    _showReauthenticationDialog(context, (password) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);
        await user.delete();
      }
    });
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          backgroundColor: const Color(0xFFE8EFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(color: const Color(0xFF545A78)),
              ),
              Icon(
                icon,
                color: const Color(0xFF545A78),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReauthenticationDialog(
      BuildContext context, Function(String) onReauthenticated) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          title: Text(
            context.lang!
                .reauthenticateTitle, // Re-authenticate // reauthenticateTitle
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1e2337),
            ),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            cursorColor: const Color(0xFF1e2337),
            decoration: InputDecoration(
              labelText: context
                  .lang!.passwordTextLabel, // Password // passwordTextLabel
              labelStyle:
                  GoogleFonts.montserrat(color: const Color(0xFF545A78)),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFF545A78)),
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFF1e2337), width: 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.cancel,
                    label: context.lang!.cancelLabel, // Cancel // cancelLabel
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showDeleteConfirmationDialog(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.check,
                    label: context.lang!.sumbitLabel, // Sumbit // sumbitLabel
                    onPressed: () {
                      final password = passwordController.text;
                      Navigator.of(context).pop();
                      onReauthenticated(password);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
