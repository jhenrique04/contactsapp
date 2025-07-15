import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../helpers/contact_helper.dart';

class ContactPage extends StatefulWidget {
  final Contact? contact;
  const ContactPage({Key? key, this.contact}) : super(key: key);

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final ContactHelper _helper = ContactHelper();

  late Contact _editedContact;
  late bool _isEditing;
  bool _userEdited = false;

  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _picker    = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _editedContact = widget.contact!.copyWith();
      _isEditing = false;
    } else {
      _editedContact = Contact(id: 0, name: '', email: '', phone: '', img: '');
      _isEditing = true;
    }
    _nameCtrl.text  = _editedContact.name;
    _emailCtrl.text = _editedContact.email;
    _phoneCtrl.text = _editedContact.phone;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_isEditing && _userEdited) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Descartar alterações?'),
          content: const Text(
            'Se você sair, todas as alterações serão perdidas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sim'),
            ),
          ],
        ),
      );
      return discard ?? false;
    }
    return true;
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = true;
      _userEdited = false;
    });
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _editedContact = _editedContact.copyWith(img: file.path);
        _userEdited = true;
      });
    }
  }

  Future<void> _saveForm() async {
    if (_editedContact.name.trim().isEmpty) {
      FocusScope.of(context).requestFocus(_nameFocus);
      return;
    }
    // *** SALVA e recupera o ID ***
    final id = await _helper.updateOrCreateContact(_editedContact);
    if (widget.contact == null) {
      // novo -> atribui o ID retornado e volta com o objeto
      _editedContact = _editedContact.copyWith(id: id);
      Navigator.of(context).pop(_editedContact);
    } else {
      // edição existente -> sai do modo de edição
      setState(() {
        _isEditing = false;
        _userEdited = false;
      });
    }
  }

  void _call() {
    if (_editedContact.phone.isNotEmpty) {
      launchUrlString('tel:${_editedContact.phone}');
    }
  }

  void _email() {
    if (_editedContact.email.isNotEmpty) {
      launchUrlString('mailto:${_editedContact.email}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? (widget.contact == null ? 'Novo Contato' : 'Editar Contato')
        : 'Detalhes';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () async {
              if (await _onWillPop()) Navigator.of(context).pop();
            },
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: _toggleEdit,
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save_outlined, color: Colors.black),
                onPressed: _saveForm,
              ),
          ],
        ),
        body: _isEditing ? _buildForm() : _buildDetails(),
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Center(
          child: CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFFE2DDFF),
            backgroundImage: _editedContact.img.isNotEmpty
                ? FileImage(File(_editedContact.img))
                : null,
            child: _editedContact.img.isEmpty
                ? const Icon(
                    Icons.person,
                    size: 68,
                    color: Colors.black,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _editedContact.name,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Celular',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editedContact.phone,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_outlined, color: Colors.black),
                    onPressed: _call,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Email',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editedContact.email,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.email_outlined, color: Colors.black),
                    onPressed: _email,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(Icons.call_outlined, 'Call', _call),
              const SizedBox(width: 48),
              _actionButton(Icons.email_outlined, 'Email', _email),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: const Color(0xFFE2DDFF),
              backgroundImage: _editedContact.img.isNotEmpty
                  ? FileImage(File(_editedContact.img))
                  : null,
              child: _editedContact.img.isEmpty
                  ? const Icon(Icons.add_a_photo_outlined,
                      size: 68, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            decoration:
                AppInputStyle.inputDecoration('Nome', 'Digite o nome'),
            textCapitalization: TextCapitalization.words,
            onChanged: (v) {
              _userEdited = true;
              _editedContact = _editedContact.copyWith(name: v);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            decoration:
                AppInputStyle.inputDecoration('Email', 'Digite o email'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) {
              _userEdited = true;
              _editedContact = _editedContact.copyWith(email: v);
            },
          ),
          const SizedBox(height: 16),
          InternationalPhoneNumberInput(
            onInputChanged: (PhoneNumber number) {
              _userEdited = true;
              _editedContact =
                  _editedContact.copyWith(phone: number.phoneNumber ?? '');
            },
            initialValue: PhoneNumber(
              isoCode: 'BR',
              phoneNumber: _editedContact.phone,
            ),
            textFieldController: _phoneCtrl,
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
              useBottomSheetSafeArea: true,
            ),
            inputDecoration:
                AppInputStyle.inputDecoration('Telefone', 'Digite o telefone'),
            formatInput: true,
            keyboardType: const TextInputType.numberWithOptions(
                signed: false, decimal: false),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFEDE7F6),
          child: IconButton(
            icon: Icon(icon, size: 24, color: Colors.black),
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      ],
    );
  }
}

class AppInputStyle {
  static InputDecoration inputDecoration(
      String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      fillColor: Colors.white,
      filled: true,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: Colors.blue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: Colors.grey[300]!),
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}
