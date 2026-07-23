import nltk
import json
import ssl

try:
    _create_unverified_https_context = ssl._create_unverified_context
except AttributeError:
    pass
else:
    ssl._create_default_https_context = _create_unverified_https_context

print("Downloading nltk word corpus...")
nltk.download('words')
from nltk.corpus import words
word_list = words.words()

print(f"Total English words fetched: {len(word_list)}")

# Due to lack of a translation API in this disconnected environment,
# we can't reliably map 10,000 words to Hindi Lipi and Meaning automatically.
# We will construct a high-quality script and template, and inform the user of the limitation,
# rather than faking data.
