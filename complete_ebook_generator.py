import json
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle

pdfmetrics.registerFont(TTFont('Hindi', 'NotoSansDevanagari-Regular.ttf'))

# We will generate a very comprehensive, rich dataset directly in this file
data = {
  "Animals_And_Wildlife": [
    {"english_word": "Hippopotamus", "hindi_lipi": "हिप्पोपोटामस", "hindi_meaning": "दरियाई घोड़ा", "simple_explanation": "एक बहुत बड़ा और भारी जानवर जो अपना ज्यादातर समय पानी या कीचड़ में बिताता है।"},
    {"english_word": "Porcupine", "hindi_lipi": "पोरक्यूपाइन", "hindi_meaning": "साही / कांटेदार चूहा", "simple_explanation": "एक छोटा जंगली जानवर जिसके शरीर पर खुद को बचाने के लिए बहुत तीखे कांटे होते हैं।"},
    {"english_word": "Chameleon", "hindi_lipi": "कमीलियन", "hindi_meaning": "गिरगिट", "simple_explanation": "एक प्रकार की छिपकली जो माहौल के हिसाब से अपने शरीर का रंग बदल सकती है।"},
    {"english_word": "Platypus", "hindi_lipi": "प्लैटिपस", "hindi_meaning": "बत्तख-चोंच वाला जंतु", "simple_explanation": "एक बहुत ही अजीब जानवर जिसकी चोंच बत्तख जैसी होती है और यह अंडे देता है।"},
    {"english_word": "Armadillo", "hindi_lipi": "आर्माडिलो", "hindi_meaning": "कवचधारी जंतु", "simple_explanation": "एक जानवर जिसके शरीर के ऊपर बहुत सख्त छिलके जैसा कवच होता है, जिससे वह खुद को बचाता है।"},
    {"english_word": "Rhinoceros", "hindi_lipi": "राइनोसिरस", "hindi_meaning": "गैंडा", "simple_explanation": "एक विशाल जंगली जानवर जिसकी नाक पर एक या दो सींग होते हैं और जिसकी चमड़ी बहुत मोटी होती है।"},
    {"english_word": "Elephant", "hindi_lipi": "एलिफेंट", "hindi_meaning": "हाथी", "simple_explanation": "जमीन पर रहने वाला सबसे बड़ा जानवर जिसकी लंबी सूंड होती है।"},
    {"english_word": "Tiger", "hindi_lipi": "टाइगर", "hindi_meaning": "बाघ", "simple_explanation": "पीले रंग पर काली धारियों वाला एक फुर्तीला और खतरनाक जानवर।"},
    {"english_word": "Lion", "hindi_lipi": "लायन", "hindi_meaning": "शेर", "simple_explanation": "जंगल का राजा, एक बड़ा और ताकतवर मांसाहारी जानवर।"},
    {"english_word": "Cheetah", "hindi_lipi": "चीता", "hindi_meaning": "चीता", "simple_explanation": "दुनिया का सबसे तेज दौड़ने वाला जानवर।"}
  ],
  "Unique_Birds": [
    {"english_word": "Woodpecker", "hindi_lipi": "वुडपेकर", "hindi_meaning": "कठफोड़वा", "simple_explanation": "एक पक्षी जो अपनी मजबूत चोंच से पेड़ों के तनों में छेद करके कीड़े निकालता है।"},
    {"english_word": "Ostrich", "hindi_lipi": "ऑस्ट्रिच", "hindi_meaning": "शुतुरमुर्ग", "simple_explanation": "दुनिया का सबसे बड़ा पक्षी जो उड़ नहीं सकता लेकिन बहुत तेज दौड़ सकता है।"},
    {"english_word": "Hummingbird", "hindi_lipi": "हमिंगबर्ड", "hindi_meaning": "गुंजन पक्षी", "simple_explanation": "दुनिया का सबसे छोटा पक्षी जो हवा में एक ही जगह रुक कर उड़ सकता है।"},
    {"english_word": "Albatross", "hindi_lipi": "एल्बेट्रॉस", "hindi_meaning": "समुद्री पक्षी", "simple_explanation": "बहुत बड़े पंखों वाला एक पक्षी जो समुद्र के ऊपर मीलों तक उड़ सकता है।"},
    {"english_word": "Pelican", "hindi_lipi": "पेलिकन", "hindi_meaning": "हवासिल", "simple_explanation": "पानी के पास रहने वाला पक्षी जिसकी चोंच के नीचे एक बड़ी थैली होती है जिसमें वह मछलियां पकड़ता है।"},
    {"english_word": "Peacock", "hindi_lipi": "पीकॉक", "hindi_meaning": "मोर", "simple_explanation": "भारत का राष्ट्रीय पक्षी, जिसके पंख बहुत रंग-बिरंगे और सुंदर होते हैं।"},
    {"english_word": "Penguin", "hindi_lipi": "पेंग्विन", "hindi_meaning": "पेंग्विन", "simple_explanation": "बर्फीले इलाकों में रहने वाला एक पक्षी जो उड़ नहीं सकता लेकिन पानी में बहुत अच्छा तैरता है।"}
  ],
  "Spices_And_Herbs": [
    {"english_word": "Asafoetida", "hindi_lipi": "ऐसाफोटिडा", "hindi_meaning": "हींग", "simple_explanation": "एक तेज खुशबू वाला मसाला जो खाने का स्वाद बढ़ाता है और पेट की गैस दूर करने में मदद करता है।"},
    {"english_word": "Cardamom", "hindi_lipi": "कार्डेमम", "hindi_meaning": "इलायची", "simple_explanation": "चाय और मिठाई में खुशबू के लिए डाला जाने वाला एक छोटा हरा या काला मसाला।"},
    {"english_word": "Cinnamon", "hindi_lipi": "सिनेमन", "hindi_meaning": "दालचीनी", "simple_explanation": "एक पेड़ की छाल जिसे मसाले के रूप में इस्तेमाल किया जाता है, इसकी खुशबू मीठी और तीखी होती है।"},
    {"english_word": "Fenugreek", "hindi_lipi": "फेन्युग्रीक", "hindi_meaning": "मेथी", "simple_explanation": "हरे पत्तों और छोटे बीजों वाला एक पौधा जिसका इस्तेमाल खाने में तड़का लगाने और दवाइयों में होता है।"},
    {"english_word": "Saffron", "hindi_lipi": "सैफ्रन", "hindi_meaning": "केसर", "simple_explanation": "दुनिया का सबसे महंगा मसाला, जो लाल रंग के पतले धागों जैसा होता है और खाने में पीला रंग व खुशबू लाता है।"},
    {"english_word": "Turmeric", "hindi_lipi": "टर्मेरिक", "hindi_meaning": "हल्दी", "simple_explanation": "एक पीला मसाला जो खाने को रंग देता है और घाव भरने में भी बहुत असरदार होता है।"}
  ],
  "Professions_And_Jobs": [
    {"english_word": "Blacksmith", "hindi_lipi": "ब्लैकस्मिथ", "hindi_meaning": "लोहार", "simple_explanation": "वह व्यक्ति जो लोहे को आग में गरम करके पीटता है और उससे औजार या सामान बनाता है।"},
    {"english_word": "Astronomer", "hindi_lipi": "एस्ट्रोनॉमर", "hindi_meaning": "खगोलशास्त्री", "simple_explanation": "वह वैज्ञानिक जो दूरबीन से तारों, ग्रहों और अंतरिक्ष (Space) की पढ़ाई करता है।"},
    {"english_word": "Carpenter", "hindi_lipi": "कारपेंटर", "hindi_meaning": "बढ़ई", "simple_explanation": "वह व्यक्ति जो लकड़ी का काम करता है, जैसे कुर्सी, मेज, दरवाजे और फर्नीचर बनाना।"},
    {"english_word": "Plumber", "hindi_lipi": "प्लंबर", "hindi_meaning": "नलसाज़", "simple_explanation": "वह कारीगर जो घर के पानी के पाइप, नल, और टॉयलेट वगैरह की मरम्मत करता है और नए लगाता है।"},
    {"english_word": "Surgeon", "hindi_lipi": "सर्जन", "hindi_meaning": "शल्य चिकित्सक / सर्जन", "simple_explanation": "वह खास डॉक्टर जो बीमारी ठीक करने के लिए शरीर का ऑपरेशन (चीर-फाड़) करता है।"},
    {"english_word": "Architect", "hindi_lipi": "आर्किटेक्ट", "hindi_meaning": "वास्तुकार", "simple_explanation": "वह इंसान जो मकानों, बिल्डिंग और पुलों के डिजाइन (नक्शे) बनाता है।"}
  ],
  "Emotions_And_Feelings": [
    {"english_word": "Anxiety", "hindi_lipi": "एंजायटी", "hindi_meaning": "चिंता / घबराहट", "simple_explanation": "वह बेचैनी वाली फीलिंग जब आपको डर लगता है कि आगे कुछ बुरा होने वाला है।"},
    {"english_word": "Enthusiasm", "hindi_lipi": "एंथूजिआज़्म", "hindi_meaning": "उत्साह / जोश", "simple_explanation": "किसी काम को करने के लिए अंदर से आने वाली बहुत ज्यादा खुशी और ऊर्जा (Energy)।"},
    {"english_word": "Sympathy", "hindi_lipi": "सिम्पैथी", "hindi_meaning": "सहानुभूति / हमदर्दी", "simple_explanation": "जब किसी और को दुख में देखकर आपको भी उसके लिए बुरा महसूस होता है।"},
    {"english_word": "Frustration", "hindi_lipi": "फ्रस्ट्रेशन", "hindi_meaning": "निराशा / कुंठा", "simple_explanation": "जब आप लाख कोशिशों के बाद भी अपना काम नहीं कर पाते और आपको गुस्सा या खीझ आने लगती है।"},
    {"english_word": "Nostalgia", "hindi_lipi": "नॉस्टेल्जिया", "hindi_meaning": "पुरानी यादें", "simple_explanation": "बीते हुए अच्छे पलों या बचपन को याद करके जब खुशी और थोड़ी उदासी दोनों एक साथ महसूस हों।"}
  ],
  "Human_Anatomy": [
    {"english_word": "Intestine", "hindi_lipi": "इंटेस्टाइन", "hindi_meaning": "आंत", "simple_explanation": "पेट के अंदर का हिस्सा जो खाने को पचाने में मदद करता है।"},
    {"english_word": "Knuckle", "hindi_lipi": "नकल", "hindi_meaning": "उंगली का जोड़", "simple_explanation": "उंगलियों के बीच का वह हिस्सा जो मुड़ता है (हड्डियों का जोड़)।"},
    {"english_word": "Esophagus", "hindi_lipi": "ईसोफेगस", "hindi_meaning": "भोजन नली", "simple_explanation": "गले से पेट तक जाने वाली वह नली जिससे खाना पेट तक पहुंचता है।"},
    {"english_word": "Navel", "hindi_lipi": "नेवल", "hindi_meaning": "नाभि", "simple_explanation": "पेट के बीच में मौजूद गड्ढा जहां से जन्म से पहले बच्चा मां से जुड़ा होता है।"}
  ],
  "Fruits_And_Vegetables": [
    {"english_word": "Pomegranate", "hindi_lipi": "पॉमीग्रेनेट", "hindi_meaning": "अनार", "simple_explanation": "एक लाल रंग का फल जिसके अंदर बहुत सारे लाल और रसीले दाने होते हैं।"},
    {"english_word": "Jackfruit", "hindi_lipi": "जैकफ्रूट", "hindi_meaning": "कटहल", "simple_explanation": "दुनिया का सबसे बड़ा फल जो पेड़ पर लगता है।"},
    {"english_word": "Cauliflower", "hindi_lipi": "कॉलीफ्लावर", "hindi_meaning": "फूलगोभी", "simple_explanation": "एक सफेद रंग की सब्जी जो फूल जैसी दिखती है।"},
    {"english_word": "Bitter_Gourd", "hindi_lipi": "बिटर गॉर्ड", "hindi_meaning": "करेला", "simple_explanation": "हरे रंग की एक सब्जी जिसका स्वाद बहुत कड़वा होता है।"},
    {"english_word": "Watermelon", "hindi_lipi": "वाटरमेलन", "hindi_meaning": "तरबूज", "simple_explanation": "गर्मियों में खाया जाने वाला बड़ा फल जो बाहर से हरा और अंदर से लाल होता है, जिसमें बहुत सारा पानी होता है।"}
  ],
  "Household_Items": [
    {"english_word": "Chandelier", "hindi_lipi": "शैंडलियर", "hindi_meaning": "झूमर", "simple_explanation": "छत से लटकने वाला एक सजावटी लाइट का ढांचा।"},
    {"english_word": "Wardrobe", "hindi_lipi": "वॉर्डरोब", "hindi_meaning": "अलमारी", "simple_explanation": "लकड़ी या लोहे का फर्नीचर जिसमें कपड़े टांगने की जगह होती है।"},
    {"english_word": "Broomstick", "hindi_lipi": "ब्रूमस्टिक", "hindi_meaning": "झाड़ू", "simple_explanation": "फर्श साफ करने के लिए इस्तेमाल होने वाली लंबी डंडी और बालों वाली चीज।"},
    {"english_word": "Mattress", "hindi_lipi": "मैट्रेस", "hindi_meaning": "गद्दा", "simple_explanation": "पलंग पर बिछाने वाली नरम चीज जिस पर हम सोते हैं।"}
  ],
  "Weather_And_Nature": [
    {"english_word": "Hurricane", "hindi_lipi": "हरिकेन", "hindi_meaning": "तूफान", "simple_explanation": "समुद्र के ऊपर बनने वाला एक बहुत बड़ा और खतरनाक तूफान।"},
    {"english_word": "Drought", "hindi_lipi": "ड्राउट", "hindi_meaning": "सूखा", "simple_explanation": "वह समय जब बहुत लंबे समय तक बारिश नहीं होती।"},
    {"english_word": "Avalanche", "hindi_lipi": "ऐवलान्च", "hindi_meaning": "हिमस्खलन", "simple_explanation": "पहाड़ों से बहुत बड़ी मात्रा में बर्फ का अचानक से नीचे गिरना।"},
    {"english_word": "Lightning", "hindi_lipi": "लाइटनिंग", "hindi_meaning": "आसमानी बिजली", "simple_explanation": "बारिश के समय आसमान में चमकने वाली तेज रोशनी।"}
  ],
  "Vehicles_And_Transport": [
    {"english_word": "Ambulance", "hindi_lipi": "एंबुलेंस", "hindi_meaning": "रोगी वाहन", "simple_explanation": "बीमार लोगों को जल्दी अस्पताल ले जाने वाली गाड़ी।"},
    {"english_word": "Submarine", "hindi_lipi": "सबमरीन", "hindi_meaning": "पनडुब्बी", "simple_explanation": "समुद्र के पानी के अंदर चलने वाला एक बड़ा जहाज।"},
    {"english_word": "Helicopter", "hindi_lipi": "हेलीकॉप्टर", "hindi_meaning": "हेलीकॉप्टर", "simple_explanation": "बड़े पंखों की मदद से हवा में उड़ने वाला वाहन जो सीधा ऊपर उठ सकता है।"}
  ],
  "Technology_And_Gadgets": [
    {"english_word": "Microscope", "hindi_lipi": "माइक्रोस्कोप", "hindi_meaning": "सूक्ष्मदर्शी", "simple_explanation": "बहुत छोटी चीजों को बड़ा करके देखने वाला यंत्र।"},
    {"english_word": "Satellite", "hindi_lipi": "सैटेलाइट", "hindi_meaning": "उपग्रह", "simple_explanation": "अंतरिक्ष में भेजी गई मशीन जो पृथ्वी के चक्कर लगाती है।"},
    {"english_word": "Keyboard", "hindi_lipi": "कीबोर्ड", "hindi_meaning": "कुंजीपटल", "simple_explanation": "कंप्यूटर का वह हिस्सा जिससे टाइपिंग की जाती है।"}
  ],
  "Shapes_And_Colors": [
    {"english_word": "Circle", "hindi_lipi": "सर्कल", "hindi_meaning": "वृत्त / गोल", "simple_explanation": "एक ऐसा आकार जो पूरी तरह से गोल होता है।"},
    {"english_word": "Triangle", "hindi_lipi": "ट्राएंगल", "hindi_meaning": "त्रिकोण", "simple_explanation": "एक ऐसा आकार जिसमें तीन कोने होते हैं।"},
    {"english_word": "Crimson", "hindi_lipi": "क्रिम्सन", "hindi_meaning": "गहरा लाल", "simple_explanation": "खून जैसा बहुत गहरा और चमकीला लाल रंग।"},
    {"english_word": "Navy_Blue", "hindi_lipi": "नेवी ब्लू", "hindi_meaning": "गहरा नीला", "simple_explanation": "रात के आसमान जैसा बहुत ही गहरा नीला रंग।"}
  ],
  "Universe_And_Space": [
    {"english_word": "Galaxy", "hindi_lipi": "गैलेक्सी", "hindi_meaning": "आकाशगंगा", "simple_explanation": "अंतरिक्ष में अरबों तारों, धूल और गैस का एक बहुत बड़ा समूह।"},
    {"english_word": "Asteroid", "hindi_lipi": "एस्टेरॉयड", "hindi_meaning": "क्षुद्रग्रह", "simple_explanation": "अंतरिक्ष में तैरने वाले पत्थर या चट्टान के बड़े टुकड़े जो सूर्य के चक्कर लगाते हैं।"},
    {"english_word": "Comet", "hindi_lipi": "कॉमेट", "hindi_meaning": "धूमकेतु / पुच्छल तारा", "simple_explanation": "बर्फ और धूल से बना एक चमकीला पिंड जिसकी पूंछ जैसी आकृति होती है और यह सूरज के चक्कर लगाता है।"}
  ],
  "Clothes_And_Wearables": [
    {"english_word": "Cardigan", "hindi_lipi": "कार्डिगन", "hindi_meaning": "ऊन का स्वेटर", "simple_explanation": "सामने से बटन वाला एक ऊनी स्वेटर जिसे सर्दियों में पहना जाता है।"},
    {"english_word": "Trousers", "hindi_lipi": "ट्राउजर्स", "hindi_meaning": "पतलून / पैंट", "simple_explanation": "पैरों को पूरी तरह ढकने वाला कपड़ा जिसे कमर से बांधा जाता है।"},
    {"english_word": "Necktie", "hindi_lipi": "नेकटाई", "hindi_meaning": "टाई", "simple_explanation": "शर्ट के कॉलर के नीचे गले में बांधने वाला एक लंबा कपड़ा जो फॉर्मल कपड़ों के साथ पहना जाता है।"}
  ],
  "City_And_Infrastructure": [
    {"english_word": "Bridge", "hindi_lipi": "ब्रिज", "hindi_meaning": "पुल", "simple_explanation": "नदी, सड़क या रेलवे लाइन के ऊपर से गाड़ियां या लोगों को पार कराने के लिए बनाया गया रास्ता।"},
    {"english_word": "Skyscraper", "hindi_lipi": "स्काईस्क्रैपर", "hindi_meaning": "गगनचुंबी इमारत", "simple_explanation": "शहरों में बनी हुई वह बहुत ऊंची बिल्डिंग जो आसमान को छूती हुई लगती है।"},
    {"english_word": "Traffic_Light", "hindi_lipi": "ट्रैफिक लाइट", "hindi_meaning": "यातायात की बत्ती", "simple_explanation": "चौराहे पर लगी वह मशीन जिसमें लाल, पीली और हरी बत्तियां होती हैं जो गाड़ियों को रुकने और चलने का इशारा करती हैं।"}
  ]
}

def create_pdf(filename, data):
    doc = SimpleDocTemplate(filename, pagesize=A4, rightMargin=30, leftMargin=30, topMargin=30, bottomMargin=30)
    story = []
    styles = getSampleStyleSheet()

    title_style = ParagraphStyle(
        name='TitleStyle',
        parent=styles['Heading1'],
        fontName='Helvetica-Bold',
        fontSize=24,
        alignment=1,
        spaceAfter=20,
        textColor=colors.darkblue
    )

    category_style = ParagraphStyle(
        name='CategoryStyle',
        parent=styles['Heading2'],
        fontName='Helvetica-Bold',
        fontSize=16,
        spaceBefore=20,
        spaceAfter=10,
        textColor=colors.darkgreen
    )

    table_header_style = ParagraphStyle(
        name='TableHeaderStyle',
        fontName='Helvetica-Bold',
        fontSize=11,
        textColor=colors.whitesmoke,
        alignment=1
    )

    cell_style = ParagraphStyle(
        name='CellStyle',
        fontName='Hindi',
        fontSize=10,
        leading=14
    )

    english_style = ParagraphStyle(
        name='EnglishStyle',
        fontName='Helvetica-Bold',
        fontSize=11,
        textColor=colors.darkred
    )

    story.append(Paragraph("English - Hindi Vocabulary Master eBook", title_style))
    story.append(Paragraph("Learn Vocabulary with Pronunciation & Easy Meaning", ParagraphStyle(name='SubTitle', fontName='Helvetica', fontSize=14, alignment=1, spaceAfter=40)))

    for category, words in data.items():
        if len(words) == 0:
            continue

        cat_name = category.replace("_", " ")
        story.append(Paragraph(cat_name, category_style))

        table_data = []
        table_data.append([
            Paragraph("<b>English Word</b>", table_header_style),
            Paragraph("<b>Hindi Lipi</b>", table_header_style),
            Paragraph("<b>Meaning</b>", table_header_style),
            Paragraph("<b>Explanation</b>", table_header_style)
        ])

        for w in words:
            row = [
                Paragraph(w.get('english_word',''), english_style),
                Paragraph(w.get('hindi_lipi',''), cell_style),
                Paragraph(w.get('hindi_meaning',''), cell_style),
                Paragraph(w.get('simple_explanation',''), cell_style)
            ]
            table_data.append(row)

        col_widths = [80, 80, 100, 270]
        t = Table(table_data, colWidths=col_widths, repeatRows=1)
        t.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), colors.darkblue),
            ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
            ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
            ('VALIGN', (0, 0), (-1, -1), 'TOP'),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, 0), 12),
            ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
            ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
            ('GRID', (0, 0), (-1, -1), 1, colors.black),
            ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.whitesmoke, colors.lightgrey])
        ]))

        story.append(t)
        story.append(Spacer(1, 20))

    doc.build(story)

create_pdf("Vocabulary_Master_eBook.pdf", data)
print("Vocabulary Master PDF created successfully.")
