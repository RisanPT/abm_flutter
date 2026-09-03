import 'package:abm_madrasa/features/website_management/domain/website_content_model.dart';
import 'package:abm_madrasa/features/website_management/presentation/website_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class WebsiteManagementScreen extends ConsumerStatefulWidget {
  const WebsiteManagementScreen({super.key});

  @override
  ConsumerState<WebsiteManagementScreen> createState() => _WebsiteManagementScreenState();
}

class _WebsiteManagementScreenState extends ConsumerState<WebsiteManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late WebsiteContentModel _currentContent;
  final List<MapEntry<String, File>> _selectedImages = [];
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(websiteControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Website Content Management')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (content) {
          if (!_isInitialized) {
            _currentContent = content;
            _isInitialized = true;
          }

          return Form(
            key: _formKey,
            child: DefaultTabController(
              length: 6,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'General (Hero & About)'),
                      Tab(text: 'Committees'),
                      Tab(text: 'Education & Study'),
                      Tab(text: 'Events'),
                      Tab(text: 'News'),
                      Tab(text: 'Media Gallery'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildGeneralTab(),
                        _buildCommitteesTab(),
                        _buildEducationTab(),
                        _buildEventsTab(),
                        _buildNewsTab(),
                        _buildMediaTab(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _saveContent,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Save All Website Content'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveContent() {
    if (_formKey.currentState!.validate()) {
      ref.read(websiteControllerProvider.notifier).updateContent(
        content: _currentContent,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      ).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Website content updated successfully!')),
        );
        _selectedImages.clear();
      });
    }
  }

  Future<void> _pickImage(String fieldName) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.removeWhere((entry) => entry.key == fieldName);
        _selectedImages.add(MapEntry(fieldName, File(pickedFile.path)));
      });
    }
  }

  File? _getImageFile(String fieldName) {
    try {
      return _selectedImages.firstWhere((entry) => entry.key == fieldName).value;
    } catch (e) {
      return null;
    }
  }

  Widget _buildGeneralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Hero Section', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextFormField(
          initialValue: _currentContent.hero.kicker,
          decoration: const InputDecoration(labelText: 'Kicker'),
          onChanged: (val) => _currentContent = _currentContent.copyWith(hero: _currentContent.hero.copyWith(kicker: val)),
        ),
        TextFormField(
          initialValue: _currentContent.hero.titlePrefix,
          decoration: const InputDecoration(labelText: 'Title Prefix'),
          onChanged: (val) => _currentContent = _currentContent.copyWith(hero: _currentContent.hero.copyWith(titlePrefix: val)),
        ),
        TextFormField(
          initialValue: _currentContent.hero.titleHighlight,
          decoration: const InputDecoration(labelText: 'Title Highlight'),
          onChanged: (val) => _currentContent = _currentContent.copyWith(hero: _currentContent.hero.copyWith(titleHighlight: val)),
        ),
        TextFormField(
          initialValue: _currentContent.hero.titleSuffix,
          decoration: const InputDecoration(labelText: 'Title Suffix'),
          onChanged: (val) => _currentContent = _currentContent.copyWith(hero: _currentContent.hero.copyWith(titleSuffix: val)),
        ),
        TextFormField(
          initialValue: _currentContent.hero.subtitle,
          decoration: const InputDecoration(labelText: 'Subtitle'),
          maxLines: 2,
          onChanged: (val) => _currentContent = _currentContent.copyWith(hero: _currentContent.hero.copyWith(subtitle: val)),
        ),
        TextFormField(
          initialValue: _currentContent.hero.description,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
          onChanged: (val) => _currentContent = _currentContent.copyWith(hero: _currentContent.hero.copyWith(description: val)),
        ),
        ListTile(
          title: const Text('Hero Background Image'),
          subtitle: const Text('Recommended: 1920x1080px (max 2MB)'),
          trailing: ElevatedButton(
            onPressed: () => _pickImage('heroImage'),
            child: const Text('Upload'),
          ),
        ),
        if (_getImageFile('heroImage') != null) Text('Selected: ${_getImageFile('heroImage')!.path.split('/').last}'),

        const Divider(height: 48),

        const Text('About Section', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextFormField(
          initialValue: _currentContent.about.heading,
          decoration: const InputDecoration(labelText: 'Heading'),
          onChanged: (val) => _currentContent = _currentContent.copyWith(about: _currentContent.about.copyWith(heading: val)),
        ),
        TextFormField(
          initialValue: _currentContent.about.title,
          decoration: const InputDecoration(labelText: 'Title'),
          onChanged: (val) => _currentContent = _currentContent.copyWith(about: _currentContent.about.copyWith(title: val)),
        ),
        TextFormField(
          initialValue: _currentContent.about.description1,
          decoration: const InputDecoration(labelText: 'Description Paragraph 1'),
          maxLines: 4,
          onChanged: (val) => _currentContent = _currentContent.copyWith(about: _currentContent.about.copyWith(description1: val)),
        ),
        TextFormField(
          initialValue: _currentContent.about.description2,
          decoration: const InputDecoration(labelText: 'Description Paragraph 2'),
          maxLines: 4,
          onChanged: (val) => _currentContent = _currentContent.copyWith(about: _currentContent.about.copyWith(description2: val)),
        ),
        ListTile(
          title: const Text('About Section Image'),
          subtitle: const Text('Recommended: 600x400px (max 2MB)'),
          trailing: ElevatedButton(
            onPressed: () => _pickImage('aboutImage'),
            child: const Text('Upload'),
          ),
        ),
        if (_getImageFile('aboutImage') != null) Text('Selected: ${_getImageFile('aboutImage')!.path.split('/').last}'),
      ],
    );
  }

  Widget _buildCommitteesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Committees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentContent = _currentContent.copyWith(
                    committees: [..._currentContent.committees, const WebsiteCommitteeModel()],
                  );
                });
              },
              child: const Text('Add Committee'),
            ),
          ],
        ),
        for (int i = 0; i < _currentContent.committees.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final list = List<WebsiteCommitteeModel>.from(_currentContent.committees);
                            list.removeAt(i);
                            _currentContent = _currentContent.copyWith(committees: list);
                          });
                        },
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: _currentContent.committees[i].name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    onChanged: (val) {
                      final list = List<WebsiteCommitteeModel>.from(_currentContent.committees);
                      list[i] = list[i].copyWith(name: val);
                      _currentContent = _currentContent.copyWith(committees: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.committees[i].group,
                    decoration: const InputDecoration(labelText: 'Group (e.g., areas, youth)'),
                    onChanged: (val) {
                      final list = List<WebsiteCommitteeModel>.from(_currentContent.committees);
                      list[i] = list[i].copyWith(group: val);
                      _currentContent = _currentContent.copyWith(committees: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.committees[i].description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    onChanged: (val) {
                      final list = List<WebsiteCommitteeModel>.from(_currentContent.committees);
                      list[i] = list[i].copyWith(description: val);
                      _currentContent = _currentContent.copyWith(committees: list);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEducationTab() {
    // Similar implementation for education and study programs...
    return const Center(child: Text('Education & Study Programs Config (Similar to Committees)'));
  }

  Widget _buildEventsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentContent = _currentContent.copyWith(
                    upcomingEvents: [..._currentContent.upcomingEvents, const WebsiteEventModel()],
                  );
                });
              },
              child: const Text('Add Upcoming Event'),
            ),
          ],
        ),
        for (int i = 0; i < _currentContent.upcomingEvents.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                            list.removeAt(i);
                            _currentContent = _currentContent.copyWith(upcomingEvents: list);
                          });
                        },
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].title,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(title: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].date,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD for banner logic)'),
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(date: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].time,
                    decoration: const InputDecoration(labelText: 'Time (e.g., 9:00 AM)'),
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(time: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].location,
                    decoration: const InputDecoration(labelText: 'Location'),
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(location: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].category,
                    decoration: const InputDecoration(labelText: 'Category (e.g., Seminar, Workshop)'),
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(category: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(description: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.upcomingEvents[i].registrationLink,
                    decoration: const InputDecoration(labelText: 'Registration Link (URL)'),
                    onChanged: (val) {
                      final list = List<WebsiteEventModel>.from(_currentContent.upcomingEvents);
                      list[i] = list[i].copyWith(registrationLink: val);
                      _currentContent = _currentContent.copyWith(upcomingEvents: list);
                    },
                  ),
                ],
              ),
            ),
          ),
          
        const Divider(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Past Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentContent = _currentContent.copyWith(
                    pastEvents: [..._currentContent.pastEvents, const WebsitePastEventModel()],
                  );
                });
              },
              child: const Text('Add Past Event'),
            ),
          ],
        ),
        for (int i = 0; i < _currentContent.pastEvents.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final list = List<WebsitePastEventModel>.from(_currentContent.pastEvents);
                            list.removeAt(i);
                            _currentContent = _currentContent.copyWith(pastEvents: list);
                          });
                        },
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: _currentContent.pastEvents[i].title,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                    onChanged: (val) {
                      final list = List<WebsitePastEventModel>.from(_currentContent.pastEvents);
                      list[i] = list[i].copyWith(title: val);
                      _currentContent = _currentContent.copyWith(pastEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.pastEvents[i].date,
                    decoration: const InputDecoration(labelText: 'Date'),
                    onChanged: (val) {
                      final list = List<WebsitePastEventModel>.from(_currentContent.pastEvents);
                      list[i] = list[i].copyWith(date: val);
                      _currentContent = _currentContent.copyWith(pastEvents: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.pastEvents[i].category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    onChanged: (val) {
                      final list = List<WebsitePastEventModel>.from(_currentContent.pastEvents);
                      list[i] = list[i].copyWith(category: val);
                      _currentContent = _currentContent.copyWith(pastEvents: list);
                    },
                  ),
                  ListTile(
                    title: const Text('Event Thumbnail'),
                    trailing: ElevatedButton(
                      onPressed: () => _pickImage('pastEvents_${i}_image'),
                      child: const Text('Upload'),
                    ),
                  ),
                  if (_getImageFile('pastEvents_${i}_image') != null) 
                    Text('Selected: ${_getImageFile('pastEvents_${i}_image')!.path.split('/').last}'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('News Articles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentContent = _currentContent.copyWith(
                    newsArticles: [..._currentContent.newsArticles, const WebsiteNewsModel()],
                  );
                });
              },
              child: const Text('Add News'),
            ),
          ],
        ),
        for (int i = 0; i < _currentContent.newsArticles.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final list = List<WebsiteNewsModel>.from(_currentContent.newsArticles);
                            list.removeAt(i);
                            _currentContent = _currentContent.copyWith(newsArticles: list);
                          });
                        },
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: _currentContent.newsArticles[i].title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    onChanged: (val) {
                      final list = List<WebsiteNewsModel>.from(_currentContent.newsArticles);
                      list[i] = list[i].copyWith(title: val);
                      _currentContent = _currentContent.copyWith(newsArticles: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.newsArticles[i].content,
                    decoration: const InputDecoration(labelText: 'Content'),
                    maxLines: 3,
                    onChanged: (val) {
                      final list = List<WebsiteNewsModel>.from(_currentContent.newsArticles);
                      list[i] = list[i].copyWith(content: val);
                      _currentContent = _currentContent.copyWith(newsArticles: list);
                    },
                  ),
                  ListTile(
                    title: const Text('News Image'),
                    trailing: ElevatedButton(
                      onPressed: () => _pickImage('newsArticles_${i}_image'),
                      child: const Text('Upload'),
                    ),
                  ),
                  if (_getImageFile('newsArticles_${i}_image') != null) 
                    Text('Selected: ${_getImageFile('newsArticles_${i}_image')!.path.split('/').last}'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Videos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentContent = _currentContent.copyWith(
                    videos: [..._currentContent.videos, const WebsiteVideoModel()],
                  );
                });
              },
              child: const Text('Add Video'),
            ),
          ],
        ),
        for (int i = 0; i < _currentContent.videos.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final list = List<WebsiteVideoModel>.from(_currentContent.videos);
                            list.removeAt(i);
                            _currentContent = _currentContent.copyWith(videos: list);
                          });
                        },
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: _currentContent.videos[i].title,
                    decoration: const InputDecoration(labelText: 'Video Title'),
                    onChanged: (val) {
                      final list = List<WebsiteVideoModel>.from(_currentContent.videos);
                      list[i] = list[i].copyWith(title: val);
                      _currentContent = _currentContent.copyWith(videos: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.videos[i].date,
                    decoration: const InputDecoration(labelText: 'Date (e.g. July 14, 2026)'),
                    onChanged: (val) {
                      final list = List<WebsiteVideoModel>.from(_currentContent.videos);
                      list[i] = list[i].copyWith(date: val);
                      _currentContent = _currentContent.copyWith(videos: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.videos[i].duration,
                    decoration: const InputDecoration(labelText: 'Duration (e.g. 4:38)'),
                    onChanged: (val) {
                      final list = List<WebsiteVideoModel>.from(_currentContent.videos);
                      list[i] = list[i].copyWith(duration: val);
                      _currentContent = _currentContent.copyWith(videos: list);
                    },
                  ),
                  TextFormField(
                    initialValue: _currentContent.videos[i].href,
                    decoration: const InputDecoration(labelText: 'YouTube Link (URL)'),
                    onChanged: (val) {
                      final list = List<WebsiteVideoModel>.from(_currentContent.videos);
                      list[i] = list[i].copyWith(href: val);
                      _currentContent = _currentContent.copyWith(videos: list);
                    },
                  ),
                  ListTile(
                    title: const Text('Video Thumbnail Image'),
                    trailing: ElevatedButton(
                      onPressed: () => _pickImage('videos_${i}_image'),
                      child: const Text('Upload'),
                    ),
                  ),
                  if (_getImageFile('videos_${i}_image') != null) 
                    Text('Selected: ${_getImageFile('videos_${i}_image')!.path.split('/').last}'),
                ],
              ),
            ),
          ),
          
        const Divider(height: 48),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Photos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentContent = _currentContent.copyWith(
                    photos: [..._currentContent.photos, const WebsitePhotoModel()],
                  );
                });
              },
              child: const Text('Add Photo'),
            ),
          ],
        ),
        for (int i = 0; i < _currentContent.photos.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            final list = List<WebsitePhotoModel>.from(_currentContent.photos);
                            list.removeAt(i);
                            _currentContent = _currentContent.copyWith(photos: list);
                          });
                        },
                      )
                    ],
                  ),
                  TextFormField(
                    initialValue: _currentContent.photos[i].title,
                    decoration: const InputDecoration(labelText: 'Photo Title'),
                    onChanged: (val) {
                      final list = List<WebsitePhotoModel>.from(_currentContent.photos);
                      list[i] = list[i].copyWith(title: val);
                      _currentContent = _currentContent.copyWith(photos: list);
                    },
                  ),
                  ListTile(
                    title: const Text('Photo Image'),
                    trailing: ElevatedButton(
                      onPressed: () => _pickImage('photos_${i}_image'),
                      child: const Text('Upload'),
                    ),
                  ),
                  if (_getImageFile('photos_${i}_image') != null) 
                    Text('Selected: ${_getImageFile('photos_${i}_image')!.path.split('/').last}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
