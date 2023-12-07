import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectShareOptionContainer extends ConsumerStatefulWidget {
  const SelectShareOptionContainer({Key? key}) : super(key: key);

  @override
  ConsumerState<SelectShareOptionContainer> createState() =>
      _SelectShareOptionContainerState();
}

class Model {
  String title;
  IconData icon;
  int index = -1;
  Color? color;

  Model({required this.title, required this.icon, this.color});
}

class _SelectShareOptionContainerState
    extends ConsumerState<SelectShareOptionContainer> {
  List<Model> items = [
    Model(
      title: 'Document',
      icon: Icons.file_copy,
      color: Colors.deepPurple,
    ),
    Model(
      title: 'Camera',
      icon: Icons.camera_alt,
      color: Colors.pink,
    ),
    Model(
      title: 'Gallery',
      icon: Icons.photo_rounded,
      color: Colors.purple,
    ),
    Model(
      title: 'Audio',
      icon: Icons.headphones,
      color: Colors.orange,
    ),
    Model(
      title: 'Location',
      icon: Icons.location_on,
      color: Colors.green,
    ),
    Model(
      title: 'Contact',
      icon: Icons.person,
      color: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical:10),
      // height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15)
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 0,
        children: items
            .map(
              (e) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: e.color ?? Colors.red,
                        child: Icon(
                          e.icon,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      e.title,
                      style: const TextStyle(color: Colors.grey),
                    )
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
