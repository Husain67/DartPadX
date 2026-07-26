#!/bin/bash
# Adding format button
sed -i '/_buildButton(/i \
          _buildButton(\
            icon: Icons.format_align_left_outlined,\
            label: '\''Format'\'',\
            onTap: () => _formatCode(ref),\
          ),' lib/ui/widgets/toolbar.dart
