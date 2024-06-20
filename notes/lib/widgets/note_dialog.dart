import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';
import 'package:notes/services/location_service.dart';
import 'package:notes/services/note_service.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;

  NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _imageFile;
  Position? _position;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
    }
  }

  Future<void> _getLocation() async {
    final location = await LocationService().getCurrentLocaton();
    setState(() {
      _position = location;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Notes' : 'Update Notes'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Title: ',
            textAlign: TextAlign.start,
          ),
          TextField(
            controller: _titleController,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'Description: ',
            ),
          ),
          TextField(
            controller: _descriptionController,
          ),
          const Padding(
            padding: EdgeInsets.only(
              top: 20,
            ),
            child: Text('Image : '),
          ),
          Expanded(
            child: _imageFile != null
                ? Image.file(io.File(_imageFile!.path), fit: BoxFit.cover)
                : (widget.note?.imageUrl != null &&
                        Uri.parse(widget.note!.imageUrl!).isAbsolute
                    ? Image.network(
                        widget.note!.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container()),
          ),
          TextButton(
            onPressed: () => _showImageSourceActionSheet(context),
            child: const Text('Pick Image : '),
          ),
          TextButton(
            onPressed: _getLocation,
            child: const Text('Get Location : '),
          ),
          Text(
            _position?.latitude != null && _position?.longitude != null
                ? "Current Location =: ${_position!.latitude.toString()}, ${_position!.longitude.toString()} "
                : "Current Location =: ${widget.note?.lat}, ${widget.note?.lng}",
            textAlign: TextAlign.start,
          )
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            String? imageUrl;

            // Cek apakah ada gambar yang dipilih
            if (_imageFile != null) {
              // Jika ada gambar dipilih, unggah gambar ke server
              imageUrl = await NoteService.uploadImage(_imageFile!);
            } else {
              imageUrl = widget.note?.imageUrl;
            }

            // Ambil lokasi saat ini jika tidak ada lokasi yang tersedia sebelumnya
            String latitude = _position?.latitude.toString() ??
                widget.note?.lat.toString() ??
                "";
            String longitude = _position?.longitude.toString() ??
                widget.note?.lng.toString() ??
                "";

            // Buat objek Note sesuai kondisi
            Note note = Note(
              id: widget.note?.id,
              title: _titleController.text,
              description: _descriptionController.text,
              imageUrl:
                  imageUrl, // imageUrl bisa null jika tidak ada gambar yang dipilih
              lat: latitude,
              lng: longitude,
              createdAt: widget.note?.createdAt,
            );

            // Jika sedang menambah catatan baru
            if (widget.note == null) {
              NoteService.addNote(note).whenComplete(() {
                Navigator.of(context).pop();
              });
            } else {
              // Jika sedang memperbarui catatan yang ada
              NoteService.updateNote(note).whenComplete(() {
                Navigator.of(context).pop();
              });
            }
          },
          child: Text(widget.note == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}