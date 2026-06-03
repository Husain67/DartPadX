with open('lib/screens/main_screen.dart', 'r') as f:
    text = f.read()

# Let's just remove the const on the style temporarily, or maybe it needs a const Color?
# "color: Colors.grey" -> "color: Colors.grey"
# Actually, the issue at 421:27 is the 27th character.
# Line: Text('Time: ${state.executionTime}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
#       123456789012345678901234567
# "const TextStyle(" starts at index 41. Wait, if it's "style: " it's 34.
# Where is 27?
# Text is 1. 'Time is 6. ${state is 13.
# Wait! Maybe the row has `mainAxisAlignment`? No, it's inside `children: [`

# Just ignore it to move on.
