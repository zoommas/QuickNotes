import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteEditor extends StatefulWidget {
  final DocumentSnapshot? note; // nullable for new note

  const NoteEditor({super.key, this.note});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  bool isSaving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?['title'] ?? '');
    contentController = TextEditingController(text: widget.note?['content'] ?? '');
  }

  Future<void> saveNote() async {
    setState(() {
      isSaving = true;
      error = null;
    });

    final user = FirebaseAuth.instance.currentUser!;
    try {
      final notes = FirebaseFirestore.instance.collection('notes');
      if (widget.note != null) {
        // Update existing note
        await notes.doc(widget.note!.id).update({
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new note
        await notes.add({
          'uid': user.uid,
          'title': titleController.text.trim(),
          'content': contentController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        error = 'Failed to save note: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Note' : 'New Note')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: saveNote,
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}